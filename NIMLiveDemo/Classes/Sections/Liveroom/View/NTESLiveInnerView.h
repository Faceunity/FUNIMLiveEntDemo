//
//  NTESLiveInnerView.h
//  NIMLiveDemo
//
//  Created by chris on 16/4/4.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <NELivePlayerFramework/NELivePlayerFramework.h>
#import "NTESLiveViewDefine.h"

@class NTESMicConnector;
@class NTESPKInfo;

@protocol NTESLiveInnerViewDelegate <NSObject>

- (BOOL)isPlayerPlaying;
- (BOOL)isAudioMode;

@optional

- (void)onCloseLiving;
- (void)onExitRoom;
- (void)onClosePlaying;
- (void)onCloseBypassingWithUid:(NSString *)uid;
- (void)onActionType:(NTESLiveActionType)type sender:(id)sender; //点击InnerView上的按钮
- (void)didSendText:(NSString *)text;
- (void)onTapChatView:(CGPoint)point;

@end

@protocol NTESLiveInnerViewDataSource <NSObject>

- (id<NELivePlayer>)currentPlayer;

@end

@interface NTESLiveInnerView : UIView

@property (nonatomic, strong) UIView *localDisplayView;  //本地预览视图

@property (nonatomic,weak) id<NTESLiveInnerViewDelegate> delegate;

@property (nonatomic,weak) id<NTESLiveInnerViewDataSource> dataSource;

- (instancetype)initWithChatroom:(NSString *)chatroomId
                           frame:(CGRect)frame
                        isAnchor:(BOOL)isAnchor;

- (void)refreshChatroom:(NIMChatroom *)chatroom;

- (void)addMessages:(NSArray<NIMMessage *> *)messages;

- (void)addPresentMessages:(NSArray<NIMMessage *> *)messages;

- (void)fireLike;

- (void)resetZoomSlider;

- (CGFloat)getActionViewHeight;

- (void)updateNetStatus:(NIMNetCallNetStatus)status;

- (void)updateUserOnMic;

- (void)updateBeautify:(BOOL)isBeautify;

- (void)updateQualityButton:(BOOL)isHigh;

- (void)updateWaterMarkButton:(BOOL)isOn;

- (void)updateflashButton:(BOOL)isOn;

- (void)updateFocusButton:(BOOL)isOn;

- (void)updateMirrorButton:(BOOL)isOn;

- (void)updateConnectorCount:(NSInteger)count;

- (void)updateExitButtonHidden:(BOOL)hidden;

- (void)addRemoteView:(UIView *)view
                  uid:(NSString *)uid;

- (void)switchToAudioTypeExitView;

- (void)switchToWaitingUI;

- (void)switchToPlayingUI;

- (void)switchToAnchorReenterView:(NTESMicConnector *)connector;

- (void)switchToAudienceBigViewUI;

- (void)switchToLinkingUI;

- (void)switchToEndUI;

- (void)switchToBypassStreamingUI:(NTESMicConnector *)connector;

- (void)switchToBypassingUI:(NTESMicConnector *)connector;

- (void)switchToBypassLoadingUI:(NTESMicConnector *)connector;

- (void)refreshBypassUI;

- (void)refreshBypassUIWithConnector:(NTESMicConnector *)connector;

#pragma mark - 多主播pk相关
- (void)updateAnchorPkRemoteView:(NSData *)yuvData
                           width:(NSUInteger)width
                          height:(NSUInteger)height
                             uid:(NSString *)uid;

- (void)switchToPkUIWithNick:(NSString *)nick uid:(NSString *)uid;

- (void)switchToResumePkUI;

//观众端
- (void)addPkToastWithPkInfo:(NTESPKInfo *)info;

- (void)removePkToast;

- (void)updateAnchorVolume:(UInt16)volume;

- (void)updateUserVolume:(UInt16)volume uid:(NSString *)uid;

@end
