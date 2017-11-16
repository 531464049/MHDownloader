//
//  ViewController.m
//  MHDownloader
//
//  Created by 马浩 on 2017/11/14.
//  Copyright © 2017年 HuZhang. All rights reserved.
//

#import "ViewController.h"
#import "MHDownloader.h"
#import "ListVC.h"
@interface ViewController ()
{
    NSArray * _arrrrrr;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    _arrrrrr = @[@{@"type":@"img",@"url":@"https://nj02all01.baidupcs.com/file/83e668257c6b5208b57a655704e13965?bkt=p3-140083e668257c6b5208b57a655704e1396542da8bc9000000045ae6&fid=4098196927-250528-485294614709658&time=1510733633&sign=FDTAXGERLQBHSK-DCb740ccc5511e5e8fedcff06b081203-BeS3RE4uQjlpyXqNuDZRxO9D9zI%3D&to=69&size=285414&sta_dx=285414&sta_cs=5&sta_ft=jpg&sta_ct=4&sta_mt=4&fm2=MH,Guangzhou,Anywhere,,guangdong,ct&newver=1&newfm=1&secfm=1&flow_ver=3&pkey=140083e668257c6b5208b57a655704e1396542da8bc9000000045ae6&sl=79364174&expires=8h&rt=pr&r=329951685&mlogid=7391003259932062067&vuk=4098196927&vbdid=1114838396&fin=A01_4%E6%89%AB%E7%A0%811.jpg&rtype=1&iv=0&dp-logid=7391003259932062067&dp-callid=0.1.1&hps=1&tsl=100&csl=100&csign=9ajh73EwkIlXys4LWRK3Fy6mz7M%3D&so=0&ut=6&uter=4&serv=0&uc=2555151813&ic=4271048668&ti=91499ea5817d802894776575375754b5a8bb1b2607c8b314&by=themis"},
                        @{@"type":@"img",@"url":@"https://nj02all01.baidupcs.com/file/33136e4c58d6a89b966a943bb6974a04?bkt=p3-140033136e4c58d6a89b966a943bb6974a04fea5e2d70000000597c0&fid=4098196927-250528-180402518670576&time=1510733698&sign=FDTAXGERLQBHSK-DCb740ccc5511e5e8fedcff06b081203-dHH8Vaf2KAijezEhtZxa4ugEsHE%3D&to=69&size=366528&sta_dx=366528&sta_cs=0&sta_ft=jpg&sta_ct=4&sta_mt=4&fm2=MH,Guangzhou,Anywhere,,guangdong,ct&newver=1&newfm=1&secfm=1&flow_ver=3&pkey=140033136e4c58d6a89b966a943bb6974a04fea5e2d70000000597c0&sl=79364174&expires=8h&rt=pr&r=557449539&mlogid=7391020897805932877&vuk=4098196927&vbdid=1114838396&fin=C01_1%E5%8A%9F%E8%83%BD%E5%88%97%E8%A1%A8.jpg&rtype=1&iv=0&dp-logid=7391020897805932877&dp-callid=0.1.1&hps=1&tsl=100&csl=100&csign=9ajh73EwkIlXys4LWRK3Fy6mz7M%3D&so=0&ut=6&uter=4&serv=0&uc=2555151813&ic=4271048668&ti=5e666840c78f197386543613cb2319d35bcda58b2ba9cdb7305a5e1275657320&by=themis"},
                        @{@"type":@"video",@"url":@"http://120.25.226.186:32812/resources/videos/minion_01.mp4"},
                        @{@"type":@"video",@"url":@"http://120.25.226.186:32812/resources/videos/minion_02.mp4"},
                        @{@"type":@"video",@"url":@"http://120.25.226.186:32812/resources/videos/minion_03.mp4"},
                        @{@"type":@"audio",@"url":@"https://nj01ct01.baidupcs.com/file/1b8390e2e1fd1c36e6d5129aa2164a1c?bkt=p3-0000e074fc529ef25affb690c25fa1466b35&fid=4098196927-250528-338664970819973&time=1510733927&sign=FDTAXGERLQBHSK-DCb740ccc5511e5e8fedcff06b081203-BFTXz3JemLTE5DOZJymULex9OBk%3D&to=63&size=7402346&sta_dx=7402346&sta_cs=3&sta_ft=mp3&sta_ct=5&sta_mt=5&fm2=MH,Yangquan,Anywhere,,guangdong,ct&newver=1&newfm=1&secfm=1&flow_ver=3&pkey=0000e074fc529ef25affb690c25fa1466b35&sl=79364174&expires=8h&rt=pr&r=756696356&mlogid=7391082333509545589&vuk=4098196927&vbdid=1114838396&fin=%E8%BD%A8%E9%A3%8E+-+%E6%8B%82%E6%99%93%E8%BD%A6%E7%AB%99.mp3&rtype=1&iv=0&dp-logid=7391082333509545589&dp-callid=0.1.1&hps=1&tsl=100&csl=100&csign=9ajh73EwkIlXys4LWRK3Fy6mz7M%3D&so=0&ut=6&uter=4&serv=0&uc=2555151813&ic=4271048668&ti=a7b7f0d6b52e1dd2f8edf3d97b870d733714adfd249d7ee9&by=themis"},];
    for (int i = 0; i < _arrrrrr.count; i ++) {
        UIButton * btn = [UIButton buttonWithType:0];
        [btn addTarget:self action:@selector(btn_click:) forControlEvents:UIControlEventTouchUpInside];
        btn.tag = 9090 + i;
        btn.backgroundColor = [UIColor redColor];
        btn.frame = CGRectMake(100, 200 + 70 * i, 100, 50);
        [self.view addSubview:btn];
    }
    UIButton * jump = [UIButton buttonWithType:0];
    jump.backgroundColor = [UIColor purpleColor];
    jump.frame = CGRectMake(0, 100, 100, 30);
    [jump addTarget:self action:@selector(jumppppp) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:jump];
}
-(void)jumppppp
{
    ListVC * vc = [[ListVC alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}
-(void)btn_click:(UIButton *)sender
{
    NSInteger tag = sender.tag - 9090;
    NSDictionary * dic = (NSDictionary *)_arrrrrr[tag];
    if ([MHDownloader.sharedDownloader hasCurentDownLoad:dic[@"url"]]) {
        NSLog(@"已存在当前任务");
    }else{
        [MHDownloader.sharedDownloader addDownLoadWithUrl:[NSURL URLWithString:dic[@"url"]] fileName:nil type:kDownloadTypeUnKnow];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
