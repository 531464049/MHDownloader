//
//  MHDownloadOpration.m
//  MHDownloader
//
//  Created by 马浩 on 2017/11/14.
//  Copyright © 2017年 HuZhang. All rights reserved.
//

#import "MHDownloadOpration.h"
NS_ASSUME_NONNULL_BEGIN

static NSString *const kProgressCallbackKey = @"progress";
static NSString *const kCompletedCallbackKey = @"completed";

typedef NSMutableDictionary<NSString *, id> MHCallbacksDictionary;

@interface MHDownloadOpration ()

@property (strong, nonatomic, nonnull) NSMutableArray<MHCallbacksDictionary *> *callbackBlocks;

@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;

// 与当前事务关联的下载任务 不太懂这里
@property (weak, nonatomic, nullable) NSURLSession *unownedSession;
// 如果初始化没传入session，需要自己创建？且需要自行销毁
@property (strong, nonatomic, nullable) NSURLSession *ownedSession;
// 下载任务
@property (strong, nonatomic, readwrite, nullable) NSURLSessionTask *dataTask;

@property (strong, nonatomic, nullable) dispatch_queue_t barrierQueue;

@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;

@property (assign, nonatomic) long long totalBytesWritten;
@property (assign, nonatomic) long long totalBytesExpectedToWrite;

@property (strong, nonatomic) MHDownloadModel * downloadModel;
@end

@implementation MHDownloadOpration
{
    BOOL responseFromCached; //貌似是用来判断响应是否从缓存中读取，默认是会从缓存中读取的
}
@synthesize executing = _executing;
@synthesize finished = _finished;

- (MHDownloadModel *)downloadModel {
    if (!_downloadModel) {
        _downloadModel = [[MHDownloader sharedDownloader] downloadModelForURLString:self.request.URL.absoluteString];
    }
    return _downloadModel;
}
- (nonnull instancetype)init {
    return [self initWithRequest:nil inSession:nil];
}
#pragma mark - 初始化
- (nonnull instancetype)initWithRequest:(nullable NSURLRequest *)request inSession:(nullable NSURLSession *)session  {
    if ((self = [super init])) {
        _request = [request copy];
        _callbackBlocks = [NSMutableArray new];
        _executing = NO;
        _finished = NO;
        _expectedSize = 0;
        _unownedSession = session;
        responseFromCached = YES;
        _barrierQueue = dispatch_queue_create("com.mahao.MHDownloaderOperationBarrierQueue", DISPATCH_QUEUE_CONCURRENT);
        
        [self.downloadModel setState:MHDownloadStateWillResume];
    }
    return self;
}
- (void)dealloc {
    
}
#pragma mark - 添加下载进度/下载完成/失败回调
- (nullable id)addHandlersForProgress:(nullable MHDownloaderProgressBlock)progressBlock
                            completed:(nullable MHDownloaderCompletedBlock)completedBlock {
    MHCallbacksDictionary *callbacks = [NSMutableDictionary new];
    if (progressBlock) callbacks[kProgressCallbackKey] = [progressBlock copy];
    if (completedBlock) callbacks[kCompletedCallbackKey] = [completedBlock copy];
    dispatch_barrier_async(self.barrierQueue, ^{
        [self.callbackBlocks addObject:callbacks];
    });
    return callbacks;
}
- (nullable NSArray<id> *)callbacksForKey:(NSString *)key {
    //不懂？？？？？？？？
    __block NSMutableArray<id> *callbacks = nil;
    dispatch_sync(self.barrierQueue, ^{
        // We need to remove [NSNull null] because there might not always be a progress block for each callback
        callbacks = [[self.callbackBlocks valueForKey:key] mutableCopy];
        [callbacks removeObjectIdenticalTo:[NSNull null]];
    });
    return [callbacks copy];    // strip mutability here
}
#pragma mark - 判断是否可取消，如果可以，直接取消当前事务
- (BOOL)cancel:(nullable id)token {
    __block BOOL shouldCancel = NO;
    dispatch_barrier_sync(self.barrierQueue, ^{
        //删除所有的回调blocks
        [self.callbackBlocks removeAllObjects];
        if (self.callbackBlocks.count == 0) {
            shouldCancel = YES;
        }
    });
    if (shouldCancel) {
        //如果可以取消，直接在这里取消
        [self cancel];
    }
    return shouldCancel;
}
#pragma mark - NSOperation的start方法
- (void)start
{
    @synchronized (self) {
    //开启线程同步锁，保证线程操作安全
        if (self.isCancelled) {
            self.finished = YES;
            [self reset];
            return;
        }
        
        __weak __typeof__ (self) wself = self;
        UIApplication * app = [UIApplication sharedApplication];
        self.backgroundTaskId = [app beginBackgroundTaskWithExpirationHandler:^{
            __strong __typeof (wself) sself = wself;
            if (sself) {
                [sself cancel];
                [app endBackgroundTask:sself.backgroundTaskId];
                sself.backgroundTaskId = UIBackgroundTaskInvalid;
            }
        }];
        NSURLSession * session = self.unownedSession;
        if (!self.unownedSession) {
            NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
            sessionConfig.timeoutIntervalForRequest = 15;

            self.ownedSession = [NSURLSession sessionWithConfiguration:sessionConfig
                                                              delegate:self
                                                         delegateQueue:nil];
            session = self.ownedSession;
        }
        
        self.dataTask = [session dataTaskWithRequest:self.request];
        self.executing = YES;
        
    //同步锁结束
    }
    [self.dataTask resume];
    
    if (self.dataTask) {
        //这里也是不懂
        for (MHDownloaderProgressBlock progressBlock in [self callbacksForKey:kProgressCallbackKey]) {
            progressBlock(0, NSURLResponseUnknownLength, 0, self.request.URL);
        }
        [self.downloadModel setState:MHDownloadStateDownloading];
        dispatch_async(dispatch_get_main_queue(), ^{
           //在这里可以发送开启下载的通知
        });
    }else{
        //无法建立下载请求。。。
        [self callCompletionBlocksWithError:[NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"无法建立下载请求。。。"}]];
    }
    
    if (self.backgroundTaskId != UIBackgroundTaskInvalid) {
        [UIApplication.sharedApplication endBackgroundTask:self.backgroundTaskId];
        self.backgroundTaskId = UIBackgroundTaskInvalid;
    }
}
#pragma mark - NSOperation的cancel方法
-(void)cancel
{
    @synchronized (self) {
        [self cancelInternal];
    }
}
#pragma mark - 取消下载事务，重置下载状态，属性
-(void)cancelInternal
{
    if (self.isFinished) return;
    [super cancel];
    
    if (self.dataTask) {
        [self.dataTask cancel];//取消下载任务
        [self.downloadModel setState:MHDownloadStateSuspened];//设置暂停状态
        dispatch_async(dispatch_get_main_queue(), ^{
           //发送暂停的通知，或其他操作
        });
        
        if (self.isExecuting) self.executing = NO;//将队列执行状态设置为no
        if (!self.isFinished) self.finished = YES;//将队列完成状态设置为yes
    }
    [self reset];
}
#pragma mark - 下载完成/失败后重置
-(void)done
{
    self.executing = NO;
    self.finished = YES;
    [self reset];
}
#pragma mark - 销毁下载任务（当下在完成/下载取消时）
- (void)reset {
    dispatch_barrier_async(self.barrierQueue, ^{
        [self.callbackBlocks removeAllObjects];
    });
    self.dataTask = nil;
    if (self.ownedSession) {
        [self.ownedSession invalidateAndCancel];
        self.ownedSession = nil;
    }
}
#pragma mark - 事务状态set方法(willChange/didChange是做啥的？？)
- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}
- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}
- (BOOL)isConcurrent {
    return YES;
}
#pragma mark - session代理方法
#pragma mark - 下载请求获取到response，通过http状态码判断该下载请求是否可用
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    
    if (![response respondsToSelector:@selector(statusCode)] || (((NSHTTPURLResponse *)response).statusCode < 400 && ((NSHTTPURLResponse *)response).statusCode != 304)) {
        //response没有http状态码，或者状态码<400且不等304（小于400代表无错误，304代表请求内容未作修改（感觉这里的判断是从图片加载库里边拔过来的））
        
        //还需要从服务器请求的文件长度
        NSInteger expected = response.expectedContentLength > 0 ? (NSInteger)response.expectedContentLength : 0;
        
        MHDownloadModel * downloadModel = [[MHDownloader sharedDownloader] downloadModelForURLString:self.request.URL.absoluteString];
        [downloadModel setTotalBytesExpectedToWrite:expected + downloadModel.totalBytesWritten];
        downloadModel.date = [NSDate date];
        
        self.expectedSize = expected;
        for (MHDownloaderProgressBlock progressBlock in [self callbacksForKey:kProgressCallbackKey]) {
            progressBlock(0,expected,0,self.request.URL);
        }
        
        self.response = response;
        dispatch_async(dispatch_get_main_queue(), ^{
            //在这里可以发送下载器获取到下载请求response的通知，或者其他操作
        });
    }else if (![response respondsToSelector:@selector(statusCode)] || ((NSHTTPURLResponse *)response).statusCode == 416) {
        //response没有http状态码，或者请求的范围不符合要求（服务器无法提供请求的东西？？）
        
        //这里可以发送请求成功的通知或者其他操作
        [self callCompletionBlocksWithError:nil];
        [self done];
    }else {
        //小于400，不等304，等416已经排除，剩下的就是400+基本就是失败了
        [self cancelInternal];
        [self.downloadModel setState:MHDownloadStateFailed];
        [self callCompletionBlocksWithError:[NSError errorWithDomain:NSURLErrorDomain code:((NSHTTPURLResponse *)response).statusCode userInfo:nil]];
        dispatch_async(dispatch_get_main_queue(), ^{
            //发送失败的通知，或者其他操作
        });
    }
    
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
}
#pragma mark - session获取到下载内容data，写入文件，计算下载速度
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    __block NSError * error = nil;
    MHDownloadModel * downloadModel = [[MHDownloader sharedDownloader] downloadModelForURLString:self.request.URL.absoluteString];
    
    //计算下载速度
    downloadModel.totalRead += data.length;
    NSDate * curentDate = [NSDate date];
    if ([curentDate timeIntervalSinceDate:downloadModel.date] >= 1) {
        double time = [curentDate timeIntervalSinceDate:downloadModel.date];
        long long speed = downloadModel.totalRead / time;
        downloadModel.speed = [self formatByteCount:speed];
        downloadModel.totalRead = 0.0;
        downloadModel.date = curentDate;
    }
    
    //写文件
    NSInputStream * inputStream = [[NSInputStream alloc] initWithData:data];
    NSOutputStream * outputStream = [[NSOutputStream alloc] initWithURL:[NSURL fileURLWithPath:downloadModel.filePath] append:YES];
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [inputStream open];
    [outputStream open];
    
    while ([inputStream hasBytesAvailable] && [outputStream hasSpaceAvailable]) {
        uint8_t buffer[1024];
        
        NSInteger bytesRead = [inputStream read:buffer maxLength:1024];
        if (inputStream.streamError || bytesRead < 0) {
            error = inputStream.streamError;
            break;
        }
        
        NSInteger bytesWritten = [outputStream write:buffer maxLength:(NSUInteger)bytesRead];
        if (outputStream.streamError || bytesWritten < 0) {
            error = outputStream.streamError;
            break;
        }
        
        if (bytesRead == 0 && bytesWritten == 0) {
            break;
        }
    }
    [outputStream close];
    [inputStream close];
    //更新下载信息block
    dispatch_main_async_safe(^{
        //更新下载进度
        downloadModel.progress = (downloadModel.totalBytesWritten/1024.0/1024.0) / (downloadModel.totalBytesExpectedToWrite/1024.0/1024.0);

        for (MHDownloaderProgressBlock progressBlock in [self callbacksForKey:kProgressCallbackKey]) {
            progressBlock(downloadModel.totalBytesWritten,downloadModel.totalBytesExpectedToWrite,downloadModel.speed.integerValue,self.request.URL);
        }
        if (self.downloadModel.downloaderProgressBlock) {
            self.downloadModel.downloaderProgressBlock(downloadModel.totalBytesWritten,downloadModel.totalBytesExpectedToWrite,downloadModel.speed.integerValue,self.request.URL);
        }
    });
}
#pragma mark - 这是一个关于缓存的代理-感觉没什么卵用，responseFromCached这个bool值应该也没啥用
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse * _Nullable))completionHandler
{
    responseFromCached = NO; // If this method is called, it means the response wasn't read from cache
    NSCachedURLResponse *cachedResponse = proposedResponse;
    if (completionHandler) {
        completionHandler(cachedResponse);
    }
}
#pragma mark - session代理方法 完成/失败
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error
{
    @synchronized (self) {
        self.dataTask = nil;
        //这里可以选择发送成功/失败的通知，或者其他操作
    }
    if (error) {
        [self callCompletionBlocksWithError:error];
    }else{
        [self callCompletionBlocksWithError:nil];
    }
    [self done];
}
#pragma mark - 发送下载失败block
-(void)callCompletionBlocksWithError:(nullable NSError *)error
{
    //这应该是从其他文件下载库（图片加载）拔过来的，原本应该是想通过block回调文件下载后的本地地址，本地文件
    if (error) {
        [self.downloadModel setState:MHDownloadStateFailed];
    }else{
        [self.downloadModel setState:MHDownloadStateCompleted];
    }
    
    NSArray<id> * completionBlocks = [self callbacksForKey:kCompletedCallbackKey];
    dispatch_main_async_safe(^{
        for (MHDownloaderCompletedBlock completedBlock in completionBlocks) {
            completedBlock(self.downloadModel,error,YES);
        }
        
        if (self.downloadModel.downloaderCompletedBlock) {
            self.downloadModel.downloaderCompletedBlock(self.downloadModel, error, YES);
        }
    });
}
#pragma mark - 将文件大小size转换成多少B
- (NSString*)formatByteCount:(long long)size
{
    return [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile];
}
@end

NS_ASSUME_NONNULL_END
