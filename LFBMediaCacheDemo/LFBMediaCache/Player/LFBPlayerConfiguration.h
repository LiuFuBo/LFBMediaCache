//
//  LFBPlayerConfiguration.h
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/11/4.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, LFBConfigurationPlayType) {
    LFBConfigurationPlayTypeDefault = 0,//仅播放一次
    LFBConfigurationPlayTypeReplay //重复播放
};

typedef NS_ENUM(NSUInteger, LFBPlayerDeviceDirection) {
    LFBPlayerDeviceDirectionCustom,//未知 
    LFBPlayerDeviceDirectionPortrait,//竖屏
    LFBPlayerDeviceDirectionLeft,//左向横屏
    LFBPlayerDeviceDirectionRight//右向横屏
};

@interface LFBPlayerConfiguration : NSObject

/** 是否打开重力感应，默认为YES */
@property (nonatomic, assign) BOOL openGravitySensing;
/** 设置设备初始方向 默认竖屏播放 */
@property (nonatomic, assign) LFBPlayerDeviceDirection deviceDirection;
/** 是否设置视频第一帧为封面 */
@property (nonatomic, assign) BOOL haveFirstFrameCover;
/** 设置封面图片  */
@property (nonatomic, strong) UIImage *frameCoverImage;
/** 设置播放类型，默认default模式   */
@property (nonatomic, assign) LFBConfigurationPlayType playType;

@end


