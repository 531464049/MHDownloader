//
//  MHDownloadOpration.h
//  MHDownloader
//
//  Created by 马浩 on 2017/11/14.
//  Copyright © 2017年 HuZhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MHDownloader.h"


@interface MHDownloadOpration : NSOperation<NSURLSessionTaskDelegate, NSURLSessionDataDelegate>
/*这四个 不知道是做什么的*/
@property (strong, nonatomic, nullable) NSURLRequest *request;
@property (strong, nonatomic, readonly, nullable) NSURLSessionTask *dataTask;
@property (assign, nonatomic) NSInteger expectedSize;
@property (strong, nonatomic, nullable) NSURLResponse *response;

/**
 初始化下载事务operation

 @param request 下载请求request
 @param session 下载事务需要运行的session
 @return 下载事务operation
 */
- (nonnull instancetype)initWithRequest:(nullable NSURLRequest *)request
                              inSession:(nullable NSURLSession *)session;
/**
 *  添加下载进度/下载完成/失败回调，返回一个token 这个+下边两个方法不懂
 *
 *  @param progressBlock  该回调在获取到新的数据时执行
 *                        @note 需回到主线程
 *  @param completedBlock 该回调在下载完成/失败时执行
 *                        @note 下载完成的回调在主线程
 *
 *  @return 返回一个token，用来处理取消这些回调
 */
- (nullable id)addHandlersForProgress:(nullable MHDownloaderProgressBlock)progressBlock
                            completed:(nullable MHDownloaderCompletedBlock)completedBlock;


/**
 判断能否取消该事务，如果能取消，则直接在该方法内部取消该事务

 @param token 代表当前需要取消的下载任务
 @return 如果当前事务被取消，返回是
 */
- (BOOL)cancel:(nullable id)token;
@end
