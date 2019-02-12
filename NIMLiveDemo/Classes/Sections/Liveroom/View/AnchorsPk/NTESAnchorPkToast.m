//
//  NTESAnchorPkToast.m
//  NIMLiveDemo
//
//  Created by Netease on 2018/10/24.
//  Copyright © 2018年 Netease. All rights reserved.
//

#import "NTESAnchorPkToast.h"
#import "UIView+NTES.h"

typedef NS_ENUM(NSInteger, NTESAnchorPkToastStyle) {
    NTESAnchorPkToastStyleTimer = 0,
    NTESAnchorPkToastStyleNick,
};

@interface NTESAnchorPkToast ()

@property (nonatomic, strong) UILabel *srcNickLab;
@property (nonatomic, strong) UILabel *dstNickLab;
@property (nonatomic, strong) UILabel *timerLab;
@property (nonatomic, strong) UILabel *tagLab;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSInteger intervalS;
@property (nonatomic, strong) UIImageView *vsImg;
@property (nonatomic, strong) UIImageView *redBlueBgImg;

@property (nonatomic, assign) NTESAnchorPkToastStyle style;


- (instancetype)initWithFrame:(CGRect)frame
                        style:(NTESAnchorPkToastStyle)style;
- (void)startTimer;
- (void)stopTimer;
@end

@implementation NTESAnchorPkToast

+ (instancetype)instanceTimerToast {
    NTESAnchorPkToast *toast = [[NTESAnchorPkToast alloc] initWithFrame:CGRectMake(0, 0, UIScreenWidth, 37)
                                                        style:NTESAnchorPkToastStyleTimer];
    return toast;
}

+ (instancetype)instanceNickToastWithSrcName:(NSString *)srcNick
                                     dstNick:(NSString *)dstNick {
    NTESAnchorPkToast *toast = [[NTESAnchorPkToast alloc] initWithFrame:CGRectMake(0, 0, UIScreenWidth, 37)
                                                        style:NTESAnchorPkToastStyleNick];
    toast.srcNick = srcNick;
    toast.dstNick = dstNick;
    return toast;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (_style ==  NTESAnchorPkToastStyleNick) {
        return;
    }
    if (newSuperview) {
        [self startTimer];
        self.centerX = (newSuperview.width/2);
    } else {
        [self stopTimer];
    }
}

- (instancetype)initWithFrame:(CGRect)frame
                        style:(NTESAnchorPkToastStyle)style {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = UIColorFromRGBA(0x0A0B33, 0.4);
        _style = style;
        switch (style) {
            case NTESAnchorPkToastStyleTimer:{
                [self addSubview:self.vsImg];
                [self addSubview:self.timerLab];
                break;
            }
            case NTESAnchorPkToastStyleNick: {
                [self addSubview:self.redBlueBgImg];
                [self addSubview:self.vsImg];
                [self addSubview:self.srcNickLab];
                [self addSubview:self.dstNickLab];
                break;
            }
            default:
                break;
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    switch (_style) {
        case NTESAnchorPkToastStyleTimer:{
            [self layoutTimerStyle];
            break;
        }
        case NTESAnchorPkToastStyleNick: {
            [self layoutNickStyle];
            break;
        }
        default:
            break;
    }
    
}

- (void)layoutTimerStyle {
    _vsImg.height = self.height - 20;
    _vsImg.width = _vsImg.height * 1.6;
    _vsImg.right = self.width / 2;
    _vsImg.centerY = self.height / 2;
    _timerLab.frame = CGRectMake(_vsImg.right + 8.0, 0, _timerLab.width, _vsImg.height);
    _timerLab.centerY = _vsImg.centerY;
}

- (void)layoutNickStyle {
    
    _redBlueBgImg.top = 5;
    _redBlueBgImg.height = 24;
    _redBlueBgImg.width = self.width - 40;
    _redBlueBgImg.centerX = self.width / 2;

    _vsImg.height = self.height - 20;
    _vsImg.width = _vsImg.height * 1.6;
    _vsImg.right = self.width / 2;
    _vsImg.centerY = self.height / 2;

    _srcNickLab.width = _srcNickLab.width;
    _srcNickLab.height = self.height;
    _srcNickLab.centerY = self.height/2;
    _srcNickLab.centerX = self.width / 4;
    
    _dstNickLab.width = _dstNickLab.width;
    _dstNickLab.height = self.height;
    _dstNickLab.centerY = self.height/2;
    _dstNickLab.centerX = self.width / 4 * 3;
}


- (void)startTimer {
    [self stopTimer];
    _intervalS = 0;
    _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onTimeFired) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)onTimeFired
{
    [self updateTimeLab];
}

- (void)stopTimer {
    [_timer invalidate];
    _timer = nil;
}

- (void)updateTimeLab {
    _intervalS = (++_intervalS)%(3600*24);
    NSString *string = @"00:00";
    if (_intervalS < 3600) {
        NSInteger min = _intervalS/60;
        NSInteger sec = _intervalS%60;
        string = [NSString stringWithFormat:@"%02d:%02d",
                            (int) min,(int)sec];
    } else {
        NSInteger sec = _intervalS%60;
        NSInteger hour = _intervalS/3600;
        NSInteger min = (_intervalS%3600)/60;
        string = [NSString stringWithFormat:@"%02d:%02d:%02d",
                            (int)hour, (int)min, (int)sec];
    }
    BOOL lengthChanged = (_timerLab.text.length != string.length);
    _timerLab.text = string;
    if (lengthChanged) {
        CGFloat width = 32 + _tagLab.width + 8.0 + _timerLab.width + 32.0;
        self.size = CGSizeMake(width, 32.0);
        if (self.superview) {
            self.centerX = (self.superview.width/2);
        }
        [self layoutIfNeeded];
    }
}

- (void)setSrcNick:(NSString *)srcNick {
    _srcNick = srcNick;
    _srcNickLab.text = srcNick;
    [_srcNickLab sizeToFit];
    CGFloat halfBgImgWidth = self.width / 2 - 20;
    if (_srcNickLab.width > halfBgImgWidth ) {
        _srcNickLab.width = halfBgImgWidth;
    }
    [self layoutIfNeeded];
}

- (void)setDstNick:(NSString *)dstNick {
    _dstNick = dstNick;
    _dstNickLab.text = dstNick;
    [_dstNickLab sizeToFit];
    CGFloat halfBgImgWidth = self.width / 2 - 20;
    if (_dstNickLab.width > halfBgImgWidth ) {
        _dstNickLab.width = halfBgImgWidth;
    }
    [self layoutIfNeeded];
}

#pragma mark - Getter
- (UILabel *)makeLabel {
    UILabel *ret = [[UILabel alloc] init];
    ret.font = [UIFont boldSystemFontOfSize:17.0];
    ret.textColor = [UIColor whiteColor];
    ret.backgroundColor = [UIColor clearColor];
    return ret;
}

- (UILabel *)srcNickLab {
    if (!_srcNickLab) {
        _srcNickLab = [self makeLabel];
    }
    return _srcNickLab;
}

- (UILabel *)dstNickLab {
    if (!_dstNickLab) {
        _dstNickLab = [self makeLabel];
    }
    return _dstNickLab;
}

- (UILabel *)timerLab {
    if (!_timerLab) {
        _timerLab = [self makeLabel];
        _timerLab.text = @"00:00";
        [_timerLab sizeToFit];
    }
    return _timerLab;
}

- (UILabel *)tagLab {
    if (!_tagLab) {
        _tagLab = [self makeLabel];
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"VS"];
        [string addAttribute:NSForegroundColorAttributeName
                       value:[UIColor blueColor]
                       range:NSMakeRange(0, 1)];
        [string addAttribute:NSForegroundColorAttributeName
                       value:[UIColor redColor]
                       range:NSMakeRange(1, 1)];
        _tagLab.attributedText = string;
        [_tagLab sizeToFit];
        _tagLab.height = 32.0;
    }
    return _tagLab;
}

- (UIImageView *)vsImg
{
    if (!_vsImg) {
        _vsImg = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"icon_pk_vs"]];
        _vsImg.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _vsImg;
}

-(UIImageView *)redBlueBgImg
{
    if (!_redBlueBgImg) {
        _redBlueBgImg = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"icon_pk_bg"]];
    }
    return _redBlueBgImg;

}

@end
