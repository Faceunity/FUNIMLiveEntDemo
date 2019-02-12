//
//  NTESPreviewInnerView.m
//  NIMLiveDemo
//
//  Created by Simon Blue on 17/3/21.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import "NTESPreviewInnerView.h"
#import "UIView+NTES.h"
#import "NTESGLView.h"
#import "NTESLiveManager.h"
#import "NTESAnchorLiveViewController.h"
#import "NTESLiveCoverView.h"
#import "NTESOrientationSelectView.h"
#import "NTESFilterMenuBar.h"
#import "NTESFiterMenuView.h"
#import "NTESLiveUtil.h"

#define orientationSelectViewHeight 100

@interface NTESPreviewInnerView ()<NTESLiveCoverViewDelegate,NTESOrientationSelectViewDelegate,NTESMenuViewProtocol>

@property (nonatomic, strong) UIButton *startLiveButton;          //开始直播按钮

@property (nonatomic, strong) UIButton *closeButton;              //关闭直播按钮

@property (nonatomic, strong) UIButton *orientationButton;        //方向按钮

@property (nonatomic, strong) UIButton *cameraButton;              //切换摄像头按钮

@property (nonatomic, strong) UIButton *beautifyButton;             //美颜按钮

@property (nonatomic, strong) NTESGLView  *preView;                 //预览视图

@property (nonatomic, strong) NTESLiveCoverView    *coverView;     //状态覆盖层

@property (nonatomic, copy)   NSString *roomId;                   //聊天室ID

@property (nonatomic, strong) NTESOrientationSelectView *orientationSelectView; //方向选择view

@property (nonatomic) BOOL showOrientataionView;

@property (nonatomic) BOOL showFilterBar;

@property (nonatomic) NIMVideoOrientation orientation;

@property (nonatomic, strong) NTESFilterMenuBar *filterBar;

@end
@implementation NTESPreviewInnerView

- (instancetype)initWithChatroom:(NSString *)chatroomId
                           frame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.roomId = chatroomId;
        self.orientation = NIMVideoOrientationPortrait;
        [self setup];
    }
    return self;
}

-(void)setup
{
    [self addSubview: self.startLiveButton];
    [self addSubview: self.closeButton];
    [self addSubview: self.coverView];
    [self addSubview: self.orientationButton];
    [self addSubview: self.cameraButton];
    [self addSubview: self.beautifyButton];
    [self addSubview: self.orientationSelectView];
    [self addSubview: self.filterBar];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (!self.showOrientataionView&&!self.showFilterBar) {
        return;
    }
    
    UITouch *touch = [touches anyObject];

    if (self.showFilterBar) {
        
        CGPoint point = [touch locationInView:_filterBar];

        if (![_filterBar pointInside:point withEvent:nil]) {

            [self.filterBar cancel];
        }
    }
    
    else if (self.showOrientataionView)
    {
        CGPoint point = [touch locationInView:_orientationSelectView];

        if (![_orientationSelectView pointInside:point withEvent:nil]) {
            
            [UIView animateWithDuration:0.5 animations:^{
                if (_orientation == NIMVideoOrientationPortrait) {
                    _orientationSelectView.bottom = self.height + orientationSelectViewHeight;
                }
                
                else
                {
                    _orientationSelectView.bottom = self.width + orientationSelectViewHeight;
                }

            } completion:^(BOOL finished) {
                self.showOrientataionView = NO;
            }];
        }
    }
}

- (void)dismissFilterBar
{
    [UIView animateWithDuration:0.5 animations:^{
        _filterBar.bottom = self.height + _filterBar.height;
    } completion:^(BOOL finished) {
        self.showFilterBar = NO;
    }];

}

- (NTESFilterMenuBar *)filterBar
{
    if (!_filterBar)
    {
        _filterBar = [[NTESFilterMenuBar alloc] init];
        _filterBar.delegate = self;
        _filterBar.selectBlock = ^(NSInteger index) {
            [[NIMAVChatSDK sharedSDK].netCallManager selectBeautifyType:(NIMNetCallFilterType)[NTESLiveUtil changeToLiveType:index]];
        };
        
        _filterBar.contrastChangedBlock = ^(CGFloat value) {
            [[NIMAVChatSDK sharedSDK].netCallManager setContrastFilterIntensity:value];
        };
        
        _filterBar.smoothChangedBlock = ^(CGFloat value) {
            [[NIMAVChatSDK sharedSDK].netCallManager setSmoothFilterIntensity:value];
        };
    }
    return _filterBar;
}


-(void)layoutSubviews
{
    
    if (self.orientation == NIMVideoOrientationPortrait) {
    
        _cameraButton.centerX = self.width/2;
        _cameraButton.bottom = self.height - 25;
        
        _orientationButton.centerY = _cameraButton.centerY;
        _orientationButton.right = _cameraButton.left - 25;
        
        _beautifyButton.centerY = _cameraButton.centerY;
        _beautifyButton.left = _cameraButton.right + 25;
        
        
        _orientationSelectView.width = self.width;
        _orientationSelectView.height = orientationSelectViewHeight;
        _orientationSelectView.left = 0;
        _orientationSelectView.bottom = self.showOrientataionView? self.height: self.height+orientationSelectViewHeight;
        
        _filterBar.width = self.width;
        _filterBar.height = _filterBar.barHeight;
        _filterBar.left  = 0;
        _filterBar.bottom = self.showFilterBar? self.height: self.height+_filterBar.barHeight;

    }
    
    else
    {
        
        _cameraButton.centerX = self.height/2;
        _cameraButton.bottom = self.width - 25;
        
        _orientationButton.centerY = _cameraButton.centerY;
        _orientationButton.right = _cameraButton.left - 25;
        
        _beautifyButton.centerY = _cameraButton.centerY;
        _beautifyButton.left = _cameraButton.right + 25;
        
        
        _orientationSelectView.width = self.height;
        _orientationSelectView.height = orientationSelectViewHeight;
        _orientationSelectView.left = 0;
        _orientationSelectView.bottom = self.showOrientataionView? self.width: self.width+orientationSelectViewHeight;
        
        _filterBar.width = self.height;
        _filterBar.height = _filterBar.barHeight;
        _filterBar.left  = 0;
        _filterBar.bottom = self.showFilterBar? self.width: self.width+_filterBar.barHeight;

    }
}

- (void)switchToWaitingUI
{
    DDLogInfo(@"switch to waiting UI");
    if ([NTESLiveManager sharedInstance].role == NTESLiveRoleAudience)
    {
        [self switchToLinkingUI];
    }
    else
    {
        self.startLiveButton.hidden = NO;
        self.cameraButton.hidden = NO;
        [self.startLiveButton setTitle:@"开始直播" forState:UIControlStateNormal];
    }
}

- (void)switchToLinkingUI
{
    DDLogInfo(@"switch to Linking UI");
    self.startLiveButton.hidden = YES;
    self.closeButton.hidden = NO;
    [self.coverView refreshWithChatroom:self.roomId status:NTESLiveCoverStatusLinking];
    self.coverView.hidden = NO;
    [self.closeButton setImage:[UIImage imageNamed:@"icon_close_n"] forState:UIControlStateNormal];
    [self.closeButton setImage:[UIImage imageNamed:@"icon_close_p"] forState:UIControlStateHighlighted];
}

- (void)switchToEndUI
{
    DDLogInfo(@"switch to End UI");
    [self.coverView refreshWithChatroom:self.roomId status:NTESLiveCoverStatusFinished];
    self.coverView.hidden = NO;
    self.cameraButton.hidden = YES;
    self.beautifyButton.hidden = YES;
    self.orientationButton.hidden = YES;
    self.orientationSelectView.hidden = YES;
    self.closeButton.hidden = YES;
}

- (NTESFiterStatusModel *)getFilterModel
{
    NTESFiterStatusModel *model = [[NTESFiterStatusModel alloc]init];
    
    model.filterIndex = _filterBar.filterIndex;
    model.smoothValue = _filterBar.smoothValue;
    model.constrastValue = _filterBar.constrastValue;
    
    return model;
}

- (void)updateBeautifyButton:(BOOL)isOn
{
    [self.beautifyButton setImage:[UIImage imageNamed:isOn? @"icon_filter_on_n" :@"icon_filter_off_n" ]forState:UIControlStateNormal];
}

#pragma mark - get
- (UIButton *)startLiveButton
{
    if (!_startLiveButton) {
        _startLiveButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *backgroundImageNormal = [[UIImage imageNamed:@"icon_cell_blue_normal"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10) resizingMode:UIImageResizingModeStretch];
        UIImage *backgroundImageHighlighted = [[UIImage imageNamed:@"icon_cell_blue_pressed"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10) resizingMode:UIImageResizingModeStretch];
        [_startLiveButton setBackgroundImage:backgroundImageNormal forState:UIControlStateNormal];
        [_startLiveButton setBackgroundImage:backgroundImageHighlighted forState:UIControlStateHighlighted];
        [_startLiveButton setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
        [_startLiveButton addTarget:self action:@selector(startLive:) forControlEvents:UIControlEventTouchUpInside];
        _startLiveButton.size = CGSizeMake(215, 46);
        _startLiveButton.center = self.center;
        _startLiveButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    }
    return _startLiveButton;
}

- (UIButton *)closeButton
{
    if(!_closeButton)
    {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:[UIImage imageNamed:@"icon_close_n"] forState:UIControlStateNormal];
        [_closeButton setImage:[UIImage imageNamed:@"icon_close_p"] forState:UIControlStateHighlighted];
        [_closeButton addTarget:self action:@selector(onClose:) forControlEvents:UIControlEventTouchUpInside];
        _closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        _closeButton.size = CGSizeMake(44, 44);
        _closeButton.top = 5.f;
        _closeButton.right = self.width - 5.f;
    }
    return _closeButton;
}

- (UIButton *)orientationButton
{
    if(!_orientationButton)
    {
        _orientationButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_orientationButton setImage:[UIImage imageNamed:@"icon_live_orientation_n"] forState:UIControlStateNormal];
        [_orientationButton setImage:[UIImage imageNamed:@"icon_live_orientation_p"] forState:UIControlStateHighlighted];
        [_orientationButton addTarget:self action:@selector(showOrientationSelectView) forControlEvents:UIControlEventTouchUpInside];
        _orientationButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        [_orientationButton sizeToFit];
    }
    return _orientationButton;
}

- (UIButton *)cameraButton
{
    if(!_cameraButton)
    {
        _cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cameraButton setImage:[UIImage imageNamed:@"icon_camera_rotate_normal"] forState:UIControlStateNormal];
        [_cameraButton setImage:[UIImage imageNamed:@"icon_camera_rotate_pressed"] forState:UIControlStateHighlighted];
        [_cameraButton addTarget:self action:@selector(onCameraRotate) forControlEvents:UIControlEventTouchUpInside];
        _cameraButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        [_cameraButton sizeToFit];
    }
    return _cameraButton;
}

- (UIButton *)beautifyButton
{
    if(!_beautifyButton)
    {
        _beautifyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_beautifyButton setImage:[UIImage imageNamed:@"icon_filter_off_n"] forState:UIControlStateNormal];
        [_beautifyButton setImage:[UIImage imageNamed:@"icon_filter_p"] forState:UIControlStateHighlighted];
        [_beautifyButton addTarget:self action:@selector(onBeautifyToggle:) forControlEvents:UIControlEventTouchUpInside];
        _beautifyButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        [_beautifyButton sizeToFit];
    }
    return _beautifyButton;
}


- (NTESOrientationSelectView *)orientationSelectView
{
    if (!_orientationSelectView) {
        _orientationSelectView = [[NTESOrientationSelectView alloc] initWithFrame:CGRectZero];
        _orientationSelectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _orientationSelectView.backgroundColor = UIColorFromRGBA(0x000000
, 0.8);
        _orientationSelectView.delegate = self;
    }
    return _orientationSelectView;
}

- (NTESLiveCoverView *)coverView
{
    if (!_coverView) {
        _coverView = [[NTESLiveCoverView alloc] initWithFrame:self.bounds];
        _coverView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _coverView.hidden = YES;
        _coverView.delegate = self;
    }
    return _coverView;
}


#pragma mark - action
- (void)startLive:(id)sender
{
    [self.startLiveButton setTitle:@"初始化中，请等待..." forState:UIControlStateNormal];
    if ([self.delegate respondsToSelector:@selector(onStartLiving)]) {
        [self.delegate onStartLiving];
    }
}

- (void)onClose:(id)sender
{
    if ([NTESLiveManager sharedInstance].role == NTESLiveRoleAnchor) {
        if ([self.delegate respondsToSelector:@selector(onCloseLiving)]) {
            [self.delegate onCloseLiving];
        }
    }
}

-(void)onCameraRotate
{
    if ([self.delegate respondsToSelector:@selector(onCameraRotate)]) {
        [self.delegate onCameraRotate];
    }
}

-(void)onBeautifyToggle:(id)sender
{
    [self showFilterView];
}

- (void)showFilterView
{
    [UIView animateWithDuration:0.5 animations:^{
        if (self.orientation == NIMVideoOrientationPortrait) {
            _filterBar.bottom = self.height;
        }
        else{
            _filterBar.bottom = self.width;
        }
    } completion:^(BOOL finished) {
        self.showFilterBar = YES;
    }];
}

- (void)showOrientationSelectView
{
    [UIView animateWithDuration:0.5 animations:^{
        if (self.orientation == NIMVideoOrientationPortrait) {
            _orientationSelectView.bottom = self.height;
        }
        else{
            _orientationSelectView.bottom = self.width;
        }
    } completion:^(BOOL finished) {
        self.showOrientataionView = YES;
    }];
}

#pragma mark - NTESOrientationSelectViewDelegate
-(void)onVerticalScreenButtonSelected
{
    if (_orientation == NIMVideoOrientationLandscapeRight) {
        _orientation = NIMVideoOrientationPortrait;
        [self.delegate onRotate:NIMVideoOrientationPortrait];
    }

}

-(void)onHorizontalScreenButtonSelected
{
    if (_orientation == NIMVideoOrientationPortrait) {
        _orientation = NIMVideoOrientationLandscapeRight;
        [self.delegate onRotate:NIMVideoOrientationLandscapeRight];
    }
}

-(BOOL)interactionDisabled
{
    if ([self.delegate respondsToSelector:@selector(interactionDisabled)]) {
        {
            return  [self.delegate interactionDisabled];
        }
    }
    return NO;
}

#pragma mark - NTESMenuViewProtocol

-(void)onFilterViewCancelButtonPressed
{
    [self dismissFilterBar];
}

-(void)onFilterViewConfirmButtonPressed
{
    [self dismissFilterBar];
    if (self.filterBar.filterIndex) {
        [self.beautifyButton setImage:[UIImage imageNamed: @"icon_filter_on_n"  ]forState:UIControlStateNormal];
    }
    else
    {
        [self.beautifyButton setImage:[UIImage imageNamed: @"icon_filter_off_n"  ]forState:UIControlStateNormal];

    }
}


#pragma mark - NTESLiveCoverViewDelegate
- (void)didPressBackButton
{
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}


@end
