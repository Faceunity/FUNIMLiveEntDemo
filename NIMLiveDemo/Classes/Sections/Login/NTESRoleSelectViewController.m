//
//  NTESRoleSelectViewController.m
//  NIMLiveDemo
//
//  Created by chris on 16/2/26.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESRoleSelectViewController.h"
#import "NTESLiveManager.h"
#import "NTESLoginManager.h"
#import "NTESLoginViewController.h"
#import "NTESLiveRoomSelectViewController.h"
#import "NTESPageContext.h"
#import "NTESLiveTypeSelectViewController.h"
#import "NTESLogUploader.h"
#import "SVProgressHUD.h"
#import "UIView+Toast.h"
#import "NTESNetDetectManger.h"
#import "UIView+NTES.h"
#import "UIImageView+WebCache.h"
#import "UIImage+GIF.h"
#import "NTESBypassTypeSelectViewController.h"

#define DetectResultNotification @"detectResult"

@interface NTESRoleSelectViewController ()

@property (nonatomic,strong) IBOutlet UIButton *roleAchorButton;

@property (nonatomic,strong) IBOutlet UIButton *roleAudienceButton;

@property (nonatomic,strong) UIButton *detectButton;

@property (nonatomic,strong) NTESLogUploader *logUploader;

@property (nonatomic,strong) UIView *detectResultView;

@property (nonatomic,strong) UIView *detectResultDetailView;

@property (nonatomic,strong) UIImageView *detectResultDetailViewBkg;

@property (nonatomic,strong) UIImageView *refreshImgView;

@property (nonatomic,strong) UILabel *lossRateLabel;

@property (nonatomic,strong) UILabel *rttMaximalLabel;

@property (nonatomic,strong) UILabel *rttMinimalLabel;

@property (nonatomic,strong) UILabel *rttAverageLabel;

@property (nonatomic,strong) UILabel *rttMeanDeviationLabel;

@property (nonatomic,strong) UILabel *netSituation;

@property (nonatomic,strong) UILabel *netTimeTip;

@property (nonatomic,strong) UIButton *detailButton;


@end

static BOOL showCountdownTip;

@implementation NTESRoleSelectViewController

NTES_USE_CLEAR_BAR

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImage *backgroundImageNormal = [[UIImage imageNamed:@"btn_round_rect_normal"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10) resizingMode:UIImageResizingModeStretch];
    UIImage *backgroundImageHighlighted = [[UIImage imageNamed:@"btn_round_rect_pressed"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10) resizingMode:UIImageResizingModeStretch];
    
    [self.roleAchorButton setBackgroundImage:backgroundImageNormal forState:UIControlStateNormal];
    [self.roleAchorButton setBackgroundImage:backgroundImageHighlighted forState:UIControlStateHighlighted];
    [self.roleAudienceButton setBackgroundImage:backgroundImageNormal forState:UIControlStateNormal];
    [self.roleAudienceButton setBackgroundImage:backgroundImageHighlighted forState:UIControlStateHighlighted];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDetectResultNotify:)
                                                 name:DetectResultNotification
                                               object:nil];
    [self setUpNetDetectView];


}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self configNav];
    [self configStatusBar];
    [self.detailButton layoutSubviews];
    if (showCountdownTip&&[[NTESNetDetectManger sharedmanager]isDetectCompleted]) {
        [self showCountdownTipLable];
    }
}


- (IBAction)beRole:(UIButton *)button
{
    NTESLiveRole role = [button tag];
    [NTESLiveManager sharedInstance].role = role;
    UIViewController *vc;
    if (role == NTESLiveRoleAnchor)
    {
        
        vc = [[NTESBypassTypeSelectViewController alloc] initWithNibName:nil bundle:nil];
    }
    else
    {
        vc = [[NTESLiveRoomSelectViewController alloc] initWithNibName:nil bundle:nil];
    }
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)onTouchLogout:(id)sender
{
    [[NTESLoginManager sharedManager] setCurrentNTESLoginData:nil];
    [[NTESServiceManager sharedManager] destory];
    [[NIMSDK sharedSDK].loginManager logout:^(NSError *error) {
        [[NTESPageContext sharedInstance] setupMainViewController];
    }];
}

- (void)configNav{
    self.navigationItem.title = @"云信娱乐直播Demo";
    self.navigationController.navigationBar.titleTextAttributes =@{NSFontAttributeName:[UIFont boldSystemFontOfSize:17],
                                                                   NSForegroundColorAttributeName:[UIColor whiteColor]};
    UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(uploadLog:)];
    [self.navigationController.navigationBar addGestureRecognizer:recognizer];
    
    UIButton *logoutBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [logoutBtn setTitle:@"注销" forState:UIControlStateNormal];
    logoutBtn.titleLabel.font = [UIFont systemFontOfSize:15.f];
    [logoutBtn setTitleColor:UIColorFromRGB(0x2294ff) forState:UIControlStateNormal];
    
    [logoutBtn setBackgroundImage:[UIImage imageNamed:@"btn_round_rect_normal"] forState:UIControlStateNormal];
    [logoutBtn setBackgroundImage:[UIImage imageNamed:@"btn_round_rect_pressed"] forState:UIControlStateHighlighted];
    [logoutBtn addTarget:self action:@selector(onTouchLogout:) forControlEvents:UIControlEventTouchUpInside];
    [logoutBtn sizeToFit];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:logoutBtn];
    
    NSShadow *shadow = [[NSShadow alloc]init];
    shadow.shadowOffset = CGSizeMake(0, 0);
    self.navigationController.navigationBar.titleTextAttributes =@{NSFontAttributeName:[UIFont boldSystemFontOfSize:17],
                                                                   NSForegroundColorAttributeName:[UIColor whiteColor]};
    [self.navigationController.navigationBar setTintColor:UIColorFromRGB(0xffffff)];
}

- (void)configStatusBar{
    UIStatusBarStyle style = [self preferredStatusBarStyle];
    [[UIApplication sharedApplication] setStatusBarStyle:style
                                                animated:NO];
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)uploadLog:(id)sender
{
    if (_logUploader == nil) {
        _logUploader = [[NTESLogUploader alloc] init];
    }
    
    [SVProgressHUD show];
    
    __weak typeof(self) weakSelf = self;
    [_logUploader upload:^(NSString *urlString,NSError *error) {
        [SVProgressHUD dismiss];
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (error == nil && urlString)
        {
            [[NIMSDK sharedSDK].resourceManager fetchNOSURLWithURL:urlString
                                                        completion:^(NSError * error, NSString * realString)
            {
                if (error == nil && realString)
                {
                    [UIPasteboard generalPasteboard].string = realString;
                    [strongSelf.view makeToast:@"上传日志成功,URL已复制到剪切板中" duration:3.0 position:CSToastPositionCenter];
                }
                else
                {
                    [strongSelf.view makeToast:@"上传日志失败" duration:3.0 position:CSToastPositionCenter];
                }
            }];
            
        }
        else
        {
            [strongSelf.view makeToast:@"上传日志失败" duration:3.0 position:CSToastPositionCenter];
        }
    }];
}

-(UIButton*)detailButton
{
    if (!_detailButton) {
        _detailButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_detailButton setImage:[UIImage imageNamed:@"btn_detect_tip_open"] forState:UIControlStateNormal];
        [_detailButton addTarget:self action:@selector(onClickDetailButton) forControlEvents:UIControlEventTouchUpInside];
        _detailButton.imageEdgeInsets = UIEdgeInsetsMake(6, 6, 6, 6);
    }
        _detailButton.frame = CGRectMake(CGRectGetMaxX(self.netSituation.frame), CGRectGetMaxY(_detectButton.frame)+9,28,28);

    return _detailButton;
}

-(UILabel*)netSituation
{
    if (!_netSituation) {
        _netSituation = [[UILabel alloc]initWithFrame:CGRectZero];
        _netSituation.text = [NSString stringWithFormat:@"网络状况：检测中..."];
        _netSituation.textAlignment = NSTextAlignmentCenter;
        _netSituation.textColor = UIColorFromRGB(0xffffff);
        _netSituation.font = [UIFont systemFontOfSize:15];
    }
    [_netSituation sizeToFit];
    
    if( _detectButton.enabled && ![[NTESNetDetectManger sharedmanager]getResult].error)
        _netSituation.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2-6, CGRectGetMaxY(_detectButton.frame)+15+8);
    else
    {
        _netSituation.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2, CGRectGetMaxY(_detectButton.frame)+15+8);
    }

    return _netSituation;
}

- (void)setUpNetDetectView
{
    //探测按钮 背景wifi图标
    _detectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _detectButton.frame =CGRectMake([UIScreen mainScreen].bounds.size.width/2-45, 50+64 ,90,90);
    [_detectButton setImage:[UIImage imageNamed:@"icon_wifi_0"] forState:UIControlStateNormal];
    [_detectButton setTitle:@"detect" forState:UIControlStateNormal];
    [_detectButton addTarget:self action:@selector(detect) forControlEvents:UIControlEventTouchUpInside];
    _detectButton.enabled = NO;
    [self.view addSubview:_detectButton];
    
    _refreshImgView = [[UIImageView alloc]initWithFrame:CGRectZero];
    _refreshImgView = [[UIImageView alloc]initWithFrame:CGRectMake(55, 55 ,13 ,13)];
    [self setRefreshGif];
    [_detectButton addSubview:_refreshImgView];

    
    //网络状况label
    [self.view addSubview:self.netSituation];

    
    _netTimeTip = [[UILabel alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/2-75, CGRectGetMaxY(_netSituation.frame)+10, 150, 15)];
    _netTimeTip.text = [NSString stringWithFormat:@"(预计耗时5S)"];
    _netTimeTip.textAlignment = NSTextAlignmentCenter;
    _netTimeTip.font = [UIFont systemFontOfSize:13];
    _netTimeTip.textColor = UIColorFromRGB(0xafd2fd);
    [self.view addSubview:_netTimeTip];

    //出现探测详细信息button
    [self.view addSubview:self.detailButton];
    self.detailButton.hidden = YES;
    
    //detectResultDetailView
    _detectResultDetailView = [[UIView alloc]init];
    _detectResultDetailView.frame = CGRectMake(0, 0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height);
    _detectResultDetailView.hidden = YES;
    [self.view addSubview:_detectResultDetailView];
    
    _detectResultDetailViewBkg = [[UIImageView alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/2-245/2, CGRectGetMaxY(_netSituation.frame),245,202.5)];
    [_detectResultDetailViewBkg setImage:[UIImage imageNamed:@"detect_tip_bkg"]];
    [_detectResultDetailView addSubview:_detectResultDetailViewBkg];
    
    CGFloat maginTop = 30;
    CGFloat maginLeft = 30;

    _lossRateLabel = [[UILabel alloc]initWithFrame:CGRectMake(maginLeft, maginTop, 150, 15)];
    _rttAverageLabel = [[UILabel alloc]initWithFrame:CGRectMake(maginLeft, maginTop+20, 150, 15)];
    _rttMaximalLabel = [[UILabel alloc]initWithFrame:CGRectMake(maginLeft, maginTop+40, 150, 15)];
    _rttMinimalLabel = [[UILabel alloc]initWithFrame:CGRectMake(maginLeft, maginTop+60, 150, 15)];
    _rttMeanDeviationLabel = [[UILabel alloc]initWithFrame:CGRectMake(maginLeft, maginTop+80, 150, 15)];

    //tips label in detailview
    UILabel * tipsLabel = [[UILabel alloc]initWithFrame:CGRectMake(maginLeft - 10, maginTop + 110, 205, 40)];
    tipsLabel.text = @"当前为480P下的网络状况(SDK提供音频+6种视频清晰度的网络状况检测)";
    tipsLabel.font = [UIFont systemFontOfSize:12];
    tipsLabel.numberOfLines = 2;
    tipsLabel.textColor = [UIColor orangeColor];
    
    _lossRateLabel.text =@"丢 包 率：";
    _rttAverageLabel.text =@"平均延时：";
    _rttMaximalLabel.text = @"最大延时：";
    _rttMinimalLabel.text = @"最小延时：";
    _rttMeanDeviationLabel.text =@"网络抖动：";
    
    _lossRateLabel.font = [UIFont systemFontOfSize:13];
    _rttAverageLabel.font = [UIFont systemFontOfSize:13];
    _rttMaximalLabel.font = [UIFont systemFontOfSize:13];
    _rttMinimalLabel.font = [UIFont systemFontOfSize:13];
    _rttMeanDeviationLabel.font = [UIFont systemFontOfSize:13];

    _lossRateLabel.textColor = UIColorFromRGB(0x999999);
    _rttAverageLabel.textColor = UIColorFromRGB(0x999999);
    _rttMaximalLabel.textColor = UIColorFromRGB(0x999999);
    _rttMinimalLabel.textColor = UIColorFromRGB(0x999999);
    _rttMeanDeviationLabel.textColor = UIColorFromRGB(0x999999);

    [_detectResultDetailViewBkg addSubview:_lossRateLabel];
    [_detectResultDetailViewBkg addSubview:_rttAverageLabel];
    [_detectResultDetailViewBkg addSubview:_rttMaximalLabel];
    [_detectResultDetailViewBkg addSubview:_rttMinimalLabel];
    [_detectResultDetailViewBkg addSubview:_rttMeanDeviationLabel];
    [_detectResultDetailViewBkg addSubview:tipsLabel];

    //close button
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame =CGRectMake(CGRectGetWidth(_detectResultDetailViewBkg.frame)-30-10,15,30,30);
    closeBtn.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    [closeBtn setImage:[UIImage imageNamed:@"btn_detect_close"] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(onClickDetailButton) forControlEvents:UIControlEventTouchUpInside];
    [_detectResultDetailViewBkg addSubview: closeBtn];
    
    _detectResultDetailViewBkg.userInteractionEnabled = YES;
    
    NIMAVChatNetDetectResult *result = [[NTESNetDetectManger sharedmanager]getResult];
    if (result) {
        [self onDetectResultNotify:nil];
    }
}

-(void)onClickDetailButton
{
    _detectResultDetailView.hidden = !_detectResultDetailView.hidden;
}

-(void)onDetectResultNotify:(NSNotification *)Notification
{
    NIMAVChatNetDetectResult *result = [[NTESNetDetectManger sharedmanager]getResult];
    _detectButton.enabled = YES;
    _netTimeTip.hidden = YES;
    _refreshImgView.image = [UIImage imageNamed:@"icon_detect_refresh"];

        if (!result.error) {
        float netIndex = ((float)result.lossRate/20)*0.5+((float)result.rttAverage/1200)*0.25+((float)result.rttMeanDeviation/150)*0.25;
        
        if (netIndex<=0.2625) {
            _netSituation.text = @"网络状况：很好";
            [_detectButton setImage:[UIImage imageNamed:@"icon_wifi_4"] forState:UIControlStateNormal];

        }
        else if (netIndex>0.2625&&netIndex<=0.55)
        {
            _netSituation.text = @"网络状况：一般";
            [_detectButton setImage:[UIImage imageNamed:@"icon_wifi_3"] forState:UIControlStateNormal];

        }
        else if (netIndex>0.55&&netIndex<=1)
        {
            _netSituation.text = @"网络状况：较差";
            [_detectButton setImage:[UIImage imageNamed:@"icon_wifi_2"] forState:UIControlStateNormal];

        }
        else
        {
            _netSituation.text = @"网络状况：很差";
            [_detectButton setImage:[UIImage imageNamed:@"icon_wifi_1"] forState:UIControlStateNormal];

        }
        self.detailButton.hidden = NO;

        _lossRateLabel.text = [NSString stringWithFormat:@"丢 包 率：%zd%%",result.lossRate];
        _rttAverageLabel.text = [NSString stringWithFormat:@"平均延时：%zdms",result.rttAverage];
        _rttMaximalLabel.text = [NSString stringWithFormat:@"最大延时：%zdms",result.rttMaximal];
        _rttMinimalLabel.text = [NSString stringWithFormat:@"最小延时：%zdms",result.rttMinimal];
        _rttMeanDeviationLabel.text = [NSString stringWithFormat:@"网络抖动：%zdms",result.rttMeanDeviation];
    }
    else
    {
        _netSituation.text = [NSString stringWithFormat:@"检测失败!"];
        
        [_detectButton setImage:[UIImage imageNamed:@"icon_wifi_0"] forState:UIControlStateNormal];
        self.detailButton.hidden = YES;
    }
    
    showCountdownTip = YES;

}

-(void)showCountdownTipLable
{
    NSDate *lastTime = [[NTESNetDetectManger sharedmanager]getLastDetectTime];
    NSDate *currentTime = [NSDate date];
    NSTimeInterval interVal = [currentTime timeIntervalSinceDate:lastTime];
    
    int minute = (int)interVal/60;

    if (minute<2) {
        _netTimeTip.text = @"(1分钟前检测)";
    }
    else
    {
        _netTimeTip.text = [NSString stringWithFormat:@"(%d分钟前检测)",minute];
    }
    _netTimeTip.hidden = NO;
}

-(void)detect
{
    [[NTESNetDetectManger sharedmanager]startNetDetect];
    _netSituation.text =@"网络状况：检测中...";
    [_detectButton setImage:[UIImage imageNamed:@"icon_wifi_0"] forState:UIControlStateNormal];
    [self setRefreshGif];
    _netTimeTip.text =@"(预计耗时5s)";
    _netTimeTip.hidden = NO;
    _detectButton.enabled = NO;
    self.detailButton.hidden = YES;
}

-(void)setRefreshGif
{
    CGFloat scale = [[UIScreen mainScreen]scale];
    
    NSString  *name = scale < 3 ? @"icon_load_gif@2x" : @"icon_load_gif@3x";
    
    NSString  *filePath = [[NSBundle bundleWithPath:[[NSBundle mainBundle] bundlePath]] pathForResource:name ofType:@"gif"];
    
    NSData  *imageData = [NSData dataWithContentsOfFile:filePath];
    
    self.refreshImgView.image = [UIImage sd_animatedGIFWithData:imageData];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (!_detectResultDetailView.hidden) {
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:_detectResultDetailViewBkg];
        BOOL isInContentView = [_detectResultDetailViewBkg pointInside:point withEvent:nil];
        if (!isInContentView) {
            _detectResultDetailView.hidden = !_detectResultDetailView.hidden;
        }
    }
    return;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
