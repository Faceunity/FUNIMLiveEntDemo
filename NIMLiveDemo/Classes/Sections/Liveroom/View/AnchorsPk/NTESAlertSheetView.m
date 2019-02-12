//
//  NTESAlertSheetView.m
//  NIMLiveDemo
//
//  Created by Netease on 2018/10/19.
//  Copyright © 2018年 Netease. All rights reserved.
//

#import "NTESAlertSheetView.h"
#import "UIView+NTES.h"
#import "NIMAvatarImageView.h"

typedef NS_ENUM(NSInteger, NTESAlertSheetStyle) {
    NTESAlertSheetMessage = 0,//消息提示
    NTESAlertSheetIdInput,    //ID输入框
    NTESAlertSheetWaiting,    //等待对方响应
    NTESAlertSheetEnd,    //等待对方响应
};

@interface NTESAlertSheetView ()
{
    CGRect _preRect;
}
@property (nonatomic, strong) UIView *bar;
@property (nonatomic, strong) UILabel *titleLab;
@property (nonatomic, strong) UIView *separatorLine;
@property (nonatomic, assign) CGFloat barHeight;

- (instancetype)initWithFrame:(CGRect)frame
                        style:(NTESAlertSheetStyle)style;

- (void)doSetupSubviews;

- (void)doLayoutSubviewsWithFrame:(CGRect)frame;

- (void)doBarCorner;

@end

#pragma mark - 消息类型弹窗
@interface NTESAlertSheetMessageView : NTESAlertSheetView

@property (nonatomic, strong) UILabel *messageLab;
@property (nonatomic, strong) UIButton *sureBtn;
@end

@implementation NTESAlertSheetMessageView

- (void)doSetupSubviews {
    [super doSetupSubviews];
    [self.bar addSubview:self.messageLab];
    [self.bar addSubview:self.sureBtn];
}

-(void)layoutSubviews
{
    [self doLayoutSubviewsWithFrame:self.frame];
}

- (void)doLayoutSubviewsWithFrame:(CGRect)frame {
    [super doLayoutSubviewsWithFrame:frame];
    _messageLab.width = self.bar.width - 50 * 2;
    _messageLab.left = 50;
    _messageLab.top = self.titleLab.bottom + 30;
    
    _sureBtn.frame = CGRectMake((self.bar.width - 160.0)/2,
                                self.messageLab.bottom + 30,
                                160.0,
                                42);
    
    self.bar.height = self.sureBtn.bottom + 25;
    self.bar.bottom = self.bottom;
    
    [super doBarCorner];
}

- (UILabel *)messageLab {
    if (!_messageLab) {
        _messageLab = [[UILabel alloc] init];
        _messageLab.font = [UIFont systemFontOfSize:15.0];
        _messageLab.textColor = UIColorFromRGB(0x6C6C6C);
        _messageLab.numberOfLines = 0;
        _messageLab.textAlignment = NSTextAlignmentCenter;
    }
    return _messageLab;
}

- (UIButton *)sureBtn {
    if (!_sureBtn) {
        _sureBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _sureBtn.backgroundColor = [UIColor blueColor];
        [_sureBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_sureBtn setTitle:@"知道了" forState:UIControlStateNormal];
        _sureBtn.titleLabel.font = [UIFont systemFontOfSize:18.0];
        _sureBtn.backgroundColor = UIColorFromRGB(0xFF6161);
        _sureBtn.layer.cornerRadius = 20;
        _sureBtn.layer.borderWidth = 1;
        _sureBtn.layer.masksToBounds = YES;
        _sureBtn.layer.borderColor = [UIColor clearColor].CGColor;

        [_sureBtn addTarget:self
                     action:@selector(dismiss)
           forControlEvents:UIControlEventTouchUpInside];
    }
    return _sureBtn;
}

- (CGFloat)barHeight {
    return (100 + [super barHeight]);
}

- (void)setMessage:(NSString *)message {
    [super setMessage:message];
    _messageLab.text = (message ? message : @"");
    [_messageLab sizeToFit];
    [self doLayoutSubviewsWithFrame:self.frame];

}

@end

#pragma mark - 输入类型弹窗
@interface NTESAlertSheetInputView : NTESAlertSheetView
@property (nonatomic, strong) UILabel *subtitleLab;
@property (nonatomic, strong) UITextField *inputField;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIButton *sureBtn;
@end

@implementation NTESAlertSheetInputView

- (void)doLayoutSubviewsWithFrame:(CGRect)frame {
    [super doLayoutSubviewsWithFrame:frame];
    [self doLayoutsubViews];
}

- (void)doSetupSubviews {
    [super doSetupSubviews];
    [self.bar addSubview:self.inputField];
    [self.bar addSubview:self.cancelBtn];
    [self.bar addSubview:self.sureBtn];
}

- (void)btnAction:(UIButton *)btn {
    [self dismiss];
    switch (btn.tag) {
        case 11: {
            if (self.delegate && [self.delegate respondsToSelector:@selector(NTESAlertSheetDidSeletedInputSure:input:)]) {
                [self.delegate NTESAlertSheetDidSeletedInputSure:self
                                                           input:_inputField.text];
            }
            break;
        }
        default:
            break;
    }
}

- (UILabel *)subtitleLab {
    if (!_subtitleLab) {
        _subtitleLab = [[UILabel alloc] init];
        _subtitleLab.font = [UIFont systemFontOfSize:14.0];
        _subtitleLab.numberOfLines = 0;
    }
    return _subtitleLab;
}

- (UITextField *)inputField {
    if (!_inputField) {
        _inputField = [[UITextField alloc] init];
        _inputField.font = [UIFont systemFontOfSize:15.0];
        _inputField.placeholder = @"邀请PK主播ID";
        _inputField.keyboardType = UIKeyboardTypeDefault;
        _inputField.returnKeyType = UIReturnKeyDone;
        _inputField.borderStyle = UITextBorderStyleNone;
        [_inputField setAutocorrectionType:UITextAutocorrectionTypeNo];
        [_inputField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        _inputField.backgroundColor = UIColorFromRGB(0xF2F2F2);
        _inputField.layer.cornerRadius = 6;
        _inputField.layer.borderWidth = 1;
        _inputField.layer.masksToBounds = YES;
        _inputField.layer.borderColor = UIColorFromRGB(0xE8E8E8).CGColor;
        
        //缩进
        UIView *letfView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 40)];
        letfView.backgroundColor = [UIColor clearColor];
        _inputField.leftViewMode = UITextFieldViewModeAlways;
        _inputField.leftView = letfView;

    }
    return _inputField;
}

- (UIButton *)cancelBtn {
    if (!_cancelBtn) {
        _cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        [_cancelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _cancelBtn.titleLabel.font = [UIFont systemFontOfSize:18.0];
        _cancelBtn.tag = 10;
        _cancelBtn.backgroundColor = UIColorFromRGB(0xFF6161);
        _cancelBtn.layer.cornerRadius = 20;
        _cancelBtn.layer.borderWidth = 1;
        _cancelBtn.layer.masksToBounds = YES;
        _cancelBtn.layer.borderColor = [UIColor clearColor].CGColor;

        [_cancelBtn addTarget:self
                       action:@selector(btnAction:)
             forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtn;
}

- (UIButton *)sureBtn {
    if (!_sureBtn) {
        _sureBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_sureBtn setTitle:@"邀请" forState:UIControlStateNormal];
        [_sureBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _sureBtn.titleLabel.font = [UIFont systemFontOfSize:18.0];
        _sureBtn.tag = 11;
        _sureBtn.backgroundColor = UIColorFromRGB(0x197BFF);
        _sureBtn.layer.cornerRadius = 20;
        _sureBtn.layer.borderWidth = 1;
        _sureBtn.layer.masksToBounds = YES;
        _sureBtn.layer.borderColor = [UIColor clearColor].CGColor;

        [_sureBtn addTarget:self
                     action:@selector(btnAction:)
           forControlEvents:UIControlEventTouchUpInside];
    }
    return _sureBtn;
}

- (void)doLayoutsubViews {

    CGRect frame = CGRectMake(20,
                        self.titleLab.bottom + 29,
                        self.bar.width - 20 * 2,
                        40.0);
    _inputField.frame = frame;
    
    _cancelBtn.width = (self.bar.width - 20 * 4) / 2;
    _cancelBtn.top = _inputField.bottom + 28.0;
    _cancelBtn.centerX =self.bar.width /4 ;
    _cancelBtn.height = 40.0;
    _cancelBtn.bottom = self.bar.height - 20;

    
    _sureBtn.width = _cancelBtn.width;
    _sureBtn.top = _inputField.bottom + 28.0;
    _sureBtn.centerX =self.bar.width /4 * 3 ;
    _sureBtn.height = 40.0;
    _sureBtn.bottom = self.bar.height - 20;
    
    [super doBarCorner];

}

- (CGFloat)barHeight {
    return (193 + [super barHeight]);
}

- (void)setSubtitle:(NSString *)subtitle {
    [super setSubtitle:subtitle];
    self.subtitleLab.text = (subtitle ? subtitle : @"");
    [self.subtitleLab sizeToFit];
    [self doLayoutSubviewsWithFrame:self.bounds];
}

@end

@class NTESAlertSheetWaitingView;

#pragma mark - 等待类弹窗
@interface NTESAlertSheetWaitingView : NTESAlertSheetView
@property (nonatomic, strong) NIMAvatarImageView *imageView;
@property (nonatomic, strong) UILabel *nameLab;
@property (nonatomic, strong) UILabel *subtitleLab;
@property (nonatomic, strong) UIButton *cancelBtn;
@end

@implementation NTESAlertSheetWaitingView

- (void)doSetupSubviews {
    [super doSetupSubviews];
    [self.bar addSubview:self.imageView];
    [self.bar addSubview:self.nameLab];
    [self.bar addSubview:self.subtitleLab];
    [self.bar addSubview:self.cancelBtn];
}

- (void)doLayoutSubviewsWithFrame:(CGRect)frame {
    [super doLayoutSubviewsWithFrame:frame];
    
    _imageView.frame = CGRectMake(self.bar.width/2 - 40.0 - 8.0,
                                  self.titleLab.bottom + 16, 60, 60);
    _imageView.centerX = self.bar.width / 2;
    
    _nameLab.centerX = self.bar.width / 2;
    _nameLab.top = _imageView.bottom + 10;
    _nameLab.height = 20;
    _nameLab.width = 100;
    
    _subtitleLab.centerX = self.bar.width / 2;
    _subtitleLab.top = _nameLab.bottom + 16;
    _subtitleLab.height = 20;
    _subtitleLab.width = 100;
    
    _cancelBtn.frame = CGRectMake((self.bar.width - 160.0)/2, _subtitleLab.bottom + 30, 160.0, 40.0);
    
    [super doBarCorner];

}

- (CGFloat)barHeight {
    return [super barHeight] + 255;
}

- (void)btnAction:(UIButton *)btn {
    [self dismiss];
    switch (btn.tag) {
        case 10: {
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(NTESAlertSheetDidWaitingCancel:)]) {
                [self.delegate NTESAlertSheetDidWaitingCancel:self];
            }
            break;
        }
        default:
            break;
    }
}

- (NIMAvatarImageView *)imageView {
    if (!_imageView) {
        _imageView = [[NIMAvatarImageView alloc] init];
        [_imageView setImage:[UIImage imageNamed:@"avatar_user"]];
    }
    return _imageView;
}

- (UILabel *)nameLab {
    if (!_nameLab) {
        _nameLab = [[UILabel alloc] init];
        _nameLab.font = [UIFont systemFontOfSize:17.0];
        [_nameLab sizeToFit];
    }
    return _nameLab;
}

- (UILabel *)subtitleLab {
    if (!_subtitleLab) {
        _subtitleLab = [[UILabel alloc] init];
        _subtitleLab.font = [UIFont systemFontOfSize:12.0];
        _subtitleLab.numberOfLines = 0;
        _subtitleLab.text = @"等待对手中...";
        _subtitleLab.textColor = UIColorFromRGB(0xAEB2BC);
        _subtitleLab.textAlignment = NSTextAlignmentCenter;
        [_subtitleLab sizeToFit];
    }
    return _subtitleLab;
}

- (UIButton *)cancelBtn {
    if (!_cancelBtn) {
        _cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelBtn setTitle:@"取消等待" forState:UIControlStateNormal];
        [_cancelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _cancelBtn.titleLabel.font = [UIFont systemFontOfSize:18.0];
        _cancelBtn.tag = 10;
        _cancelBtn.backgroundColor = UIColorFromRGB(0xFF6161);
        _cancelBtn.layer.cornerRadius = 20;
        _cancelBtn.layer.borderWidth = 1;
        _cancelBtn.layer.masksToBounds = YES;
        _cancelBtn.layer.borderColor = [UIColor clearColor].CGColor;

        [_cancelBtn addTarget:self
                       action:@selector(btnAction:)
             forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtn;
}

- (void)setImageUrl:(NSString *)imageUrl {
    [super setImageUrl:imageUrl];
    if (imageUrl) {
        [_imageView nim_setImageWithURL:[NSURL URLWithString:imageUrl]
                       placeholderImage:[UIImage imageNamed:@"avatar_user"]];
    }
}

- (void)setName:(NSString *)name {
    [super setName:name];
    _nameLab.text = (name ? name : @"");
    [_nameLab sizeToFit];
    [self doLayoutSubviewsWithFrame:self.bounds];
}

@end

#pragma mark - 结束类弹窗
@interface NTESAlertSheetEndView : NTESAlertSheetWaitingView
@end

@implementation NTESAlertSheetEndView
- (void)doSetupSubviews {
    [super doSetupSubviews];
    [super doBarCorner];
    self.subtitleLab.hidden = YES;
    [self.cancelBtn setTitle:@"结束PK" forState:UIControlStateNormal];
}

- (void)btnAction:(UIButton *)btn {
    [self dismiss];
    switch (btn.tag) {
        case 10: {
            if (self.delegate
                && [self.delegate respondsToSelector:@selector(NTESAlertSheetDidSeletedEnd:)]) {
                [self.delegate NTESAlertSheetDidSeletedEnd:self];
            }
            break;
        }
        default:
            break;
    }
}


@end

#pragma mark - 弹窗基类
@implementation NTESAlertSheetView

+ (instancetype)showMessageWithTitle:(nullable NSString *)title
                             message:(nullable NSString *)message {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    CGRect frame = window.bounds;
    NTESAlertSheetView *tmp = [[NTESAlertSheetView alloc] initWithFrame:frame
                                                                  style:NTESAlertSheetMessage];
    tmp.title = title;
    tmp.message = message;
    [tmp show];
    return tmp;
}

+ (instancetype)showInputWithTitle:(nullable NSString *)title
                          subtitle:(nullable NSString *)subtitle
                          delegate:(id<NTESAlertSheetViewDelegate>)delegate {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    CGRect frame = window.bounds;
    NTESAlertSheetView *tmp = [[NTESAlertSheetView alloc] initWithFrame:frame
                                                                  style:NTESAlertSheetIdInput];
    tmp.title = title;
    tmp.subtitle = subtitle;
    tmp.delegate = delegate;
    [tmp show];
    return tmp;
}

+ (instancetype)showWaitWithTitle:(nullable NSString *)title
                            image:(nullable NSString *)imageUrl
                             name:(nullable NSString *)name
                         delegate:(id<NTESAlertSheetViewDelegate>)delegate {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    CGRect frame = window.bounds;
    NTESAlertSheetView *tmp = [[NTESAlertSheetView alloc] initWithFrame:frame
                                                                  style:NTESAlertSheetWaiting];
    tmp.title = title;
    tmp.imageUrl = imageUrl;
    tmp.name = name;
    tmp.delegate = delegate;
    [tmp show];
    return tmp;
}

+ (instancetype)showEndWithTitle:(nullable NSString *)title
                           image:(nullable NSString *)imageUrl
                            name:(nullable NSString *)name
                        delegate:(nullable id<NTESAlertSheetViewDelegate>)delegate {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    CGRect frame = window.bounds;
    NTESAlertSheetView *tmp = [[NTESAlertSheetView alloc] initWithFrame:frame
                                                                  style:NTESAlertSheetEnd];
    tmp.title = title;
    tmp.imageUrl = imageUrl;
    tmp.name = name;
    tmp.delegate = delegate;
    [tmp show];
    return tmp;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addTarget:self
                 action:@selector(dismiss)
       forControlEvents:UIControlEventTouchUpInside];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShown:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHiden:) name:UIKeyboardWillHideNotification object:nil];
        [self doSetupSubviews];
        [self doLayoutSubviewsWithFrame:frame];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
                        style:(NTESAlertSheetStyle)style {
    NTESAlertSheetView *ret = nil;
    switch (style) {
        case NTESAlertSheetMessage:
            ret = [[NTESAlertSheetMessageView alloc] initWithFrame:frame];
            break;
        case NTESAlertSheetIdInput:
            ret = [[NTESAlertSheetInputView alloc] initWithFrame:frame];
            break;
        case NTESAlertSheetWaiting:
            ret = [[NTESAlertSheetWaitingView alloc] initWithFrame:frame];
            break;
        case NTESAlertSheetEnd:
            ret = [[NTESAlertSheetEndView alloc] initWithFrame:frame];
            break;
        default:
            break;
    }
    return ret;
}

- (void)doLayoutSubviewsWithFrame:(CGRect)frame {
    _bar.frame = CGRectMake(0, frame.size.height, frame.size.width, self.barHeight);
    _titleLab.frame = CGRectMake(0 , 28, self.bar.width, 28.0);
    
}

- (void)doSetupSubviews {
    [self addSubview:self.bar];
    [self.bar addSubview:self.titleLab];
    [self.bar addSubview:self.separatorLine];
}

- (void)doBarCorner
{
    //设置bar半边圆角
    UIBezierPath *maskPath;
    maskPath = [UIBezierPath bezierPathWithRoundedRect:_bar.bounds
                                     byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight)
                                           cornerRadii:CGSizeMake(10, 10)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = _bar.bounds;
    maskLayer.path = maskPath.CGPath;
    _bar.layer.mask = maskLayer;
}

- (void)show {
    [self endEditing:YES];
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if ([[window.subviews lastObject] isKindOfClass:[NTESAlertSheetView class]]) {
        NTESAlertSheetView *lastView = [window.subviews lastObject];
        __weak typeof(self) weakSelf = self;
        [lastView dismissWithCompletion:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                [window addSubview:strongSelf];
                strongSelf.bar.top = strongSelf.height;
                [UIView animateWithDuration:0.25 animations:^{
                    strongSelf.bar.bottom = strongSelf.height;
                }];
            }
        }];
    } else {
        [window addSubview:self];
        self.bar.top = self.height;
        [UIView animateWithDuration:0.25 animations:^{
            self.bar.bottom = self.height;
        }];
    }
}

- (void)dismissWithCompletion:(nullable void (^)())completion {
    [self endEditing:YES];
    [UIView animateWithDuration:0.25 animations:^{
        self.bar.top = self.height;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        if (completion) {
            completion();
        }
    }];
}

- (void)dismiss {
    [self dismissWithCompletion:nil];
}


- (void)onTapBackground {
    [self dismiss];
}

- (UIView *)bar {
    if (!_bar) {
        _bar = [[UIView alloc] init];
        _bar.backgroundColor = UIColorFromRGB(0xFFFFFF);
    }
    return _bar;
}

- (CGFloat)barHeight {
    return 29.0;
}

- (UILabel *)titleLab {
    if (!_titleLab) {
        _titleLab = [[UILabel alloc] init];
        _titleLab.font = [UIFont systemFontOfSize:20.0];
        _titleLab.textColor = [UIColor blackColor];
        _titleLab.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLab;
}

- (UIView *)separatorLine {
    if (!_separatorLine) {
        _separatorLine = [[UIView alloc] init];
        _separatorLine.backgroundColor = [UIColor grayColor];
    }
    return _separatorLine;
}

- (void)setTitle:(NSString *)title {
    _title = title;
    _titleLab.text = (title ? title : @"");
}

- (void)keyboardWillShown:(NSNotification *)note {
    // 获取键盘的高度
    CGRect frame = [[[note userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [UIView animateWithDuration:0.2 animations:^{
        self.bar.bottom = self.height - frame.size.height;
    }];
}

- (void)keyboardWillBeHiden:(NSNotification *)note {
    [UIView animateWithDuration:0.2 animations:^{
        self.bar.bottom = self.height;
    }];
}

@end
