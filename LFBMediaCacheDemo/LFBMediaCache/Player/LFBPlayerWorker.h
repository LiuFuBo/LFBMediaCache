//
//  LFBPlayerWorker.h
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/11/4.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


@protocol LFBResourceLoadingPlayerWorkerDelegate;
@class LFBPlayerConfiguration;

@interface LFBPlayerWorker : NSObject

- (instancetype)initWithURL:(NSURL *)url configuration:(LFBPlayerConfiguration *)configuration;

@property (nonatomic, strong, readwrite) NSURL *url;
@property (nonatomic, strong, readonly) AVPlayer *player;

@property (nonatomic, weak) id <LFBResourceLoadingPlayerWorkerDelegate> delegate;

- (void)startPlay;
- (void)pausePlay;
- (void)playerWorkerReset;
- (void)workerCleanCache;

- (void)workerSeekToTime:(CGFloat)seconds didCompletionHandler:(void(^)(BOOL finished))completionHandler;


@end


@protocol LFBResourceLoadingPlayerWorkerDelegate <NSObject>
//返回总的时间和当前时间
- (void)resourceLoadingPlayerWorker:(LFBPlayerWorker *)playerWorker didCompleteWithDuration:(CGFloat)duration currentDuration:(CGFloat)currentduration;
//播放完成
- (void)resourceDidFinishedPlayWithPlayerWorker:(LFBPlayerWorker *)playerWorker duration:(CGFloat)duration;



@end


