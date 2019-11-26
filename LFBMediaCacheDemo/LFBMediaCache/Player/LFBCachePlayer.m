//
//  LFBCachePlayer.m
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/11/4.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import "LFBCachePlayer.h"
#import "LFBPlayerWorker.h"
#import "LFBPlayerControl.h"
#import "Masonry.h"
#import "LFBCachePlayerTool.h"
#import "LFBPlayerConfiguration.h"


@import AVFoundation;
@interface LFBPlayerLayerView : UIView

- (AVPlayerLayer *)playerLayer;

- (void)setPlayer:(AVPlayer *)player;

@end


@implementation LFBPlayerLayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer *)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
    [(AVPlayerLayer *)[self layer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)self.layer;
}

@end



@interface LFBCachePlayer ()<LFBResourceLoadingPlayerWorkerDelegate,LFBResourcePlayerControlDelegate>

@property (nonatomic, strong) LFBPlayerLayerView *playerView;
@property (nonatomic, readwrite) LFBPlayerDeviceDirection deviceDirection;
@property (nonatomic, strong) LFBPlayerWorker *playerWorker;
@property (nonatomic, strong) LFBPlayerControl *controlView;
@property (nonatomic, strong) UIView *viewLoadContent;
@property (nonatomic, strong) UIImageView *coverFrameImageView;
@property (nonatomic, strong) LFBPlayerConfiguration *configuration;

@end

@implementation LFBCachePlayer

- (instancetype)initWithURL:(NSURL *)url configuration:(LFBPlayerConfiguration *)configuration {
    self = [super init];
    if (self) {
        _playerWorker = [[LFBPlayerWorker alloc]initWithURL:url configuration:configuration];
        _playerWorker.delegate = self;
        _playerWorker.url = url;
        _configuration = configuration;
        [self initContentInfo];
    }
    return self;
}

- (void)initContentInfo {
    
    UIView *viewLoadContent = [[UIView alloc]init];
    [viewLoadContent setBackgroundColor:[UIColor whiteColor]];
    [self setViewLoadContent:viewLoadContent];
    [self addSubview:viewLoadContent];
    [self.viewLoadContent mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.insets(UIEdgeInsetsZero);
    }];
    
    LFBPlayerLayerView *playerView = [[LFBPlayerLayerView alloc]init];
    [playerView setBackgroundColor:[UIColor whiteColor]];
    [playerView setPlayer:self.playerWorker.player];
    [self setPlayerView:playerView];
    [self.viewLoadContent addSubview:self.playerView];
    [self.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.insets(UIEdgeInsetsZero);
    }];
    
    UIImageView *coverFrameImageView = [[UIImageView alloc]init];
    [self setCoverFrameImageView:coverFrameImageView];
    [self.viewLoadContent addSubview:coverFrameImageView];
    [self.coverFrameImageView mas_makeConstraints:^(MASConstraintMaker *make) {
       make.edges.insets(UIEdgeInsetsZero);
    }];
    if (self.configuration.haveFirstFrameCover) {
        self.configuration.frameCoverImage = [LFBCachePlayerTool lfb_playerFirstFrameImageWithURL:self.playerWorker.url];
    }
    self.coverFrameImageView.image = self.configuration.frameCoverImage;
    
    LFBPlayerControl *controlView = [[LFBPlayerControl alloc]initWithDelegate:self];
    [self setControlView:controlView];
    [self.viewLoadContent addSubview:controlView];
    [self.controlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.insets(UIEdgeInsetsZero);
    }];
    
    if (self.configuration.openGravitySensing) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChange) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    [self setDeviceDirection:LFBPlayerDeviceDirectionPortrait];
    [self initDeviceDirection];
}

- (void)initDeviceDirection {
    switch (self.configuration.deviceDirection) {
        case LFBPlayerDeviceDirectionCustom:
        {
            [self deviceScreenInterfaceOrientationPortrait];
        }
            break;
        case LFBPlayerDeviceDirectionPortrait:
        {
            [self deviceScreenInterfaceOrientationPortrait];
        }
            break;
        case LFBPlayerDeviceDirectionLeft:
        {
            [self deviceScreenInterfaceOrientationLeft];
        }
            break;
        case LFBPlayerDeviceDirectionRight:
        {
            [self deviceScreenInterfaceOrientationRight];
        }
            break;
        default:
            break;
    }
}


#pragma mark LFBResourceLoadingPlayerWorkerDelegate (API层代理)
- (void)resourceLoadingPlayerWorker:(LFBPlayerWorker *)playerWorker didCompleteWithDuration:(CGFloat)duration currentDuration:(CGFloat)currentduration {
    
    [self.controlView playerControlDuration:duration currentDuration:currentduration];
}

- (void)resourceDidFinishedPlayWithPlayerWorker:(LFBPlayerWorker *)playerWorker duration:(CGFloat)duration{
    [self mediaReplayWithPlayerWorker:playerWorker playControl:self.controlView];
    [self.controlView playerControlDuration:duration currentDuration:0.0f];
}

- (void)mediaReplayWithPlayerWorker:(LFBPlayerWorker *)playerWorker playControl:(LFBPlayerControl *)playControl {
    [playControl playerControlStartPlay];
    [self.coverFrameImageView setHidden:NO];
    [playerWorker workerSeekToTime:0.0f didCompletionHandler:nil];
    [UIView animateWithDuration:0.2 animations:^{
        [self.coverFrameImageView setHidden:YES];
    }];
}

#pragma mark - LFBResourcePlayerControlDelegate  (控制层代理)
- (void)resourceStartPlayWithPlayControl:(LFBPlayerControl *)playControl {
    [self startPlay];
}

- (void)resourcePauseWithPlayControl:(LFBPlayerControl *)playControl {
    [self pausePlay];
}

- (void)resourceFullScreenWithPlayControl:(LFBPlayerControl *)playControl {
    [self deviceScreenInterfaceOrientationRight];
}

- (void)resourceQuitFullScreenWithPlayControl:(LFBPlayerControl *)playControl {
    [self deviceScreenInterfaceOrientationPortrait];
}

- (void)resourcePlayControl:(LFBPlayerControl *)playControl sliderValue:(CGFloat)value sliderTouchState:(LFBPlayerControlSliderState)state {
    switch (state) {
        case LFBPlayerControlSliderStateBegan:
        {
            [self.playerWorker pausePlay];
        }
            break;
        case LFBPlayerControlSliderStateMoved:
        {
            
        }
            break;
        case LFBPlayerControlSliderStateEnded:
        {
            __weak typeof(self) weakSelf = self;
            [weakSelf.playerWorker workerSeekToTime:value didCompletionHandler:nil];
        }
            break;
        default:
            break;
    }
}

#pragma mark - DeviceOrientiationChangeNotification
- (void)deviceOrientationChange{
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation )orientation;
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
        {//竖屏 (home键在下)
            [self deviceScreenInterfaceOrientationPortrait];
        }
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
        {//竖屏 (home键在上)
            [self deviceScreenInterfaceOrientationPortrait];
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:
        {//左向旋转横屏(home)
            [self deviceScreenInterfaceOrientationLeft];
        }
            break;
        case UIInterfaceOrientationLandscapeRight:
        {//右向旋转横屏(home)
            [self deviceScreenInterfaceOrientationRight];
        }
            break;
        default:
            break;
    }
}

#pragma mark - 屏幕竖屏
- (void)deviceScreenInterfaceOrientationPortrait {
    if (self.deviceDirection == LFBPlayerDeviceDirectionPortrait) {
        return;
    }
    [self setDeviceDirection:LFBPlayerDeviceDirectionPortrait];
    if (![self.subviews containsObject:self.viewLoadContent]) {
        [self.viewLoadContent removeFromSuperview];
        [self addSubview:self.viewLoadContent];
    }
    [self.viewLoadContent mas_remakeConstraints:^(MASConstraintMaker *make) {
       make.left.top.right.bottom.mas_equalTo(self);
    }];
    CGFloat duration = [[UIApplication sharedApplication] statusBarOrientationAnimationDuration];
    [UIView animateWithDuration:duration animations:^{
        [self.viewLoadContent setTransform:CGAffineTransformMakeRotation(0.0f)];
    } completion:^(BOOL finished) {
        [self.controlView playerControlQuitFullScreen];
        [self.viewLoadContent setNeedsLayout];
        [self.viewLoadContent layoutIfNeeded];
    }];
}

#pragma mark - 屏幕横屏向左
- (void)deviceScreenInterfaceOrientationLeft {
    if (self.deviceDirection == LFBPlayerDeviceDirectionLeft) {
        return;
    }
    [self setDeviceDirection:LFBPlayerDeviceDirectionLeft];
    UIWindow *keyWindow = [[[UIApplication sharedApplication] delegate] window];
    if (![keyWindow.subviews containsObject:self.viewLoadContent]) {
        [self.viewLoadContent removeFromSuperview];
        [keyWindow addSubview:self.viewLoadContent];
    }
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:YES];
    [self.viewLoadContent mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(keyWindow);
        make.width.mas_equalTo(MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height));
        make.height.mas_equalTo(MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height));
    }];
    CGFloat duration = [[UIApplication sharedApplication] statusBarOrientationAnimationDuration];
    [UIView animateWithDuration:duration animations:^{
        [self.viewLoadContent setTransform:CGAffineTransformMakeRotation(-M_PI /2)];
    } completion:^(BOOL finished) {
        [self.controlView playerControlFullScreen];
        [self.viewLoadContent setNeedsLayout];
        [self.viewLoadContent layoutIfNeeded];
    }];
}

#pragma mark - 屏幕横屏向右
- (void)deviceScreenInterfaceOrientationRight {
    if (self.deviceDirection == LFBPlayerDeviceDirectionRight) {
        return;
    }
    [self setDeviceDirection:LFBPlayerDeviceDirectionRight];
    UIWindow *keyWindow = [[[UIApplication sharedApplication] delegate] window];
    if (![keyWindow.subviews containsObject:self.viewLoadContent]) {
        [self.viewLoadContent removeFromSuperview];
        [keyWindow addSubview:self.viewLoadContent];
    }
     [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeLeft animated:YES];
    [self.viewLoadContent mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(keyWindow);
        make.width.mas_equalTo(MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height));
        make.height.mas_equalTo(MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height));
    }];
    CGFloat duration = [[UIApplication sharedApplication] statusBarOrientationAnimationDuration];
    [UIView animateWithDuration:duration animations:^{
        [self.viewLoadContent setTransform:CGAffineTransformMakeRotation(M_PI/2)];
    } completion:^(BOOL finished) {
        [self.controlView playerControlFullScreen];
        [self.viewLoadContent setNeedsLayout];
        [self.viewLoadContent layoutIfNeeded];
    }];
}

- (void)startPlay {
    [self.playerWorker startPlay];
    [self.controlView playerControlStartPlay];
    [UIView animateWithDuration:0.2 animations:^{
        self.coverFrameImageView.hidden = YES;
    }];
}

- (void)pausePlay {
    [self.playerWorker pausePlay];
    [self.controlView playerControlPausePlay];
}


@end
