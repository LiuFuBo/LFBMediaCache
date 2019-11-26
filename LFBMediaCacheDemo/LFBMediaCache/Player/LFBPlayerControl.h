//
//  LFBPlayerControl.h
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/11/5.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, LFBPlayerControlSliderState) {
    LFBPlayerControlSliderStateBegan, //start move
    LFBPlayerControlSliderStateMoved, // moved
    LFBPlayerControlSliderStateEnded // end move
};

@protocol LFBResourcePlayerControlDelegate;

@interface LFBPlayerControl : UIView

- (instancetype)initWithDelegate:(id <LFBResourcePlayerControlDelegate>)delegate;

@property (nonatomic, weak) id <LFBResourcePlayerControlDelegate> delegate;

- (void)playerControlDuration:(CGFloat)duration currentDuration:(CGFloat)currentDuration;

// external playback status changes cause the control to change
- (void)playerControlStartPlay;
- (void)playerControlPausePlay;
- (void)playerControlFullScreen;
- (void)playerControlQuitFullScreen;

@end


@protocol LFBResourcePlayerControlDelegate <NSObject>
// play
- (void)resourceStartPlayWithPlayControl:(LFBPlayerControl *)playControl;
// pause
- (void)resourcePauseWithPlayControl:(LFBPlayerControl *)playControl;
//fullscreen
- (void)resourceFullScreenWithPlayControl:(LFBPlayerControl *)playControl;
//quitfullscreen
- (void)resourceQuitFullScreenWithPlayControl:(LFBPlayerControl *)playControl;
//slider move state
- (void)resourcePlayControl:(LFBPlayerControl *)playControl sliderValue:(CGFloat)value sliderTouchState:(LFBPlayerControlSliderState)state;

@end


