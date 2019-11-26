//
//  LFBPlayerWorker.m
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/11/4.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import "LFBPlayerWorker.h"
#import "LFBMediaCache.h"
#import "LFBPlayerConfiguration.h"

@interface LFBPlayerWorker ()

@property (nonatomic, strong) LFBPlayerConfiguration *configuration;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) id timeObserver;
@property (nonatomic, assign) CGFloat duration;
@property (nonatomic, assign) CGFloat cDuration;
@property (nonatomic, strong, readwrite) AVPlayer *player;
@property (nonatomic, strong) LFBResourceLoaderManager *resourceLoaderManager;

@end

@implementation LFBPlayerWorker

- (void)dealloc {
    [self removePlayerObserver];
}

- (instancetype)initWithURL:(NSURL *)url configuration:(LFBPlayerConfiguration *)configuration {
    self = [super init];
    if (self) {
        _url = url;
        _configuration = configuration;
        [self fullfillContentInfo];
    }
    return self;
}

- (void)fullfillContentInfo {
    [self playerWorkerReset];//清除播放器
    LFBResourceLoaderManager *resourceLoaderManager = [[LFBResourceLoaderManager alloc]init];
    [self setResourceLoaderManager:resourceLoaderManager];
    
    AVPlayerItem *playerItem = [resourceLoaderManager playerItemWithURL:self.url];
    [self setPlayerItem:playerItem];
    
    LFBCacheConfiguration *configuration = [LFBCacheManager cacheConfigurationForURL:self.url];
    if (configuration.progress >= 1.0) {
        NSLog(@"cache completed");
    }
    
    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    if (@available(iOS 10.0, *)) {
        player.automaticallyWaitsToMinimizeStalling = NO;
    }
    
    [self setPlayer:player];
   
    __weak typeof(self) weakSelf = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 10) queue:dispatch_queue_create("player.time.queue", NULL) usingBlock:^(CMTime time) {
        dispatch_async(dispatch_get_main_queue(), ^{
            CGFloat duration = CMTimeGetSeconds(weakSelf.player.currentItem.duration);
            [weakSelf setDuration:duration];
            CGFloat cDuration = CMTimeGetSeconds(time);
            [weakSelf setCDuration:cDuration];
            if ([weakSelf.delegate respondsToSelector:@selector(resourceLoadingPlayerWorker:didCompleteWithDuration:currentDuration:)]) {
                [weakSelf.delegate resourceLoadingPlayerWorker:weakSelf didCompleteWithDuration:duration currentDuration:cDuration];
            }
            if (cDuration / duration >= 1.0 && [weakSelf.delegate respondsToSelector:@selector(resourceDidFinishedPlayWithPlayerWorker:duration:)]) {
                [weakSelf.delegate resourceDidFinishedPlayWithPlayerWorker:weakSelf duration:duration];
            }
        });
    }];
    
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.player addObserver:self forKeyPath:@"timeControlStatus" options:NSKeyValueObservingOptionNew context:nil];
    
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaCacheDidChanged:) name:LFBCacheManagerDidUpdateCacheNotification object:nil];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if (object == self.playerItem && [keyPath isEqualToString:@"status"]) {
        if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
            dispatch_async(dispatch_get_main_queue(), ^{
                CGFloat duration = CMTimeGetSeconds(self.playerItem.duration);
                if ([self.delegate respondsToSelector:@selector(resourceLoadingPlayerWorker:didCompleteWithDuration:currentDuration:)]) {
                    [self.delegate resourceLoadingPlayerWorker:self didCompleteWithDuration:duration currentDuration:self.cDuration];
                }
            });
        }else if(self.playerItem.status == AVPlayerItemStatusFailed || self.playerItem.status == AVPlayerItemStatusUnknown){
            [self pausePlay];
            NSLog(@"播放失败");
        }
    }else if (object == self.player && [keyPath isEqualToString:@"timeControlStatus"]) {
        if (@available(iOS 10.0, *)) {
            NSLog(@"timeControlStatus: %@, reason: %@, rate: %@", @(self.player.timeControlStatus), self.player.reasonForWaitingToPlay, @(self.player.rate));
        } else {
            // Fallback on earlier versions
        }
    }
}

- (void)playerWorkerReset {
    if (!self.playerItem) {return;}
    if (self.player) {[self pausePlay];}
    [self removePlayerObserver];
    self.playerItem = nil;
}

- (void)workerCleanCache {
    NSError *error;
    [LFBCacheManager cleanAllCacheWithError:&error];
    if (error) {
        NSLog(@"clean cache failure: %@", error);
    }
}


- (void)startPlay {
    [self.player play];
}

- (void)pausePlay {
    [self.player pause];
}

- (void)workerSeekToTime:(CGFloat)seconds didCompletionHandler:(void (^)(BOOL))completionHandler {
    
    seconds = MIN(MAX(0, seconds), self.duration);
    [self setDuration:seconds];
    
    [self pausePlay];
    __weak typeof(self) weakSelf = self;
    [weakSelf.player seekToTime:CMTimeMakeWithSeconds(seconds, self.playerItem.currentTime.timescale) completionHandler:^(BOOL finished) {
        [weakSelf startPlay];
        !completionHandler ? : completionHandler(finished);
    }];
}

#pragma mark - MediaCacheNotification
- (void)mediaCacheDidChanged:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    LFBCacheConfiguration *configuration = userInfo[LFBCacheConfigurationKey];
    NSArray<NSValue *> *cachedFragments = configuration.cacheFragments;
    long long contentLength = configuration.contentInfo.contentLength;
    
    NSInteger number = 100;
    NSMutableString *progressStr = [NSMutableString string];
    
    [cachedFragments enumerateObjectsUsingBlock:^(NSValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSRange range = obj.rangeValue;
        
        NSInteger location = roundf((range.location / (double)contentLength) * number);
        
        NSInteger progressCount = progressStr.length;
        [self string:progressStr appendString:@"0" muti:location - progressCount];
        
        NSInteger length = roundf((range.length / (double)contentLength) * number);
        [self string:progressStr appendString:@"1" muti:length];
        
        
        if (idx == cachedFragments.count - 1 && (location + length) <= number + 1) {
            [self string:progressStr appendString:@"0" muti:number - (length + location)];
        }
    }];
}

- (void)string:(NSMutableString *)string appendString:(NSString *)appendString muti:(NSInteger)muti {
    for (NSInteger i = 0; i < muti; i++) {
        [string appendString:appendString];
    }
    NSLog(@"下载二进制:%@",string);
}


- (void)removePlayerObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.player removeTimeObserver:self.timeObserver];
    [self setTimeObserver:nil];
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.player removeObserver:self forKeyPath:@"timeControlStatus"];
}

@end
