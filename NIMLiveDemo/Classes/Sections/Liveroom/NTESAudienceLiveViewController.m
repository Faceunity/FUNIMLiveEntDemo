//
//  NTESAudienceLiveViewController.m
//  NIM
//
//  Created by chris on 15/12/16.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "NTESAudienceLiveViewController.h"
#import "UIImage+NTESColor.h"
#import "UIView+NTES.h"
#import "NSString+NTES.h"
#import "SVProgressHUD.h"
#import "UIView+Toast.h"
#import "NTESLiveManager.h"
#import "NTESDemoLiveroomTask.h"
#import "NSDictionary+NTESJson.h"
#import "UIAlertView+NTESBlock.h"
#import "NTESDemoService.h"
#import "NTESSessionMsgConverter.h"
#import "NTESLiveInnerView.h"
#import "NTESPresentShopView.h"
#import "NTESAudienceConnectView.h"
#import "NTESInteractSelectView.h"
#import "NTESPresentAttachment.h"
#import "NTESLikeAttachment.h"
#import "NTESLiveViewDefine.h"
#import "NTESMicConnector.h"
#import "NTESMicAttachment.h"
#import "NTESLiveAudienceHandler.h"
#import "NTESTimerHolder.h"
#import "NTESDevice.h"
#import "NTESUserUtil.h"
#import "NTESLiveUtil.h"
#import "NTESAudiencePresentViewController.h"
#import "NTESFiterMenuView.h"
#import "NTESPKAttachment.h"
#import "NTESPKInfo.h"
#import "NTESAnchorPkToast.h"
#import "NTESCustomKeyDefine.h"
#import "NTESAlertSheetView.h"

typedef void(^NTESDisconnectAckHandler)(NSError *);
typedef void(^NTESAgreeMicHandler)(NSError *);

@interface NTESAudienceLiveViewController ()<NIMChatroomManagerDelegate,NTESLiveInnerViewDelegate,
NIMChatManagerDelegate,NIMSystemNotificationManagerDelegate,NIMNetCallManagerDelegate,NTESLiveInnerViewDataSource,
NTESPresentShopViewDelegate,NTESInteractSelectDelegate,NTESAudienceConnectDelegate,NTESLiveAudienceHandlerDelegate,NTESLiveAudienceHandlerDatasource,NTESMenuViewProtocol>
{
    NSTimeInterval _lastPressLikeTimeInterval;
    NIMNetCallCamera _cameraType;
    NSString *_chatroomId;
}

@property (nonatomic, assign) BOOL isPlaying;

@property (nonatomic, assign) BOOL isAnchorPKing;

@property (nonatomic, assign) BOOL isStreamSwitching;//拉流模式的切换

@property (nonatomic, strong) UIView *canvas;

@property (nonatomic, strong) NTESAudienceConnectView *connectingView;

@property (nonatomic, strong) NTESLiveInnerView *innerView;

@property (nonatomic, strong) NTESLiveAudienceHandler *handler;

@property (nonatomic, copy) NSString *streamUrl;

@end

@implementation NTESAudienceLiveViewController

NTES_USE_CLEAR_BAR
NTES_FORBID_INTERACTIVE_POP

- (instancetype)initWithChatroomId:(NSString *)chatroomId streamUrl:(NSString *)url{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _chatroomId = chatroomId;
        _streamUrl = url;
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    return self;
}

- (void)dealloc{
    [[NIMSDK sharedSDK].chatroomManager removeDelegate:self];
    [[NIMSDK sharedSDK].chatManager removeDelegate:self];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [[NTESLiveManager sharedInstance] delAllConnectorsOnMic];
    [[NTESLiveManager sharedInstance] stop];
    if (self.handler.isWaitingForAgreeConnect) {
        [self onCancelConnect:nil];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUp];
    
    DDLogInfo(@"enter live room , room id %@:, current user: %@",_chatroomId,[[NIMSDK sharedSDK].loginManager currentAccount]);
    
    
    [self startPlay:self.streamUrl inView:self.canvas];

    //先切到等待界面
    [self.innerView switchToWaitingUI];
    
//    请求拉流地址
//    [self requestPlayStream];
    //进入聊天室
    [self enterChatroom];
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.view addSubview:self.innerView];
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
}

#pragma mark - 本地预览回调
- (void)onLocalDisplayviewReady:(UIView *)displayView {
    _innerView.localDisplayView = displayView;
}

#pragma mark - NIMChatManagerDelegate
- (void)willSendMessage:(NIMMessage *)message
{
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
        }
            break;
        default:
            break;
    }
}

- (void)onRecvMessages:(NSArray *)messages
{
    for (NIMMessage *message in messages) {
        if (![message.session.sessionId isEqualToString:_chatroomId]
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
                else if ([attachment isKindOfClass:[NTESMicConnectedAttachment class]] || [attachment isKindOfClass:[NTESDisConnectedAttachment class]]) {
                    [self.handler dealWithBypassMessage:message];
                }
            }
                break;
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
- (void)onReceiveCustomSystemNotification:(NIMCustomSystemNotification *)notification
{
    NSString *content  = notification.content;
    NSDictionary *dict = [content jsonObject];
    NTESLiveCustomNotificationType type = [dict jsonInteger:@"command"];
    switch (type) {
        case NTESLiveCustomNotificationTypeAgreeConnectMic:
        case NTESLiveCustomNotificationTypeForceDisconnect:
            [self.handler dealWithBypassCustomNotification:notification];
            break;
        case NTESLiveCustomNotificationTypePkOnlineRequest:
        {
            NSString *pkInviter= notification.sender;
            [self doSendPkInvalidToUser:pkInviter];
        }
            break;
        default:
            break;
    }
}

//发送无效响应
- (void)doSendPkInvalidToUser:(NSString *)dstUserId {
    NIMSession *session = [NIMSession session:dstUserId type:NIMSessionTypeP2P];
    NIMCustomSystemNotification *notification = [NTESSessionCustomNotificationConverter notificationWithPkInvalid:_chatroomId];
    [NTESLiveManager sharedInstance].dstPkAnchor = nil;
    [NTESLiveManager sharedInstance].pkStatus = NTESAnchorPKStatusIdle;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].systemNotificationManager sendCustomNotification:notification toSession:session completion:^(NSError * _Nullable error){
        if (error) {
            DDLogError(@"notification with agree mic error: %@",error);
            [weakSelf.view makeToast:@"发送PkInvalid失败" duration:2.0 position:CSToastPositionCenter];
        }
    }];
}

#pragma mark - NIMNetCallManagerDelegate
- (void)onUserJoined:(NSString *)uid
             meeting:(NIMNetCallMeeting *)meeting
{
    DDLogInfo(@"on user joined uid %@",uid);
}

- (void)onUserLeft:(NSString *)uid
           meeting:(NIMNetCallMeeting *)meeting
{
    DDLogInfo(@"on user left %@",uid);
    
    NSMutableArray *uids = [[NTESLiveManager sharedInstance] uidsOfConnectorsOnMic];
    DDLogInfo(@"current on mic user is [%@]", [uids componentsJoinedByString:@" "]);
    //DDLogInfo(@"current on mic user is %@",[NTESLiveManager sharedInstance].connectorOnMic.uid);
    [[NTESLiveManager sharedInstance] delConnectorOnMicWithUid:uid];
    
    NIMChatroom *roomInfo = [[NTESLiveManager sharedInstance] roomInfo:_chatroomId];
    if ([uid isEqualToString:roomInfo.creator]) {
        //如果是遇到主播退出了的情况，则自己默默退出去
        [[NTESLiveManager sharedInstance] delAllConnectorsOnMic];
        [self.view makeToast:@"连接已断开" duration:2.0 position:CSToastPositionCenter];
        [[NIMAVChatSDK sharedSDK].netCallManager leaveMeeting:self.handler.currentMeeting];
    }
    
    [self.innerView refreshBypassUI];
    [self.innerView updateUserOnMic];
}

- (void)onMeetingError:(NSError *)error
               meeting:(NIMNetCallMeeting *)meeting
{
    DDLogError(@"on meeting error: %zd",error.code);
    [self.view.window makeToast:[NSString stringWithFormat:@"互动直播失败 code: %zd",error.code] duration:2.0 position:CSToastPositionCenter];
    //[NTESLiveManager sharedInstance].connectorOnMic = nil;
    [[NTESLiveManager sharedInstance] removeAllConnectors];
    [self.innerView switchToWaitingUI];
    [self requestPlayStream];
}


- (void)onRemoteYUVReady:(NSData *)yuvData
                   width:(NSUInteger)width
                  height:(NSUInteger)height
                    from:(NSString *)user
{
    [self.innerView updateRemoteView:yuvData width:width height:height uid:user];
}

- (void)onCameraTypeSwitchCompleted:(NIMNetCallCamera)cameraType
{}


#pragma mark - NTESLiveAudienceHandlerDelegate
- (void)didUpdateUserOnMicWithUid:(NSString *)uid
{
    NSLog(@"%@ - %@", uid, [[NIMSDK sharedSDK].loginManager currentAccount]);
    
    if (self.player.playbackState != NELPMoviePlaybackStatePlaying) {
        //即普通连麦观众,并且是正在推拉流的状态,则整个UI更新一把
        NTESMicConnector *connector = [[NTESLiveManager sharedInstance] connectorOnMicWithUid:uid];
        [self.innerView refreshBypassUIWithConnector:connector];
    }
    [self.innerView updateUserOnMic];
}

- (void)willStartByPassing:(NTESPlayerShutdownCompletion)completion
{
    DDLogInfo(@"will start by passing");
    [self.player.view removeFromSuperview];
    [self shutdown:^{
        completion();
    }];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)joinMeetingError:(NSError *)error
{
    DDLogInfo(@"join meeting error %@",error);
    [self.view makeToast:[NSString stringWithFormat:@"与主播连麦失败, code: %zd",error.code]];
    NSString *uid = [[NIMSDK sharedSDK].loginManager currentAccount];
    [self didStopByPassingWithUid:uid];
}

- (void)didStartByPassingWithUid:(NSString *)uid
{
    DDLogInfo(@"did start by passing:uid:[%@]", uid);
    NTESMicConnector *connector = [NTESMicConnector me:_chatroomId];
    [self.innerView switchToBypassingUI:connector];
    [self.connectingView dismiss];
    self.connectingView = nil;
    self.isPlaying = NO;
}

- (void)didStopByPassingWithUid:(NSString *)uid
{
    DDLogInfo(@"did stop by passing");
    [[NTESLiveManager sharedInstance] delConnectorOnMicWithUid:uid];
    if ([uid isEqualToString:[[NIMSDK sharedSDK].loginManager currentAccount]]) {
        //    [NTESLiveManager sharedInstance].connectorOnMic = nil;
        [self.innerView switchToWaitingUI];
        [self requestPlayStream];
    } else {
        [self.innerView refreshBypassUI];
    }
}

- (void)didUpdateLiveType:(NTESLiveType)type
{
    //说明主播重新进来了，这种情况下，刷下type就好了。
    DDLogInfo(@"on receive anchor update live type notification: %zd",type);
    [NTESLiveManager sharedInstance].type = type;
    if (type == NTESLiveTypeInvalid) {
        //PK状态重置
        self.isAnchorPKing = NO;
        self.isStreamSwitching = NO;
        [self.innerView removePkToast];

        //发出全局播放结束通知
        [self.player.view removeFromSuperview];
        [self shutdown:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:NTESLivePlayerPlaybackFinishedNotification object:nil userInfo:@{NELivePlayerPlaybackDidFinishReasonUserInfoKey:@(NELPMovieFinishReasonPlaybackEnded)}];
    }
}

-(void)didUpdateLiveOrientation:(NIMVideoOrientation)orientation
{
    //旋转controller
    if ( [NTESLiveManager sharedInstance].orientation != orientation)
    {
        NTESAudiencePresentViewController *vc = [[NTESAudiencePresentViewController alloc]init];
        [NTESLiveManager sharedInstance].orientation = orientation;
        
        //需要清掉界面，防止界面异常
        if (self.connectingView) {
            [self.connectingView dismiss];
            self.connectingView = nil;
        }

        [self presentViewController:vc animated:NO completion:^{
            dispatch_after(0, dispatch_get_main_queue(), ^{
                [vc dismissViewControllerAnimated:NO completion:nil];
            });

        }];

    }
}

- (void)didUpdateChatroomMemebers:(BOOL)isAdd userId:(NSString *)userId {
    if (![userId isEqualToString:[[NIMSDK sharedSDK].loginManager currentAccount]]) {
        NIMChatroom *chatroom = [[NTESLiveManager sharedInstance] roomInfo:_chatroomId];
        if (isAdd) {
            chatroom.onlineUserCount++;
        } else {
            chatroom.onlineUserCount--;
        }
        chatroom.onlineUserCount =
        (chatroom.onlineUserCount < 0 ? 0 : chatroom.onlineUserCount);
        [self.innerView refreshChatroom:chatroom];
    }
}

-(void)didUpdateToastWithPkInfo:(NTESPKInfo *)info
{
    if (info.isPking) {
        [self.innerView addPkToastWithPkInfo:info];
        _isAnchorPKing = YES;
        _isStreamSwitching = YES;
    }
    else{
        [self.innerView removePkToast];
        _isAnchorPKing = NO;
        _isStreamSwitching = YES;
    }
}


#pragma mark - NTESPresentShopViewDelegate
- (void)didSelectPresent:(NTESPresent *)present
{
    NIMMessage *message = [NTESSessionMsgConverter msgWithPresent:present];
    NIMSession *session = [NIMSession session:_chatroomId type:NIMSessionTypeChatroom];
    [[NIMSDK sharedSDK].chatManager sendMessage:message toSession:session error:nil];
}

#pragma mark - NIMChatroomManagerDelegate
- (void)chatroom:(NSString *)roomId beKicked:(NIMChatroomKickReason)reason
{
    if ([roomId isEqualToString:_chatroomId]) {
        NSString *toast = [NSString stringWithFormat:@"你被踢出聊天室"];
        DDLogInfo(@"chatroom be kicked, roomId:%@  rease:%zd",roomId,reason);
        [[NIMSDK sharedSDK].chatroomManager exitChatroom:roomId completion:nil];
        [self.view.window makeToast:toast duration:2.0 position:CSToastPositionCenter];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)chatroom:(NSString *)roomId connectionStateChanged:(NIMChatroomConnectionState)state;
{
    DDLogInfo(@"chatroom connection state changed roomId : %@  state:%zd",roomId,state);
    if (state == NIMChatroomConnectionStateEnterOK) {
        //获取连麦队列状态
        [self requestMicQueue];
    }
}

#pragma mark - Private

- (void)setUp
{
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    self.view.backgroundColor = UIColorFromRGB(0xdfe2e6);
    [self.view addSubview:self.canvas];
    [[NIMSDK sharedSDK].chatroomManager addDelegate:self];
    [[NIMSDK sharedSDK].chatManager addDelegate:self];
    [[NIMSDK sharedSDK].systemNotificationManager addDelegate:self];
    [[NIMAVChatSDK sharedSDK].netCallManager addDelegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidPlay:) name:NTESLivePlayerFirstVideoDisplayedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidPlay:) name:NTESLivePlayerFirstAudioDisplayedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinshed:) name:NTESLivePlayerPlaybackFinishedNotification object:nil];
}

- (void)changeKeyBoardHeight
{
    UIWindow *keyboardWindow = nil;
    for (UIWindow *testWindow in [[UIApplication sharedApplication] windows]) {
        if(![[testWindow class] isEqual:[UIWindow class]]) {
            keyboardWindow = testWindow;
            break;
        }
    }
    
    for (__strong UIView *possibleKeyboard in [keyboardWindow subviews]) {
        if ([possibleKeyboard isKindOfClass:NSClassFromString(@"UIInputSetContainerView")]) {
            for (__strong UIView *possibleKeyboardSubview in [possibleKeyboard subviews]) {
                if ([possibleKeyboardSubview isKindOfClass:NSClassFromString(@"UIInputSetHostView")]) {
                    possibleKeyboardSubview.height = 0;
                }
            }
        }
    }
}

- (void)enterChatroom
{
    __weak typeof(self) wself = self;
    NIMChatroomEnterRequest *request = [[NIMChatroomEnterRequest alloc] init];
    request.roomId = _chatroomId;
    [[NIMSDK sharedSDK].chatroomManager enterChatroom:request completion:^(NSError * _Nullable error, NIMChatroom * _Nullable chatroom, NIMChatroomMember * _Nullable me) {
        if (!error) {
            [[NTESLiveManager sharedInstance] cacheMyInfo:me roomId:request.roomId];
            [[NTESLiveManager sharedInstance] cacheChatroom:chatroom];
            wself.handler = [[NTESLiveAudienceHandler alloc] initWithChatroom:chatroom];
            wself.handler.delegate = self;
            wself.handler.datasource = self;
            [wself.innerView refreshChatroom:chatroom];
            if (wself.isPlaying) {
                //如果开始播放了，就刷一遍播放界面，否则什么事也不做
                [wself.innerView switchToPlayingUI];
            }
            if (!chatroom.ext) {
                return ;
            }
            NSDictionary *extDic = [NTESLiveUtil dictByJsonString:chatroom.ext];
            if (!extDic) {
                return;
            }
            NTESPKInfo *pkInfo = [[NTESPKInfo alloc] init];
            BOOL ispking = [[extDic objectForKey:NTESCMPKState] boolValue];
            if (ispking) {
                pkInfo.inviter = [extDic objectForKey:NTESCMPKStartedInviter];
                pkInfo.invitee = [extDic objectForKey:NTESCMPKStartedInvitee];
                if (pkInfo.inviter && pkInfo.invitee) {
                    [self.innerView addPkToastWithPkInfo:pkInfo];
                }
                _isAnchorPKing = YES;
            }
        }
        else
        {
            DDLogError(@"enter chat room error, code : %zd, room id : %@",error.code,request.roomId);
            [wself.view makeToast:@"直播间进入失败，请确认ID是否正确" duration:2.0 position:CSToastPositionCenter];
        }
    }];
}

- (void)requestPlayStream
{
    if (self.player.playbackState == NELPMoviePlaybackStatePlaying) {
        return;
    }
    __weak typeof(self) wself = self;
    [[NTESDemoService sharedService] requestPlayStream:_chatroomId completion:^(NSError *error, NSString *playStreamUrl,NTESLiveType liveType,NIMVideoOrientation orientation) {
        NSString *me = [[NIMSDK sharedSDK].loginManager currentAccount];
        
        if ([[NTESLiveManager sharedInstance] connectorOnMicWithUid:me]) {
            DDLogDebug(@"already on mic ,ignore requested play stream");
            //请求拉流地址回来后，发现自己已经上麦了，则不需要再开启播放器
            return;
        }
//        if ([[NTESLiveManager sharedInstance].connectorOnMic.uid isEqualToString:me]) {
//            DDLogDebug(@"already on mic ,ignore requested play stream");
//            //请求拉流地址回来后，发现自己已经上麦了，则不需要再开启播放器
//            return;
//        }
        if (!error) {
            DDLogDebug(@"request play stream complete: %@, canvas: %@, live type : %@",playStreamUrl,wself.canvas,[NTESLiveUtil liveTypeToString:liveType]);
            [NTESLiveManager sharedInstance].type = liveType;
            [wself startPlay:playStreamUrl inView:wself.canvas];
        }
        else
        {
            DDLogDebug(@"start play stream error: %zd, try again in 5 sec.",error.code);
            //拉地址没成功，则过5秒重试
            NSTimeInterval delay = 5.f;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [wself requestPlayStream];
            });
        }
    }];
}

- (void)requestMicQueue
{
    DDLogInfo(@"audience request mic queue...");
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].chatroomManager fetchChatroomQueue:_chatroomId completion:^(NSError * _Nullable error, NSArray<NSDictionary<NSString *,NSString *> *> * _Nullable info) {
        if (!error)
        {
            DDLogInfo(@"audience request mic queue result: %@",info);
            [[NTESLiveManager sharedInstance] delAllConnectorsOnMic];
            //[NTESLiveManager sharedInstance].connectorOnMic = nil;
            for (NSDictionary *pair in info) {
                NTESMicConnector *connector = [[NTESMicConnector alloc] initWithDictionary:pair];
                if (connector.state == NTESLiveMicStateConnected) {
                    [[NTESLiveManager sharedInstance] addConnectorOnMic:connector];
                }
            }
            
            NSString *myUid = [[NIMSDK sharedSDK].loginManager currentAccount];
            if ([[NTESLiveManager sharedInstance] connectorOnMicWithUid:myUid]) {
                if (weakSelf.isPlaying) {
                    [weakSelf.innerView switchToPlayingUI];
                }else{
                    [weakSelf.innerView switchToLinkingUI];
                }
            }
        }
        else
        {
            DDLogDebug(@"fetch chatroom queue error: %@",error);
        }
    }];
}

- (void)shareStreamUrl
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = self.streamUrl;
    
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

#pragma mark - NTESLiveInnerViewDelegate
- (BOOL)isPlayerPlaying {
    return (self.player.playbackState == NELPMoviePlaybackStatePlaying);
}

- (void)didSendText:(NSString *)text
{
    NIMMessage *message = [NTESSessionMsgConverter msgWithText:text];
    NIMSession *session = [NIMSession session:_chatroomId type:NIMSessionTypeChatroom];
    [[NIMSDK sharedSDK].chatManager sendMessage:message toSession:session error:nil];
}

- (void)onActionType:(NTESLiveActionType)type sender:(id)sender
{
    switch (type) {
        case NTESLiveActionTypeLike:
        {
            NSTimeInterval frequencyTimestamp = 1.0; //赞最多一秒发一次
            NSTimeInterval now = [NSDate date].timeIntervalSince1970;
            if ( now - _lastPressLikeTimeInterval > frequencyTimestamp) {
                _lastPressLikeTimeInterval = now;
                NIMMessage *message = [NTESSessionMsgConverter msgWithLike];
                NIMSession *session = [NIMSession session:_chatroomId type:NIMSessionTypeChatroom];
                [[NIMSDK sharedSDK].chatManager sendMessage:message toSession:session error:nil];
            }
        }
            break;
        case NTESLiveActionTypePresent:{
            NTESPresentShopView *shop = [[NTESPresentShopView alloc] initWithFrame:self.view.bounds];
            shop.delegate = self;
            [shop show];
            break;
        }
        case NTESLiveActionTypeCamera:{
            if (_cameraType == NIMNetCallCameraFront) {
                _cameraType = NIMNetCallCameraBack;
            }else{
                _cameraType = NIMNetCallCameraFront;
            }
            [[NIMAVChatSDK sharedSDK].netCallManager switchCamera:_cameraType];
        }
            break;
        case NTESLiveActionTypeInteract:
            if ([NTESLiveManager sharedInstance].role == NTESLiveRoleAudience)
            {
                if (self.connectingView) {
                    //说明正在请求连接
                    [self.connectingView show];
                }
                else
                {
                    NTESInteractSelectView *interact = [[NTESInteractSelectView alloc] initWithFrame:self.view.bounds];
                    interact.delegate = self;
                    if ([NTESLiveManager sharedInstance].type == NIMNetCallMediaTypeVideo) {
                        interact.types = @[@(NIMNetCallMediaTypeVideo),@(NIMNetCallMediaTypeAudio)];
                    }else{
                        interact.types = @[@(NIMNetCallMediaTypeAudio)];
                    }
                    [interact show];
                }
            }
            break;
            
        case NTESLiveActionTypeShare:{
            [self shareStreamUrl];
        }
            break;

        default:
            break;
    }
}

- (void)onClosePlaying
{
    if (self.player.playbackState == NELPMoviePlaybackStatePlaying || self.handler.currentMeeting) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"确定离开直播间吗？" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"离开", nil];
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
            UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"" message:@"确定离开直播间吗？" preferredStyle:UIAlertControllerStyleAlert];
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
    }
}

- (void)doExitLive
{
    [[NIMSDK sharedSDK].chatroomManager exitChatroom:_chatroomId completion:nil];
    [[NIMAVChatSDK sharedSDK].netCallManager leaveMeeting:self.handler.currentMeeting];
    [SVProgressHUD showWithStatus:@"关闭中" maskType:SVProgressHUDMaskTypeClear];
    __weak typeof(self) weakSelf = self;
    [self shutdown:^{
        [SVProgressHUD dismiss];
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    }];
    
}

- (void)onCloseBypassingWithUid:(NSString *)uid
{
    DDLogInfo(@"audience close by passing");
    if (![[NTESDevice currentDevice] canConnectInternet]) {
        [self.view makeToast:@"当前无网络,请稍后重试" duration:2.0 position:CSToastPositionCenter];
        return;
    }
    [[NTESLiveManager sharedInstance] delConnectorOnMicWithUid:uid];
    
    if ([uid isEqualToString:[NIMSDK sharedSDK].loginManager.currentAccount]) {
        [self.innerView switchToWaitingUI];
        [self requestPlayStream];
        [[NIMAVChatSDK sharedSDK].netCallManager leaveMeeting:self.handler.currentMeeting];
    }
}

#pragma mark - NTESInteractSelectDelegate
- (void)onSelectInteractType:(NIMNetCallMediaType)type
{
    __weak typeof(self) weakSelf = self;
    if (_isAnchorPKing) {
        [NTESAlertSheetView showMessageWithTitle:@"互动提醒" message:@"主播正在PK，请PK结束后发起互动申请"];
        return;
    }
    
    [NTESUserUtil requestMediaCapturerAccess:type handler:^(NSError *error){
        if (error) {
            DDLogInfo(@"start error by privacy");
            if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"申请连麦失败，请检查网络和权限重新开启" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                [alert show];
            }
            else
            {
                UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"" message:@"申请连麦失败，请检查网络和权限重新开启" preferredStyle:UIAlertControllerStyleAlert];
                [alertVc addAction:[UIAlertAction actionWithTitle:@"确定" style: UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alertVc animated:YES completion:nil];
            }
        }
        else
        {
            weakSelf.connectingView = [[NTESAudienceConnectView alloc] initWithFrame:self.view.bounds];
            weakSelf.connectingView.delegate = weakSelf;
            weakSelf.connectingView.roomId = _chatroomId;
            weakSelf.connectingView.type = type;
            [weakSelf.connectingView show];
            
            NIMChatroomMember *me = [[NTESLiveManager sharedInstance] myInfo:_chatroomId];
            NIMChatroom *chatroom = [[NTESLiveManager sharedInstance] roomInfo:_chatroomId];
            NTESQueuePushData *data = [[NTESQueuePushData alloc] init];
            data.roomId = _chatroomId;
            data.ext = [@{@"style":@(type),
                          @"state":@(NTESLiveMicStateWaiting),
                          @"info":@{
                                  @"nick" : me.roomNickname.length? me.roomNickname : me.userId,
                                  @"avatar":me.roomAvatar.length? me.roomAvatar : @"avatar_default"}} jsonBody];
            data.uid = me.userId;
            
            [[NTESDemoService sharedService] requestMicQueuePush:data completion:^(NSError *error) {
                //应用服务器会做数量限制，保证队列人数有个最大值，目前为100
                if (!error)
                {
                    //发一条自定义通知告诉主播我进队列了，主播最多同一时间接到100条通知，不用担心主播会被撑爆
                    NIMCustomSystemNotification *notification = [NTESSessionCustomNotificationConverter notificationWithPushMic:chatroom.roomId style:type];
                    NIMSession *session = [NIMSession session:chatroom.creator type:NIMSessionTypeP2P];
                    [[NIMSDK sharedSDK].systemNotificationManager sendCustomNotification:notification toSession:session completion:^(NSError * _Nullable error) {
                        if (error) {
                            [weakSelf.view makeToast:@"申请失败,请重试" duration:2.0 position:CSToastPositionCenter];
                            weakSelf.handler.isWaitingForAgreeConnect = NO;
                            [weakSelf.connectingView dismiss];
                            weakSelf.connectingView = nil;
                        }else{
                            //把自己加入的互动直播方式存起来
                            [NTESLiveManager sharedInstance].bypassType  = type;
                            //标记自己正在请求连麦
                            weakSelf.handler.isWaitingForAgreeConnect = YES;
                        }
                    }];
                    
                }
                else
                {
                    switch (error.code) {
                        case NTESRemoteErrorCodeOverFlow:
                            [weakSelf.view makeToast:@"连麦人数超过上限" duration:2.0 position:CSToastPositionCenter];
                            break;
                        default:
                            [weakSelf.view makeToast:@"连麦请求失败，请重试" duration:2.0 position:CSToastPositionCenter];
                            break;
                    }
                    [weakSelf.connectingView dismiss];
                    weakSelf.connectingView = nil;
                }
            }];
        }
    }];
}

#pragma mark - NTESAudienceConnectDelegate
- (void)onCancelConnect:(id)sender
{
    DDLogInfo(@"cancel connect");
    NTESQueuePopData *data = [[NTESQueuePopData alloc] init];
    data.roomId = _chatroomId;
    data.uid = [[NIMSDK sharedSDK].loginManager currentAccount];
    [[NTESDemoService sharedService] requestMicQueuePop:data completion:nil];
    
    //标记自己不再请求连麦
    self.handler.isWaitingForAgreeConnect = NO;
    self.connectingView = nil;
    
    NIMChatroom *chatroom = [[NTESLiveManager sharedInstance] roomInfo:_chatroomId];
    //发一条自定义通知告诉主播我退出队列了，主播最多同一时间接到100条通知，不用担心主播会被撑爆
    NIMCustomSystemNotification *notification = [NTESSessionCustomNotificationConverter notificationWithPopMic:_chatroomId];
    NIMSession *session = [NIMSession session:chatroom.creator type:NIMSessionTypeP2P];
    [[NIMSDK sharedSDK].systemNotificationManager sendCustomNotification:notification toSession:session completion:nil];
}

#pragma mark - Notification

- (void)playerDidPlay:(NSNotification *)notification
{
    DDLogInfo(@"player %@ did play",self.player);
    [self.innerView switchToPlayingUI];

    for (UIView * view in self.canvas.subviews) {
        if ([view isKindOfClass:NSClassFromString(@"IJKSDLGLView")]) {
            view.contentMode = UIViewContentModeScaleAspectFill;
            break;
        }
    }
    self.isPlaying = YES;
    self.isStreamSwitching = NO;
}

- (void)playbackFinshed:(NSNotification *)notification
{
    switch ([[[notification userInfo] valueForKey:NELivePlayerPlaybackDidFinishReasonUserInfoKey] intValue])
    {
        case NELPMovieFinishReasonPlaybackEnded:
            if (!self.isStreamSwitching) {
                self.isPlaying = NO;
                [self.innerView switchToEndUI];
            }
            break;
        case NELPMovieFinishReasonPlaybackError:{
            self.isStreamSwitching = NO;
            if (self.isPlaying) {
                [self.innerView switchToLinkingUI];
            }else{
                [self.innerView switchToEndUI];
            }
        }
            break;
        case NELPMovieFinishReasonUserExited:
            break;
        default:
            break;
    }
}

#pragma mark - NTESLiveInnerViewDataSource
- (id<NELivePlayer>)currentPlayer
{
    return self.player;
}
#pragma mark - Get
- (UIView *)canvas
{
    if (!_canvas) {
        _canvas = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height )];
        _canvas.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _canvas.contentMode = UIViewContentModeScaleAspectFill;
        _canvas.clipsToBounds = YES;
    }
    return _canvas;
}

- (UIView *)innerView
{
    if (!_innerView) {
        _innerView = [[NTESLiveInnerView alloc] initWithChatroom:_chatroomId frame:self.view.bounds isAnchor:NO];
        _innerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _innerView.delegate = self;
        _innerView.dataSource = self;
    }
    return _innerView;
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


@end
