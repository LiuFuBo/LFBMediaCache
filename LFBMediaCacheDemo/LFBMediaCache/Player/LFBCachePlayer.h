//
//  LFBCachePlayer.h
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/11/4.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFBPlayerConfiguration.h"



@interface LFBCachePlayer : UIView

- (instancetype)initWithURL:(NSURL *)url configuration:(LFBPlayerConfiguration *)configuration;

@property (nonatomic, readonly) LFBPlayerDeviceDirection deviceDirection;

- (void)startPlay;
- (void)pausePlay;


@end


