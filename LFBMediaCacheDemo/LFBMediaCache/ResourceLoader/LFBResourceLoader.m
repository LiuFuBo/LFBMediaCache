//
//  LFBResourceLoader.m
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/10/31.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import "LFBResourceLoader.h"
#import "LFBMediaDownloader.h"
#import "LFBResourceLoadingRequestWorker.h"
#import "LFBContentInfo.h"
#import "LFBMediaCacheWorker.h"

NSString *const MCResourceLoaderErrorDomain = @"MCFilePlayerResourceLoaderErrorDomain";

@interface LFBResourceLoader () <LFBResourceLoadingRequestWorkerDelegate>

@property (nonatomic, strong, readwrite) NSURL *url;
@property (nonatomic, strong) LFBMediaCacheWorker *cacheWorker;
@property (nonatomic, strong) LFBMediaDownloader *mediaDownloader;
@property (nonatomic, strong) NSMutableArray<LFBResourceLoadingRequestWorker *> *pendingRequestWorkers;

@property (nonatomic, getter=isCancelled) BOOL cancelled;

@end



@implementation LFBResourceLoader

- (void)dealloc {
    [_mediaDownloader cancel];
}

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        _url = url;
        _cacheWorker = [[LFBMediaCacheWorker alloc] initWithURL:url];
        _mediaDownloader = [[LFBMediaDownloader alloc] initWithURL:url cacheWorker:_cacheWorker];
        _pendingRequestWorkers = [NSMutableArray array];
    }
    return self;
}

- (instancetype)init {
    NSAssert(NO, @"Use - initWithURL: instead");
    return nil;
}

- (void)addRequest:(AVAssetResourceLoadingRequest *)request {
  /**每次请求数据都是请求完成以后不管成功还是失败，都需要删除当前request，
   然后继续后面的策略，所以如果在当前网络请求还没完成的情况下，
   再次来了一个新的request请求就需要创建新的下载器*/
    if (self.pendingRequestWorkers.count > 0) {
        [self startNoCacheWorkerWithRequest:request];
    }else{
        [self startWorkerWithRequest:request];
    }
}

- (void)removeRequest:(AVAssetResourceLoadingRequest *)request {
    __block LFBResourceLoadingRequestWorker *requestWorker = nil;
    [self.pendingRequestWorkers enumerateObjectsUsingBlock:^(LFBResourceLoadingRequestWorker * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.request == request) {
            requestWorker = obj;
            *stop = YES;
        }
    }];
    if (requestWorker) {
        [requestWorker finish];
        [self.pendingRequestWorkers removeObject:requestWorker];
    }
}

- (void)cancel {
    [self.mediaDownloader cancel];
    [self.pendingRequestWorkers removeAllObjects];
    
    [[LFBMediaDownloaderStatus shared] removelURL:self.url];
}

#pragma mark - LFBResourceLoadingRequestWorkerDelegate
//在response 响应成功完成当前range数据请求或者失败调用
- (void)resourceLoadingRequestWorker:(LFBResourceLoadingRequestWorker *)requestWorker didCompleteWithError:(NSError *)error {
    [self removeRequest:requestWorker.request];
    if (error && [self.delegate respondsToSelector:@selector(resourceLoader:didFailWithError:)]) {
        [self.delegate resourceLoader:self didFailWithError:error];
    }
    if (self.pendingRequestWorkers.count == 0) {
        [[LFBMediaDownloaderStatus shared] removelURL:self.url];
    }
}

- (void)startNoCacheWorkerWithRequest:(AVAssetResourceLoadingRequest *)request {
    [[LFBMediaDownloaderStatus shared] addURL:self.url];
    LFBMediaDownloader *mediaDownloader = [[LFBMediaDownloader alloc] initWithURL:self.url cacheWorker:self.cacheWorker];
    LFBResourceLoadingRequestWorker *requestWorker = [[LFBResourceLoadingRequestWorker alloc] initWithMediaDownloader:mediaDownloader resourceLoadingRequest:request];
    [self.pendingRequestWorkers addObject:requestWorker];
    requestWorker.delegate = self;
    [requestWorker startWork];
}

- (void)startWorkerWithRequest:(AVAssetResourceLoadingRequest *)request {
    [[LFBMediaDownloaderStatus shared] addURL:self.url];
    LFBResourceLoadingRequestWorker *requestWorker = [[LFBResourceLoadingRequestWorker alloc] initWithMediaDownloader:self.mediaDownloader resourceLoadingRequest:request];
    [self.pendingRequestWorkers addObject:requestWorker];
    requestWorker.delegate = self;
    [requestWorker startWork];
}



@end
