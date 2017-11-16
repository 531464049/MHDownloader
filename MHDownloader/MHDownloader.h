//
//  MHDownloader.h
//  MHDownloader
//
//  Created by 马浩 on 2017/11/14.
//  Copyright © 2017年 HuZhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MHDownloadModel.h"
#import "MHDownloadOpration.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Use dispatch_main_async_safe instead of dispatch_async(dispatch_get_main_queue(), block)
//这个不懂 不知道直接用dispatch_async(dispatch_get_main_queue(), block有啥问题
#ifndef dispatch_main_async_safe
#define dispatch_main_async_safe(block)\
if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}
#endif


FOUNDATION_EXPORT NSString * const MHDownloadCacheFolderName;
FOUNDATION_EXPORT NSString * cacheFolder(void);

@interface MHDownloader : NSObject

/**
 * 当前还未下载完成的数量
 */
@property (readonly, nonatomic) NSUInteger currentDownloadCount;

/**
 *  下载进程 超时时间 默认15秒
 */
@property (assign, nonatomic) NSTimeInterval downloadTimeout;

/**
 全部下载地址
 */
@property(nonatomic,strong)NSMutableArray * allDownloadUrlArr;

/**
 下载队列 次序（先进先出，后进先出），默认先进先出FIFO
 */
@property (nonatomic, assign) MHDownloadPrioritization downloadPrioritizaton;


/**
 下载器单例

 @return 全局下载器
 */
+ (nonnull instancetype)sharedDownloader;

#pragma mark - 判断是否存在下载任务
/**
 判断当前下载任务是否已存在
 
 @param url 下载地址
 @return 是否已存在当前下载地址
 */
-(BOOL )hasCurentDownLoad:(NSString *)url;


/**
 判断当前下载任务是否已存在
 
 @param url 下载地址
 @param fileName 文件名字
 @return 是否已存在当前下载地址
 */
-(BOOL )hasCurentDownload:(NSString *)url fileName:(nullable NSString *)fileName;

#pragma mark - 初始化方法
/**
 添加一个下载任务

 @param url 下载地址
 @return 下载信息model
 */
-(nullable MHDownloadModel *)addDownLoadWithUrl:(nullable NSURL *)url;

/**
 添加一个下载任务（提供文件名，文件类型）

 @param url 下载地址
 @param fileName 文件名
 @param downloadType 文件类型
 @return 下载信息model
 */
-(nullable MHDownloadModel *)addDownLoadWithUrl:(nullable NSURL *)url
                                       fileName:(nullable NSString *)fileName
                                           type:(kDownloadType)downloadType;

/**
 添加一个下载任务，包含下载进度，下载完成/失败回调block

 @param url 下载地址
 @param progressBlock 下载进度回调
 @param completedBlock 下载完成/失败回调
 @return 下载信息model
 */
- (nullable MHDownloadModel *)addDownloadDataWithURL:(nullable NSURL *)url
                                            progress:(nullable MHDownloaderProgressBlock)progressBlock
                                           completed:(nullable MHDownloaderCompletedBlock)completedBlock;

/**
 添加一个下载任务，（提供文件名，文件类型）包含下载进度，下载完成/失败回调block

 @param url 下载地址
 @param fileName 文件名
 @param downloadType 文件类型
 @param progressBlock 下载进度回调
 @param completedBlock 下载完成/失败回调
 @return 下载信息model
 */
-(nullable MHDownloadModel *)addDownloadWithUrl:(nullable NSURL *)url
                                       fileName:(nullable NSString *)fileName
                                           type:(kDownloadType)downloadType
                                       progress:(nullable MHDownloaderProgressBlock)progressBlock
                                      completed:(nullable MHDownloaderCompletedBlock)completedBlock;


/**
 根据下载地址获取下载信息model

 @param URLString 下载地址
 @return 下载信息model
 */
- (nullable MHDownloadModel *)downloadModelForURLString:(nullable NSString *)URLString;

#pragma mark - 下载控制-暂停/开始/删除
- (void)suspened:(nullable MHDownloadModel *)downloadModel;
- (void)suspened:(nullable MHDownloadModel *)downloadModel completed:(nullable void (^)(void))completed;
- (void)start:(nullable MHDownloadModel *)downloadModel;
- (void)start:(nullable MHDownloadModel *)downloadModel completed:(nullable void (^)(void))completed;
- (void)remove:(nullable MHDownloadModel *)downloadModel;
- (void)remove:(nullable MHDownloadModel *)downloadModel completed:(nullable void (^)(void))completed;

- (void)suspendAllDownloads;
- (void)startAllDownloads;
- (void)removeAndClearAll;
@end

NS_ASSUME_NONNULL_END
