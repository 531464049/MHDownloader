//
//  MYCell.m
//  MHDownloader
//
//  Created by 马浩 on 2017/11/15.
//  Copyright © 2017年 HuZhang. All rights reserved.
//

#import "MYCell.h"
#import "MHDownloader.h"

#define kWidth         [UIScreen mainScreen].bounds.size.width
#define kHeight        180

@interface MYCell()
{
    UILabel * _nameLab;//名字
    UILabel * _progressLab;//进度
    UILabel * _sizeLab;//大小
    UILabel * _curentSizeLab;//已下载大小
    UILabel * _speedlab;//速度
    UILabel * _stateLab;//状态
    UIButton * _beginStopBtn;//开始暂停按钮
}
@end

@implementation MYCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _nameLab = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWidth/2, kHeight/3)];
        _nameLab.numberOfLines = 1;
        _nameLab.textColor = [UIColor blackColor];
        _nameLab.font = [UIFont systemFontOfSize:16];
        _nameLab.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_nameLab];
        
        _progressLab = [[UILabel alloc] initWithFrame:CGRectMake(kWidth/2, 0, kWidth/2, kHeight/3)];
        _progressLab.numberOfLines = 1;
        _progressLab.textColor = [UIColor blackColor];
        _progressLab.font = [UIFont systemFontOfSize:16];
        _progressLab.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_progressLab];
        
        _sizeLab = [[UILabel alloc] initWithFrame:CGRectMake(0, kHeight/3, kWidth/3, kHeight/3)];
        _sizeLab.numberOfLines = 1;
        _sizeLab.textColor = [UIColor blackColor];
        _sizeLab.font = [UIFont systemFontOfSize:16];
        _sizeLab.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_sizeLab];
        
        _curentSizeLab = [[UILabel alloc] initWithFrame:CGRectMake(kWidth/3, kHeight/3, kWidth/3, kHeight/3)];
        _curentSizeLab.numberOfLines = 1;
        _curentSizeLab.textColor = [UIColor blackColor];
        _curentSizeLab.font = [UIFont systemFontOfSize:16];
        _curentSizeLab.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_curentSizeLab];
        
        _beginStopBtn = [UIButton buttonWithType:0];
        _beginStopBtn.frame = CGRectMake(kWidth/3*2, kHeight/3, kWidth/3, kHeight/3);
        _beginStopBtn.backgroundColor = [UIColor grayColor];
        [_beginStopBtn setTitleColor:[UIColor blackColor] forState:0];
        _beginStopBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [_beginStopBtn addTarget:self action:@selector(bbbbbbbbbb) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_beginStopBtn];
        
        _stateLab = [[UILabel alloc] initWithFrame:CGRectMake(0, kHeight/3*2, kWidth/3, kHeight/3)];
        _stateLab.numberOfLines = 1;
        _stateLab.textColor = [UIColor blackColor];
        _stateLab.font = [UIFont systemFontOfSize:16];
        _stateLab.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_stateLab];
        
        _speedlab = [[UILabel alloc] initWithFrame:CGRectMake(kWidth/3, kHeight/3*2, kWidth/3, kHeight/3)];
        _speedlab.numberOfLines = 1;
        _speedlab.textColor = [UIColor blackColor];
        _speedlab.font = [UIFont systemFontOfSize:16];
        _speedlab.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_speedlab];
    }
    return self;
}
-(void)setUrl:(NSString *)url
{
    _url = url;
    
    MHDownloadModel * model = [[MHDownloader sharedDownloader] downloadModelForURLString:url];
    if (model) {
        _nameLab.text = model.fileTrueName;
        _progressLab.text = [NSString stringWithFormat:@"%0.2f",model.progress];
        _sizeLab.text = [NSString stringWithFormat:@"总：%0.2fMB",model.totalBytesExpectedToWrite/1024.0/1024];
        _curentSizeLab.text = [NSString stringWithFormat:@"已下：%0.2fMB",model.totalBytesWritten/1024.0/1024];
        _speedlab.text = [NSString stringWithFormat:@"%@kb/s",model.speed];
        
        __weak typeof(model) weakModel = model;
        model.downloaderProgressBlock = ^(NSInteger receivedSize, NSInteger expectedSize, NSInteger speed, NSURL * _Nullable targetURL) {
            __strong typeof(weakModel) strongModel = weakModel;
            if ([targetURL.absoluteString isEqualToString:_url]) {
                _progressLab.text = [NSString stringWithFormat:@"%0.2f",(receivedSize/1024.0/1024) / (expectedSize/1024.0/1024)];
                _sizeLab.text = [NSString stringWithFormat:@"总：%0.2fMB",expectedSize/1024.0/1024];
                _curentSizeLab.text = [NSString stringWithFormat:@"已下：%0.2fMB",receivedSize/1024.0/1024];
                _speedlab.text = [NSString stringWithFormat:@"%@kb/s",strongModel.speed];
            }
        };
        model.downloaderCompletedBlock = ^(MHDownloadModel * model, NSError * _Nullable error, BOOL finished) {
            if (error) {
                NSLog(@"下载失败");
                [_beginStopBtn setTitle:@"下载失败" forState:0];
                _beginStopBtn.enabled = YES;
                _stateLab.text = @"下载失败";
            }else {
                NSLog(@"下载完成");
                [_beginStopBtn setTitle:@"下载完成" forState:0];
                _beginStopBtn.enabled = NO;
                _stateLab.text = @"下载完成";
            }
        };
        switch (model.state) {
            case MHDownloadStateNone:
            {
                [_beginStopBtn setTitle:@"未知" forState:0];
                _beginStopBtn.enabled = NO;
                _stateLab.text = @"未知状态";
            }
                break;
            case MHDownloadStateWillResume:
            {
                [_beginStopBtn setTitle:@"停止" forState:0];
                _beginStopBtn.enabled = YES;
                _stateLab.text = @"等待中";
            }
                break;
            case MHDownloadStateDownloading:
            {
                [_beginStopBtn setTitle:@"停止" forState:0];
                _beginStopBtn.enabled = YES;
                _stateLab.text = @"下载中";
            }
                break;
            case MHDownloadStateSuspened:
            {
                [_beginStopBtn setTitle:@"开始" forState:0];
                _beginStopBtn.enabled = YES;
                _stateLab.text = @"已暂停";
            }
                break;
            case MHDownloadStateCompleted:
            {
                [_beginStopBtn setTitle:@"下载完成" forState:0];
                _beginStopBtn.enabled = NO;
                _stateLab.text = @"下载完成";
            }
                break;
            case MHDownloadStateFailed:
            {
                [_beginStopBtn setTitle:@"开始" forState:0];
                _beginStopBtn.enabled = YES;
                _stateLab.text = @"下载失败";
            }
                break;
            default:
                break;
        }
    }
}
-(void)bbbbbbbbbb
{
    MHDownloadModel * model = [[MHDownloader sharedDownloader] downloadModelForURLString:_url];
    if (model.state == MHDownloadStateDownloading || model.state == MHDownloadStateWillResume) {
        //暂停
        [[MHDownloader sharedDownloader] suspened:model];
    }else{
        //开始
        [[MHDownloader sharedDownloader] start:model];
    }
}
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
