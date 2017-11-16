//
//  MHDownloadModel.h
//  MHDownloader
//
//  Created by 马浩 on 2017/11/14.
//  Copyright © 2017年 HuZhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class MHDownloadModel;

/** 文件下载类型 */
typedef enum : NSInteger {
    kDownloadTypeUnKnow,    /** 未知类型 */
    kDownloadTypeImage,    /** 图片类型 */
    kDownloadTypeVideo,    /** 视频类型 */
    kDownloadTypeAudio,    /** 音频类型 */
    kDownloadTypeText,     /** 文字类型 */
}kDownloadType;//文件下载类型

/** 文件下载状态 */
typedef NS_ENUM(NSUInteger, MHDownloadState) {
    MHDownloadStateNone,           /** 状态-未知 */
    MHDownloadStateWillResume,     /** 等待 */
    MHDownloadStateDownloading,    /** 下载中 */
    MHDownloadStateSuspened,       /** 暂停 */
    MHDownloadStateCompleted,      /** 下载完成 */
    MHDownloadStateFailed          /** 下载失败 */
};

/** 下载队列顺讯-先进先出-后进先出 */
typedef NS_ENUM(NSInteger, MHDownloadPrioritization) {
    MHDownloadPrioritizationFIFO,  /** 先进先出 */
    MHDownloadPrioritizationLIFO   /** 后进先出 */
};

/**
 下载进度回调

 @param receivedSize 已下载大小
 @param expectedSize 总下载大小
 @param speed 下载速度
 @param targetURL 下载地址
 */
typedef void (^MHDownloaderProgressBlock)(NSInteger receivedSize, NSInteger expectedSize,  NSInteger speed, NSURL * _Nullable targetURL);

/**
 下载完成/失败 回调

 @param model 下载model
 @param error 错误信息
 @param finished 是否下载成功
 */
typedef void (^MHDownloaderCompletedBlock)(MHDownloadModel * _Nullable model, NSError * _Nullable error, BOOL finished);

@interface MHDownloadModel : NSObject

/**
 下载状态
 */
@property (nonatomic,assign,readonly) MHDownloadState state;

/**
 文件类型
 */
@property(nonatomic,assign,readonly)kDownloadType downloadType;

/**
 下载地址
 */
@property (nonatomic,copy,readonly,nonnull) NSString * url;

/**
 文件保存路径
 */
@property (nonatomic, copy, readonly, nonnull) NSString * filePath;

/**
 文件名 - 通过MD5加密过得文件名字
 */
@property (nonatomic, copy,readonly, nullable) NSString * filename;

/**
 文件名真是名字，下载列表cell里边显示的名字
 */
@property (nonatomic, copy,readonly, nullable) NSString * fileTrueName;

/**
 下载速度 KB/s
 */
@property (nonatomic, copy, readonly, nullable) NSString * speed;

/**
 已下载大小 B
 */
@property (assign, nonatomic, readonly) long long totalBytesWritten;

/**
 总下载大小 B
 */
@property (assign, nonatomic, readonly) long long totalBytesExpectedToWrite;

/**
 当前下载进度
 */
@property (nonatomic, assign, readonly) CGFloat progress;

@property (nonatomic,copy, nullable, readonly)MHDownloaderProgressBlock downloaderProgressBlock;
@property (nonatomic,copy, nullable, readonly)MHDownloaderCompletedBlock downloaderCompletedBlock;


/**
 初始化一个下载model

 @param URLString 下载地址
 @param downloaderProgressBlock 下载进度block回调
 @param downloaderCompletedBlock 下载完成/失败block回调
 @return 下载model
 */
- (nonnull instancetype)initWithURLString:(nonnull NSString *)URLString
                  downloaderProgressBlock:(nullable MHDownloaderProgressBlock)downloaderProgressBlock
                 downloaderCompletedBlock:(nullable MHDownloaderCompletedBlock)downloaderCompletedBlock;

/**
 只读属性set方法
 */
- (void)setTotalBytesExpectedToWrite:(long long)totalBytesExpectedToWrite;
- (void)setState:(MHDownloadState)state;
- (void)setDownloadType:(kDownloadType)downloadType;
- (void)setProgress:(CGFloat)progress;
- (void)setFileTrueName:(NSString * _Nullable)fileTrueName;
- (void)setDownloaderProgressBlock:(nullable MHDownloaderProgressBlock)downloaderProgressBlock;
- (void)setDownloaderCompletedBlock:(nullable MHDownloaderCompletedBlock)downloaderCompletedBlock;
- (void)setSpeed:(NSString * _Nullable)speed;

/**
 用来计算下载速度的两个变量
 */
@property (nonatomic, assign) NSUInteger totalRead;
@property (nonatomic, strong, nullable) NSDate *date;

@end

