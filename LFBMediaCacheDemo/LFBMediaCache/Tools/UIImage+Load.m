//
//  UIImage+Load.m
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/11/6.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import "UIImage+Load.h"

@implementation UIImage (Load)

+ (UIImage *)lfb_imageName:(NSString *)imageName {
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"M_Images" ofType:@"bundle"];
    NSString *imagePath = [bundlePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png",imageName]];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    return image;
}

@end
