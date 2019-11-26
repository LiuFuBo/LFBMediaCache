//
//  LFBResourceLoader.h
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/10/31.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AVFoundation;
@protocol LFBResourceLoaderDelegate;

@interface LFBResourceLoader : NSObject

@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, weak) id<LFBResourceLoaderDelegate> delegate;

- (instancetype)initWithURL:(NSURL *)url;

- (void)addRequest:(AVAssetResourceLoadingRequest *)request;
- (void)removeRequest:(AVAssetResourceLoadingRequest *)request;

- (void)cancel;

@end


@protocol LFBResourceLoaderDelegate <NSObject>

- (void)resourceLoader:(LFBResourceLoader *)resourceLoader didFailWithError:(NSError *)error;

@end

