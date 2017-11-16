//
//  ListVC.m
//  MHDownloader
//
//  Created by 马浩 on 2017/11/15.
//  Copyright © 2017年 HuZhang. All rights reserved.
//

#import "ListVC.h"
#import "MHDownloader.h"
#import "MYCell.h"
@interface ListVC ()<UITableViewDelegate,UITableViewDataSource>
{
    UITableView * _tableView;
    NSMutableArray * _dataArr;
}
@end

@implementation ListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor grayColor];
    _dataArr = [NSMutableArray arrayWithCapacity:0];
    for (int i = 0; i<[MHDownloader sharedDownloader].allDownloadUrlArr.count; i++) {
        NSString * url = [MHDownloader sharedDownloader].allDownloadUrlArr[i];
        [_dataArr addObject:url];
    }
 
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height-64) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataArr.count;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 180;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * cellid = @"muuuuuuuuuu";
    MYCell * cell = [tableView dequeueReusableCellWithIdentifier:cellid];
    if (!cell) {
        cell = [[MYCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellid];
    }
    cell.url = _dataArr[indexPath.row];
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MHDownloadModel * model = [[MHDownloader sharedDownloader] downloadModelForURLString:_dataArr[indexPath.row]];
    NSLog(@"%@",model.filePath);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
