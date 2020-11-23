//
//  NTESAnchorPreviewController.m
//  NIMLiveDemo
//
//  Created by Simon Blue on 17/3/21.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import "NTESAnchorPreviewController.h"
#import "NTESRoomBypassLiveViewController.h"
#import "NTESLiveAnchorHandler.h"
#import "NTESMediaCapture.h"
#import "UIView+NTES.h"
#import "UIAlertView+NTESBlock.h"
#import "NTESPreviewInnerView.h"
#import "NTESLiveManager.h"
#import "NTESUserUtil.h"
#import "NTESCustomKeyDefine.h"
#import "NSDictionary+NTESJson.h"
#import "NTESAnchorLiveViewController.h"
#import "NTESSessionMsgConverter.h"
#import "NTESDemoService.h"
#import "SVProgressHUD.h"
#import "UIView+Toast.h"
#import "NTESLiveUtil.h"
#import "NTESFilterMenuBar.h"
#import "NTESFiterMenuView.h"
#import "NTESBundleSetting.h"

@interface NTESAnchorPreviewController ()<NTESPreviewInnerViewDelegate,NTESAnchorLiveViewControllerDelegate,NIMNetCallManagerDelegate,NTESMenuViewProtocol>

@property (nonatomic, strong) UIButton *startLiveButton;          //开始直播按钮

@property (nonatomic, copy)   NIMChatroom *chatroom;

@property (nonatomic, strong)   NIMChatroomMember *selfMember;

@property (nonatomic, strong) NIMNetCallMeeting *currentMeeting;

@property (nonatomic, strong) NIMNetCallMeeting *preMeeting;

@property (nonatomic, copy) NSString *meetingname;

@property (nonatomic, strong) NTESLiveAnchorHandler *handler;

@property (nonatomic, strong) NTESMediaCapture  *capture;

@property (nonatomic, strong) NTESPreviewInnerView *previewInnerView;

@property (nonatomic, strong) UIView *captureView;

@property (nonatomic, strong) UIView *beautifyToastView;

@property (nonatomic, strong) UIView *requestToastView;

@property (nonatomic ) NIMVideoOrientation orientation;

@property (nonatomic ) BOOL disableClick;

@property (nonatomic, assign)NTESBypassType bypassType;

@property (nonatomic, assign)BOOL exitFromLive; //从房间推流离开

@end

@implementation NTESAnchorPreviewController

- (instancetype)initWithBypassType:(NTESBypassType)bypassType
{
    self= [super init];
    if (self) {
        self.automaticallyAdjustsScrollViewInsets = NO;
        _capture = [[NTESMediaCapture alloc] init];
        _orientation = NIMVideoOrientationPortrait;
        [NTESLiveManager sharedInstance].orientation = NIMVideoOrientationPortrait;
        _bypassType = bypassType;
    }
    return self;
}

- (void)dealloc
{
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    __weak typeof(self) wself = self;
    
    [self setUp];

    [self.previewInnerView switchToWaitingUI];
    
    [self.capture startPreview: (NIMNetCallMediaType)[NTESLiveManager sharedInstance].type container:self.captureView  handler:^(NSError * error) {
        [wself.view addSubview:wself.previewInnerView];
        if (error) {
                        DDLogInfo(@"start error by privacy");
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"直播失败，请检查网络和权限重新开启" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                        [alert showAlertWithCompletionHandler:^(NSInteger index) {
                            [wself dismissViewControllerAnimated:YES completion:nil];
                        }];
                    }
    }];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    //把美颜toastView恢复原始位置
    if (self.beautifyToastView) {
        self.beautifyToastView.transform = CGAffineTransformIdentity;
    }
    if (self.requestToastView) {
        self.requestToastView.transform = CGAffineTransformIdentity;
    }
}

- (void)setUp
{
    [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
    self.view.backgroundColor = UIColorFromRGB(0xdfe2e6);
    [self.view addSubview:self.captureView];
    [[NIMAVChatSDK sharedSDK].netCallManager addDelegate:self];
}


- (void)sendDisconnectedNotify:(NTESMicConnector *)connector
{
    NIMMessage *message = [NTESSessionMsgConverter msgWithDisconnectedMic:connector];
    NIMSession *session = [NIMSession session:self.chatroom.roomId type:NIMSessionTypeChatroom];
    [[NIMSDK sharedSDK].chatManager sendMessage:message toSession:session error:nil];
}

- (UIView *)previewInnerView
{
    if (!_previewInnerView) {
        _previewInnerView = [[NTESPreviewInnerView alloc] initWithChatroom:nil frame:self.view.bounds];
        _previewInnerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _previewInnerView.delegate = self;
    }
    return _previewInnerView;
}


- (UIView *)captureView
{
    if (!_captureView) {
        _captureView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height)];
        _captureView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _captureView.clipsToBounds = YES;
    }
    return _captureView;
}


- (void)onLocalDisplayviewReady:(UIView *)displayView
{
    [self.capture onLocalDisplayviewReady:displayView];
    if (self.previewInnerView) {
        [self.view bringSubviewToFront:self.previewInnerView];
    }
    
    [self.previewInnerView updateBeautifyButton:YES];
}

#pragma mark - private method


- (void)rotateUI:(NIMVideoOrientation)orientation
{
        if (orientation == NIMVideoOrientationPortrait) {
            _orientation = NIMVideoOrientationPortrait;
            [UIView animateWithDuration:0.5 animations:^{
                _previewInnerView.transform = CGAffineTransformIdentity;
                _previewInnerView.frame = CGRectMake(0, 0, self.view.width, self.view.height);
                [_previewInnerView layoutIfNeeded];
            }];
        }
        else
        {
            _orientation = NIMVideoOrientationLandscapeRight;
            [UIView animateWithDuration:0.5 animations:^{
                _previewInnerView.transform = CGAffineTransformRotate(CGAffineTransformIdentity, M_PI_2);
                _previewInnerView.frame = CGRectMake(0, 0, self.view.width, self.view.height);
                [_previewInnerView layoutIfNeeded];

            }];
        }
}

- (UIView *)getBeautifyToastView
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    for ( UIView *view in [window subviews]) {
        if ([view isKindOfClass:[UIControl class]]) {
            for (UIView *toastView in view.subviews) {
                if ([toastView isKindOfClass:[SVProgressHUD class]]) {
                    return toastView;
                    break;
                }
            }
        }
    }
    return nil;
}


- (void)continueTolive
{
    [[NTESLiveManager sharedInstance] cacheMyInfo:self.selfMember roomId:self.chatroom.roomId];
    [[NTESLiveManager sharedInstance] cacheChatroom:self.chatroom];
    __weak typeof(self) weakSelf = self;
    [SVProgressHUD show];
    [self.capture startLiveStreamHandler:^(NIMNetCallMeeting * _Nonnull meeting, NSError * _Nonnull error) {
        if (error) {
            [SVProgressHUD dismiss];
            weakSelf.disableClick = NO;
            [weakSelf.previewInnerView makeToast:@"房间已解散"];
            [weakSelf.previewInnerView switchToWaitingUI];
            DDLogError(@"start error:%@",error);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf onCloseLiving];
            });
        }else
        {
            NSString *uid = [NIMSDK sharedSDK].loginManager.currentAccount;
            UInt64 meetingUid = [[NIMAVChatSDK sharedSDK].netCallManager getMeetingIdWithUserUid:uid];
            [weakSelf doUpdateChatroomExtWithMeetingUid:meetingUid];
            
            weakSelf.currentMeeting = meeting;
            [SVProgressHUD dismiss];
            weakSelf.disableClick = NO;
            
            weakSelf.exitFromLive = NO;
           NTESBypassLiveViewController *vc = [[NTESRoomBypassLiveViewController alloc]initWithChatroom:weakSelf.chatroom currentMeeting:weakSelf.currentMeeting capture:weakSelf.capture delegate:weakSelf];
            vc.orientation = weakSelf.orientation;
            vc.filterModel = [weakSelf.previewInnerView getFilterModel];

            vc.modalPresentationStyle =  UIModalPresentationFullScreen;
            dispatch_after(0, dispatch_get_main_queue(), ^{
                [weakSelf presentViewController:vc animated:NO completion:^{
                    [weakSelf.previewInnerView switchToEndUI];
                }];
            });
        }
    }];
}

- (void)requestVideoStreamWithCompletion:(void(^)(NSError *error))completion
{
    if (self.disableClick) {
        return;
    }
    _disableClick = YES;
    
    //如果是离开房间返回的，点开始直播就是继续直播的意思
    if (_exitFromLive) {
        [self continueTolive];
        return;
    }
    
    NSString *meetingName = [NSUUID UUID].UUIDString;
    self.meetingname = meetingName;
    
    [SVProgressHUD show];
    
    _requestToastView  = [self getBeautifyToastView];
    
    if (_orientation == NIMVideoOrientationPortrait) {
        _requestToastView.transform = CGAffineTransformIdentity;
    }
    else
    {
        _requestToastView.transform = CGAffineTransformRotate(CGAffineTransformIdentity, M_PI_2);
    }

    [NTESLiveManager sharedInstance].requestOrientation = self.orientation;
    
    __weak typeof(self) wself = self;

    [[NTESDemoService sharedService] requestLiveStream:meetingName completion:^(NSError *error, NIMChatroom *chatroom) {
        if (!error)
        {
            NSInteger orientation = !(wself.orientation ==NIMVideoOrientationLandscapeRight) ? 1 : 2;
            NSInteger pushType = (wself.bypassType == NTESBypassTypeAnchor) ? 1 : 2;

            _chatroom = chatroom;
            NIMChatroomEnterRequest *request = [[NIMChatroomEnterRequest alloc] init];
            request.roomId = chatroom.roomId;
            
            request.roomNotifyExt = [@{
                                       NTESCMType  : @([NTESLiveManager sharedInstance].type),
                                       NTESCMMeetingName: meetingName,
                                       NTESCMOrientation :@(orientation),
                                       NTESCMPushType : @(pushType),
                                       } jsonBody];
            
            [[NIMSDK sharedSDK].chatroomManager enterChatroom:request completion:^(NSError *error, NIMChatroom *room, NIMChatroomMember *me) {
                if (!error) {
                    //这里拿到的是应用服务器的人数，没有把自己加进去，手动添加。
                    chatroom.onlineUserCount++;
                    //将room的扩展也加进去
                    chatroom.ext =[NTESLiveUtil jsonString:chatroom.ext addJsonString:request.roomNotifyExt];
                    
                    wself.selfMember = me;
                    [[NTESLiveManager sharedInstance] cacheMyInfo:me roomId:request.roomId];
                    [[NTESLiveManager sharedInstance] cacheChatroom:chatroom];
                    
                    NIMNetCallMeeting *meeting = [[NIMNetCallMeeting alloc] init];
                    meeting.name = meetingName;
                    meeting.type = (NIMNetCallMediaType)[NTESLiveManager sharedInstance].type;
                    meeting.actor = YES;
                    wself.preMeeting = meeting;
                    NIMNetCallOption *option = [NTESUserUtil fillNetCallOption:meeting];
                    option.bypassStreamingUrl = chatroom.broadcastUrl;
                    
                    if (_bypassType == NTESBypassTypeRoom) {
                        option.bypassTaskConfig= [wself bypassTaskConfig:chatroom];
                    }
                    
                    [[NIMAVChatSDK sharedSDK].netCallManager reserveMeeting:meeting completion:^(NIMNetCallMeeting * _Nonnull currentMeeting, NSError * _Nonnull error) {

                        [wself.capture setMeeting:currentMeeting];
                        if (completion) {
                            completion(error);
                        }
                    }];
                }
                else
                {
                    if (completion) {
                        completion(error);
                    }
                }
            }];
        }
        else
        {
            if (completion) {
                completion(error);
            }
        }
    }];
}

- (NSArray *)bypassTaskConfig:(NIMChatroom *)chatroom
{
    NIMNetCallBypassTaskConfig *bypassTaskConfig = [[NIMNetCallBypassTaskConfig alloc]init];
    
    bypassTaskConfig.taskId = [NSString stringWithFormat:@"%@%@",[NIMSDK sharedSDK].loginManager.currentAccount,[NTESLiveUtil currentTimeStr]];
    bypassTaskConfig.streamingUrl = chatroom.broadcastUrl;
    bypassTaskConfig.serverRecord = [[NTESBundleSetting sharedConfig] bypassStreamingServerRecord];
    bypassTaskConfig.accid = [NIMSDK sharedSDK].loginManager.currentAccount;
    
    return @[bypassTaskConfig];
}

#pragma mark - NTESPreviewInnerViewDelegate
- (void)onRotate:(NIMVideoOrientation)orientation
{
    if (_exitFromLive) {
        [self.previewInnerView makeToast:@"主播未结束直播，不支持旋转"];
        return;
    }
    [self rotateUI:orientation];
}

- (BOOL)interactionDisabled
{
    return self.disableClick;
}

- (void)onStartLiving
{

    __weak typeof(self) weakSelf = self;

    [self requestVideoStreamWithCompletion:^(NSError *error) {
        if (!error) {
            if (!weakSelf.capture.isLiveStream) {
                [weakSelf.capture startLiveStreamHandler:^(NIMNetCallMeeting * _Nonnull meeting, NSError * _Nonnull error) {
                    if (error) {
                        [SVProgressHUD dismiss];
                        weakSelf.disableClick = NO;
                        [weakSelf.previewInnerView makeToast:@"直播初始化失败"];
                        [weakSelf.previewInnerView switchToWaitingUI];
                        DDLogError(@"start error:%@",error);
                    }else
                    {
                        NSString *uid = [NIMSDK sharedSDK].loginManager.currentAccount;
                        UInt64 meetingUid = [[NIMAVChatSDK sharedSDK].netCallManager getMeetingIdWithUserUid:uid];
                        [weakSelf doUpdateChatroomExtWithMeetingUid:meetingUid];
                        
                        //将服务器连麦请求队列清空
                        [[NIMSDK sharedSDK].chatroomManager dropChatroomQueue:weakSelf.chatroom.roomId completion:nil];
                        //发一个全局断开连麦的通知给观众，表示之前的连麦都无效了
                        [weakSelf sendDisconnectedNotify:nil];
                        weakSelf.currentMeeting = meeting;
                        [SVProgressHUD dismiss];
                        weakSelf.disableClick = NO;
                        
                        NTESBypassLiveViewController *vc;
                        
                        if (_bypassType == NTESBypassTypeRoom) {
                            vc = [[NTESRoomBypassLiveViewController alloc]initWithChatroom:weakSelf.chatroom currentMeeting:weakSelf.currentMeeting capture:weakSelf.capture delegate:weakSelf];
                        }
                        else
                        {
                            vc = [[NTESAnchorLiveViewController alloc]initWithChatroom:weakSelf.chatroom currentMeeting:weakSelf.currentMeeting capture:weakSelf.capture delegate:weakSelf];
                        }
                        vc.orientation = weakSelf.orientation;
                        vc.filterModel = [weakSelf.previewInnerView getFilterModel];

                        vc.modalPresentationStyle =  UIModalPresentationFullScreen;
                        dispatch_after(0, dispatch_get_main_queue(), ^{
                            [weakSelf presentViewController:vc animated:NO completion:^{
                                [weakSelf.previewInnerView switchToEndUI];
                            }];
                        });
                        
                    }
                }];
            }
            else
            {
                [SVProgressHUD dismiss];
                weakSelf.disableClick = NO;
            }
        }
        else
        {
            DDLogError(@"start error:%@",error);

            [SVProgressHUD dismiss];
            weakSelf.disableClick = NO;
            [weakSelf.previewInnerView makeToast:@"直播初始化失败"];
            [weakSelf.previewInnerView switchToWaitingUI];
            
        }
    }];
    
}

- (void)onCloseLiving{
    if (self.disableClick) {
        return;
    }
    [self.capture stopVideoCapture];
    //房间推流离开模式，不需要离开聊天室
    if (_exitFromLive) {
        
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
                
        [[NTESLiveManager sharedInstance] removeAllConnectors];
        [[NTESLiveManager sharedInstance] stop];
    }

    if (self.chatroom && !_exitFromLive) {
        [[NIMSDK sharedSDK].chatroomManager exitChatroom:self.chatroom.roomId completion:nil];
    }
    if (self.meetingname) {
        NIMNetCallMeeting *meeting = [[NIMNetCallMeeting alloc] init];
        meeting.name = self.meetingname;
        [[NIMAVChatSDK sharedSDK].netCallManager leaveMeeting:meeting];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)onExitRoom
{
    _exitFromLive = YES;
    self.capture.canContinueLiveStream = YES;
    __weak typeof(self) wself = self;

    //切换到预览的UI
    [self.previewInnerView switchToPreviewUI];
    
}

- (void)onResourceFreed
{
    __weak typeof(self) wself = self;
    if (_exitFromLive) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.capture startPreview: (NIMNetCallMediaType)[NTESLiveManager sharedInstance].type container:self.captureView  handler:^(NSError * error) {
                    [wself.view addSubview:wself.previewInnerView];
                    if (error) {
                            DDLogInfo(@"start error by privacy");
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"直播失败，请检查网络和权限重新开启" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                            [alert showAlertWithCompletionHandler:^(NSInteger index) {
                                [wself dismissViewControllerAnimated:YES completion:nil];
                            }];
                        }
                }];
        });
    }
}

- (void)onCameraRotate
{
    [self.capture switchCamera];
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

#pragma mark - NTESAnchorLiveViewControllerDelegate

- (void)onCloseLiveView
{
    [self.previewInnerView switchToEndUI];
}

#pragma mark - statusBar

- (BOOL)prefersStatusBarHidden
{
    return YES;
}
@end

