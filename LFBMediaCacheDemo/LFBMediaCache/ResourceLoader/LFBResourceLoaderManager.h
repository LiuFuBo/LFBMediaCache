//
//  LFBResourceLoaderManager.h
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/10/31.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AVFoundation;
@protocol LFBResourceLoaderManagerDelegate;

@interface LFBResourceLoaderManager : NSObject <AVAssetResourceLoaderDelegate>

@property (nonatomic, weak) id<LFBResourceLoaderManagerDelegate> delegate;

/**
 Normally you no need to call this method to clean cache. Cache cleaned after AVPlayer delloc.
 If you have a singleton AVPlayer then you need call this method to clean cache at suitable time.
 */
- (void)cleanCache;

/**
 Cancel all downloading loaders.
 */
- (void)cancelLoaders;

@end

@protocol LFBResourceLoaderManagerDelegate <NSObject>

- (void)resourceLoaderManagerLoadURL:(NSURL *)url didFailWithError:(NSError *)error;

@end

@interface LFBResourceLoaderManager (Convenient)

+ (NSURL *)assetURLWithURL:(NSURL *)url;
- (AVPlayerItem *)playerItemWithURL:(NSURL *)url;

@end


