//
//  NTESLiveViewController.m
//  NIM
//
//  Created by chris on 15/12/16.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "NTESAnchorLiveViewController.h"
#import "UIImage+NTESColor.h"
#import "UIView+NTES.h"
#import "NSString+NTES.h"
#import "SVProgressHUD.h"
#import "UIView+Toast.h"
#import "NTESMediaCapture.h"
#import "NTESLiveManager.h"
#import "NTESDemoLiveroomTask.h"
#import "NSDictionary+NTESJson.h"
#import "UIAlertView+NTESBlock.h"
#import "NTESDemoService.h"
#import "NTESSessionMsgConverter.h"
#import "NTESLiveInnerView.h"
#import "NTESPresentBoxView.h"
#import "NTESPresentAttachment.h"
#import "NTESLikeAttachment.h"
#import "NTESLiveViewDefine.h"
#import "NTESMicConnector.h"
#import "NTESConnectQueueView.h"
#import "NTESMicAttachment.h"
#import "NTESLiveAnchorHandler.h"
#import "NTESTimerHolder.h"
#import "NTESDevice.h"
#import "NTESUserUtil.h"
#import "NTESCustomKeyDefine.h"
#import "NTESMixAudioSettingView.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import <CoreLocation/CoreLocation.h>
#import "NTESLiveUtil.h"
#import "NTESFiterMenuView.h"
#import "NTESVideoQualityView.h"
#import "NTESMirrorView.h"
#import "NTESWaterMarkView.h"
#import "NTESAlertSheetView.h"
#import "NTESPKInfo.h"
#import "NTESAnchorPKView.h"

/* faceU */
#import "FUAPIDemoBar.h"
#import "FUManager.h"

#import "FUTestRecorder.h"


#import "NTESFiterStatusModel.h"

typedef void(^NTESDisconnectAckHandler)(NSError *);
typedef void(^NTESAgreeMicHandler)(NSError *);

@interface NTESAnchorLiveViewController ()<NIMChatroomManagerDelegate,NTESLiveInnerViewDelegate,NTESLiveAnchorHandlerDelegate,
NIMChatManagerDelegate,NIMSystemNotificationManagerDelegate,NIMNetCallManagerDelegate,NTESConnectQueueViewDelegate,NTESTimerHolderDelegate,NTESMixAudioSettingViewDelegate,NTESMenuViewProtocol,NTESVideoQualityViewDelegate,NTESMirrorViewDelegate,NTESWaterMarkViewDelegate, NTESAlertSheetViewDelegate,NTESAnchorPKViewDelegate,FUAPIDemoBarDelegate>
{
    NTESTimerHolder *_timer;
    NTESDisconnectAckHandler _ackHandler;
}

@property (nonatomic, copy)   NIMChatroom *chatroom;

@property (nonatomic, strong) NIMNetCallMeeting *currentMeeting;

@property (nonatomic, strong) NIMNetCallMeeting *pkMeeting;

@property (nonatomic, strong) NTESMediaCapture  *capture;

@property (nonatomic, strong) UIView *captureView;

@property (nonatomic, strong) NTESLiveInnerView *innerView;

@property (nonatomic, strong) NTESLiveAnchorHandler *handler;

@property (nonatomic, strong) NTESMixAudioSettingView *mixAudioSettingView;

@property (nonatomic, strong) NTESVideoQualityView *videoQualityView;

@property (nonatomic, strong) NTESMirrorView *mirrorView;

@property (nonatomic, strong) NTESWaterMarkView *waterMarkView;

@property (nonatomic, weak)   id<NTESAnchorLiveViewControllerDelegate> delegate;

@property (nonatomic, strong) NTESFiterMenuView *filterView;

@property (nonatomic, strong) UIImageView *focusView;

@property (nonatomic, strong) UIAlertView *pkAlertView;

@property (nonatomic) BOOL audioLiving;

@property (nonatomic) BOOL isflashOn;

@property (nonatomic) BOOL isFocusOn;

@property (nonatomic) BOOL isVideoLiving;

@property (nonatomic, strong) NTESAlertSheetView *pkAlert;

@property (nonatomic, assign) BOOL isAnchorPking;

@property (nonatomic, assign) BOOL isInviter;

@property (nonatomic, assign) BOOL isSwitchNewMeeting;

@property (nonatomic, assign) BOOL isSwitchOriginMeeting;

@property (nonatomic, strong) NSString *roomName;

/**faceU */
@property(nonatomic,strong)FUAPIDemoBar *demoBar;

@end

@implementation NTESAnchorLiveViewController

NTES_USE_CLEAR_BAR
NTES_FORBID_INTERACTIVE_POP

- (instancetype)initWithChatroom:(NIMChatroom *)chatroom currentMeeting:(NIMNetCallMeeting*)currentMeeting capture:(NTESMediaCapture*)capture delegate:(id<NTESAnchorLiveViewControllerDelegate>)delegate{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _chatroom = chatroom;
        _currentMeeting = currentMeeting;
        self.automaticallyAdjustsScrollViewInsets = NO;
        _handler = [[NTESLiveAnchorHandler alloc] initWithChatroom:chatroom];
        _handler.delegate = self;
        _delegate = delegate;
        _capture = capture;
        
        _isVideoLiving = YES;
        
    }
    return self;
}

- (instancetype)initWithChatroom:(NIMChatroom *)chatroom
{
    if (self) {
        _chatroom = chatroom;
        self.automaticallyAdjustsScrollViewInsets = NO;
        _handler = [[NTESLiveAnchorHandler alloc] initWithChatroom:chatroom];
        _handler.delegate = self;
        _capture = [[NTESMediaCapture alloc]init];
    }
    return self;

}

- (void)dealloc{
    
    [[FUManager shareManager] destoryItems];
    [[NIMSDK sharedSDK].chatroomManager removeDelegate:self];
    [[NIMSDK sharedSDK].chatManager removeDelegate:self];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [[NTESLiveManager sharedInstance] stop];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [NTESLiveManager sharedInstance].orientation = self.orientation;
    [[NIMAVChatSDK sharedSDK].netCallManager setVideoCaptureOrientation:[NTESLiveManager sharedInstance].orientation];

    [self setUp];
    
    [[FUTestRecorder shareRecorder] setupRecord];
    
    /* faceU */
    [[FUManager shareManager] loadFilter];
    [FUManager shareManager].isRender = YES;
    [FUManager shareManager].flipx = NO;
    [FUManager shareManager].trackFlipx = NO;
    [self.innerView addSubview:self.demoBar];
    
    
    DDLogInfo(@"enter live room , live room type %d, current user: %@",
              (int)[NTESLiveManager sharedInstance].type,[[NIMSDK sharedSDK].loginManager currentAccount]);
    //视频直播
    if (_isVideoLiving) {
        
        self.demoBar.hidden = NO;
        [NTESLiveManager sharedInstance].type = NTESLiveTypeVideo;
        [_capture switchContainerToView:self.captureView];
        [self.innerView switchToPlayingUI];
        [self.view addSubview:self.innerView];
        [self.innerView updateBeautify:self.filterModel.filterIndex];
        [self.innerView updateQualityButton:[NTESLiveManager sharedInstance].liveQuality == NTESLiveQualityHigh];
    }
    //语音直播
    else
    {
        
        self.demoBar.hidden = YES;
        [self.innerView switchToWaitingUI];
        [self.view addSubview:self.innerView];
        __weak typeof(self) wself = self;
        NTESMediaCaptureRequest *request = [[NTESMediaCaptureRequest alloc] init];
        request.url = self.chatroom.broadcastUrl;
        request.roomId = self.chatroom.roomId;
        request.container = self.captureView;
        request.type = (NIMNetCallMediaType)[NTESLiveManager sharedInstance].type;
        request.meetingName = [NTESUserUtil meetingName:self.chatroom];
    
        [self.capture startVideoPreview:request
                                handler:^(NIMNetCallMeeting * _Nonnull currentMeeting, NSError * _Nonnull error) {
                                    [wself.view addSubview:wself.innerView];
                                    wself.currentMeeting = currentMeeting;
                                    if (error) {
                                        DDLogInfo(@"start error by privacy");
                                        //横屏模式下 UIAlertView 问题较多 建议使用 UIAlertViewController
                                        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
                                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"直播失败，请检查网络和权限重新开启" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                                            [alert showAlertWithCompletionHandler:^(NSInteger index) {
                                                [wself dismissViewControllerAnimated:YES completion:nil];
                                            }];
                                        }
                                        else
                                        {
                                            UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"" message:@"直播失败，请检查网络和权限重新开启" preferredStyle:UIAlertControllerStyleAlert];
                                            [alertVc addAction:[UIAlertAction actionWithTitle:@"确定" style: UIAlertActionStyleDefault handler:nil]];
                                            [wself presentViewController:alertVc animated:YES completion:nil];
                                        }

                                    }
                                }];
    }
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent
                                                animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault
                                                animated:NO];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    //判断是否进行手动对焦显示
    [self doManualFocusWithPointInView:point];
}

#pragma mark - NIMChatManagerDelegate
- (void)willSendMessage:(NIMMessage *)message
{
    switch (message.messageType) {
        case NIMMessageTypeText:
            [self.innerView addMessages:@[message]];
            break;
        default:
            break;
    }
}

- (void)onRecvMessages:(NSArray *)messages
{
    for (NIMMessage *message in messages) {
        if (![message.session.sessionId isEqualToString:self.chatroom.roomId]
            && message.session.sessionType == NIMSessionTypeChatroom) {
            //不属于这个聊天室的消息
            return;
        }
        switch (message.messageType) {
            case NIMMessageTypeText:
                [self.innerView addMessages:@[message]];
                break;
            case NIMMessageTypeCustom:
            {
                NIMCustomObject *object = message.messageObject;
                id<NIMCustomAttachment> attachment = object.attachment;
                if ([attachment isKindOfClass:[NTESPresentAttachment class]]) {
                    [self.innerView addPresentMessages:@[message]];
                }
                else if ([attachment isKindOfClass:[NTESLikeAttachment class]]) {
                    [self.innerView fireLike];
                }
                break;
            }
            case NIMMessageTypeNotification:{
                [self.handler dealWithNotificationMessage:message];
            }
                break;
            default:
                break;
        }
    }
}

#pragma mark - NIMSystemNotificationManagerDelegate
- (void)onReceiveCustomSystemNotification:(NIMCustomSystemNotification *)notification {
    [self.handler dealWithBypassCustomNotification:notification];
}

#pragma mark - NIMNetCallManagerDelegate
- (void)onUserJoined:(NSString *)uid
             meeting:(NIMNetCallMeeting *)meeting
{
    DDLogInfo(@"on user joined uid %@",uid);
    if (_isAnchorPking) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    }
    
    NTESMicConnector *connector = [[NTESLiveManager sharedInstance] findConnector:uid];
    if (connector) {
        connector.state = NTESLiveMicStateConnected;
        connector.meetingUid = [[NIMAVChatSDK sharedSDK].netCallManager getMeetingIdWithUserUid:uid];
        [[NTESLiveManager sharedInstance] addConnectorOnMic:connector];
        
        //将连麦者的GLView扔到右下角，并显示名字
        [self.innerView switchToBypassStreamingUI:connector];
        
        //发送全局已连麦通知
        [self sendConnectedNotify:connector];
        
        //修改服务器队列
        NTESQueuePushData *data = [[NTESQueuePushData alloc] init];
        data.roomId = self.chatroom.roomId;
        data.ext = [@{@"style":@(connector.type),
                      @"state":@(NTESLiveMicStateConnected),
                      @"info":@{
                              @"nick" : connector.nick.length? connector.nick : connector.uid,
                              @"avatar":connector.avatar.length? connector.avatar : @"avatar_default",
                              @"meetingUid":@(connector.meetingUid)}} jsonBody];
        data.uid = uid;
        [[NTESDemoService sharedService] requestMicQueuePush:data completion:nil];
    }
}

- (void)onUserLeft:(NSString *)uid
           meeting:(NIMNetCallMeeting *)meeting
{
    DDLogInfo(@"on user left %@, pk uid %@",uid, [NTESLiveManager sharedInstance].dstPkAnchor.uid);

    //判断是不是主播PK
    if (_isAnchorPking && [uid isEqualToString:[NTESLiveManager sharedInstance].dstPkAnchor.uid]) {
        [self didReceivePkExit];
        return;
    }
    
    //DDLogInfo(@"current on mic user is %@",[NTESLiveManager sharedInstance].connectorOnMic.uid);
    NSMutableArray *uids = [[NTESLiveManager sharedInstance] uidsOfConnectorsOnMic];
    DDLogInfo(@"current on mic user is [%@]", [uids componentsJoinedByString:@" "]);
    
    //修改服务器队列
    NTESMicConnector *connectorOnMic = [[NTESLiveManager sharedInstance] connectorOnMicWithUid:uid];
    if (connectorOnMic) {
        NTESQueuePopData *data = [[NTESQueuePopData alloc] init];
        data.roomId = self.chatroom.roomId;
        data.uid    = connectorOnMic.uid;
        [[NTESDemoService sharedService] requestMicQueuePop:data completion:^(NSError *error, NSString *ext) {
            if (error) {
                DDLogError(@"request mic queue pop error %d",(int)error.code);
            }
        }];
    }

    //修正内存队列
    [[NTESLiveManager sharedInstance] removeConnectors:uid];
    
    if ([uid isEqualToString:[NIMSDK sharedSDK].loginManager.currentAccount]) {
         [[NTESLiveManager sharedInstance] delAllConnectorsOnMic];
    } else {
         [[NTESLiveManager sharedInstance] delConnectorOnMicWithUid:uid];
    }
   
    [self.innerView updateConnectorCount:[[NTESLiveManager sharedInstance] connectors:NTESLiveMicStateWaiting].count];
    
    //发送全局连麦者断开的通知
    [self sendDisconnectedNotify:connectorOnMic];
    
    //刷新小窗画面
    if (!_isAnchorPking) {
        [self.innerView switchToPlayingUI];
    }
    
    //可能是强制要求对面离开，这个时候肯定记录了回调，尝试回调
    if (_ackHandler) {
        _ackHandler(nil);
        _ackHandler = nil;
        _timer = nil;
    }
}

- (void)onMeetingError:(NSError *)error
               meeting:(NIMNetCallMeeting *)meeting
{
    DDLogError(@"on meeting error: %d", (int)error.code);
    if (_isAnchorPking) {
        [NTESAlertSheetView showMessageWithTitle:@"PK提醒" message:@"当前网路异常，PK直播已经结束"];
        [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusComplete;

        return;
    }

    [self.view.window makeToast:[NSString stringWithFormat:@"互动直播失败 code: %d", (int)error.code]
                       duration:2.0
                       position:CSToastPositionCenter];
    [[NTESLiveManager sharedInstance] delAllConnectorsOnMic];
    [self.capture stopLiveStream];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onRemoteDisplayviewReady:(UIView *)displayView user:(NSString *)user {
    BOOL isOnMic = [NTESLiveManager sharedInstance].connectorsOnMic.count;
    if (isOnMic) {
        [self.innerView addRemoteView:displayView uid:user];
    }
}

- (void)onRemoteYUVReady:(NSData *)yuvData
                   width:(NSUInteger)width
                  height:(NSUInteger)height
                    from:(NSString *)user
{
    BOOL isOnMic = [NTESLiveManager sharedInstance].connectorsOnMic.count;
    BOOL isPk = ([NTESLiveManager sharedInstance].pkStatus == NTESAnchorPKStatusComplete);
    if (!isOnMic && isPk) {
        [self.innerView updateAnchorPkRemoteView:yuvData width:width height:height uid:user];
    }
}

-(void)onCameraTypeSwitchCompleted:(NIMNetCallCamera)cameraType
{
    [FUManager shareManager].trackFlipx = ![FUManager shareManager].trackFlipx;
    if (cameraType == NIMNetCallCameraBack) {
        // 镜像关闭
        [self.mirrorView setMirrorDisabled];
        [self.innerView updateMirrorButton:NO];
    }
    else
    {
        //镜像重置
        [self.mirrorView resetMirror];
        
        //闪光灯关闭 - 设置button图片
        _isflashOn = NO;
        [self.innerView updateflashButton:NO];
        
        //手动对焦关闭
        _isFocusOn = NO;
        [self.innerView updateFocusButton:NO];
        self.focusView.hidden = YES;
        
        [FUManager shareManager].flipx = NO;
    }
    
    [self.innerView resetZoomSlider];
}

-(void)onCameraOrientationSwitchCompleted:(NIMVideoOrientation)orientation
{
    [self.capture onCameraOrientationSwitchCompleted:orientation];
}

- (void)onNetStatus:(NIMNetCallNetStatus)status user:(NSString *)user
{
    if ([user isEqualToString:[[NIMSDK sharedSDK].loginManager currentAccount]]) {
        [self.innerView updateNetStatus:status];
    }
}

- (void)onMyVolumeUpdate:(UInt16)volume {
    [self.innerView updateAnchorVolume:volume];
}

- (void)onSpeakingUsersReport:(nullable NSArray<NIMNetCallUserInfo *> *)report {
    __weak typeof(self) weakSelf = self;
    [report enumerateObjectsUsingBlock:^(NIMNetCallUserInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [weakSelf.innerView updateUserVolume:obj.volume uid:obj.uid];
    }];
}

#pragma mark - NTESLiveAnchorHandlerDelegate
- (void)didUpdateConnectors
{
    DDLogInfo(@"did update connectors");
    [self.innerView updateConnectorCount:[[NTESLiveManager sharedInstance] connectors:NTESLiveMicStateWaiting].count];
}

- (void)didUpdateChatroomMemebers:(BOOL)isAdd {
    if (isAdd) {
        _chatroom.onlineUserCount++;
    } else {
        _chatroom.onlineUserCount--;
    }
    _chatroom.onlineUserCount =
        (_chatroom.onlineUserCount < 0 ? 0 : _chatroom.onlineUserCount);
    [self.innerView refreshChatroom:_chatroom];
}

#pragma mark - NIMChatroomManagerDelegate
- (void)chatroom:(NSString *)roomId beKicked:(NIMChatroomKickReason)reason
{
    if ([roomId isEqualToString:self.chatroom.roomId]) {
        NSString *toast = [NSString stringWithFormat:@"你被踢出聊天室"];
        DDLogInfo(@"chatroom be kicked, roomId:%@  rease:%d",roomId, (int)reason);
        [self.capture stopLiveStream];
        [[NIMSDK sharedSDK].chatroomManager exitChatroom:roomId completion:nil];
        [self.view.window makeToast:toast duration:2.0 position:CSToastPositionCenter];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)chatroom:(NSString *)roomId connectionStateChanged:(NIMChatroomConnectionState)state;
{
    DDLogInfo(@"chatroom connection state changed roomId : %@  state : %d",roomId, (int)state);
}

#pragma mark - Private

- (void)setUp
{
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    self.view.backgroundColor = UIColorFromRGB(0xdfe2e6);
    [self.view addSubview:self.captureView];
    [self.view addSubview:self.focusView];

    [[NIMSDK sharedSDK].chatroomManager addDelegate:self];
    [[NIMSDK sharedSDK].chatManager addDelegate:self];
    [[NIMSDK sharedSDK].systemNotificationManager addDelegate:self];
    [[NIMAVChatSDK sharedSDK].netCallManager addDelegate:self];
}


#pragma mark - NTESLiveInnerViewDelegate
- (BOOL)isPlayerPlaying {
    return NO;
}

- (BOOL)isAudioMode {
    return ([NTESLiveManager sharedInstance].type == NTESLiveTypeAudio);
}

- (void)didSendText:(NSString *)text
{
    NIMMessage *message = [NTESSessionMsgConverter msgWithText:text];
    NIMSession *session = [NIMSession session:self.chatroom.roomId type:NIMSessionTypeChatroom];
    [[NIMSDK sharedSDK].chatManager sendMessage:message toSession:session error:nil];
}

- (void)onActionType:(NTESLiveActionType)type sender:(id)sender
{
    __weak typeof(self) weakSelf = self;
    switch (type) {
        case NTESLiveActionTypeLive:{
            if (!self.capture.isLiveStream) {
                [self.capture startLiveStreamHandler:^(NIMNetCallMeeting * _Nonnull meeting, NSError * _Nonnull error) {
                    if (error) {
                        [weakSelf.view makeToast:@"直播初始化失败"];
                        [weakSelf.innerView switchToWaitingUI];
                        DDLogError(@"start error:%@",error);
                    }else
                    {
                        NSString *uid = [NIMSDK sharedSDK].loginManager.currentAccount;
                        UInt64 meetingUid = [[NIMAVChatSDK sharedSDK].netCallManager getMeetingIdWithUserUid:uid];
                        [weakSelf doUpdateChatroomExtWithMeetingUid:meetingUid];
                        //将服务器连麦请求队列清空
                        [[NIMSDK sharedSDK].chatroomManager dropChatroomQueue:weakSelf.chatroom.roomId completion:nil];
                        //发一个全局断开连麦的通知给观众，表示之前的连麦都无效了
                        [self sendDisconnectedNotify:nil];
                        weakSelf.audioLiving = YES;
                        weakSelf.currentMeeting = meeting;
                        [weakSelf.innerView switchToPlayingUI];
                    }
                }];
            }
        }
            break;
        case NTESLiveActionTypePresent:{
            NTESPresentBoxView *box = [[NTESPresentBoxView alloc] initWithFrame:self.view.bounds];
            [box show];
            break;
        }
        case NTESLiveActionTypeCamera:
            [self.capture switchCamera];
            [FUManager shareManager].flipx = ![FUManager shareManager].flipx;
            break;

        case NTESLiveActionTypeInteract:{
            NTESConnectQueueView *queueView = [[NTESConnectQueueView alloc] initWithFrame:self.view.bounds];
            queueView.delegate = self;
            [queueView refreshWithQueue:[[NTESLiveManager sharedInstance] connectors: NTESLiveMicStateWaiting]];
            [queueView show];
        }
            break;
        case NTESLiveActionTypeBeautify:{
            [self.filterView show];
            
        }
            break;
        case NTESLiveActionTypeMixAudio:{
            [self.mixAudioSettingView show];
        }
            break;
        case NTESLiveActionTypeSnapshot:{
            [self snapshotFromLocalVideo];
        }
            break;
        case NTESLiveActionTypeShare:{
            [self shareStreamUrl];
        }
            break;
        case NTESLiveActionTypeQuality:{
            [self.videoQualityView show];
        }
            break;
        case NTESLiveActionTypeMirror:{
            if ([self.capture isCameraBack]) {
                [_mirrorView setMirrorDisabled];
                [self.view makeToast:@"后置摄像头模式，无法使用镜像" duration:1.0 position:CSToastPositionCenter];
            }
            else
            {
                [self.mirrorView show];
            }
        }
            break;
        case NTESLiveActionTypeWaterMark:{
            [self.waterMarkView show];
        }
            break;
        case NTESLiveActionTypeFlash:{
            NSString * toast ;
            if ([self.capture isCameraBack]) {
                _isflashOn = !_isflashOn;
                [[NIMAVChatSDK sharedSDK].netCallManager setCameraFlash:_isflashOn];
                toast = _isflashOn ? @"闪光灯已打开" : @"闪光灯已关闭";
                UIButton * button = (UIButton *)sender;
                [button setImage: [UIImage imageNamed:_isflashOn ? @"icon_flash_on_n" :@"icon_flash_off_n"] forState:UIControlStateNormal];
            }
            else
            {
                toast = @"前置摄像头模式，无法使用闪光灯";
            }
            [self.view makeToast:toast duration:1.0 position:CSToastPositionCenter];
        }
            break;
        case NTESLiveActionTypeFocus:
        {
            NSString * toast ;
            if ([self.capture isCameraBack]) {
                _isFocusOn = !_isFocusOn;
                self.focusView.hidden = YES;
                toast = _isFocusOn ? @"手动对焦已打开" : @"手动对焦已关闭，启动自动对焦模式";
                if (!_isFocusOn) {
                    [[NIMAVChatSDK sharedSDK].netCallManager setFocusMode:NIMNetCallFocusModeAuto];
                }
                UIButton * button = (UIButton *)sender;
                [button setImage:[UIImage imageNamed:_isFocusOn ? @"icon_focus_on_n" : @"icon_focus_off_n"] forState:UIControlStateNormal];
                [button setImage:[UIImage imageNamed:_isFocusOn ? @"icon_focus_on_p" : @"icon_focus_off_p"] forState:UIControlStateHighlighted];
            }
            else
            {
                toast = @"前置摄像头模式，无法手动调焦";
            }
            
            [self.view makeToast:toast duration:1.0 position:CSToastPositionCenter];
            break;
        }
        case NTESLiveActionTypePk:
        {
            NSLog(@"[zgn] ======================= 点击主播连麦PK =================================");
            NTESAnchorPKStatus pkStatus = [NTESLiveManager sharedInstance].pkStatus;
            if (pkStatus == NTESAnchorPKStatusIdle) {
                _pkAlert = [NTESAlertSheetView showInputWithTitle:@"邀请PK"
                                                         subtitle:@"邀请PK主播ID"
                                                         delegate:self];
            } else if (pkStatus == NTESAnchorPKStatusComplete) {
                NTESMicConnector *pkAnchor = [NTESLiveManager sharedInstance].dstPkAnchor;
                _pkAlert = [NTESAlertSheetView showEndWithTitle:@"PK提示"
                                                          image:pkAnchor.avatar
                                                           name:pkAnchor.nick
                                                       delegate:self];
            }
            else
            {
                [_pkAlert show];
            }
            break;
        }
        default:
            break;
    }
}

-(void)onTapChatView:(CGPoint)point
{
    [self doManualFocusWithPointInView:point];
}

#pragma mark - NTESVideoQualityViewDelegate

- (void)onVideoQualitySelected:(NTESLiveQuality)type
{
    NIMNetCallVideoQuality q;

    switch (type) {
        case NTESLiveQualityNormal:
            q = NIMNetCallVideoQualityDefault;
            break;
        case NTESLiveQualityHigh:
            q = NIMNetCallVideoQuality540pLevel;
            break;
        default:
            q = [NTESUserUtil defaultVideoQuality];
            break;
    }

    BOOL success = [[NIMAVChatSDK sharedSDK].netCallManager switchVideoQuality:q];
    DDLogInfo(@"switch video quality: %d success %@", (int)type,(success?@"Y":@"N"));
    if (success) {
        [NTESLiveManager sharedInstance].liveQuality = type;
    }else{
        [self.view makeToast:@"分辨率切换失败"];
    }
    
    NIMNetCallNetStatus status = [[NIMAVChatSDK sharedSDK].netCallManager netStatus:[NIMSDK sharedSDK].loginManager.currentAccount];
    [self.innerView updateNetStatus:status];
    
    [self.videoQualityView dismiss];
    [self.innerView updateQualityButton:type == NTESLiveQualityHigh];
    [self.innerView resetZoomSlider];
    
    //重置水印状态
    [self.innerView updateWaterMarkButton:NO];
    [self.waterMarkView reset];
    
    //重置闪光灯状态
    _isflashOn = NO;
    [self.innerView updateflashButton:NO];
}

-(void)onVideoQualityViewCancelButtonPressed
{
    [self.videoQualityView dismiss];
}

#pragma mark - NTESConnectQueueViewDelegate
- (void)onSelectMicConnector:(NTESMicConnector *)connector
{
    if (_isAnchorPking) {
        [self.view makeToast:@"当前正在PK无法与观众进行连麦" duration:2.0 position:CSToastPositionCenter];
        return;
    }
    if (connector.state == NTESLiveMicStateWaiting) {
        __weak typeof(self) weakSelf = self;
        //NSString *mic = [NTESLiveManager sharedInstance].connectorOnMic.uid;
        [SVProgressHUD show];
        
        if (![[NTESLiveManager sharedInstance] canAddConnectorOnMic])
        {
            //上麦队列已满，踢掉最早的那个
            NTESMicConnector *earliestConnector = [[NTESLiveManager sharedInstance] earliestConnectorOnMic];
            NSString *mic = earliestConnector.uid;
            [self forceDisconnectedUser:mic handler:^(NSError *error) {
                if (error) {
                    [SVProgressHUD dismiss];
                    [weakSelf.view makeToast:@"切换连麦失败，请重试" duration:2.0 position:CSToastPositionCenter];
                }
                else
                {
                    [weakSelf agreeMicConnector:connector handler:^(NSError *error) {
                        [SVProgressHUD dismiss];
                    }];
                }
            }];
        }
        else
        {
            //可以上麦，直接上麦到最后
            [self agreeMicConnector:connector handler:^(NSError *error) {
                [SVProgressHUD dismiss];
            }];
        }
    }
}

- (void)onCloseLiving{
    
    if (!((NIMNetCallMediaType)[NTESLiveManager sharedInstance].type == NTESLiveTypeAudio&&!self.audioLiving)) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"确定结束直播吗？" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"离开", nil];
            [alert showAlertWithCompletionHandler:^(NSInteger index) {
                switch (index) {
                    case 1:{
                        [self doExitLive];
                        break;
                    }
                    default:
                        break;
                }
            }];
        }
        else
        {
            UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"" message:@"确定结束直播吗？" preferredStyle:UIAlertControllerStyleAlert];
            [alertVc addAction:[UIAlertAction actionWithTitle:@"取消" style: UIAlertActionStyleDefault handler:nil]];
            [alertVc addAction:[UIAlertAction actionWithTitle:@"离开" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self doExitLive];
            }]];
            [self presentViewController:alertVc animated:YES completion:nil];
        }
    }
    else
    {
        [self doExitLive];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)doExitLive
{
    [NTESLiveManager sharedInstance].type = NTESLiveTypeInvalid;
    NIMChatroomUpdateRequest *request = [[NIMChatroomUpdateRequest alloc] init];
    NSString *update = [@{
                          NTESCMType  : @([NTESLiveManager sharedInstance].type),
                          NTESCMMeetingName: @""
                          } jsonBody];
    NSString *ext = [NTESLiveUtil jsonString:self.chatroom.ext addJsonString:update];
    request.roomId = self.chatroom.roomId;
    request.updateInfo = @{@(NIMChatroomUpdateTagExt) : ext};
    request.needNotify = YES;
    request.notifyExt  = update;
    [[NIMSDK sharedSDK].chatroomManager updateChatroomInfo:request completion:nil];
    [[NIMSDK sharedSDK].chatroomManager exitChatroom:self.chatroom.roomId completion:nil];
    
    if ([NTESLiveManager sharedInstance].pkStatus == NTESAnchorPKStatusPkInteractive) {
        [self doSendPkCancelToUser:[NTESLiveManager sharedInstance].dstPkAnchor.uid];
    }
    if (_isAnchorPking) {
        [[NIMAVChatSDK sharedSDK].netCallManager leaveMeeting:self.pkMeeting];
    }
    
    [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusIdle;
    [[NIMAVChatSDK sharedSDK].netCallManager leaveMeeting:self.currentMeeting];
    [[NTESLiveManager sharedInstance] removeAllConnectors];
    
    if (_isVideoLiving) {
        if (_delegate && [_delegate respondsToSelector:@selector(onCloseLiveView)]) {
            [_delegate onCloseLiveView];
        }
        [self dismissViewControllerAnimated:NO completion:nil];
    }
    else
    {
        [self.innerView switchToEndUI];
    }
    
}

- (void)onCloseBypassingWithUid:(NSString *)uid
{
    if (![[NTESDevice currentDevice] canConnectInternet]) {
        [self.view makeToast:@"当前无网络,请稍后重试" duration:2.0 position:CSToastPositionCenter];
        return;
    }
    
    //可能这个时候都没连上,或者连上了在说话
    __block NTESMicConnector *connector = nil;
    __block BOOL isConnecting = NO;
    [[[NTESLiveManager sharedInstance] connectors:NTESLiveMicStateConnecting] enumerateObjectsUsingBlock:^(NTESMicConnector * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.uid isEqualToString:connector.uid]) {
            connector = obj;
            isConnecting = YES;
            *stop = YES;
        }
    }];
    
    //等待连接中没找到，去已上麦里找
    if (!connector) {
        connector = [[NTESLiveManager sharedInstance] connectorOnMicWithUid:uid];
    }

    DDLogInfo(@"anchor close by passing");
    
    if (connector)
    {
        if (isConnecting)
        {
            DDLogInfo(@"anchor close when user is connecting uid: %@",uid);
            //还没有进入房间的情况
            [[NTESLiveManager sharedInstance] removeConnectors:uid];
            [self.innerView switchToPlayingUI];
            [self forceDisconnectedUser:uid handler:nil];
        }
        else
        {
            //进入房间了，就等等到那个人真的走了
            DDLogInfo(@"anchor close when user is connected uid: %@",uid);
            
            [SVProgressHUD show];
            [self forceDisconnectedUser:uid handler:^(NSError *error) {
                [SVProgressHUD dismiss];
                if (error)
                {
                    DDLogError(@"on close bypassing error: force disconnect user error %d", (int)error.code);
                }
                else
                {
                    [self.innerView switchToPlayingUI];
                }
            }];
        }
    }
    else
    {
        DDLogWarn(@"unfind uid info, unknown error.");
    }
}

#pragma mark - NTESMixAudioSettingViewDelegate
- (void)didSelectMixAuido:(NSURL *)url
               sendVolume:(CGFloat)sendVolume
           playbackVolume:(CGFloat)playbackVolume
{
    NIMNetCallAudioFileMixTask *task = [[NIMNetCallAudioFileMixTask alloc] initWithFileURL:url];
    task.sendVolume = sendVolume;
    task.playbackVolume = playbackVolume;
    [[NIMAVChatSDK sharedSDK].netCallManager startAudioMix:task];
}

- (void)didPauseMixAudio
{
    [[NIMAVChatSDK sharedSDK].netCallManager pauseAudioMix];
}

- (void)didResumeMixAudio
{
    [[NIMAVChatSDK sharedSDK].netCallManager resumeAudioMix];
}

- (void)didUpdateMixAuido:(CGFloat)sendVolume
           playbackVolume:(CGFloat)playbackVolume
{
    NIMNetCallAudioFileMixTask *task = [NIMAVChatSDK sharedSDK].netCallManager.currentAudioMixTask;
    if (task) {
        task.sendVolume = sendVolume;
        task.playbackVolume = playbackVolume;
        [[NIMAVChatSDK sharedSDK].netCallManager updateAudioMix:task];
    }
}

#pragma mark - NTESMenuViewProtocol
- (void)menuView:(NTESFiterMenuView *)menu didSelect:(NSInteger)index
{
    [[NIMAVChatSDK sharedSDK].netCallManager selectBeautifyType:(NIMNetCallFilterType)[NTESLiveUtil changeToLiveType:index]];
}

- (void)menuView:(NTESFiterMenuView *)menu contrastDidChanged:(CGFloat)value
{
    [[NIMAVChatSDK sharedSDK].netCallManager setContrastFilterIntensity:value];
}

- (void)menuView:(NTESFiterMenuView *)menu smoothDidChanged:(CGFloat)value
{
    [[NIMAVChatSDK sharedSDK].netCallManager setSmoothFilterIntensity:value];
}

-(void)onFilterViewCancelButtonPressed
{
    [self.filterView dismiss];
}

-(void)onFilterViewConfirmButtonPressed
{
    [self.filterView dismiss];
    [self.innerView updateBeautify:self.filterView.selectedIndex];
}

#pragma mark - NTESMirrorViewDelegate

-(void)onPreviewMirror:(BOOL)isOn
{
    if ([self.capture isCameraBack]) {
        [self.view makeToast:@"后置摄像头模式，无法使用镜像" duration:2.0 position:CSToastPositionCenter];
        self.mirrorView.isPreviewMirrorOn = NO;
        return;
    }
    self.mirrorView.isPreviewMirrorOn = isOn;
    [[NIMAVChatSDK sharedSDK].netCallManager setPreViewMirror:isOn];
}

-(void)onCodeMirror:(BOOL)isOn
{
    if ([self.capture isCameraBack]) {
        [self.view makeToast:@"后置摄像头模式，无法使用镜像" duration:2.0 position:CSToastPositionCenter];
        self.mirrorView.isCodeMirrirOn = NO;
        return;
    }
    self.mirrorView.isCodeMirrirOn = isOn;
    [[NIMAVChatSDK sharedSDK].netCallManager setCodeMirror:isOn];
}

- (void)onMirrorCancelButtonPressed
{
    [self.mirrorView dismiss];
}

-(void)onMirrorConfirmButtonPressedWithPreviewMirror:(BOOL)isPreviewMirrorOn CodeMirror:(BOOL)isCodeMirrorOn
{
    [self.mirrorView dismiss];
    [self.innerView updateMirrorButton:isPreviewMirrorOn||isCodeMirrorOn];
}

#pragma mark - NTESWaterMarkViewDelegate

-(void)onWaterMarkCancelButtonPressed
{
    [self.waterMarkView dismiss];
}

-(void)onWaterMarkTypeSelected:(NTESWaterMarkType)type
{
    UIImage *image = [UIImage imageNamed:@"icon_waterMark"];

    CGRect rect ;
    
    CGFloat topOffset = 30 ;
    
    if ([NTESLiveManager sharedInstance].liveQuality == NTESLiveQualityNormal) {
        rect = CGRectMake(10, 10 + topOffset, 110/1.5, 40/1.5);
    }
    else
    {
        rect = CGRectMake(10, 10 + topOffset * 1.5, 110, 40);
    }

    switch (type) {
        case NTESWaterMarkTypeNone:
            [[NIMAVChatSDK sharedSDK].netCallManager cleanWaterMark];
            break;
            
        case NTESWaterMarkTypeNormal:
            
            [[NIMAVChatSDK sharedSDK].netCallManager cleanWaterMark];
            [[NIMAVChatSDK sharedSDK].netCallManager addWaterMark:image rect:rect location:NIMNetCallWaterMarkLocationRightUp];
            break;
            
        case NTESWaterMarkTypeDynamic:
        {
            NSMutableArray *array = [NSMutableArray array];
            for (NSInteger i = 0; i < 23; i++) {
                NSString *str = [NSString stringWithFormat:@"水印_%ld.png",(long)i];
                UIImage* image = [UIImage imageNamed:[[[NSBundle mainBundle] bundlePath]stringByAppendingPathComponent:str]];
                [array addObject:image];
            }

            [[NIMAVChatSDK sharedSDK].netCallManager cleanWaterMark];
            [[NIMAVChatSDK sharedSDK].netCallManager addDynamicWaterMarks:array fpsCount:4 loop:YES rect:rect location:NIMNetCallWaterMarkLocationRightUp];
        }
            break;
        default:
            break;
    }
    
    [self.innerView updateWaterMarkButton:type != NTESWaterMarkTypeNone];
    
}

#pragma mark - NTESTimerHolderDelegate
- (void)onNTESTimerFired:(NTESTimerHolder *)holder
{
    if (_ackHandler) {
        NSError *error = [NSError errorWithDomain:NIMRemoteErrorDomain code:NIMRemoteErrorCodeTimeoutError userInfo:nil];
        _ackHandler(error);
    }
    _ackHandler = nil;
}

#pragma mark - NTESAlertSheetViewDelegate
- (void)NTESAlertSheetDidSeletedInputSure:(NTESAlertSheetView *)alert
                                    input:(NSString *)input {
    NSString *userId = input;
    if (input.length == 0) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [_pkAlert dismissWithCompletion:^{
        weakSelf.pkAlert = nil;
        BOOL isOnMic = ([NTESLiveManager sharedInstance].connectorsOnMic.count != 0);
        if (isOnMic) {
            [NTESAlertSheetView showMessageWithTitle:@"PK提醒" message:@"你当前在和观众互动，请先结束互动再发起PK邀请"];
        } else {
            NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:weakSelf.chatroom.roomId];
            if ([userId isEqualToString:member.userId]) {
                [NTESAlertSheetView showMessageWithTitle:@"PK提醒" message:@"请不要随意向自己发起PK"];
            } else {
                [[NIMSDK sharedSDK].userManager fetchUserInfos:@[userId] completion:^(NSArray<NIMUser *> * _Nullable users, NSError * _Nullable error) {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    if (error) {
                        [NTESAlertSheetView showMessageWithTitle:@"PK提醒" message:@"你当前邀请的主播账号不存在"];
                    } else {
                        if ([users lastObject]) {
                            [strongSelf doSendPKOnlineRequestWithUser:[users lastObject]];
                        } else {
                            [NTESAlertSheetView showMessageWithTitle:@"PK提醒" message:@"你当前邀请的主播账号不存在"];
                        }
                    }
                }];
            }
        }

    }];
}

- (void)NTESAlertSheetDidWaitingCancel:(NTESAlertSheetView *)alert {
    //取消PK请求
    [self doSendPkCancelToUser:[NTESLiveManager sharedInstance].dstPkAnchor.uid];
}

- (void)NTESAlertSheetDidSeletedEnd:(NTESAlertSheetView *)alert {
    //关闭请求
    [self doSendPkExitToUser:[NTESLiveManager sharedInstance].dstPkAnchor.uid];
}

#pragma mark - NTESAnchorPKViewDelegate
- (void)NTESAnchorPKViewDidExit:(nonnull NTESAnchorPKView *)pkView {
    [self doSendPkExitToUser:[NTESLiveManager sharedInstance].dstPkAnchor.uid];
}

#pragma mark - Private
- (void)forceDisconnectedUser:(NSString *)uid handler:(NTESDisconnectAckHandler)handler
{
    if (!uid.length) {
        DDLogError(@"force disconnect error : no user id!");
        handler(nil);
        return;
    }
    if (!_ackHandler) {
        //如果 _ackHandler 有值， 说明有一条强制请求已经发出去了，这个时候只要替换掉回调就可以了。
        DDLogInfo(@"send custom notification force disconnect to user %@",uid);
        NIMCustomSystemNotification *notification = [NTESSessionCustomNotificationConverter notificationWithForceDisconnect:self.chatroom.roomId uid:uid];
        NIMSession *session = [NIMSession session:uid type:NIMSessionTypeP2P];
        [[NIMSDK sharedSDK].systemNotificationManager sendCustomNotification:notification toSession:session completion:nil];
        _timer = [[NTESTimerHolder alloc] init];
        [_timer startTimer:10.0 delegate:self repeats:NO];
    }
    _ackHandler = handler;
}

- (void)agreeMicConnector:(NTESMicConnector *)connector handler:(NTESAgreeMicHandler)handler
{
    __weak typeof(self) weakSelf = self;
    NIMCustomSystemNotification *notification = [NTESSessionCustomNotificationConverter notificationWithAgreeMic:self.chatroom.roomId
                                                                                                           style:connector.type];
    NIMSession *session = [NIMSession session:connector.uid type:NIMSessionTypeP2P];
    DDLogError(@"anchor: agree mic: %@",connector.uid);
    [[NIMSDK sharedSDK].systemNotificationManager sendCustomNotification:notification toSession:session completion:^(NSError * _Nullable error) {
        if (!error) {
            connector.state = NTESLiveMicStateConnecting;
            
            [[NTESLiveManager sharedInstance] addConnectorOnMic:connector];
            
            [[NTESLiveManager sharedInstance] updateConnectors:connector];
            //显示连接中的图案
            [weakSelf.innerView switchToBypassLoadingUI:connector];
            //刷新等待列表人数
            [weakSelf.innerView updateConnectorCount:[[NTESLiveManager sharedInstance] connectors:NTESLiveMicStateWaiting].count];
        }else{
            DDLogError(@"notification with agree mic error: %@",error);
            [weakSelf.view makeToast:@"选择失败，请重试" duration:2.0 position:CSToastPositionCenter];
        }
        if (handler) {
            handler(error);
        }
    }];
}

- (void)sendConnectedNotify:(NTESMicConnector *)connector
{
    NIMMessage *message = [NTESSessionMsgConverter msgWithConnectedMic:connector];
    NIMSession *session = [NIMSession session:self.chatroom.roomId type:NIMSessionTypeChatroom];
    [[NIMSDK sharedSDK].chatManager sendMessage:message toSession:session error:nil];
}

- (void)sendDisconnectedNotify:(NTESMicConnector *)connector
{
    NIMMessage *message = [NTESSessionMsgConverter msgWithDisconnectedMic:connector];
    NIMSession *session = [NIMSession session:self.chatroom.roomId type:NIMSessionTypeChatroom];
    [[NIMSDK sharedSDK].chatManager sendMessage:message toSession:session error:nil];
}

- (void)shareStreamUrl
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    
    NSDictionary * dic = [NTESLiveUtil dictByJsonString:self.chatroom.ext];
    NSString * pullUrl = [dic objectForKey:@"pullUrl"];
    if (pullUrl) {
        pasteboard.string = pullUrl;
    }
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"拉流地址已复制" message:@"在拉流播放器中粘贴地址\n观看直播" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
        [alert show];
    }
    else
    {
        UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"拉流地址已复制" message:@"在拉流播放器中粘贴地址\n观看直播" preferredStyle:UIAlertControllerStyleAlert];
        [alertVc addAction:[UIAlertAction actionWithTitle:@"知道了" style: UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertVc animated:YES completion:nil];
    }
}

- (void)snapshotFromLocalVideo
{
    __weak typeof(self) weakself = self;
    
    [[NIMAVChatSDK sharedSDK].netCallManager snapshotFromLocalVideoCompletion:^(UIImage * _Nonnull image) {
        if (image) {
            //保存到相册
            if ([weakself isCanUsePhotos]) {
               UIImageWriteToSavedPhotosAlbum(image, weakself,  @selector(image:didFinishSavingWithError:contextInfo:), nil);
            }
            else
            {
                [weakself.view makeToast:@"截图保存失败，没有相册权限" duration:1.0 position:CSToastPositionCenter ];
            }
        }
        else
        {
            [weakself.view makeToast:@"截图失败" duration:1.0 position:CSToastPositionCenter];
        }
    }];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo: (void *) contextInfo;
{
    if(!error)
    {
        [self.view makeToast:@"截图已保存" duration:1.0 position:CSToastPositionCenter];
    }
    else
    {
        [self.view makeToast:@"截图失败" duration:1.0 position:CSToastPositionCenter];
    }
}

- (BOOL)isCanUsePhotos {
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        ALAuthorizationStatus author =[ALAssetsLibrary authorizationStatus];
        if (author == kCLAuthorizationStatusRestricted || author == kCLAuthorizationStatusDenied) {
            //无权限
            return NO;
        }
    }
    else {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status == PHAuthorizationStatusRestricted ||
            status == PHAuthorizationStatusDenied) {
            //无权限
            return NO;
        }
    }
    return YES;
}

- (void)doManualFocusWithPointInView:(CGPoint)point
{
    CGFloat actionViewHeight = [self.innerView getActionViewHeight];
    BOOL pointsInRect = point.y < self.view.height - actionViewHeight;
    //后置摄像头允许对焦
    if ((NIMNetCallMediaType)[NTESLiveManager sharedInstance].type == NTESLiveTypeVideo && [self.capture isCameraBack] && _isFocusOn && pointsInRect ) {
        // 代执行的延迟消失数量
        static int delayCount = 0;
        
        // 焦点显示
        self.focusView.center = CGPointMake(point.x, point.y);
        [self.view bringSubviewToFront:self.focusView];
        self.focusView.hidden = NO;
        
        CGPoint devicePoint = CGPointMake(self.focusView.center.x/self.innerView.frame.size.width, self.focusView.center.y/self.innerView.frame.size.height);
        //对焦
        [[NIMAVChatSDK sharedSDK].netCallManager changeNMCVideoPreViewManualFocusPoint:devicePoint];
        
        delayCount++;
        //3秒自动消失
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!self.focusView.hidden && delayCount == 1) {
                self.focusView.hidden = YES;
            }
            delayCount--;
        });
    }
}

- (void)updateBeautify:(NSInteger)selectedIndex
{
    [self.innerView updateBeautify:selectedIndex != 0];
}

- (void)disconnectedAllconnectors:(void(^)())completion
{
    NSMutableArray *uids = [[NTESLiveManager sharedInstance] uidsOfConnectorsOnMic];
    dispatch_group_t group = dispatch_group_create();

    __block BOOL success = YES;
    [SVProgressHUD show];
    for (NSString *uid in uids) {
        dispatch_group_enter(group);
        [self forceDisconnectedUser:uid handler:^(NSError *error) {
            dispatch_group_leave(group);
            if (error) {
                DDLogError(@"on close bypassing error: force disconnect user error %d", (int)error.code);
                success = NO;
            }
        }];
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        if (success) {
            completion();
        }
    });
}

- (void)doSendPKOnlineRequestWithUser:(NIMUser *)user {
    NIMUserInfo *userInfo = user.userInfo;
    _pkAlert = [NTESAlertSheetView showWaitWithTitle:@"PK邀请"
                                               image:userInfo.avatarUrl
                                                name:userInfo.nickName
                                            delegate:self];
    [self doSendOnlineRequestToUser:user.userId roomId:_chatroom.roomId];
}

#pragma mark - Get

- (UIView *)captureView
{
    if (!_captureView) {
        _captureView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height )];
        _captureView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _captureView.clipsToBounds = YES;
    }
    return _captureView;
}

- (UIView *)innerView
{
    if (!_innerView) {
        _innerView = [[NTESLiveInnerView alloc] initWithChatroom:self.chatroom.roomId frame:self.view.bounds isAnchor:YES];
        [_innerView refreshChatroom:self.chatroom];
        _innerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _innerView.delegate = self;
        _innerView.localDisplayView = self.captureView;
    }
    return _innerView;
}

- (NTESMixAudioSettingView *)mixAudioSettingView
{
    //因为每次打开混音界面其实需要记住之前的状态，这里直接retain住
    if (!_mixAudioSettingView) {
        _mixAudioSettingView = [[NTESMixAudioSettingView alloc] initWithFrame:self.view.bounds];
        _mixAudioSettingView.delegate = self;
    }
    return _mixAudioSettingView;
}


- (NTESVideoQualityView *)videoQualityView
{
    if (!_videoQualityView) {
        _videoQualityView = [[NTESVideoQualityView alloc]initWithFrame:self.view.bounds quality:[NTESLiveManager sharedInstance].liveQuality];
        _videoQualityView.delegate =self;
    }
    return _videoQualityView;
}

- (NTESMirrorView *)mirrorView
{
    if (!_mirrorView) {
        _mirrorView = [[NTESMirrorView alloc]initWithFrame:self.view.bounds];
        _mirrorView.delegate =self;
    }
    return _mirrorView;
}

- (NTESWaterMarkView *)waterMarkView
{
    if (!_waterMarkView) {
        _waterMarkView = [[NTESWaterMarkView alloc]initWithFrame:self.view.bounds];
        _waterMarkView.delegate =self;
    }
    return _waterMarkView;
}

-(UIImageView *)focusView
{
    if (!_focusView) {
        _focusView = [[UIImageView alloc]init];
        _focusView.image = [UIImage imageNamed:@"icon_focus_frame"];
        [_focusView sizeToFit];
        _focusView.hidden = YES;
    }
    return _focusView;
}

-(NTESFiterMenuView *)filterView
{
    if (!_filterView) {
        _filterView = [[NTESFiterMenuView alloc]initWithFrame:self.view.bounds];
        _filterView.selectedIndex = self.filterModel.filterIndex;
        _filterView.smoothValue = self.filterModel.smoothValue;
        _filterView.constrastValue = self.filterModel.constrastValue;

        _filterView.delegate = self;
    }
    return _filterView;
}

#pragma mark - Rotate supportedInterfaceOrientations

-(BOOL)shouldAutorotate
{
    return NO;
}

-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{

    if ((NIMNetCallMediaType)[NTESLiveManager sharedInstance].type == NTESLiveTypeVideo&&[NTESLiveManager sharedInstance].orientation == NIMVideoOrientationLandscapeRight) {
        return UIInterfaceOrientationLandscapeRight;
    }
    else
    {
        return UIInterfaceOrientationPortrait;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if ((NIMNetCallMediaType)[NTESLiveManager sharedInstance].type == NTESLiveTypeVideo&&[NTESLiveManager sharedInstance].orientation == NIMVideoOrientationLandscapeRight) {
        return UIInterfaceOrientationMaskLandscapeRight;
    }
    else
    {
        return UIInterfaceOrientationMaskPortrait;
    }
}

#pragma mark - 多主播PK - 私有

- (void)doReserveAndJoinWithAnchorNewPkMeeting
{
    _isAnchorPking = YES;
    DDLogInfo(@"doReserveAndJoinWithAnchorNewPkMeeting");
    NTESMicConnector *connector = [NTESLiveManager sharedInstance].dstPkAnchor;

    NSString *dstUserUid = connector.uid;
    //创建新的音视频房间
    NIMNetCallMeeting *newMeeting = [[NIMNetCallMeeting alloc] init];
    newMeeting.name = [NSUUID UUID].UUIDString;
    newMeeting.type = _currentMeeting.type;
    newMeeting.actor = YES;
    NIMNetCallOption *option = [NTESUserUtil fillNetCallOption:newMeeting];
    option.bypassStreamingUrl = _currentMeeting.option.bypassStreamingUrl;
    option.bypassStreamingMixMode = NIMNetCallBypassStreamingMixModeCustomVideoLayout;
    option.bypassStreamingMixCustomLayoutConfig = [NTESUserUtil bypassStreamingMixCustomLayoutConfigForPK];
    if (newMeeting.type == NIMNetCallMediaTypeVideo) {
        //开启摄像头
        NIMNetCallVideoCaptureParam *param = [NTESUserUtil videoCaptureParam];
        param.videoCaptureOrientation = [NTESLiveManager sharedInstance].orientation;
        param.videoHandler = self.capture.videoHandler;
        param.preferredVideoQuality = NIMNetCallVideoQualityDefault;
        option.videoCaptureParam = param;
    }
    __weak typeof(self) weakSelf = self;
    [[NIMAVChatSDK sharedSDK].netCallManager reserveMeeting:newMeeting completion:^(NIMNetCallMeeting * _Nonnull meeting, NSError * _Nullable error) {
        if (error) {
            weakSelf.isAnchorPking = NO;
            weakSelf.isSwitchNewMeeting = NO;
            DDLogError(@"reserveMeeting error: %@",error);
            NSString *msg = [NSString stringWithFormat:@"reserveMeeting error:[%d]", (int)error.code];
            [weakSelf.view makeToast:msg duration:2.0 position:CSToastPositionCenter];
            [weakSelf doSendPkRejectToUser:dstUserUid]; //拒绝吧
        } else {
            weakSelf.pkMeeting = newMeeting;
            //加入新的会议
            [[NIMAVChatSDK sharedSDK].netCallManager joinMeeting:newMeeting
                                                      completion:^(NIMNetCallMeeting * _Nonnull meeting, NSError * _Nullable error) {
                                                          if (error) {
                                                              weakSelf.isAnchorPking = NO;
                                                              DDLogError(@"joinMeeting error:[%d]", (int)error.code);
                                                              NSString *msg = [NSString stringWithFormat:@"joinMeeting error:[%d]",
                                                                               (int)error.code];
                                                              [weakSelf.view makeToast:msg duration:2.0 position:CSToastPositionCenter];
                                                              [weakSelf doSendPkRejectToUser:dstUserUid]; //拒绝吧
                                                          } else {
                                                              weakSelf.isAnchorPking = YES;
                                                              NTESMicConnector *dstUser = [NTESLiveManager sharedInstance].dstPkAnchor;
                                                              [weakSelf.innerView switchToPkUIWithNick:dstUser.nick uid:dstUser.uid];
                                                              [weakSelf doSendPkInfoToAudienceWithPkState:YES];
                                                              [weakSelf doSendPkAgreeToUser:dstUserUid]; //同意了
                                                              //等10s
                                                              [weakSelf performSelector:@selector(doWaitEnterMeetingTimeout) withObject:nil afterDelay:10];
                                                          }
                                                          weakSelf.isSwitchNewMeeting = NO;
                                                      }];
        }
    }];
}

- (void)doJoinWithAnchorNewPkMeeting
{
    DDLogInfo(@"doJoinWithAnchorNewPkMeeting");
    NTESMicConnector *dstAnchor = [NTESLiveManager sharedInstance].dstPkAnchor;
    NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:_chatroom.roomId];
    
    NIMNetCallMeeting *newMeeting = [[NIMNetCallMeeting alloc] init];
    newMeeting.name  = self.roomName ? : @"";
    newMeeting.actor = YES;
    newMeeting.type  = dstAnchor.type;
    NIMNetCallOption *option = [NTESUserUtil fillNetCallOption:newMeeting];
    option.bypassStreamingUrl = _currentMeeting.option.bypassStreamingUrl;
    option.bypassStreamingMixMode = NIMNetCallBypassStreamingMixModeCustomVideoLayout;
    option.bypassStreamingMixCustomLayoutConfig = [NTESUserUtil bypassStreamingMixCustomLayoutConfigForPK];
    if (newMeeting.type == NIMNetCallMediaTypeVideo) {
        //开启摄像头
        NIMNetCallVideoCaptureParam *param = [NTESUserUtil videoCaptureParam];
        param.videoCaptureOrientation = [NTESLiveManager sharedInstance].orientation;
        param.videoHandler = self.capture.videoHandler;
        param.preferredVideoQuality = NIMNetCallVideoQualityDefault;
        option.videoCaptureParam = param;
    }
    _pkMeeting = newMeeting;
    __weak typeof(self) weakSelf = self;
    
    [[NIMAVChatSDK sharedSDK].netCallManager joinMeeting:newMeeting completion:^(NIMNetCallMeeting * _Nonnull meeting, NSError * _Nullable error) {
        weakSelf.isSwitchNewMeeting = NO;
        if (error) {
            DDLogError(@"joinMeeting error:[%d]", (int)error.code);
            NSString *msg = [NSString stringWithFormat:@"joinMeeting error:[%d]",
                             (int)error.code];
            [weakSelf.view makeToast:msg duration:2.0 position:CSToastPositionCenter];
            //取消吧
            //--------------------
        } else {
            NTESMicConnector *dstUser = [NTESLiveManager sharedInstance].dstPkAnchor;
            [weakSelf.innerView switchToPkUIWithNick:dstUser.nick uid:dstUser.uid];
            weakSelf.isAnchorPking = YES;
            NTESPKInfo *pkInfo = [[NTESPKInfo alloc] init];
            pkInfo.isPking = YES;
            pkInfo.inviter = member.roomNickname;
            pkInfo.invitee = dstUser.nick;
            [weakSelf doSendPkStartedNotifyToAudience:pkInfo];
            [weakSelf doUpdateChatroomNotifyExt:pkInfo];
        }
    }];
}

- (void)doJoinWithAnchorOriginMeeting
{
    //重新加入原来的meeting
    DDLogInfo(@"doJoinWithAnchorOriginMeeting");
    if (_currentMeeting.type == NIMNetCallMediaTypeVideo) {
        //开启摄像头
        NIMNetCallVideoCaptureParam *param = [NTESUserUtil videoCaptureParam];
        param.videoCaptureOrientation = [NTESLiveManager sharedInstance].orientation;
        param.videoHandler = self.capture.videoHandler;
        param.preferredVideoQuality = NIMNetCallVideoQualityDefault;
        _currentMeeting.option.videoCaptureParam = param;
    }
    __weak typeof(self) weakSelf = self;
    [[NIMAVChatSDK sharedSDK].netCallManager reserveMeeting:_currentMeeting completion:^(NIMNetCallMeeting * _Nonnull meeting, NSError * _Nullable error) {
        weakSelf.isSwitchOriginMeeting = NO;
        if (error) {
            DDLogError(@"reserveMeeting error: %@",error);
            NSString *msg = [NSString stringWithFormat:@"reserveMeeting error:[%d]", (int)error.code];
            [weakSelf.view makeToast:msg duration:2.0 position:CSToastPositionCenter];
        }
        else
        {
            [[NIMAVChatSDK sharedSDK].netCallManager joinMeeting:_currentMeeting completion:^(NIMNetCallMeeting * _Nonnull meeting, NSError * _Nullable error) {
                if (error) {
                    NSString *msg = [NSString stringWithFormat:@"joinMeeting error:[%d]",
                                     (int)error.code];
                    [weakSelf.view makeToast:msg duration:2.0 position:CSToastPositionCenter];
                }
                weakSelf.isSwitchOriginMeeting = NO;
            }];
        }
    }];
}

- (void)doAgreeAnchorPkToUser:(NSString *)dstUserUid {
    DDLogInfo(@"同意PK了");
    self.isInviter = NO;
    self.isSwitchNewMeeting = YES;
    //离开当前的音视频房间
    [[NIMAVChatSDK sharedSDK].netCallManager leaveMeeting:_currentMeeting];
}

- (void)doSendPkStartedNotifyToAudience:(NTESPKInfo *)info
{
    NIMMessage *message = [NTESSessionMsgConverter msgWithPKStartedInfo:info];
    NIMSession *session = [NIMSession session:self.chatroom.roomId type:NIMSessionTypeChatroom];
    [[NIMSDK sharedSDK].chatManager sendMessage:message toSession:session error:nil];
}

- (void)doSendPkExitedNotifyToAudience
{
    NIMMessage *message = [NTESSessionMsgConverter msgWithPKExited];
    NIMSession *session = [NIMSession session:self.chatroom.roomId type:NIMSessionTypeChatroom];
    [[NIMSDK sharedSDK].chatManager sendMessage:message toSession:session error:nil];
}


- (void)doSendPkInfoToAudienceWithPkState:(BOOL)ispking
{
    NTESMicConnector *dstUser = [NTESLiveManager sharedInstance].dstPkAnchor;
    NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:_chatroom.roomId];
    
    NTESPKInfo *pkInfo = [[NTESPKInfo alloc] init];
    pkInfo.isPking = ispking;
    pkInfo.inviter = member.roomNickname; //me
    pkInfo.invitee = dstUser.nick;
    [self doUpdateChatroomNotifyExt:pkInfo];
}

- (void)doUpdateChatroomNotifyExt:(NTESPKInfo *)info
{
    NIMChatroomUpdateRequest *request = [[NIMChatroomUpdateRequest alloc] init];
    NSString *update = nil;
    update = [@{
                  NTESCMPKState           : @(info.isPking),
                  NTESCMPKStartedInviter  : info.inviter ? : @"",
                  NTESCMPKStartedInvitee  : info.invitee ? : @"",
                  NTESCMMeetingName : _currentMeeting.name ? : @"",
                  } jsonBody];
    
    NSString *ext = [NTESLiveUtil jsonString:self.chatroom.ext addJsonString:update];
    request.roomId = self.chatroom.roomId;
    request.updateInfo = @{@(NIMChatroomUpdateTagExt) : ext};
    request.needNotify = YES;
    request.notifyExt  = update;
    [[NIMSDK sharedSDK].chatroomManager updateChatroomInfo:request completion:nil];
}

- (void)doUpdateChatroomExtWithMeetingUid:(UInt64)anchorMeetingUid {
    NIMChatroomUpdateRequest *request = [[NIMChatroomUpdateRequest alloc] init];
    NSString *update = nil;
    update = [@{
                NTESCMConnectMicMeetingUid : @(anchorMeetingUid)
                } jsonBody];
    NSString *ext = [NTESLiveUtil jsonString:self.chatroom.ext addJsonString:update];
    request.roomId = self.chatroom.roomId;
    request.updateInfo = @{@(NIMChatroomUpdateTagExt) : ext};
    request.needNotify = YES;
    request.notifyExt  = update;
    [[NIMSDK sharedSDK].chatroomManager updateChatroomInfo:request completion:nil];
}


#pragma mark - 多主播PK - 发
- (void)doWaitOnlineResponseTimeout {
    if ([NTESLiveManager sharedInstance].pkStatus != NTESAnchorPKStatusPingInteractive) {
        return;
    }
    [_pkAlert dismissWithCompletion:^{
        [NTESAlertSheetView showMessageWithTitle:@"PK提醒"
                                         message:@"邀请PK主播此刻不在线，请稍后邀请"];
    }];
    [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusIdle;
    [NTESLiveManager sharedInstance].dstPkAnchor = nil;
}

- (void)doWaitRequestResponseTimeout {
    if ([NTESLiveManager sharedInstance].pkStatus != NTESAnchorPKStatusPkInteractive) {
        return;
    }
    NSString *dstNick = [NTESLiveManager sharedInstance].dstPkAnchor.nick;
    NSString *msg = [NSString stringWithFormat:@"很遗憾，%@没有回应PK邀请，试试邀请其他主播吧", dstNick];
    [_pkAlert dismissWithCompletion:^{
        [NTESAlertSheetView showMessageWithTitle:@"PK提醒"
                                         message:msg];
    }];
    [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusIdle;
    [NTESLiveManager sharedInstance].dstPkAnchor = nil;
}

- (void)doWaitEnterMeetingTimeout {
    if ([NTESLiveManager sharedInstance].pkStatus != NTESAnchorPKStatusPkInteractive) {
        return;
    }
    [self.view makeToast:@"Pk失败，对方加入会议超时" duration:2.0 position:CSToastPositionCenter];
    [self didReceivePkExit];
    [self doSendPkCancelToUser:[NTESLiveManager sharedInstance].dstPkAnchor.uid];
}

//发送在线响应
- (void)doSendOnlineRequestToUser:(NSString *)dstUserId roomId:(NSString *)roomId {
    NIMSession *session = [NIMSession session:dstUserId type:NIMSessionTypeP2P];
    NIMCustomSystemNotification *notification = [NTESSessionCustomNotificationConverter notificationWithPkOnlineRequest:_chatroom.roomId];
    
    __weak typeof(self) weakSelf = self;
    NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:_chatroom.roomId];
    DDLogInfo(@"YAT 发送 PkOnlineRequest：[%@] -> [%@]", member.userId, dstUserId);
    [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusPingInteractive;
    [[NIMSDK sharedSDK].systemNotificationManager sendCustomNotification:notification toSession:session completion:^(NSError * _Nullable error){
        if (error) {
            DDLogError(@"YAT notification with agree mic error: %@",error);
            [weakSelf.view makeToast:@"发送OnlineRequest失败" duration:2.0 position:CSToastPositionCenter];
            [weakSelf.pkAlert dismissWithCompletion:nil];
            [NTESLiveManager sharedInstance].dstPkAnchor = nil;
            [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusPingInteractive;
        } else {
            //开启等待回包定时器
            [weakSelf performSelector:@selector(doWaitOnlineResponseTimeout)
                           withObject:nil
                           afterDelay:10];
        }
    }];
}

//发送在线响应
- (void)doSendOnlineResponseToUser:(NSString *)dstUserId roomId:(NSString *)roomId {
    NIMSession *session = [NIMSession session:dstUserId type:NIMSessionTypeP2P];
    NIMCustomSystemNotification *notification = [NTESSessionCustomNotificationConverter notificationWithPkOnlineResponse:_chatroom.roomId];
    __weak typeof(self) weakSelf = self;
    [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusPingInteractive;
    NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:_chatroom.roomId];
    DDLogInfo(@"YAT 发送 PkOnlineResponse：[%@] -> [%@]", member.userId, dstUserId);
    [[NIMSDK sharedSDK].systemNotificationManager sendCustomNotification:notification toSession:session completion:^(NSError * _Nullable error){
        if (error) {
            DDLogError(@"YAT notification with agree mic error: %@",error);
            [weakSelf.view makeToast:@"发送OnlineResponse失败" duration:2.0 position:CSToastPositionCenter];
            [NTESLiveManager sharedInstance].dstPkAnchor = nil;
            [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusIdle;
        }
    }];
}

//发送PK请求
- (void)doSendPkRequestToUser:(NSString *)dstUserId {
    NIMSession *session = [NIMSession session:dstUserId type:NIMSessionTypeP2P];
    NIMCustomSystemNotification *notification = [NTESSessionCustomNotificationConverter notificationWithPkRequest:_chatroom.roomId pushUrl:nil layoutParam:nil];
    
    [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusPkInteractive;
    NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:_chatroom.roomId];
    DDLogInfo(@"YAT 发送 PkRequest：[%@] -> [%@]", member.userId, dstUserId);
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].systemNotificationManager sendCustomNotification:notification toSession:session completion:^(NSError * _Nullable error){
        if (error) {
            DDLogError(@"YAT notification with agree mic error: %@",error);
            [weakSelf.view makeToast:@"发送PkRequest响应失败" duration:2.0 position:CSToastPositionCenter];
            [NTESLiveManager sharedInstance].dstPkAnchor = nil;
            [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusIdle;
        }
    }];
}

- (void)doSendPkCancelToUser:(NSString *)dstUserId {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    NIMSession *session = [NIMSession session:dstUserId type:NIMSessionTypeP2P];
    NIMCustomSystemNotification *notification = [NTESSessionCustomNotificationConverter notificationWithPkCancel:_chatroom.roomId];
    [NTESLiveManager sharedInstance].dstPkAnchor = nil;
    [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusIdle;
    NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:_chatroom.roomId];
    
    DDLogInfo(@"YAT 发送 PkCancel：[%@] -> [%@]", member.userId, dstUserId);
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].systemNotificationManager sendCustomNotification:notification toSession:session completion:^(NSError * _Nullable error){
        if (error) {
            DDLogError(@"YAT notification with cancel error: %@",error);
            [weakSelf.view makeToast:@"发送PkCancel失败" duration:2.0 position:CSToastPositionCenter];
        }
    }];
}

//发送无效响应
- (void)doSendPkInvalidToUser:(NSString *)dstUserId {
    NIMSession *session = [NIMSession session:dstUserId type:NIMSessionTypeP2P];
    NIMCustomSystemNotification *notification = [NTESSessionCustomNotificationConverter notificationWithPkInvalid:_chatroom.roomId];
    [NTESLiveManager sharedInstance].dstPkAnchor = nil;
    [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusIdle;
    NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:_chatroom.roomId];
    DDLogInfo(@"YAT 发送 PkInvalid：[%@] -> [%@]", member.userId, dstUserId);
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].systemNotificationManager sendCustomNotification:notification toSession:session completion:^(NSError * _Nullable error){
        if (error) {
            DDLogError(@"YAT notification with agree mic error: %@",error);
            [weakSelf.view makeToast:@"发送PkInvalid失败" duration:2.0 position:CSToastPositionCenter];
        }
    }];
}

//发送忙碌响应
- (void)doSendPkBusyToUser:(NSString *)dstUserId {
    NIMSession *session = [NIMSession session:dstUserId type:NIMSessionTypeP2P];
    NIMCustomSystemNotification *notification = [NTESSessionCustomNotificationConverter notificationWithPkBusy:_chatroom.roomId];
    NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:_chatroom.roomId];
    DDLogInfo(@"YAT 发送 PkBusy：[%@] -> [%@]", member.userId, dstUserId);
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].systemNotificationManager sendCustomNotification:notification toSession:session completion:^(NSError * _Nullable error){
        if (error) {
            DDLogError(@"YAT notification with agree mic error: %@",error);
            [weakSelf.view makeToast:@"发送PkBusy失败" duration:2.0 position:CSToastPositionCenter];
        }
    }];
}

//发送拒绝响应
- (void)doSendPkRejectToUser:(NSString *)dstUserId {
    NIMSession *session = [NIMSession session:dstUserId type:NIMSessionTypeP2P];
    NIMCustomSystemNotification *notification = [NTESSessionCustomNotificationConverter notificationWithPkReject:_chatroom.roomId];
    [NTESLiveManager sharedInstance].dstPkAnchor = nil;
    [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusIdle;
    NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:_chatroom.roomId];
    DDLogInfo(@"YAT 发送 PkReject：[%@] -> [%@]", member.userId, dstUserId);
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].systemNotificationManager sendCustomNotification:notification toSession:session completion:^(NSError * _Nullable error){
        if (error) {
            DDLogError(@"YAT notification with agree mic error: %@",error);
            [weakSelf.view makeToast:@"发送PkReject失败" duration:2.0 position:CSToastPositionCenter];
        }
    }];
}

//发送同意响应
- (void)doSendPkAgreeToUser:(NSString *)dstUserId {
    NIMSession *session = [NIMSession session:dstUserId type:NIMSessionTypeP2P];
    NIMCustomSystemNotification *notification = [NTESSessionCustomNotificationConverter notificationWithPkAgreeWithRoomName:_pkMeeting.name roomId:_chatroom.roomId];
    NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:_chatroom.roomId];
    [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusComplete;
    DDLogInfo(@"YAT 发送 PkAgree：[%@] -> [%@]", member.userId, dstUserId);
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].systemNotificationManager sendCustomNotification:notification toSession:session completion:^(NSError * _Nullable error){
        if (error) {
            DDLogError(@"YAT notification with agree mic error: %@",error);
            [weakSelf.view makeToast:@"发送在线响应失败" duration:2.0 position:CSToastPositionCenter];
            [NTESLiveManager sharedInstance].dstPkAnchor = nil;
            [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusIdle;
        }
    }];
}

- (void)doSendPkExitToUser:(NSString *)dstUserId {
    NIMSession *session = [NIMSession session:dstUserId type:NIMSessionTypeP2P];
    NIMCustomSystemNotification *notification = [NTESSessionCustomNotificationConverter notificationWithPkDidExit:_chatroom.roomId];
    [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusIdle;

    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].systemNotificationManager sendCustomNotification:notification toSession:session completion:^(NSError * _Nullable error){
        if (error) {
            DDLogError(@"YAT notification with agree mic error: %@",error);
            [weakSelf.view makeToast:@"发送PK退出失败" duration:2.0 position:CSToastPositionCenter];
        }
        else
        {
            weakSelf.isAnchorPking = NO;
            [weakSelf doSendPkInfoToAudienceWithPkState:NO];
            weakSelf.isSwitchOriginMeeting = YES;
            [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusIdle;
            [[NIMAVChatSDK sharedSDK].netCallManager leaveMeeting:weakSelf.pkMeeting];
            
            //先改变布局
            [weakSelf.innerView removePkToast];
            [weakSelf.innerView switchToPlayingUI];

        }
    }];
}

#pragma mark - 多主播PK - 收
- (void)didReceivePkOnlineRequestFromUser:(NTESMicConnector *)user {
    NTESAnchorPKStatus pkStatus = [NTESLiveManager sharedInstance].pkStatus;
    
    if (pkStatus != NTESAnchorPKStatusIdle) {
        DDLogWarn(@"YAT 当前状态 %d, 不再接收 OnlineRequest 请求",
                  (int)pkStatus);
        [self doSendPkBusyToUser:user.uid];
    }
    else {
        [_pkAlert dismissWithCompletion:nil];//有弹窗，先关闭弹窗
        _pkAlert = nil;

        [NTESLiveManager sharedInstance].dstPkAnchor = user;
        if ([NTESLiveManager sharedInstance].type == NTESLiveTypeVideo) {
            [self doSendOnlineResponseToUser:user.uid roomId:_chatroom.roomId];//发送在线响应
        } else {
            //音频直播直接拒绝邀请
            [self doSendPkRejectToUser:user.uid]; //无效用户
        }
    }
}

- (void)didReceivePkRoomBypassOnlineRequestFromUser:(NTESMicConnector *)user;
{
    //主播推流收到了来自房间推流的PK请求直接拒绝
    [self doSendPkRejectToUser:user.uid]; //无效用户
}

- (void)didReceivePkOnlineResponse {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    NTESMicConnector *dstUser = [NTESLiveManager sharedInstance].dstPkAnchor;
    if (dstUser) {
        [self doSendPkRequestToUser:dstUser.uid];
    }
}

- (void)didReceivePkCancel{
    NTESAnchorPKStatus pkStatus = [NTESLiveManager sharedInstance].pkStatus;
        
    [_pkAlertView dismissWithClickedButtonIndex:0 animated:YES];
    //先提示
    [NTESAlertSheetView showMessageWithTitle:@"PK提示" message:@"对方已取消PK"];
    
    //有可能已经同意PK了 没办法要退出
    if (pkStatus == NTESAnchorPKStatusComplete) {
        [self didReceivePkExit];
    }

    [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusIdle;
    [NTESLiveManager sharedInstance].dstPkAnchor = nil;
}

- (void)didReceivePkInvalid {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusIdle;
    [NTESLiveManager sharedInstance].dstPkAnchor = nil;
    [_pkAlert dismissWithCompletion:^{
        [NTESAlertSheetView showMessageWithTitle:@"PK提示" message:@"不是主播账号"];
    }];
}

- (void)didReceivePkBusy {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusIdle;
    [NTESLiveManager sharedInstance].dstPkAnchor = nil;
    [_pkAlert dismissWithCompletion:^{
        [NTESAlertSheetView showMessageWithTitle:@"PK提示"
                                         message:@"邀请的主播正在PK，请稍后发起邀请"];
    }];
}

- (void)didReceivePkRequest:(NSString *)pushUrl layoutParam:(NSString *)layoutParam{
    NTESMicConnector *connector = [NTESLiveManager sharedInstance].dstPkAnchor;
    BOOL isOnMic = ([NTESLiveManager sharedInstance].connectorsOnMic.count != 0);
    if (isOnMic) {
        [self doSendPkRejectToUser:connector.uid]; //正在连麦就拒绝对方
        [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusIdle;
        return;
    }

    [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusPkInteractive;
    //弹窗
    NSString *msg = [NSString stringWithFormat:@"主播%@邀请你PK", connector.nick];
    _pkAlertView = [[UIAlertView alloc] initWithTitle:@"PK邀请" message:msg delegate:nil cancelButtonTitle:@"拒绝" otherButtonTitles:@"接受", nil];
    
    __weak typeof(self) weakSelf = self;
    [_pkAlertView showAlertWithCompletionHandler:^(NSInteger index) {
        if (index == 0) {
            [weakSelf doSendPkRejectToUser:connector.uid]; //拒绝PK
        } else {
            [weakSelf doAgreeAnchorPkToUser:connector.uid];
        }
    }];
}

- (void)didReceivePkReject {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    NSString *dstNick = [NTESLiveManager sharedInstance].dstPkAnchor.nick;
    [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusIdle;
    [NTESLiveManager sharedInstance].dstPkAnchor = nil;
    [_pkAlert dismissWithCompletion:^{
        NSString *msg = [NSString stringWithFormat:@"很遗憾，%@拒绝了你的PK邀请", dstNick];
        [NTESAlertSheetView showMessageWithTitle:@"PK提示" message:msg];
    }];
}

- (void)didReceivePkAgreeWithRoomName:(NSString *)roomName {

    [_pkAlert dismiss];
    [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusComplete;
    self.isInviter = YES;
    self.isSwitchNewMeeting = YES;
    self.roomName = roomName;
    //离开当前的音视频房间
    [[NIMAVChatSDK sharedSDK].netCallManager leaveMeeting:_currentMeeting];
}

- (void)didReceivePkExit;
{
    self.isAnchorPking = NO;
    [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusIdle;
    [self doSendPkInfoToAudienceWithPkState:NO];
    self.isSwitchOriginMeeting = YES;
    [[NIMAVChatSDK sharedSDK].netCallManager leaveMeeting:self.pkMeeting];
    
    //先改变布局
    [self.innerView removePkToast];
    [self.innerView switchToPlayingUI];
}

#pragma mark - 资源释放
//资源释放后加入新的会议
- (void)onResourceFreed
{
    if (_isSwitchNewMeeting) {
        if (self.isInviter) {
            [self doJoinWithAnchorNewPkMeeting];
        }
        else
        {
            [self doReserveAndJoinWithAnchorNewPkMeeting];
        }
        return;
    }
    if (_isSwitchOriginMeeting) {
        [self doJoinWithAnchorOriginMeeting];
        return;
    }
}

#pragma  mark ----  faceU start  -----
// demobar 初始化
-(FUAPIDemoBar *)demoBar{
    if (!_demoBar) {
        _demoBar = [[FUAPIDemoBar alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 300, self.view.frame.size.width, 194)];
        _demoBar.mDelegate = self;
    }
    return _demoBar ;
}

/**      FUAPIDemoBarDelegate       **/

-(void)filterValueChange:(FUBeautyParam *)param{
    [[FUManager shareManager] filterValueChange:param];
}

-(void)switchRenderState:(BOOL)state{
    [FUManager shareManager].isRender = state;
}

-(void)bottomDidChange:(int)index{
    if (index < 3) {
        [[FUManager shareManager] setRenderType:FUDataTypeBeautify];
    }
    if (index == 3) {
        [[FUManager shareManager] setRenderType:FUDataTypeStrick];
    }
    
    if (index == 4) {
        [[FUManager shareManager] setRenderType:FUDataTypeMakeup];
    }
    if (index == 5) {
        [[FUManager shareManager] setRenderType:FUDataTypebody];
    }
}

#pragma  mark ----  faceU End  -----


@end

