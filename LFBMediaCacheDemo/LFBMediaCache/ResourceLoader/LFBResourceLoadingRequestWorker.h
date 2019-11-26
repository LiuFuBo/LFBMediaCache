//
//  LFBResourceLoadingRequestWorker.h
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/10/31.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LFBMediaDownloader, AVAssetResourceLoadingRequest;
@protocol LFBResourceLoadingRequestWorkerDelegate;

@interface LFBResourceLoadingRequestWorker : NSObject

- (instancetype)initWithMediaDownloader:(LFBMediaDownloader *)mediaDownloader resourceLoadingRequest:(AVAssetResourceLoadingRequest *)request;

@property (nonatomic, weak) id<LFBResourceLoadingRequestWorkerDelegate> delegate;

@property (nonatomic, strong, readonly) AVAssetResourceLoadingRequest *request;

- (void)startWork;
- (void)cancel;
- (void)finish;

@end

@protocol  LFBResourceLoadingRequestWorkerDelegate <NSObject>

- (void)resourceLoadingRequestWorker:(LFBResourceLoadingRequestWorker *)requestWorker didCompleteWithError:(NSError *)error;

@end


