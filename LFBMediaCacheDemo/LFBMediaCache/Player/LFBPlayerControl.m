//
//  LFBPlayerControl.m
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/11/5.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import "LFBPlayerControl.h"
#import "LFBCachePlayerTool.h"
#import "UIImage+Load.h"
#import "Masonry.h"

@interface LFBPlayerControl ()<UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *fullScreenButton;
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UIProgressView *loadingProgress;
@property (nonatomic, strong) UILabel *labelMinimumValueText;
@property (nonatomic, strong) UILabel *labelMaxmumValueText;
@end

@implementation LFBPlayerControl

- (instancetype)initWithDelegate:(id<LFBResourcePlayerControlDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
        [self makeConstraints];
    }
    return self;
}

- (void)makeConstraints {
    [self addSubview:self.playButton];
    [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.mas_left);
        make.bottom.mas_equalTo(self.mas_bottom);
        make.width.height.mas_equalTo(50);
    }];
    [self addSubview:self.fullScreenButton];
    [self.fullScreenButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.mas_right);
        make.bottom.mas_equalTo(self.mas_bottom);
        make.width.height.mas_equalTo(50);
    }];
    [self addSubview:self.loadingProgress];
    [self.loadingProgress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.playButton.mas_right);
        make.bottom.mas_equalTo(self.mas_bottom).with.offset(-24);
        make.right.mas_equalTo(self.fullScreenButton.mas_left);
        make.height.mas_equalTo(2);
    }];
    [self addSubview:self.slider];
    [self.slider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.playButton.mas_right);
        make.centerY.mas_equalTo(self.loadingProgress.mas_centerY);
        make.width.mas_equalTo(self.loadingProgress.mas_width);
        make.height.mas_equalTo(20);
    }];
    [self addSubview:self.labelMinimumValueText];
    [self.labelMinimumValueText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.playButton.mas_right);
        make.bottom.mas_equalTo(self.mas_bottom).with.offset(-5);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(11);
    }];
    [self addSubview:self.labelMaxmumValueText];
    [self.labelMaxmumValueText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.fullScreenButton.mas_left);
        make.bottom.mas_equalTo(self.mas_bottom).with.offset(-5);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(11);
    }];
}

- (void)playerControlDuration:(CGFloat)duration currentDuration:(CGFloat)currentDuration {
    if (self.slider.maximumValue < duration) {
       [self.slider setMaximumValue:duration];
       [self.labelMaxmumValueText setText:[LFBCachePlayerTool lfb_playerConvertTime:duration]];
    }
    if (currentDuration >= duration) {
        [self.playButton setSelected:NO];
    }
    [self.labelMinimumValueText setText:[LFBCachePlayerTool lfb_playerConvertTime:currentDuration]];
    [self.slider setValue:currentDuration animated:YES];
}

- (void)playOrPauseTargetAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        if ([self.delegate respondsToSelector:@selector(resourceStartPlayWithPlayControl:)]) {
            [self.delegate resourceStartPlayWithPlayControl:self];
        }
    }else{
        if ([self.delegate respondsToSelector:@selector(resourcePauseWithPlayControl:)]) {
            [self.delegate resourcePauseWithPlayControl:self];
        }
    }
}

- (void)fullScreenTargetAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        if ([self.delegate respondsToSelector:@selector(resourceFullScreenWithPlayControl:)]) {
            [self.delegate resourceFullScreenWithPlayControl:self];
        }
    }else{
        if ([self.delegate respondsToSelector:@selector(resourceQuitFullScreenWithPlayControl:)]) {
            [self.delegate resourceQuitFullScreenWithPlayControl:self];
        }
    }
}

- (void)sliderValueChanged:(UISlider*)slider forEvent:(UIEvent*)event {
    UITouch *touchEvent = [[event allTouches] anyObject];
    switch (touchEvent.phase) {
        case UITouchPhaseBegan:
        { //began
            if ([self.delegate respondsToSelector:@selector(resourcePlayControl:sliderValue:sliderTouchState:)]) {
                [self.delegate resourcePlayControl:self sliderValue:slider.value sliderTouchState:LFBPlayerControlSliderStateBegan];
            }
            self.playButton.selected = NO;
        }
            break;
        case UITouchPhaseMoved:
        {//moved
            if ([self.delegate respondsToSelector:@selector(resourcePlayControl:sliderValue:sliderTouchState:)]) {
                [self.delegate resourcePlayControl:self sliderValue:slider.value sliderTouchState:LFBPlayerControlSliderStateMoved];
            }
        }
            break;
        case UITouchPhaseEnded:
        {//ended
            if ([self.delegate respondsToSelector:@selector(resourcePlayControl:sliderValue:sliderTouchState:)]) {
                [self.delegate resourcePlayControl:self sliderValue:slider.value sliderTouchState:LFBPlayerControlSliderStateEnded];
            }
            self.playButton.selected = YES;
            [self.slider setValue:slider.value animated:YES];
        }
            break;
        default:
            break;
    }
}

- (void)singleTapGestureForSlider:(UITapGestureRecognizer *)gesture {
    CGPoint touchPoint = [gesture locationInView:self.slider];
    [self.playButton setSelected:YES];
    CGFloat value = (self.slider.maximumValue - self.slider.minimumValue)*(touchPoint.x / self.slider.frame.size.width);
    [self.slider setValue:value animated:YES];
    if ([self.delegate respondsToSelector:@selector(resourcePlayControl:sliderValue:sliderTouchState:)]) {
        [self.delegate resourcePlayControl:self sliderValue:value sliderTouchState:LFBPlayerControlSliderStateEnded];
    }
}

- (void)playerControlStartPlay {
    [self.playButton setSelected:YES];
    [self.playButton setImage:[UIImage lfb_imageName:@"lfb_cache_player_pause"] forState:UIControlStateSelected];
}

- (void)playerControlPausePlay {
    [self.playButton setSelected:NO];
    [self.playButton setImage:[UIImage lfb_imageName:@"lfb_cache_player_play"] forState:UIControlStateNormal];
}

- (void)playerControlFullScreen {
    [self.fullScreenButton setSelected:YES];
}

- (void)playerControlQuitFullScreen {
    [self.fullScreenButton setSelected:NO];
}

#pragma mark - Getter & Setter
- (UIButton *)playButton {
    return _playButton?:({
        _playButton = [[UIButton alloc]init];
        [_playButton setImage:[UIImage lfb_imageName:@"lfb_cache_player_play"] forState:UIControlStateNormal];
        [_playButton setImage:[UIImage lfb_imageName:@"lfb_cache_player_pause"] forState:UIControlStateSelected];
        [_playButton addTarget:self action:@selector(playOrPauseTargetAction:) forControlEvents:UIControlEventTouchUpInside];
        _playButton;
    });
}

- (UIButton *)fullScreenButton {
    return _fullScreenButton?:({
        _fullScreenButton = [[UIButton alloc]init];
        [_fullScreenButton setImage:[UIImage lfb_imageName:@"lfb_cache_player_full"] forState:UIControlStateNormal];
        [_fullScreenButton setImage:[UIImage lfb_imageName:@"lfb_cache_player_quit"] forState:UIControlStateSelected];
        [_fullScreenButton addTarget:self action:@selector(fullScreenTargetAction:) forControlEvents:UIControlEventTouchUpInside];
        _fullScreenButton;
    });
}

- (UISlider *)slider {
    return _slider?:({
        _slider = [[UISlider alloc]init];
        _slider.backgroundColor = [UIColor clearColor];
        _slider.minimumValue = 0.0f;
        [_slider setThumbImage:[UIImage lfb_imageName:@"lfb_cache_player_dot"] forState:UIControlStateNormal];
        _slider.minimumTrackTintColor = [UIColor clearColor];
        _slider.maximumTrackTintColor = [UIColor clearColor];
        _slider.value = 0.0f;
        [_slider addTarget:self action:@selector(sliderValueChanged:forEvent:) forControlEvents:UIControlEventValueChanged];
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(singleTapGestureForSlider:)];
        singleTap.delegate = self;
        [_slider addGestureRecognizer:singleTap];
        _slider;
    });
}

- (UIProgressView *)loadingProgress {
    return _loadingProgress ?:({
        _loadingProgress = [[UIProgressView alloc]init];
        _loadingProgress.trackTintColor = [UIColor lightGrayColor];
        _loadingProgress.progressTintColor = [UIColor whiteColor];
        _loadingProgress.progress = 0.0f;
        _loadingProgress;
    });
}

- (UILabel *)labelMinimumValueText {
    return _labelMinimumValueText?:({
        _labelMinimumValueText = [[UILabel alloc]init];
        _labelMinimumValueText.font = [UIFont systemFontOfSize:11];
        _labelMinimumValueText.textAlignment = NSTextAlignmentLeft;
        _labelMinimumValueText.textColor = [UIColor whiteColor];
        _labelMinimumValueText.text = [LFBCachePlayerTool lfb_playerConvertTime:0.0f];
        _labelMinimumValueText;
    });
}

- (UILabel *)labelMaxmumValueText {
    return _labelMaxmumValueText?:({
        _labelMaxmumValueText = [[UILabel alloc]init];
        _labelMaxmumValueText.font = [UIFont systemFontOfSize:11];
        _labelMaxmumValueText.textAlignment = NSTextAlignmentRight;
        _labelMaxmumValueText.textColor = [UIColor whiteColor];
        _labelMaxmumValueText.text = [LFBCachePlayerTool lfb_playerConvertTime:0.0f];
        _labelMaxmumValueText;
    });
}


@end
