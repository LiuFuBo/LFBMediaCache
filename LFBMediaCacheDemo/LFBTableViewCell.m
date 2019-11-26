//
//  LFBTableViewCell.m
//  LFBMediaCacheDemo
//
//  Created by liufubo on 2019/11/21.
//  Copyright © 2019 liufubo. All rights reserved.
//

#import "LFBTableViewCell.h"
#import "LFBCachePlayerTool.h"
#import "Masonry.h"
#import "UIImage+Load.h"

@interface LFBTableViewCell ()
@property (nonatomic, strong) UIImageView *imageViewIcon;
@property (nonatomic, strong) UIButton *buttonPlay;
@end

@implementation LFBTableViewCell


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self UISetUp];
    }
    return self;
}

- (void)UISetUp {
    [self.contentView addSubview:self.imageViewIcon];
    [self.contentView addSubview:self.buttonPlay];
    [self.imageViewIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.bottom.mas_equalTo(self.contentView);
    }];
    [self.buttonPlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self.contentView);
        make.width.height.mas_equalTo(60);
    }];
}

- (void)setUrl:(NSString *)url {
    _url = url;
    __weak typeof(self) weakSelf = self;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        UIImage *image = [LFBCachePlayerTool lfb_playerFirstFrameImageWithURL:[NSURL URLWithString:url]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.imageViewIcon setImage:image];
        });
    });
}

- (void)clickTarget:(UIButton *)sender {
    if (self.targetClickBlock) {
        self.targetClickBlock(sender);
    }
}


- (UIImageView *)imageViewIcon {
    return _imageViewIcon?:({
        _imageViewIcon = [[UIImageView alloc]init];
        _imageViewIcon.contentMode = UIViewContentModeScaleAspectFill;
        _imageViewIcon;
    });
}

- (UIButton *)buttonPlay {
    return _buttonPlay?:({
        _buttonPlay = [[UIButton alloc]init];
        [_buttonPlay setImage:[UIImage lfb_imageName:@"lfb_cache_player_play"] forState:UIControlStateNormal];
        [_buttonPlay addTarget:self action:@selector(clickTarget:) forControlEvents:UIControlEventTouchUpInside];
        _buttonPlay;
    });
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
