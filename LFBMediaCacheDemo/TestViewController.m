//
//  TestViewController.m
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/11/25.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import "TestViewController.h"
#import "LFBMediaCache.h"
#import "Masonry.h"

@interface TestViewController ()

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    LFBPlayerConfiguration *configuratino = [[LFBPlayerConfiguration alloc]init];
    configuratino.openGravitySensing = YES; //手机是否开启重力感应
    configuratino.playType = LFBConfigurationPlayTypeReplay;
    LFBCachePlayer *playerView = [[LFBCachePlayer alloc]initWithURL:[NSURL URLWithString:@"https://mvvideo5.meitudata.com/56ea0e90d6cb2653.mp4"] configuration:configuratino];
    [self.view addSubview:playerView];
    [playerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.view);
        make.top.mas_equalTo(self.view.mas_top).with.offset(64);
        make.height.mas_equalTo(300);
    }];
    self.view.backgroundColor = [UIColor lightGrayColor];
}



@end
