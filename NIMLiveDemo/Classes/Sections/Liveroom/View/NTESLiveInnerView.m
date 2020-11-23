//
//  NTESLiveInnerView.m
//  NIMLiveDemo
//
//  Created by chris on 16/4/4.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESLiveInnerView.h"
#import "NTESLiveChatView.h"
#import "NTESLiveLikeView.h"
#import "NTESLivePresentView.h"
#import "NTESLiveCoverView.h"
#import "NTESLiveroomInfoView.h"
#import "NTESTextInputView.h"
#import "NTESLiveManager.h"
#import "UIView+NTES.h"
#import "NTESLiveActionView.h"
#import "NTESTimerHolder.h"
#import "NTESLiveBypassView.h"
#import "NTESMicConnector.h"
#import "NTESGLView.h"
#import "NTESAnchorMicView.h"
#import "NTESNetStatusView.h"
#import "NTESCameraZoomView.h"
#import "NTESNickListView.h"
#import "NTESAnchorPKView.h"
#import "NTESAnchorPkToast.h"
#import "NTESPKInfo.h"

@interface NTESLiveInnerView()<NTESLiveActionViewDelegate,NTESTextInputViewDelegate,NTESTimerHolderDelegate,NTESLiveBypassViewDelegate,NTESLiveCoverViewDelegate,NTESLiveChatViewDelegate>{
    CGFloat _keyBoradHeight;
    NTESTimerHolder *_timer;
    CALayer *_cameraLayer;
    CGSize _lastRemoteViewSize;
}

@property (nonatomic, strong) UIButton *startLiveButton;          //开始直播按钮
@property (nonatomic, strong) UIButton *closeButton;              //关闭直播按钮
@property (nonatomic, strong) UIButton *exitButton;              //主播离开房间按钮
@property (nonatomic, strong) UIButton *cameraButton;             //相机反转按钮

@property (nonatomic, copy)   NSString *roomId;                   //聊天室ID

@property (nonatomic, strong) NTESLiveroomInfoView *infoView;      //直播间信息视图
@property (nonatomic, strong) NTESTextInputView    *textInputView; //输入框
@property (nonatomic, strong) NTESLiveChatView     *chatView;      //聊天窗
@property (nonatomic, strong) NTESLiveActionView   *actionView;    //操作条
@property (nonatomic, strong) NTESLiveLikeView     *likeView;      //爱心视图
@property (nonatomic, strong) NTESLivePresentView  *presentView;   //礼物到达视图
@property (nonatomic, strong) NTESLiveCoverView    *coverView;     //状态覆盖层

@property (nonatomic, strong) NSMutableArray <NTESLiveBypassView *> *bypassViews;
@property (nonatomic, strong) UIView               *glViewContainer;        //接收YUV数据的视图
@property (nonatomic, strong) NTESAnchorMicView    *micView;       //主播是音视频的时候的麦克风图
@property (nonatomic, strong) NTESNickListView     *bypassNickList;  //互动直播昵称
@property (nonatomic, strong) UILabel              *roomIdLabel;      //房间ID

@property (nonatomic, strong) NTESNetStatusView    *netStatusView;    //网络状态视图
@property (nonatomic, strong) UILabel              *anchorVolumeLab;     //主播音量
@property (nonatomic, assign) uint64_t              anchorVolumeTime;

@property (nonatomic, strong) NTESCameraZoomView   *cameraZoomView;

@property (nonatomic) BOOL isActionViewMoveUp;    //actionView上移标识

@property (nonatomic, assign) BOOL  isAnchor;

@property (nonatomic, strong) NTESAnchorPKView *anchorPkView;  //主播pk页面
@property (nonatomic, strong) NTESAnchorPkToast *anchorPkToast; //主播pk信息

@end

@implementation NTESLiveInnerView

- (instancetype)initWithChatroom:(NSString *)chatroomId
                           frame:(CGRect)frame
                        isAnchor:(BOOL)isAnchor
{
    self = [super initWithFrame:frame];
    if (self) {
        _roomId = chatroomId;
        _isAnchor = isAnchor;
        [self setup];
    }
    return self;
}

- (void)dealloc{
    [_chatView.tableView removeObserver:self forKeyPath:@"contentOffset"];
    [_micView removeObserver:self forKeyPath:@"hidden"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public
- (void)addMessages:(NSArray<NIMMessage *> *)messages
{
    [self.chatView addMessages:messages];
}

- (void)addPresentMessages:(NSArray<NIMMessage *> *)messages
{
    for (NIMMessage *message in messages) {
        [self.presentView addPresentMessage:message];
    }
}

- (void)resetZoomSlider;
{
    [self.cameraZoomView reset];
}

- (void)fireLike
{
    [self.likeView fireLike];
}

- (void)updateExitButtonHidden:(BOOL)hidden
{
    [self.exitButton setHidden:hidden];
}

- (void)updateNetStatus:(NIMNetCallNetStatus)status
{
    [self.netStatusView refresh:status];
    [self.netStatusView sizeToFit];
}

- (void)updateConnectorCount:(NSInteger)count
{
    [self.actionView updateInteractButton:count];
}

- (void)refreshChatroom:(NIMChatroom *)chatroom
{
    _roomId = chatroom.roomId;
    [self.infoView refreshWithChatroom:chatroom];
    
    NSString *placeHolder = [NSString stringWithFormat:@"当前直播间ID:%@",chatroom.roomId];
    NTESGrowingTextView *textView = self.textInputView.textView;
    textView.editable = YES;
    textView.placeholderAttributedText = [[NSAttributedString alloc] initWithString:placeHolder attributes:@{NSFontAttributeName:textView.font,NSForegroundColorAttributeName:[UIColor lightGrayColor]}];
}

- (void)addRemoteView:(UIView *)view
                  uid:(NSString *)uid {
    
    if ([NTESLiveManager sharedInstance].role == NTESLiveRoleAnchor){
        NTESLiveBypassView *bypassView = [self bypassViewWithUid:uid];
        [bypassView addRemoteView:view];
    }else{
        NIMChatroom *roomInfo = [[NTESLiveManager sharedInstance] roomInfo:self.roomId];
        if ([uid isEqualToString:roomInfo.creator]) {
            [self.glViewContainer.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            view.frame = self.glViewContainer.bounds;
            view.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
            [_glViewContainer addSubview:view];
        } else {
            NTESLiveBypassView *bypassView = [self bypassViewWithUid:uid];
            [bypassView addRemoteView:view];
        }
    }
}

- (void)updateAnchorPkRemoteView:(NSData *)yuvData
                           width:(NSUInteger)width
                          height:(NSUInteger)height
                             uid:(NSString *)uid {
    if ([uid isEqualToString:_anchorPkView.uid]) {
        [_anchorPkView updateRemoteView:yuvData width:width height:height];
    }
}

- (void)updateBeautify:(BOOL)isBeautify
{
    [self.actionView updateBeautify:isBeautify];
}

- (void)updateflashButton:(BOOL)isOn
{
    [self.actionView updateflashButton:isOn];
}

- (void)updateFocusButton:(BOOL)isOn
{
    [self.actionView updateFocusButton:isOn];
}

- (void)updateMirrorButton:(BOOL)isOn
{
    [self.actionView updateMirrorButton:isOn];
}

- (void)updateQualityButton:(BOOL)isHigh
{
    [self.actionView updateQualityButton:isHigh];
}

- (void)updateWaterMarkButton:(BOOL)isOn
{
    [self.actionView updateWaterMarkButton:isOn];
}

- (CGFloat)getActionViewHeight
{
    return self.actionView.height;
}

#pragma mark - Action

- (void)startLive:(id)sender
{
    [self.startLiveButton setTitle:@"初始化中，请等待..." forState:UIControlStateNormal];
    if ([self.delegate respondsToSelector:@selector(onActionType:sender:)]) {
        [self.delegate onActionType:NTESLiveActionTypeLive sender:self.startLiveButton];
    }
}

- (void)onRotateCamera:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(onActionType:sender:)]) {
        [self.delegate onActionType:NTESLiveActionTypeCamera sender:self.cameraButton];
    }

}
- (void)onClose:(id)sender
{
    if ([NTESLiveManager sharedInstance].role == NTESLiveRoleAnchor) {
        if ([self.delegate respondsToSelector:@selector(onCloseLiving)]) {
            [self.delegate onCloseLiving];
        }
    }else{
        if ([self.delegate respondsToSelector:@selector(onClosePlaying)]) {
            [self.delegate onClosePlaying];
        }
    }
}

- (void)onExit:(id)sender
{
    if ([NTESLiveManager sharedInstance].role == NTESLiveRoleAnchor) {
        if ([self.delegate respondsToSelector:@selector(onExitRoom)]) {
            [self.delegate onExitRoom];
        }
    }
}

#pragma mark - Notification

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    _keyBoradHeight = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    [self layoutSubviews];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    _keyBoradHeight = 0;
    [self layoutSubviews];
}

- (void)adjustViewPosition
{
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (_keyBoradHeight)
    {
        self.textInputView.bottom = self.height - _keyBoradHeight;
        self.chatView.bottom = self.textInputView.top;
    }
    else
    {
        CGFloat rowHeight = 35.f;
        self.textInputView.bottom = self.height + 44.f;
        if (_isActionViewMoveUp) {
            _chatView.bottom = self.height - 3 * rowHeight -  30.f;
        }
        else
        {
            _chatView.bottom = self.height - rowHeight - 20.f;
        }
    }
    CGFloat padding = 20.f;
    CGFloat delta = self.chatView.tableView.contentOffset.y;
    CGFloat bottom  = (delta < 0) ? self.chatView.top - delta : self.chatView.top;
    self.presentView.bottom = bottom - padding;
    
    self.roomIdLabel.top = self.infoView.bottom + 10.f;
    self.roomIdLabel.left = 10.f;
    self.roomIdLabel.width = [self getRoomIdLabelWidth];
    self.anchorVolumeLab.frame = CGRectMake(_roomIdLabel.left,
                                         _roomIdLabel.bottom + 16.0,
                                         _roomIdLabel.width,
                                         _roomIdLabel.height);
    
    self.likeView.bottom = self.actionView.top;
    self.likeView.right  = self.width - 10.f;

    self.glViewContainer.size = self.size;
    
    self.bypassNickList.frame = CGRectMake(_roomIdLabel.right + padding,
                                           _infoView.top,
                                           _exitButton.left - padding*2 - _infoView.right,
                                           _bypassNickList.estimationHeight);
    self.netStatusView.centerX = self.width * .5f;
    self.netStatusView.top = 70.f;
    
    self.actionView.left = 0;
    self.actionView.bottom = self.height - 10.f;
    self.actionView.width = self.width;
    
    //互动直播连麦布局
    bottom = 10.0f + 32.0 + 8.0;
    __weak typeof(self) weakSelf = self;
    if ([NTESLiveManager sharedInstance].orientation == NIMVideoOrientationLandscapeRight) {
        CGFloat width = (self.width - 8.0*4)/3;
        CGFloat height = width/1.7;
        [_bypassViews enumerateObjectsUsingBlock:^(NTESLiveBypassView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.frame = CGRectMake(weakSelf.width - (width + 8.0) * (idx + 1),
                                   weakSelf.height - bottom - (height + 8.0),
                                   width,
                                   height);
        }];
        
    } else {
        CGFloat height = (self.height - (self.closeButton.bottom + 8.0) - bottom - 2*8.0)/3;
        CGFloat width = height / 1.7;
        [_bypassViews enumerateObjectsUsingBlock:^(NTESLiveBypassView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.frame = CGRectMake(weakSelf.width - padding - width,
                                   weakSelf.height - bottom - (height + 8.0) * (idx + 1),
                                   width,
                                   height);
        }];
    }
    
    if ([NTESLiveManager sharedInstance].orientation == NIMVideoOrientationLandscapeRight) {
        self.cameraZoomView.centerY = self.infoView.centerY;
        self.cameraZoomView.centerX = self.width * .5f;
        self.cameraZoomView.height = 22.f;
        self.cameraZoomView.width = 225.f;
    }
    else
    {
        self.cameraZoomView.top = self.roomIdLabel.bottom + 20.f;
        self.cameraZoomView.centerX = self.width * .5f;
        self.cameraZoomView.height = 22.f;
        self.cameraZoomView.width = self.width - 2 * 30.f;
    }
    
    [self bringSubviewToFront:self.bypassNickList];
}

#pragma mark - NTESLiveActionViewDelegate

- (void)     onActionType:(NTESLiveActionType)type sender:(id)sender
{
    switch (type) {
        case NTESLiveActionTypeLike:
            [self.likeView fireLike];
        break;
        
        case NTESLiveActionTypeChat:
        {
            self.textInputView.hidden = NO;
            UITextView *textview = (UITextView*)[self getTextViewFromTextInputView];
            [textview becomeFirstResponder];
        }
        break;
            
        case NTESLiveActionTypeMoveUp:
        {
            [self actionViewMoveToggle];
        }
        break;
            
        case NTESLiveActionTypeZoom:
        {
            self.cameraZoomView.hidden = !self.cameraZoomView.hidden;
            UIButton * button = (UIButton *)sender;
            [button setImage:[UIImage imageNamed:self.cameraZoomView.hidden ? @"icon_camera_zoom_n" :@"icon_camera_zoom_on_n"] forState:UIControlStateNormal];
            [button setImage:[UIImage imageNamed:self.cameraZoomView.hidden ? @"icon_camera_zoom_p" :@"icon_camera_zoom_on_p"] forState:UIControlStateHighlighted];
        }
            break;
        default:
        break;
    }
    
    
    if ([self.delegate respondsToSelector:@selector(onActionType:sender:)]) {
        [self.delegate onActionType:type sender:sender];
    }
}

#pragma mark - NTESTextInputViewDelegate
- (void)didSendText:(NSString *)text
{
    if ([self.delegate respondsToSelector:@selector(didSendText:)]) {
        [self.delegate didSendText:text];
    }
}

- (void)willChangeHeight:(CGFloat)height
{
    [self adjustViewPosition];
}

#pragma mark - NTESLiveBypassViewDelegate
- (void)didConfirmExitBypassWithUid:(NSString *)uid
{
    if ([self.delegate respondsToSelector:@selector(onCloseBypassingWithUid:)]) {
        [self.delegate onCloseBypassingWithUid:uid];
    }
}


#pragma mark - NTESLiveChatViewDelegate
- (void)onTapChatView:(CGPoint)point
{
    if ([self.delegate respondsToSelector:@selector(onTapChatView:)]) {
        [self.delegate onTapChatView:point];
    }
}

#pragma mark - NTESTimerHolderDelegate
- (void)onNTESTimerFired:(NTESTimerHolder *)holder
{
    __weak typeof(self) wself = self;
    DDLogInfo(@"start refresh chatroom info");
    [[NIMSDK sharedSDK].chatroomManager fetchChatroomInfo:self.roomId completion:^(NSError *error, NIMChatroom *chatroom) {
        if (!error) {
            DDLogInfo(@"refresh chatroom info OK");
            [wself.infoView refreshWithChatroom:chatroom];
        }else{
            DDLogInfo(@"refresh chatroom info error : %@",error);
        }
    }];
}

#pragma mark - Private
- (UIView *)getTextViewFromTextInputView
{
    for (UIView *view in self.textInputView.subviews) {
        if ([view isKindOfClass:[NTESGrowingTextView class]]) {
            for (UIView * subview in view.subviews) {
                if ([subview isKindOfClass:[UITextView class]]) {
                    return subview;
                }
            }
        }
    }
    return nil;
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
        self.roomIdLabel.hidden = YES;
        self.anchorVolumeLab.hidden = YES;
        [self.startLiveButton setTitle:@"开始直播" forState:UIControlStateNormal];
    }
    
    [self cleanBypassUI];
    
    //[self.bypassView refresh:nil status:NTESLiveBypassViewStatusNone];
    [self updateUserOnMic];
}


- (void)switchToAudioTypeExitView
{
    self.micView.hidden = YES;
    self.exitButton.hidden = YES;
    self.infoView.hidden = YES;
    self.likeView.hidden = YES;
    self.chatView.hidden = YES;
    self.presentView.hidden = YES;
    self.actionView.hidden  = YES;
    self.cameraButton.hidden = YES;
    self.roomIdLabel.hidden = YES;
    self.anchorVolumeLab.hidden = YES;
    self.netStatusView.hidden = YES;

    [self switchToWaitingUI];
}

- (void)switchToPlayingUI
{
    DDLogInfo(@"switch to playing UI");
    self.coverView.hidden = YES;
    self.textInputView.hidden = YES;
    self.micView.hidden = [NTESLiveManager sharedInstance].type != NIMNetCallMediaTypeAudio;
    
    _localDisplayView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    [_anchorPkView removeFromSuperview];
    _anchorPkView = nil;
    
    NIMChatroom *room = [[NTESLiveManager sharedInstance] roomInfo:self.roomId];
    if (!room) {
        DDLogInfo(@"chat room has not entered, ignore show playing UI");
        return;
    }
    self.startLiveButton.hidden = YES;
    self.infoView.hidden = NO;
    self.likeView.hidden = NO;
    self.chatView.hidden = NO;
    self.presentView.hidden = NO;
    self.actionView.hidden  = NO;
    self.cameraButton.hidden = NO;
    self.roomIdLabel.hidden = NO;
    self.anchorVolumeLab.hidden = NO;
    self.netStatusView.hidden = [NTESLiveManager sharedInstance].role == NTESLiveRoleAudience;

    //更新bypass view
    [self refreshBypassUI];

    self.glViewContainer.hidden = YES;
    if ([NTESLiveManager sharedInstance].role == NTESLiveRoleAudience
        || [NTESLiveManager sharedInstance].type == NIMNetCallMediaTypeAudio) {
        [self.actionView setActionType:NTESLiveActionTypeCamera disable:YES];
        [self.actionView setActionType:NTESLiveActionTypeBeautify disable:YES];
        [self.actionView setActionType:NTESLiveActionTypeQuality disable:YES];
    }
    self.actionView.userInteractionEnabled = YES;
    [self.actionView setActionType:NTESLiveActionTypeInteract disable:NO];
}

- (void)switchToAnchorReenterView:(NTESMicConnector *)connector
{
    NSLog(@"YAT switchToAnchorReenterView %@",connector.uid);
    if (_localDisplayView.superview == self) {
        [_localDisplayView removeFromSuperview];
    }
    [self switchToBypassingUI:connector];
}

- (void)switchToAudienceBigViewUI
{
    self.glViewContainer.hidden = YES;
    
    NTESLiveBypassView *view = [self bypassViewWithUid:[[NIMSDK sharedSDK].loginManager currentAccount]];
    [_bypassViews removeObject:view];
    [view removeFromSuperview];
    
    //自己画面变成大画面
    _localDisplayView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    [self insertSubview:_localDisplayView atIndex:0];
}


- (void)switchToLinkingUI
{
    DDLogInfo(@"switch to Linking UI");
    self.startLiveButton.hidden = YES;
    self.closeButton.hidden = NO;
    self.cameraButton.hidden = YES;
    self.roomIdLabel.hidden = YES;
    self.anchorVolumeLab.hidden = YES;
    
    [self.coverView refreshWithChatroom:self.roomId status:NTESLiveCoverStatusLinking];
    self.coverView.hidden = NO;
}

- (void)switchToEndUI
{
    DDLogInfo(@"switch to End UI");
    [self.coverView refreshWithChatroom:self.roomId status:NTESLiveCoverStatusFinished];
    self.coverView.hidden = NO;
    self.roomIdLabel.hidden = YES;
    self.anchorVolumeLab.hidden = YES;
    if (_anchorPkToast) {
        [self removePkToast];
    }
    self.netStatusView.hidden = YES;
    if ([NTESLiveManager sharedInstance].role == NTESLiveRoleAnchor) {
        self.closeButton.hidden = YES;
        self.cameraButton.hidden = YES;
    }else{
        self.closeButton.hidden = NO;
        self.cameraButton.hidden = YES;
    }
}

- (void)switchToPkUIWithNick:(NSString *)nick uid:(NSString *)uid {
    DDLogInfo(@"switch to Pk UI");
    if (!_isAnchor) {
        return;
    }
    BOOL isAudio = ([NTESLiveManager sharedInstance].type == NIMNetCallMediaTypeAudio);
    if (isAudio) {
        if ([NTESLiveManager sharedInstance].orientation == NIMVideoOrientationLandscapeRight) {
            self.micView.frame = CGRectMake(0, _netStatusView.bottom + 4.0, self.width/2, (self.width/2)*9/16);
        } else {
            self.micView.frame = CGRectMake(0, _netStatusView.bottom + 4.0, self.width/2, (self.width/2)*16/9);
        }
        self.anchorPkView.frame = CGRectMake(_micView.right, _micView.top, _micView.width, _micView.height);
        [self insertSubview:_anchorPkView aboveSubview:_micView];
    } else {
        if (_localDisplayView) {
            [_localDisplayView removeFromSuperview];
            if ([NTESLiveManager sharedInstance].orientation == NIMVideoOrientationLandscapeRight) {
                _localDisplayView.frame = CGRectMake(0, _netStatusView.bottom + 4.0, self.width/2, (NSInteger)(self.width/2)*9/16);
                _localDisplayView.centerY = self.height / 2;
            } else {
                _localDisplayView.frame = CGRectMake(0, _netStatusView.bottom + 4.0, self.width/2, (NSInteger)(self.width/2)*16/9);
            }
            
            [self insertSubview:_localDisplayView atIndex:0];
            self.anchorPkView.frame = CGRectMake(_localDisplayView.right, _localDisplayView.top, _localDisplayView.width, (NSInteger)_localDisplayView.height);
            [self insertSubview:_anchorPkView aboveSubview:_localDisplayView];
            NSLog(@"pkleft frame = %@",NSStringFromCGRect(_localDisplayView.frame));
            NSLog(@"pkright frame = %@",NSStringFromCGRect(_anchorPkView.frame));
        }
    }
    
    _anchorPkView.nick = nick;
    _anchorPkView.uid = uid;
    self.anchorPkView.hidden = NO;
    if (!_anchorPkToast) {
        _anchorPkToast = [NTESAnchorPkToast instanceTimerToast];
        _anchorPkToast.top = _anchorPkView.bottom;
//        [self insertSubview:_anchorPkToast aboveSubview:_anchorPkView];
        [self addSubview:_anchorPkToast];
    }
}

- (void)switchToResumePkUI {
    DDLogInfo(@"switch to Pk before UI");
    if (!_isAnchor) {
        return;
    }
    
    [_anchorPkView removeFromSuperview];
    _anchorPkView = nil;
    
    [_anchorPkToast removeFromSuperview];
    _anchorPkView = nil;
    
    BOOL isAudio = ([NTESLiveManager sharedInstance].type == NIMNetCallMediaTypeAudio);
    if (isAudio) {
        self.micView.frame = self.bounds;
    } else {
        [self.localDisplayView removeFromSuperview];
        self.localDisplayView.frame = self.bounds;
        [self.superview insertSubview:_localDisplayView atIndex:0];
    }
}

- (void)cleanBypassUI {
    [_bypassViews enumerateObjectsUsingBlock:^(NTESLiveBypassView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"--zgn-- 移除bypass view:[%@]", obj.uid);
        [obj removeFromSuperview];
    }];
    [_bypassViews removeAllObjects];
}


- (void)refreshBypassUIWithConnector:(NTESMicConnector *)connector {
    NSLog(@"YAT refreshBypassUIWithConnector uid %@",connector.uid);
    [self refreshBypassUI];

    NTESLiveBypassView *bypassView = [self bypassViewWithUid:connector.uid];
    NTESLiveBypassViewStatus status;
    if ([connector.uid isEqualToString:[[NIMSDK sharedSDK].loginManager currentAccount]]) {
        status = connector.type == NIMNetCallMediaTypeAudio? NTESLiveBypassViewStatusLocalAudio: NTESLiveBypassViewStatusLocalVideo;
    } else {
        status = connector.type == NIMNetCallMediaTypeAudio ? NTESLiveBypassViewStatusStreamingAudio : NTESLiveBypassViewStatusStreamingVideo;
    }
    [bypassView refresh:connector status:status];
}

- (void)refreshBypassUI {
    
    if ([_delegate isPlayerPlaying] && ![_delegate isAudioMode]) {
        NSLog(@"YAT isPlayerPlaying");
        [_bypassViews enumerateObjectsUsingBlock:^(NTESLiveBypassView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperview];
        }];
        [_bypassViews removeAllObjects];
        return;
    } else {
        NSLog(@"YAT refrash connectorsOnMic");

        __block NSMutableIndexSet *delIndex = [NSMutableIndexSet indexSet];
        NSMutableArray *connectorsOnMic = [NTESLiveManager sharedInstance].connectorsOnMic;
        __weak typeof(self) weakSelf = self;
        [_bypassViews enumerateObjectsUsingBlock:^(NTESLiveBypassView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            __block BOOL isExist = NO;
            [connectorsOnMic enumerateObjectsUsingBlock:^(NTESMicConnector *_Nonnull d_obj, NSUInteger d_idx, BOOL * _Nonnull d_stop) {
                if ([obj.uid isEqualToString:d_obj.uid]) {
                    isExist = YES;
                    *d_stop = YES;
                }
            }];
            if (!isExist) {
                NSLog(@"--zgn-- 移除bypass view:[%@]", obj.uid);
                [delIndex addIndex:idx];
                [obj removeFromSuperview];
            }
        }];
        
        if (delIndex.count != 0) {
            [_bypassViews removeObjectsAtIndexes:delIndex];
        }
        
        [connectorsOnMic enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [weakSelf addBypassViewWithConnector:obj];
        }];
    }
    
    [self updateUserOnMic];
}

- (void)switchToBypassStreamingUI:(NTESMicConnector *)connector
{
    DDLogInfo(@"switch to bypass streaming UI connector id %@",connector.uid);
    
    self.startLiveButton.hidden = YES;
    self.infoView.hidden = NO;
    self.likeView.hidden = NO;
    self.chatView.hidden = NO;
    self.presentView.hidden = NO;
    self.actionView.hidden  = NO;
    self.textInputView.hidden = NO;
    self.netStatusView.hidden = NO;
    self.cameraButton.hidden = NO;
    self.roomIdLabel.hidden = NO;
    self.anchorVolumeLab.hidden = NO;

    NTESLiveBypassViewStatus status = connector.type == NIMNetCallMediaTypeAudio? NTESLiveBypassViewStatusStreamingAudio: NTESLiveBypassViewStatusStreamingVideo;
    
    [self refreshBypassUI];
    NTESLiveBypassView *bypassView = [self bypassViewWithUid:connector.uid];
    [bypassView refresh:connector status:status];
    
    //[self.bypassView refresh:connector status:status];
    self.glViewContainer.hidden = YES;
    [self updateUserOnMic];
}

- (void)switchToBypassingUI:(NTESMicConnector *)connector
{
    DDLogInfo(@"switch to bypassing UI connector id %@",connector.uid);
    self.startLiveButton.hidden = YES;
    self.infoView.hidden = NO;
    self.likeView.hidden = NO;
    self.chatView.hidden = NO;
    self.presentView.hidden = NO;
    self.actionView.hidden  = NO;
    self.textInputView.hidden = NO;
    self.netStatusView.hidden = YES;
    self.roomIdLabel.hidden = NO;
    self.anchorVolumeLab.hidden = NO;
    
    [self refreshBypassUIWithConnector:connector];
    //[self.bypassView refresh:connector status:status];
    self.glViewContainer.hidden = NO;
    [self.actionView setActionType:NTESLiveActionTypeCamera disable: [NTESLiveManager sharedInstance].bypassType == NIMNetCallMediaTypeAudio];
    [self.actionView setActionType:NTESLiveActionTypeBeautify disable:[NTESLiveManager sharedInstance].bypassType == NIMNetCallMediaTypeAudio];
    [self.actionView setActionType:NTESLiveActionTypeInteract disable:YES];
    [self updateUserOnMic];
}

- (void)switchToBypassLoadingUI:(NTESMicConnector *)connector
{
    DDLogInfo(@"switch to bypass loading UI connector id %@",connector.uid);
    
    [self refreshBypassUI];
    NTESLiveBypassView *bypassView = [self bypassViewWithUid:connector.uid];
    [bypassView refresh:connector status:NTESLiveBypassViewStatusLoading];
//    [self.bypassView refresh:connector status:NTESLiveBypassViewStatusLoading];
    [self setNeedsLayout];
}

- (void)addPkToastWithPkInfo:(NTESPKInfo *)info
{
    if (!_anchorPkToast) {
        _anchorPkToast = [NTESAnchorPkToast instanceNickToastWithSrcName:info.inviter dstNick:info.invitee];
        _anchorPkToast.bottom = [NTESLiveManager sharedInstance].orientation == NIMVideoOrientationLandscapeRight ? self.actionView.top - 5: self.bottom - 100;
    }
    [self addSubview:_anchorPkToast];
}

- (void)removePkToast
{
    if (_anchorPkToast) {
        [_anchorPkToast removeFromSuperview];
        _anchorPkToast = nil;
    }
}

- (void)updateAnchorVolume:(UInt16)volume {
    uint64_t curTime = [[NSDate date] timeIntervalSince1970]*1000;
    if (curTime - _anchorVolumeTime > 1000) {
        _anchorVolumeLab.text = [NSString stringWithFormat:@"音量：%d", volume];
        _anchorVolumeTime = curTime;
    }
}

- (void)updateUserVolume:(UInt16)volume uid:(NSString *)uid {
    NTESLiveBypassView *view = [self bypassViewWithUid:uid];
    view.volume = volume;
}

//- (void)switchToBypassExitConfirmUI
//{
//    DDLogInfo(@"switch to bypass exit confirm UI");
//
//    [self.bypassView refresh:nil status:NTESLiveBypassViewStatusExitConfirm];
//    [self setNeedsLayout];
//}

- (void)setup
{
    [self addSubview:self.startLiveButton];
    [self addSubview:self.glViewContainer];
    [self addSubview:self.micView];
    [self addSubview:self.bypassNickList];
    [self addSubview:self.likeView];
    [self addSubview:self.presentView];
    [self addSubview:self.chatView];
    [self addSubview:self.actionView];
    [self addSubview:self.infoView];
    [self addSubview:self.textInputView];
    [self addSubview:self.coverView];
    [self addSubview:self.closeButton];
    [self addSubview:self.exitButton];
    [self addSubview:self.netStatusView];
    [self addSubview:self.roomIdLabel];
    [self addSubview:self.cameraZoomView];
    [self addSubview:self.anchorVolumeLab];
    [self adjustViewPosition];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [self.chatView.tableView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    [self.micView addObserver:self forKeyPath:@"hidden" options:NSKeyValueObservingOptionNew context:nil];
    _timer = [[NTESTimerHolder alloc] init];
    [_timer startTimer:60 delegate:self repeats:YES];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentOffset"]) {
        CGPoint point = [change[@"new"] CGPointValue];
        CGFloat padding = 20.f;
        CGFloat bottom = (point.y < 0) ? self.chatView.top - point.y : self.chatView.top;
        self.presentView.bottom = bottom - padding;
    }
    if ([keyPath isEqualToString:@"hidden"]) {
        BOOL hidden = [change[@"new"] boolValue];
        if (hidden)
        {
            [self.micView stopAnimating];
        }
        else
        {
            [self.micView startAnimating];
        }
    }
}

-(void)actionViewMoveToggle
{
    _isActionViewMoveUp = !_isActionViewMoveUp;
    CGFloat rowHeight = 35;
    [self.actionView firstLineViewMoveToggle:_isActionViewMoveUp];
    if (_isActionViewMoveUp) {
        [UIView animateWithDuration:0.5 animations:^{
            _chatView.bottom = self.height - 3 * rowHeight - 30;
        }];
    }
    else
    {
        [UIView animateWithDuration:0.5 animations:^{
            _chatView.bottom = self.height - rowHeight - 20;
        }];
    }
}

- (CGFloat)getRoomIdLabelWidth
{
    CGRect rectTitle = [_roomIdLabel.text boundingRectWithSize:CGSizeMake(999, 30)
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                    attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:9.f]}
        
                                                       context:nil];
    CGFloat width = self.infoView.width;
    if (rectTitle.size.width > self.infoView.width) {
        width = rectTitle.size.width + 10.f;
    }
    
    return width;
}

- (void)updateUserOnMic
{
    NSMutableArray *nicks = [NSMutableArray array];
    [[NTESLiveManager sharedInstance].connectorsOnMic enumerateObjectsUsingBlock:^(NTESMicConnector * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *nickString = (obj.nick.length == 0 ? @"null" : obj.nick);
        [nicks insertObject:nickString atIndex:0];
    }];

    _bypassNickList.hidden = (nicks.count == 0);
    _bypassNickList.nicks = nicks;
}

#pragma mark - NTESLiveCoverViewDelegate
- (void)didPressBackButton
{
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Get
- (UIButton *)startLiveButton
{
    if (!_startLiveButton) {
        _startLiveButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *backgroundImageNormal = [[UIImage imageNamed:@"btn_round_rect_normal"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10) resizingMode:UIImageResizingModeStretch];
        UIImage *backgroundImageHighlighted = [[UIImage imageNamed:@"btn_round_rect_pressed"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10) resizingMode:UIImageResizingModeStretch];
        [_startLiveButton setBackgroundImage:backgroundImageNormal forState:UIControlStateNormal];
        [_startLiveButton setBackgroundImage:backgroundImageHighlighted forState:UIControlStateHighlighted];
        [_startLiveButton setTitleColor:UIColorFromRGB(0x238efa) forState:UIControlStateNormal];
        [_startLiveButton addTarget:self action:@selector(startLive:) forControlEvents:UIControlEventTouchUpInside];
        _startLiveButton.size = CGSizeMake(215, 46);
        _startLiveButton.center = self.center;
        _startLiveButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    }
    return _startLiveButton;
}

- (NTESTextInputView *)textInputView
{
    if (!_textInputView) {
        CGFloat height = 44.f;
        _textInputView = [[NTESTextInputView alloc] initWithFrame:CGRectMake(0, 0, self.width, height)];
        _textInputView.delegate = self;
        _textInputView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        _textInputView.hidden = YES;
        NTESGrowingTextView *textView = _textInputView.textView;
        NSString *placeHolder = @"聊天室连接中，暂时无法发言";
        textView.editable = NO;
        textView.placeholderAttributedText = [[NSAttributedString alloc] initWithString:placeHolder attributes:@{NSFontAttributeName:textView.font,NSForegroundColorAttributeName:[UIColor lightGrayColor]}];
    }
    return _textInputView;
}

- (NTESLiveChatView *)chatView
{
    if (!_chatView) {
        CGFloat height = 85.f;
        CGFloat width  = 200.f;
        _chatView = [[NTESLiveChatView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        _chatView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _chatView.hidden = YES;
        _chatView.delegate = self;
    }
    return _chatView;
}

- (NTESLiveActionView *)actionView
{
    if (!_actionView) {
        _actionView = [[NTESLiveActionView alloc] initWithFrame:CGRectZero];
        [_actionView sizeToFit];
        _actionView.delegate = self;
        _actionView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
        _actionView.hidden = YES;
        if ([NTESLiveManager sharedInstance].type == NIMNetCallMediaTypeAudio) {
            [self.actionView setActionType:NTESLiveActionTypeCamera disable:YES];
        }
    }
    return _actionView;
}

- (NTESLiveLikeView *)likeView
{
    if (!_likeView) {
        CGFloat width  = 50.f;
        CGFloat height = 300.f;
        _likeView = [[NTESLiveLikeView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        _likeView.hidden = YES;
    }
    return _likeView;
}

- (NTESLivePresentView *)presentView
{
    if(!_presentView){
        CGFloat width  = 200.f;
        CGFloat height = 96.f;
        _presentView = [[NTESLivePresentView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        _presentView.bottom = self.actionView.top;
        _presentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _presentView.hidden = YES;
    }
    return _presentView;
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

- (NTESLiveroomInfoView *)infoView
{
    if (!_infoView) {
        _infoView = [[NTESLiveroomInfoView alloc] initWithFrame:CGRectMake(10, 10, 0, 0)];
        [_infoView sizeToFit];
        _infoView.hidden = YES;
    }
    return _infoView;
}

- (UIButton *)closeButton
{
    if(!_closeButton)
    {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton addTarget:self action:@selector(onClose:) forControlEvents:UIControlEventTouchUpInside];
        _closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        [_closeButton setTitle:@"结束" forState:UIControlStateNormal];
        [_closeButton setBackgroundColor:[UIColor redColor]];
        _closeButton.size = CGSizeMake(44, 30);
        _closeButton.top = 5.f;
        _closeButton.right = self.width - 5.f;
        _closeButton.layer.masksToBounds = YES;
        _closeButton.layer.cornerRadius = 5;
    }
    return _closeButton;
}

- (UIButton *)exitButton
{
    if(!_exitButton)
    {
        _exitButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_exitButton addTarget:self action:@selector(onExit:) forControlEvents:UIControlEventTouchUpInside];
        _exitButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        [_exitButton setTitle:@"离开" forState:UIControlStateNormal];
        [_exitButton setBackgroundColor:[UIColor blueColor]];
        _exitButton.size = CGSizeMake(44, 30);
        _exitButton.top = 5.f;
        _exitButton.right = self.closeButton.left - 5.f;
        _exitButton.hidden = YES;
        _exitButton.layer.masksToBounds = YES;
        _exitButton.layer.cornerRadius = 5;
    }
    return _exitButton;
}



- (UIButton *)cameraButton
{
    if (!_cameraButton) {
        _cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cameraButton.tag = NTESLiveActionTypeCamera;
        [_cameraButton setImage:[UIImage imageNamed:@"icon_camera_rotate_n"] forState:UIControlStateNormal];
        [_cameraButton setImage:[UIImage imageNamed:@"icon_camera_rotate_p"] forState:UIControlStateHighlighted];
        [_cameraButton sizeToFit];
        [_cameraButton addTarget:self action:@selector(onRotateCamera:) forControlEvents:UIControlEventTouchUpInside];
        _cameraButton.size = CGSizeMake(44, 44);
        _cameraButton.top = 5.f;
        _cameraButton.right = _closeButton.left - 10.f;

    }
    return _cameraButton;
}

- (UIView *)glViewContainer {
    if (!_glViewContainer) {
        _glViewContainer = [[NTESGLView alloc] initWithFrame:self.bounds];
        _glViewContainer.contentMode = UIViewContentModeScaleAspectFill;
        _glViewContainer.hidden = YES;
    }
    return _glViewContainer;
}

- (NTESAnchorMicView *)micView
{
    if (!_micView) {
        _micView = [[NTESAnchorMicView alloc] initWithFrame:self.bounds];
        _micView.hidden = YES;
    }
    return _micView;
}

- (NTESNickListView *)bypassNickList {
    if (!_bypassNickList) {
        _bypassNickList = [[NTESNickListView alloc] initWithFrame:CGRectZero];
    }
    return _bypassNickList;
}

- (UILabel *)roomIdLabel
{
    if (!_roomIdLabel) {
        _roomIdLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _roomIdLabel.backgroundColor = UIColorFromRGBA(0x0,0.6);
        _roomIdLabel.textColor = UIColorFromRGB(0xffffff);
        _roomIdLabel.font = [UIFont systemFontOfSize:9.f];
        _roomIdLabel.text =[NSString stringWithFormat:@"房间ID:%@",_roomId];
        _roomIdLabel.textAlignment = NSTextAlignmentCenter;
        _roomIdLabel.layer.masksToBounds = YES;
        _roomIdLabel.layer.cornerRadius = 8.f;
        CGRect rectTitle = [_roomIdLabel.text boundingRectWithSize:CGSizeMake(999, 30)
                                                options:NSStringDrawingUsesLineFragmentOrigin
                                             attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:9.f]}
                                                context:nil];
        _roomIdLabel.height = rectTitle.size.height + 8.f ;
    }
    return _roomIdLabel;
}

- (NTESCameraZoomView*)cameraZoomView
{
    if(!_cameraZoomView)
    {
        _cameraZoomView = [[NTESCameraZoomView alloc]initWithFrame:CGRectZero];
        _cameraZoomView.hidden = YES;
    }
    return _cameraZoomView;
}


- (NTESNetStatusView *)netStatusView
{
    if (!_netStatusView) {
        _netStatusView = [[NTESNetStatusView alloc] initWithFrame:CGRectZero];
        //没有回调之前，默认为较好的网络情况
        [_netStatusView refresh:NIMNetCallNetStatusGood];
        [_netStatusView sizeToFit];
        _netStatusView.hidden = YES;
        [self setNeedsLayout];
    }
    return _netStatusView;
}

- (UILabel *)anchorVolumeLab {
    if (!_anchorVolumeLab) {
        _anchorVolumeLab = [[UILabel alloc] init];
        _anchorVolumeLab.font = [UIFont systemFontOfSize:13.f];
        _anchorVolumeLab.backgroundColor = [UIColor clearColor];
        _anchorVolumeLab.textColor = UIColorFromRGB(0xffffff);
    }
    return _anchorVolumeLab;
}

#pragma mark - 连麦视图
//添加连麦视图
- (NTESLiveBypassView *)addBypassViewWithConnector:(NTESMicConnector *)connector {
    
    NSLog(@"YAT addBypassViewWithConnector %@",connector.uid);
    __block BOOL isAdd = YES;
    __block NTESLiveBypassView *ret = nil;
    [_bypassViews enumerateObjectsUsingBlock:^(NTESLiveBypassView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.uid isEqualToString:connector.uid]) {
            isAdd = NO;
            ret = obj;
            *stop = YES;
        }
    }];
    
    if (isAdd) {
        NSLog(@"YAT really addBypassViewWithConnector %@",connector.uid);
        NTESLiveBypassView *bypassView = [[NTESLiveBypassView alloc] initWithFrame:CGRectZero];
        bypassView.isAnchor = _isAnchor;
        bypassView.uid = connector.uid;
        bypassView.delegate = self;
        if ([connector.uid isEqualToString:[[NIMSDK sharedSDK].loginManager currentAccount]]) {
            bypassView.localVideoDisplayView = _localDisplayView;
        }
        [bypassView sizeToFit];
        if (!_bypassViews) {
            _bypassViews = [NSMutableArray array];
        }
        if (connector.type == NIMNetCallMediaTypeAudio) {
            if (connector.state == NTESLiveMicStateConnected) {
                [bypassView refresh:nil status:NTESLiveBypassViewStatusStreamingAudio];
            } else if (connector.state == NTESLiveMicStateConnecting) {
                [bypassView refresh:nil status:NTESLiveBypassViewStatusLoading];
            } else {
                [bypassView refresh:nil status:NTESLiveBypassViewStatusPlayingAndBypassingAudio];
            }
        } else {
            if (connector.state == NTESLiveMicStateConnected) {
                [bypassView refresh:nil status:NTESLiveBypassViewStatusStreamingVideo];
            } else if (connector.state == NTESLiveMicStateConnecting) {
                [bypassView refresh:nil status:NTESLiveBypassViewStatusLoading];
            } else {
                [bypassView refresh:nil status:NTESLiveBypassViewStatusPlaying];
            }
        }
        
        [_bypassViews addObject:bypassView];
        [self insertSubview:bypassView belowSubview:self.actionView];
        ret = bypassView;
        [self layoutIfNeeded];
        NSLog(@"--zgn-- 添加bypass view:[%@]", bypassView.uid);
    }
    return ret;
}

//查询连麦视图
- (NTESLiveBypassView *)bypassViewWithUid:(NSString *)uid {
    __block NTESLiveBypassView *ret = nil;
    [_bypassViews enumerateObjectsUsingBlock:^(NTESLiveBypassView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.uid isEqualToString:uid]) {
            ret = obj;
            *stop = YES;
        }
    }];
    return ret;
}

#pragma mark - PK视图
- (NTESAnchorPKView *)anchorPkView {
    if (!_anchorPkView) {
        _anchorPkView = [[NTESAnchorPKView alloc] init];
        _anchorPkView.nick = @"阿拉蕾";
        BOOL isAudio = ([NTESLiveManager sharedInstance].type == NIMNetCallMediaTypeAudio);
        _anchorPkView.status = (isAudio ? NTESPKViewStatusAudioPlaying : NTESPKViewStatusVideoPlaying);
        _anchorPkView.delegate = self.viewController;
    }
    return _anchorPkView;
}

@end
