//
//  LFBPlayerConfiguration.m
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/11/4.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import "LFBPlayerConfiguration.h"

@implementation LFBPlayerConfiguration

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.openGravitySensing = YES;
        self.haveFirstFrameCover = YES;
        self.playType = LFBConfigurationPlayTypeDefault;
        self.deviceDirection = LFBPlayerDeviceDirectionPortrait;
    }
    return self;
}

@end
