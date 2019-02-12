//
//  NTESLiveCoverView.m
//  NIMLiveDemo
//
//  Created by chris on 16/3/31.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESLiveCoverView.h"
#import "NIMAvatarImageView.h"
#import "NTESLiveManager.h"
#import "NTESDataManager.h"
#import "UIView+NTES.h"

@interface NTESLiveCoverView ()

@property (nonatomic,strong) UILabel *statusLabel;

@property (nonatomic,strong) UILabel *nameLabel;

@property (nonatomic,strong) NIMAvatarImageView *avatar;

@property (nonatomic,strong) UIButton *backButton;

@end

@implementation NTESLiveCoverView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColorFromRGB(0xdfe2e6);
        [self addSubview:self.statusLabel];
        [self addSubview:self.nameLabel];
        [self addSubview:self.avatar];
        [self.backButton setTitle:@"返 回" forState:UIControlStateNormal];
        [self addSubview:self.backButton];
    }
    return self;
}

- (void)refreshWithChatroom:(NSString *)roomId
                     status:(NTESLiveCoverStatus)status
{
    switch (status) {
        case NTESLiveCoverStatusLinking:
            self.statusLabel.text  = @"连接中,请等待";
            self.backButton.hidden = YES;
            break;
        case NTESLiveCoverStatusFinished:
            self.statusLabel.text  = @"直播已结束";
            self.backButton.hidden = [NTESLiveManager sharedInstance].role == NTESLiveRoleAudience;
            break;
        default:
            break;
    }
    [self.statusLabel sizeToFit];
    
    __weak typeof(self) wself = self;
    
    [[NTESLiveManager sharedInstance] anchorInfo:roomId handler:^(NSError *error, NIMChatroomMember *anchor) {
        wself.nameLabel.text = anchor.roomNickname;
        [wself.nameLabel sizeToFit];
        [wself.avatar nim_setImageWithURL:[NSURL URLWithString:anchor.roomAvatar] placeholderImage:[NTESDataManager sharedInstance].defaultUserAvatar];
    }];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.avatar.bottom  = self.height * .5f - 40.f;
    self.avatar.centerX = self.width * .5f;
    self.nameLabel.centerX = self.width * .5f;
    self.nameLabel.top  = self.avatar.bottom + 7.f;
    self.statusLabel.top = self.nameLabel.bottom + 18.f;
    self.statusLabel.centerX = self.width * .5f;
}

- (void)didPressBack:(UIButton *)button
{
    if ([self.delegate respondsToSelector:@selector(didPressBackButton)]) {
        [self.delegate didPressBackButton];
    }
}

#pragma mark - Get
- (UILabel *)statusLabel
{
    if (!_statusLabel) {
        _statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _statusLabel.font = [UIFont systemFontOfSize:24.f];
    }
    return _statusLabel;
}

- (UILabel *)nameLabel
{
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _nameLabel.font = [UIFont systemFontOfSize:14.f];
    }
    return _nameLabel;
}

- (NIMAvatarImageView *)avatar
{
    if (!_avatar) {
        _avatar = [[NIMAvatarImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    }
    return _avatar;
}

- (UIButton *)backButton
{
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *backgroundImageNormal = [[UIImage imageNamed:@"btn_round_rect_normal"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10) resizingMode:UIImageResizingModeStretch];
        UIImage *backgroundImageHighlighted = [[UIImage imageNamed:@"btn_round_rect_pressed"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10) resizingMode:UIImageResizingModeStretch];
        [_backButton setBackgroundImage:backgroundImageNormal forState:UIControlStateNormal];
        [_backButton setBackgroundImage:backgroundImageHighlighted forState:UIControlStateHighlighted];
        [_backButton setTitleColor:UIColorFromRGB(0x0) forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(didPressBack:) forControlEvents:UIControlEventTouchUpInside];
        [_backButton setTitleColor:UIColorFromRGB(0x238efa) forState:UIControlStateNormal];
        _backButton.size = CGSizeMake(215, 46);
        _backButton.centerX = self.width * .5f;
        _backButton.bottom  = self.height - 80.f;
        _backButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    }
    return _backButton;
}

@end
