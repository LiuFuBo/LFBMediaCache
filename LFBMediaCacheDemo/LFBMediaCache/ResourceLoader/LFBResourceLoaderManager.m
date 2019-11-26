//
//  LFBResourceLoaderManager.m
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/10/31.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import "LFBResourceLoaderManager.h"
#import "LFBResourceLoader.h"

static NSString *kCacheScheme = @"__LFBMediaCache__:";

@interface LFBResourceLoaderManager () <LFBResourceLoaderDelegate>

@property (nonatomic, strong) NSMutableDictionary<id<NSCoding>, LFBResourceLoader *> *loaders;

@end

@implementation LFBResourceLoaderManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _loaders = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)cleanCache {
    [self.loaders removeAllObjects];
}

- (void)cancelLoaders {
    [self.loaders enumerateKeysAndObjectsUsingBlock:^(id<NSCoding>  _Nonnull key, LFBResourceLoader * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj cancel];
    }];
    [self.loaders removeAllObjects];
}

#pragma mark - AVAssetResourceLoaderDelegate
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    //获取系统中不能处理的url
    NSURL *resourceURL = [loadingRequest.request URL];
    //判断当前url是否s遵守设置的规范
    if ([resourceURL.absoluteString hasPrefix:kCacheScheme]) {
        LFBResourceLoader *loader = [self loaderForRequest:loadingRequest];
        if (!loader) {
            NSURL *originURL = nil;
            NSString *originStr = [resourceURL absoluteString];
            originStr = [originStr stringByReplacingOccurrencesOfString:kCacheScheme withString:@""];
            originURL = [NSURL URLWithString:originStr];
            loader = [[LFBResourceLoader alloc]initWithURL:originURL];
            loader.delegate = self;
            NSString *key = [self keyForResourceLoaderWithURL:resourceURL];
            self.loaders[key] = loader;
        }
        [loader addRequest:loadingRequest];
        return YES;
    }
    return NO;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    LFBResourceLoader *loader = [self loaderForRequest:loadingRequest];
    [loader removeRequest:loadingRequest];
}

#pragma mark - Helper
- (NSString *)keyForResourceLoaderWithURL:(NSURL *)requestURL {
    if ([[requestURL absoluteString] hasPrefix:kCacheScheme]) {
        NSString *s = requestURL.absoluteString;
        return s;
    }
    return nil;
}

- (LFBResourceLoader *)loaderForRequest:(AVAssetResourceLoadingRequest *)request {
    NSString *requestKey = [self keyForResourceLoaderWithURL:request.request.URL];
    LFBResourceLoader *loader = self.loaders[requestKey];
    return loader;
}

#pragma mark - LFBResourceLoaderDelegate
- (void)resourceLoader:(LFBResourceLoader *)resourceLoader didFailWithError:(NSError *)error {
    [resourceLoader cancel];
    if ([self.delegate respondsToSelector:@selector(resourceLoaderManagerLoadURL:didFailWithError:)]) {
        [self.delegate resourceLoaderManagerLoadURL:resourceLoader.url didFailWithError:error];
    }
}

@end


@implementation  LFBResourceLoaderManager (Convenient)

+ (NSURL *)assetURLWithURL:(NSURL *)url {
    if (!url) {
        return nil;
    }
    //拼接不可识别前缀，让其不间断走delegate
    NSURL *assetURL = [NSURL URLWithString:[kCacheScheme stringByAppendingString:[url absoluteString]]];
    return assetURL;
}

- (AVPlayerItem *)playerItemWithURL:(NSURL *)url {
    NSURL *assetURL = [LFBResourceLoaderManager assetURLWithURL:url];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
    [urlAsset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:urlAsset];
    if ([playerItem respondsToSelector:@selector(setCanUseNetworkResourcesForLiveStreamingWhilePaused:)]) {
        if (@available(iOS 9.0, *)) {
            playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = YES;
        }
    }
    return playerItem;
}

@end
