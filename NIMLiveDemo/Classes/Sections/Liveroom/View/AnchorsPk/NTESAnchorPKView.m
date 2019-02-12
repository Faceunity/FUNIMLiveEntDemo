//
//  NTESAnchorPKView.m
//  NIMLiveDemo
//
//  Created by Netease on 2018/10/22.
//  Copyright © 2018年 Netease. All rights reserved.
//

#import "NTESAnchorPKView.h"
#import "UIView+NTES.h"
#import "NTESGLView.h"
#import "NTESLiveManager.h"
#import "NIMAvatarImageView.h"

@interface NTESAnchorPKStatuesView : UIView

@property (nonatomic,strong) NIMAvatarImageView *avatar;
@property (nonatomic,strong) UILabel *nickLabel;
@property (nonatomic,strong) UILabel *statusLabel;

- (void)refreshWithAvatar:(NSString *)avatar
                     nick:(NSString *)nick;

@end

@implementation NTESAnchorPKStatuesView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        _avatar = [[NIMAvatarImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        [self addSubview:_avatar];
        
        _nickLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _nickLabel.font = [UIFont systemFontOfSize:9];
        _nickLabel.textColor = UIColorFromRGB(0x999999);
        [self addSubview:_nickLabel];
        
        _statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _statusLabel.font = [UIFont systemFontOfSize:11.f];
        _statusLabel.textColor = UIColorFromRGB(0x333333);
        [self addSubview:_statusLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat nickAndAvatarSpacing = 2.f;
    CGFloat nickAndStatusSpacing = 8.f;
    self.avatar.top = (self.height - (_nickLabel.height + _statusLabel.height + _avatar.height + nickAndAvatarSpacing + nickAndStatusSpacing))/2;
    self.avatar.centerX = self.width * .5f;
    self.nickLabel.top = self.avatar.bottom + nickAndAvatarSpacing;
    self.nickLabel.centerX = self.width * .5f;
    self.statusLabel.top = self.nickLabel.bottom + nickAndStatusSpacing;
    self.statusLabel.centerX = self.width * .5f;
}

- (void)refreshWithAvatar:(NSString *)avatar nick:(NSString *)nick {
    _nickLabel.text= nick ? nick : @"";
    [_nickLabel sizeToFit];
    [_avatar nim_setImageWithURL:nil
                placeholderImage:[UIImage imageNamed:@"avatar_user"]];
    [self setNeedsLayout];
}

@end

@interface NTESAnchorPKExitConfirmView : UIView
@property (nonatomic,strong) UILabel   *titleLabel;
@property (nonatomic,strong) UIView    *topSeperator;
@property (nonatomic,strong) UIView    *bottomSeperator;
@property (nonatomic,strong) UIButton  *confirmButton;
@property (nonatomic,strong) UIButton  *cancelButton;
@end

@implementation NTESAnchorPKExitConfirmView
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont systemFontOfSize:14.f];
        _titleLabel.textColor = UIColorFromRGB(0x333333);
        _titleLabel.numberOfLines = 2;
        _titleLabel.text = @"确定结束当前PK吗？";
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_titleLabel];
        
        _confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_confirmButton setTitleColor:UIColorFromRGB(0xff4055) forState:UIControlStateNormal];
        _confirmButton.titleLabel.font = [UIFont systemFontOfSize:17];
        [_confirmButton setTitle:@"确定" forState:UIControlStateNormal];
        [self addSubview:_confirmButton];
        
        _cancelButton  = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelButton setTitleColor:UIColorFromRGB(0xff4055) forState:UIControlStateNormal];
        _cancelButton.titleLabel.font = [UIFont systemFontOfSize:17];
        [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
        [self addSubview:_cancelButton];
        
        _topSeperator = [[UIView alloc] initWithFrame:CGRectZero];
        _topSeperator.backgroundColor = UIColorFromRGB(0xafa493);
        [self addSubview:_topSeperator];
        
        _bottomSeperator = [[UIView alloc] initWithFrame:CGRectZero];
        _bottomSeperator.backgroundColor = UIColorFromRGB(0xafa493);
        [self addSubview:_bottomSeperator];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _topSeperator.size    = CGSizeMake(self.width, 0.5f);
    _bottomSeperator.size = CGSizeMake(self.width, 0.5f);
    
    _titleLabel.width = self.width;
    _titleLabel.height = 48.0;
    _titleLabel.centerX = self.width * .5f;
    
    _cancelButton.width = self.width;
    _cancelButton.height = (self.height - _titleLabel.height)/2;
    _cancelButton.bottom  = self.height;
    
    _confirmButton.width = self.width;
    _confirmButton.height = (self.height - _titleLabel.height)/2;
    _confirmButton.bottom = _cancelButton.top;
    
    _topSeperator.bottom  = _confirmButton.top;
    _bottomSeperator.bottom = _cancelButton.top;
}
@end

@interface NTESAnchorPKView ()

@property (nonatomic, strong) UILabel *nickLabel;
@property (nonatomic, strong) NTESAnchorPKStatuesView *statuesView;
@property (nonatomic, strong) NTESGLView  *glView;
@property (nonatomic, strong) UIImageView *localAudioView;
@property (nonatomic, strong) NTESAnchorPKExitConfirmView *exitConfirmView;
@property (nonatomic, strong) UIButton    *stopButton;
@end

@implementation NTESAnchorPKView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addSubview:self.glView];
        [self addSubview:self.localAudioView];
        [self addSubview:self.exitConfirmView];
        [self addSubview:self.nickLabel];
        [self addSubview:self.stopButton];
        [self addSubview:self.statuesView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _glView.frame = self.bounds;
    _localAudioView.frame = self.bounds;
    _stopButton.origin = CGPointMake(self.width - _stopButton.width, 0);
    _nickLabel.frame = CGRectMake(8.0, 8.0, self.width - 8.0*2 - _stopButton.width, _nickLabel.height);
    
    if ([NTESLiveManager sharedInstance].orientation==NIMVideoOrientationLandscapeRight) {
        _exitConfirmView.frame = CGRectMake(self.width - 8.0 - 100.0, _stopButton.bottom + 8.0, 120.0, 100.0);
    } else {
        _exitConfirmView.frame = CGRectMake(self.width - 8.0 - 100.0, _stopButton.bottom + 8.0, 100.0, 120.0);
    }
    _statuesView.frame = self.bounds;
}

#pragma mark - Action
- (void)confirmExit:(UIButton *)btn {
    if(_delegate && [_delegate respondsToSelector:@selector(NTESAnchorPKViewDidExit:)]) {
        [_delegate NTESAnchorPKViewDidExit:self];
    }
}

- (void)cancelExit:(UIButton *)btn {
    _exitConfirmView.hidden = YES;
}

- (void)stopConfirm:(UIButton *)btn {
    _exitConfirmView.hidden = NO;
}

#pragma mark - Getter
- (UILabel *)nickLabel {
    if (!_nickLabel) {
        _nickLabel = [[UILabel alloc] init];
        _nickLabel.font = [UIFont systemFontOfSize:14.0];
        _nickLabel.textColor = UIColorFromRGB(0x999999);
    }
    return _nickLabel;
}

- (NTESGLView *)glView {
    if (!_glView) {
        _glView = [[NTESGLView alloc] initWithFrame:CGRectZero];
        _glView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"icon_glview_background"]];
        _glView.contentMode = UIViewContentModeScaleAspectFill;
        _glView.hidden = YES;
    }
    return _glView;
}


- (UIImageView *)localAudioView {
    if (!_localAudioView) {
        _localAudioView = [[UIImageView alloc] initWithFrame:CGRectZero];
        UIImage *image1 = [UIImage imageNamed:@"icon_mic_audience_1"];
        UIImage *image2 = [UIImage imageNamed:@"icon_mic_audience_2"];
        UIImage *image3 = [UIImage imageNamed:@"icon_mic_audience_3"];
        _localAudioView = [[UIImageView alloc] initWithImage:image1];
        [_localAudioView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"icon_mic_audience_bkg"]]];
        _localAudioView.contentMode = UIViewContentModeCenter;
        _localAudioView.animationDuration = 1.2f;
        _localAudioView.animationImages = @[image1,image2,image3];
        _localAudioView.hidden = YES;
    }
    return _localAudioView;
}

- (NTESAnchorPKExitConfirmView *)exitConfirmView {
    if (!_exitConfirmView) {
        _exitConfirmView = [[NTESAnchorPKExitConfirmView alloc] init];
        [_exitConfirmView.confirmButton addTarget:self
                                           action:@selector(confirmExit:)
                                 forControlEvents:UIControlEventTouchUpInside];
        [_exitConfirmView.cancelButton addTarget:self
                                          action:@selector(cancelExit:)
                                forControlEvents:UIControlEventTouchUpInside];
        _exitConfirmView.hidden = YES;
    }
    return _exitConfirmView;
}

- (UIButton *)stopButton {
    if (!_stopButton) {
        _stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_stopButton setImage:[UIImage imageNamed:@"icon_close_n"] forState:UIControlStateNormal];
        [_stopButton setImage:[UIImage imageNamed:@"icon_close_p"] forState:UIControlStateNormal];
        _stopButton.size = CGSizeMake(44, 44);
        [_stopButton addTarget:self
                        action:@selector(stopConfirm:)
              forControlEvents:UIControlEventTouchUpInside];
    }
    return _stopButton;
}

- (NTESAnchorPKStatuesView *)statuesView {
    if (!_statuesView) {
        _statuesView = [[NTESAnchorPKStatuesView alloc] init];
    }
    return _statuesView;
}

- (void)setNick:(NSString *)nick {
    _nick = nick;
    _nickLabel.text = (nick ? nick : @"");
    [_nickLabel sizeToFit];
    [_statuesView refreshWithAvatar:nil nick:nick];
    [self setNeedsLayout];
}

- (void)updateRemoteView:(NSData *)yuvData
                   width:(NSUInteger)width
                  height:(NSUInteger)height {
    self.backgroundColor = UIColorFromRGBA(0x0,.2);
    [self.glView render:yuvData width:width height:height];
}

- (void)setStatus:(NTESLivePKViewStatus)status {
    switch (status) {
        case NTESPKViewStatusNone: {
            _nickLabel.hidden = NO;
            _stopButton.hidden = NO;
            _glView.hidden = YES;
            _localAudioView.hidden = YES;
            _statuesView.hidden = YES;
            break;
        }
        case NTESPKViewStatusLoading: {
            _nickLabel.hidden = YES;
            _stopButton.hidden = YES;
            _glView.hidden = YES;
            _localAudioView.hidden = YES;
            _statuesView.hidden = NO;
            _statuesView.statusLabel.text = @"正在连接中...";
            break;
        }
        case NTESPKViewStatusVideoPlaying: {
            _nickLabel.hidden = NO;
            _stopButton.hidden = NO;
            _glView.hidden = NO;
            _localAudioView.hidden = YES;
            _statuesView.hidden = YES;
            break;
        }
        case NTESPKViewStatusAudioPlaying: {
            _nickLabel.hidden = NO;
            _stopButton.hidden = NO;
            _glView.hidden = YES;
            _localAudioView.hidden = NO;
            _statuesView.hidden = YES;
            break;
        }
        case NTESPKViewStatusAudioEnd: {
            _nickLabel.hidden = YES;
            _stopButton.hidden = NO;
            _glView.hidden = YES;
            _localAudioView.hidden = YES;
            _statuesView.hidden = NO;
            _statuesView.statusLabel.text = @"连接结束";
            break;
        }
        default:
            break;
    }
    _status = status;
}

@end
