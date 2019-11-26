//
//  LFBCachePlayerTool.m
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/11/14.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import "LFBCachePlayerTool.h"
#import <AVFoundation/AVFoundation.h>

@implementation LFBCachePlayerTool

+ (NSString *)lfb_playerConvertTime:(CGFloat)second {
    int sec = ((int)second % 3600) % 60 ;
    int minute = ((int)second % 3600)/60;
    int hour = (int)second / 3600;
    NSString *timeStr  = nil;
    if (hour <= 0) {
      timeStr = [NSString stringWithFormat:@"%02d:%02d",minute,sec];
    }else{
     timeStr = [NSString stringWithFormat:@"%02d:%02d:%02d",hour,minute,sec];
    }
    return timeStr;
}

+ (UIImage *)lfb_playerFirstFrameImageWithURL:(NSURL *)url {
    // 初始化视频媒体文件
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *assetGen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetGen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    /// 获取视频第一帧图片
    CGImageRef image = [assetGen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *videoImage = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return videoImage;
}

@end
