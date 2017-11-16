//
//  MHDownloader.m
//  MHDownloader
//
//  Created by 马浩 on 2017/11/14.
//  Copyright © 2017年 HuZhang. All rights reserved.
//

#import "MHDownloader.h"

NSString * const MHDownloadCacheFolderName = @"MHDownloadCache";

static NSString *cacheFolderPath;

NSString * cacheFolder() {
    if (!cacheFolderPath) {
        NSString *cacheDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject;
        cacheFolderPath = [cacheDir stringByAppendingPathComponent:MHDownloadCacheFolderName];
        NSFileManager *filemgr = [NSFileManager defaultManager];
        NSError *error = nil;
        if(![filemgr createDirectoryAtPath:cacheFolderPath withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Failed to create cache directory at %@", cacheFolderPath);
            cacheFolderPath = nil;
        }
    }
    return cacheFolderPath;
}

static void clearCacheFolder() {
    cacheFolderPath = nil;
}

static NSString * LocalDownloadModelsPath() {
    return [cacheFolder() stringByAppendingPathComponent:@"downloadModels.data"];
}

static NSString * LocalDownloadUrlArrPath() {
    return [cacheFolder() stringByAppendingPathComponent:@"localDownLoadUrlArr.data"];
}
@interface MHDownloader() <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>
//下载队列
@property (strong, nonatomic, nonnull) NSOperationQueue * downloadQueue;
//最后一次添加的事务
@property (weak, nonatomic, nullable) NSOperation *lastAddedOperation;
//保存所有下载事务的字典（url：operation）
@property (strong, nonatomic, nonnull) NSMutableDictionary<NSURL *, MHDownloadOpration *> *URLOperations;
//这个是用来序列化单个下载事务的网络响应（暂时还不懂到底是怎么个意思）
@property (strong, nonatomic, nullable) dispatch_queue_t barrierQueue;

@property (strong, nonatomic) NSURLSession *session;
//保存全部下载信息的字典（url：model）
@property (nonatomic, strong) NSMutableDictionary *allDownloadModels;

@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;
@end

@implementation MHDownloader

#pragma mark - get 获取本地所有下载信息字典（url：model）
- (NSMutableDictionary *)allDownloadModels {
    if (!_allDownloadModels) {
        NSDictionary *models = [NSKeyedUnarchiver unarchiveObjectWithFile:LocalDownloadModelsPath()];
        _allDownloadModels = models != nil ? models.mutableCopy : [NSMutableDictionary dictionary];
    }
    return _allDownloadModels;
}
#pragma mark - get 获取本地所有下载地址数组
-(NSMutableArray *)allDownloadUrlArr
{
    if (_allDownloadUrlArr == nil) {
        NSArray *urlArr = [NSKeyedUnarchiver unarchiveObjectWithFile:LocalDownloadUrlArrPath()];
        _allDownloadUrlArr = urlArr != nil ? urlArr.mutableCopy : [NSMutableArray array];
    }
    return _allDownloadUrlArr;
}
#pragma mark - 单例
+ (nonnull instancetype)sharedDownloader {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}
#pragma mark - 初始化方法
- (nonnull instancetype)init {
    return [self initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
}
- (nonnull instancetype)initWithSessionConfiguration:(nullable NSURLSessionConfiguration *)sessionConfiguration
{
    if (self = [super init]) {
        //初始化下载器设置
        _downloadPrioritizaton = MHDownloadPrioritizationFIFO;
        _downloadQueue = [NSOperationQueue new];
        _downloadQueue.maxConcurrentOperationCount = 3;//同时下载数量
        _downloadQueue.name = @"com.mh.MHDownloader";
        
        _URLOperations = [NSMutableDictionary new];
        //这个queue现在还不懂
        _barrierQueue = dispatch_queue_create("com.mh.MHDownloaderBarrierQueue", DISPATCH_QUEUE_CONCURRENT);
        
        _downloadTimeout = 15.0;//响应超时时间
        
        sessionConfiguration.timeoutIntervalForRequest = _downloadTimeout;
        sessionConfiguration.HTTPMaximumConnectionsPerHost = 10;
        
        self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
        
        //添加app状态改变的通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}
#pragma mark - 初始化方法
-(nullable MHDownloadModel *)addDownLoadWithUrl:(nullable NSURL *)url
{
    return [self addDownloadWithUrl:url fileName:nil type:kDownloadTypeUnKnow progress:nil completed:nil];
}
#pragma mark - 添加一个下载任务（提供文件名，文件类型）
-(nullable MHDownloadModel *)addDownLoadWithUrl:(nullable NSURL *)url
                                       fileName:(nullable NSString *)fileName
                                           type:(kDownloadType)downloadType
{
    return [self addDownloadWithUrl:url fileName:fileName type:kDownloadTypeUnKnow progress:nil completed:nil];
}
#pragma mark - 添加一个下载任务，包含下载进度，下载完成/失败回调block
- (nullable MHDownloadModel *)addDownloadDataWithURL:(nullable NSURL *)url
                                            progress:(nullable MHDownloaderProgressBlock)progressBlock
                                           completed:(nullable MHDownloaderCompletedBlock)completedBlock
{
    return [self addDownloadWithUrl:url fileName:nil type:kDownloadTypeUnKnow progress:progressBlock completed:completedBlock];
}
#pragma mark - 添加一个下载任务，（提供文件名，文件类型）包含下载进度，下载完成/失败回调block
-(nullable MHDownloadModel *)addDownloadWithUrl:(nullable NSURL *)url
                                       fileName:(nullable NSString *)fileName
                                           type:(kDownloadType)downloadType
                                       progress:(nullable MHDownloaderProgressBlock)progressBlock
                                      completed:(nullable MHDownloaderCompletedBlock)completedBlock
{
    MHDownloadModel * model;
    if ([self hasCurentDownload:url.absoluteString fileName:fileName]) {
        //如果已存在该下载任务，直接取出该下载任务
        model = [self downloadModelForURLString:url.absoluteString];
    }else{
        //初始化一个下载信息
        model = [[MHDownloadModel alloc] initWithURLString:url.absoluteString downloaderProgressBlock:progressBlock downloaderCompletedBlock:completedBlock];
        model.fileTrueName = fileName;
        model.downloadType = downloadType;
        self.allDownloadModels[url.absoluteString] = model;
        [self.allDownloadUrlArr addObject:url.absoluteString];
    }
    
    if (model.state == MHDownloadStateCompleted) {
        //如果该下载任务已经是完成状态，直接返回下载完成的block回调
        dispatch_main_async_safe(^{
            
            if (completedBlock) {
                completedBlock(model ,nil ,YES);
            }
            if (model.downloaderCompletedBlock) {
                model.downloaderCompletedBlock(model, nil, YES);
            }
        });
        return model;
    }
    return [self addProgressCallBack:progressBlock completedBlock:completedBlock forURL:url];
}
#pragma mark - 将下载任务添加到下载队列
-(nullable MHDownloadModel *)addProgressCallBack:(MHDownloaderProgressBlock )progressBlock completedBlock:(MHDownloaderCompletedBlock )completedBlock forURL:(nullable NSURL *)url
{
    if (url == nil) {
        if (completedBlock != nil) {
            completedBlock(nil, nil, NO);
        }
        return nil;
    }
     __weak MHDownloader * wself = self;
    __block MHDownloadModel * model = nil;
    
    dispatch_barrier_sync(self.barrierQueue, ^{
        //这里不算太明白，按照我的理解就是，当任务进行到这里，所有线程都需要等这边处理完毕才能进行，感觉是一个线程同步锁
        
        //尝试从当前队列信息里去除事务，如果没有则创建新的事务
        MHDownloadOpration * operation = self.URLOperations[url];
        if (!operation) {
            __strong __typeof (wself) sself = wself;
            //创建operation
            operation = [sself creatOperation:url];
            self.URLOperations[url] = operation;//保存
            
            __weak MHDownloadOpration * woperation = operation;
            operation.completionBlock = ^{
                MHDownloadOpration * soperation = woperation;
                if (!soperation) return;
                if (self.URLOperations[url] == soperation) {
                    [self.URLOperations removeObjectForKey:url];
                }
            };
        }
        [operation addHandlersForProgress:progressBlock completed:completedBlock];
        
        if (!self.allDownloadModels[url.absoluteString]) {
            //这里有判断了一次有没有model，感觉有点多余了
            model = [[MHDownloadModel alloc] initWithURLString:url.absoluteString downloaderProgressBlock:progressBlock downloaderCompletedBlock:completedBlock];
            self.allDownloadModels[url.absoluteString] = model;
            [self.allDownloadUrlArr addObject:url.absoluteString];
        }else{
            model = self.allDownloadModels[url.absoluteString];
        }
    });
    return model;
}
#pragma mark - 将当前下载地址添加到线程，返回一个operation实例
-(MHDownloadOpration *)creatOperation:(nullable NSURL *)url
{
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    MHDownloadModel * model = [self downloadModelForURLString:url.absoluteString];
    if (model.totalBytesWritten > 0) {
        NSString *range = [NSString stringWithFormat:@"bytes=%zd-", model.totalBytesWritten];
        [request setValue:range forHTTPHeaderField:@"Range"];
    }
    request.HTTPShouldUsePipelining = YES;
    
    MHDownloadOpration * operation = [[MHDownloadOpration alloc] initWithRequest:request inSession:self.session];
    [self.downloadQueue addOperation:operation];
    if (self.downloadPrioritizaton == MHDownloadPrioritizationLIFO) {
        //如果队列进行方式是先进后出
        [self.lastAddedOperation addDependency:operation];
        self.lastAddedOperation = operation;
    }
    
    return operation;
}
#pragma mark - 判断当前下载任务是否已存在
-(BOOL )hasCurentDownLoad:(NSString *)url
{
    return [self hasCurentDownload:url fileName:nil];
}
#pragma mark - 判断当前下载任务是否已存在
-(BOOL )hasCurentDownload:(NSString *)url fileName:(NSString *)fileName
{
    if ([self.allDownloadUrlArr containsObject:url]) {
        return YES;
    }
    MHDownloadModel * model = self.allDownloadModels[@"url"];
    if (model) {
        return YES;
    }
    if (fileName) {
        for (MHDownloadModel * model in self.allDownloadModels.allValues) {
            if ([model.fileTrueName isEqualToString:fileName]) {
                return YES;
            }
        }
    }
    return NO;
}
#pragma mark - 根据下载地址获取下载信息model
- (nullable MHDownloadModel *)downloadModelForURLString:(nullable NSString *)URLString
{
    if (self.allDownloadModels[URLString]) {
        return self.allDownloadModels[URLString];
    }
    return nil;
}
#pragma mark - 下载控制-暂停/开始/删除
#pragma mark - 暂停
- (void)suspened:(nullable MHDownloadModel *)downloadModel
{
    [self suspened:downloadModel completed:nil];
}
- (void)suspened:(nullable MHDownloadModel *)downloadModel completed:(nullable void (^)(void))completed
{
    //感觉这里应该判断下当前model是否是已完成
    dispatch_barrier_async(self.barrierQueue, ^{
        MHDownloadOpration * operation = self.URLOperations[[NSURL URLWithString:downloadModel.url]];
        BOOL cancled = [operation cancel:nil];
        if (cancled) {
            [self.URLOperations removeObjectForKey:[NSURL URLWithString:downloadModel.url]];
            [downloadModel setState:MHDownloadStateSuspened];
        }
        dispatch_main_async_safe(^{
            if (completed) {
                completed();
            }
        });
    });
}
#pragma mark - 开始
- (void)start:(nullable MHDownloadModel *)downloadModel
{
    [self start:downloadModel completed:nil];
}
- (void)start:(nullable MHDownloadModel *)downloadModel completed:(nullable void (^)(void))completed
{
    [self addDownLoadWithUrl:[NSURL URLWithString:downloadModel.url]];
    dispatch_main_async_safe(^{
        if (completed) {
            completed();
        }
    });
}
#pragma mark - 删除
- (void)remove:(nullable MHDownloadModel *)downloadModel
{
    [self remove:downloadModel completed:nil];
}
- (void)remove:(nullable MHDownloadModel *)downloadModel completed:(nullable void (^)(void))completed
{
    [downloadModel setState:MHDownloadStateNone];
    [self suspened:downloadModel completed:^{
        NSFileManager * fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:downloadModel.filePath error:nil];
        [self.allDownloadModels removeObjectForKey:downloadModel.url];
        [self.allDownloadUrlArr removeObject:downloadModel.url];
        dispatch_main_async_safe(^{
            if (completed) {
                completed();
            }
        });
    }];
}
#pragma mark - 暂停全部
- (void)suspendAllDownloads
{
    [self.downloadQueue cancelAllOperations];
    [self setAllDownloadModelStateToSuspened];
    [self saveAllDownloadReceipts];
    [self saveAllDownloadUrlArr];
}
#pragma mark - 设置全部下载信息model-暂停
- (void)setAllDownloadModelStateToSuspened {
    [self.allDownloadModels enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[MHDownloadModel class]]) {
            MHDownloadModel *model = obj;
            if (model.state != MHDownloadStateCompleted) {
                [model setState:MHDownloadStateSuspened];
            }
        }
    }];
}
#pragma mark - 开始全部
- (void)startAllDownloads
{
    for (NSString * url in self.allDownloadUrlArr) {
        [self start:[self downloadModelForURLString:url]];
    }
}
#pragma mark - 删除全部
- (void)removeAndClearAll
{
    [self suspendAllDownloads];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:cacheFolder() error:nil];
    clearCacheFolder();
}
#pragma mark - 本地保存 所有下载信息
- (void)saveAllDownloadReceipts {
    [NSKeyedArchiver archiveRootObject:self.allDownloadModels toFile:LocalDownloadModelsPath()];
}
#pragma mark - 本地保存 所有下载地址
-(void)saveAllDownloadUrlArr
{
    [NSKeyedArchiver archiveRootObject:self.allDownloadUrlArr toFile:LocalDownloadUrlArrPath()];
}
#pragma mark - 根据task取出operation
- (MHDownloadOpration *)operationWithTask:(NSURLSessionTask *)task {
    MHDownloadOpration *returnOperation = nil;
    for (MHDownloadOpration *operation in self.downloadQueue.operations) {
        if (operation.dataTask.taskIdentifier == task.taskIdentifier) {
            returnOperation = operation;
            break;
        }
    }
    return returnOperation;
}
#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    MHDownloadOpration *dataOperation = [self operationWithTask:dataTask];
    [dataOperation URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
    
}
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
    MHDownloadOpration *dataOperation = [self operationWithTask:dataTask];
    [dataOperation URLSession:session dataTask:dataTask didReceiveData:data];
    
}
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler {
    
    MHDownloadOpration *dataOperation = [self operationWithTask:dataTask];
    [dataOperation URLSession:session dataTask:dataTask willCacheResponse:proposedResponse completionHandler:completionHandler];
    
}
#pragma mark - NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    MHDownloadOpration *dataOperation = [self operationWithTask:task];
    [dataOperation URLSession:session task:task didCompleteWithError:error];
    
}
#pragma mark -  NSNotification
#pragma mark - app将要退出
- (void)applicationWillTerminate:(NSNotification *)not {
    [self setAllDownloadModelStateToSuspened];
    [self saveAllDownloadUrlArr];
    [self saveAllDownloadReceipts];
}
#pragma mark - app收到内存警告
- (void)applicationDidReceiveMemoryWarning:(NSNotification *)not {
    [self saveAllDownloadUrlArr];
    [self saveAllDownloadReceipts];
}
#pragma mark - app将要进入后台
- (void)applicationWillResignActive:(NSNotification *)not {
    [self saveAllDownloadUrlArr];
    [self saveAllDownloadReceipts];
    /// 捕获到失去激活状态后
    __weak __typeof__ (self) wself = self;
    self.backgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        __strong __typeof (wself) sself = wself;

        if (sself) {
            [sself setAllDownloadModelStateToSuspened];
            [sself saveAllDownloadUrlArr];
            [sself saveAllDownloadReceipts];

            [[UIApplication sharedApplication] endBackgroundTask:sself.backgroundTaskId];
            sself.backgroundTaskId = UIBackgroundTaskInvalid;
        }
    }];
}
#pragma mark - app将要变成第一响应（前台）
- (void)applicationDidBecomeActive:(NSNotification *)not {
    if (self.backgroundTaskId != UIBackgroundTaskInvalid) {
        UIApplication * app = [UIApplication sharedApplication];
        [app endBackgroundTask:self.backgroundTaskId];
        self.backgroundTaskId = UIBackgroundTaskInvalid;
    }
}
- (void)dealloc {
    [self.session invalidateAndCancel];
    self.session = nil;
    [self.downloadQueue cancelAllOperations];
    //按理说应该把注册的那些通知给移除吧？？？？？
}
@end
