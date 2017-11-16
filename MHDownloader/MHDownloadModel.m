//
//  MHDownloadModel.m
//  MHDownloader
//
//  Created by 马浩 on 2017/11/14.
//  Copyright © 2017年 HuZhang. All rights reserved.
//

#import "MHDownloadModel.h"
#import <CommonCrypto/CommonDigest.h>

extern NSString * cacheFolder(void);

/**
 计算路径下文件大小

 @param path 文件路径
 @return 文件大小
 */
static unsigned long long fileSizeForPath(NSString *path) {
    
    signed long long fileSize = 0;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *fileDict = [fileManager attributesOfItemAtPath:path error:&error];
        if (!error && fileDict) {
            fileSize = [fileDict fileSize];
        }
    }
    return fileSize;
}

/**
 字符创MD5加密

 @param str str
 @return md5 str
 */
static NSString * getMD5String(NSString *str) {
    
    if (str == nil) return nil;
    
    const char *cstring = str.UTF8String;
    unsigned char bytes[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cstring, (CC_LONG)strlen(cstring), bytes);
    
    NSMutableString *md5String = [NSMutableString string];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [md5String appendFormat:@"%02x", bytes[i]];
    }
    return md5String;
}

@interface MHDownloadModel()

@property (nonatomic, assign) MHDownloadState state;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *filename;
@property(nonatomic,assign)kDownloadType downloadType;
@property (nonatomic, assign) CGFloat progress;
@property (assign, nonatomic) long long totalBytesWritten;

@end
@implementation MHDownloadModel

#pragma mark - get方法
#pragma mark - 文件路径
- (NSString *)filePath {
    if (!_filePath) {
        NSString *path = [cacheFolder() stringByAppendingPathComponent:self.filename];
        _filePath = path;
    }
    return _filePath;
}
#pragma mark - 文件名
- (NSString *)filename {
    if (!_filename) {
        if (self.fileTrueName == nil) {
            self.fileTrueName = self.url.lastPathComponent;
        }
        _filename = self.url.lastPathComponent;
        NSString *pathExtension = _filename.pathExtension;
        if (pathExtension.length) {
            _filename = [NSString stringWithFormat:@"%@.%@", getMD5String(_filename), pathExtension];
        } else {
            _filename = getMD5String(_filename);
        }
    }
    return _filename;
}
#pragma mark - 已下载大小
- (long long)totalBytesWritten {
    
    return fileSizeForPath(self.filePath);
}

- (instancetype)initWithURL:(NSString *)url {
    if (self = [self init]) {
        self.url = url;
    }
    return self;
}
#pragma mark - NSCoding
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.url forKey:NSStringFromSelector(@selector(url))];
    [aCoder encodeObject:@(self.state) forKey:NSStringFromSelector(@selector(state))];
    [aCoder encodeObject:self.filename forKey:NSStringFromSelector(@selector(filename))];
    [aCoder encodeObject:self.fileTrueName forKey:NSStringFromSelector(@selector(fileTrueName))];
    [aCoder encodeObject:@(self.downloadType) forKey:NSStringFromSelector(@selector(downloadType))];
    [aCoder encodeObject:@(self.totalBytesWritten) forKey:NSStringFromSelector(@selector(totalBytesWritten))];
    [aCoder encodeObject:@(self.totalBytesExpectedToWrite) forKey:NSStringFromSelector(@selector(totalBytesExpectedToWrite))];
    [aCoder encodeObject:@(self.progress) forKey:NSStringFromSelector(@selector(progress))];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.url = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(url))];
        self.state = [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(state))] unsignedIntegerValue];
        self.filename = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(filename))];
        self.fileTrueName = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(fileTrueName))];
        self.downloadType = [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(downloadType))] unsignedIntegerValue];
        self.totalBytesWritten = [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(totalBytesWritten))] unsignedIntegerValue];
        self.totalBytesExpectedToWrite = [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(totalBytesExpectedToWrite))] unsignedIntegerValue];
        self.progress = [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(progress))] unsignedIntegerValue];
    }
    return self;
}
#pragma mark - 初始化方法
- (nonnull instancetype)initWithURLString:(nonnull NSString *)URLString
                  downloaderProgressBlock:(nullable MHDownloaderProgressBlock)downloaderProgressBlock
                 downloaderCompletedBlock:(nullable MHDownloaderCompletedBlock)downloaderCompletedBlock
{
    if (self = [self init]) {
        self.url = URLString;
        self.downloadType = kDownloadTypeUnKnow;
        self.totalBytesExpectedToWrite = 0;
        self.downloaderProgressBlock = downloaderProgressBlock;
        self.downloaderCompletedBlock = downloaderCompletedBlock;
    }
    return self;
}

/**
 只读属性set方法
 */
- (void)setTotalBytesExpectedToWrite:(long long)totalBytesExpectedToWrite
{
    _totalBytesExpectedToWrite = totalBytesExpectedToWrite;
}
- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
}
- (void)setState:(MHDownloadState)state
{
    _state = state;
}
- (void)setFileTrueName:(NSString * _Nullable)fileTrueName
{
    _fileTrueName = fileTrueName;
}
- (void)setDownloaderProgressBlock:(nullable MHDownloaderProgressBlock)downloaderProgressBlock
{
    _downloaderProgressBlock = downloaderProgressBlock;
}
- (void)setDownloaderCompletedBlock:(nullable MHDownloaderCompletedBlock)downloaderCompletedBlock
{
    _downloaderCompletedBlock = downloaderCompletedBlock;
}
- (void)setSpeed:(NSString * _Nullable)speed
{
    _speed = speed;
}
-(void)setDownloadType:(kDownloadType)downloadType
{
    _downloadType = downloadType;
}

@end
