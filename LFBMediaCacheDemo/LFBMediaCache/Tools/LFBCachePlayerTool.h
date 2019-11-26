//
//  LFBCachePlayerTool.h
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/11/14.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LFBCachePlayerTool : NSObject

+ (NSString *)lfb_playerConvertTime:(CGFloat)second;

+ (UIImage *)lfb_playerFirstFrameImageWithURL:(NSURL *)url;

@end


