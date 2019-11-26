//
//  LFBCacheSessionManager.h
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/10/29.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LFBCacheSessionManager : NSObject

@property (nonatomic, strong, readonly) NSOperationQueue *downloadQueue;

+ (instancetype)shared;

@end


