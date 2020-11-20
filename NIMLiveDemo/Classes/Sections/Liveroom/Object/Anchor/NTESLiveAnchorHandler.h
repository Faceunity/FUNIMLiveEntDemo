//
//  NTESLiveAnchorHandler.h
//  NIMLiveDemo
//
//  Created by chris on 16/8/15.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
@class NTESMicConnector;
@protocol NTESLiveAnchorHandlerDelegate <NSObject>

- (void)didUpdateConnectors;

- (void)didUpdateChatroomMemebers:(BOOL)isAdd;

- (void)didReceivePkOnlineRequestFromUser:(NTESMicConnector *)user;
- (void)didReceivePkRoomBypassOnlineRequestFromUser:(NTESMicConnector *)user;
- (void)didReceivePkOnlineResponse;
- (void)didReceivePkCancel;
- (void)didReceivePkInvalid;
- (void)didReceivePkBusy;
- (void)didReceivePkRequest:(NSString *)pushUrl layoutParam:(NSString *)layoutParam;
- (void)didReceivePkReject;
- (void)didReceivePkAgreeWithRoomName:(NSString *)roomName;
- (void)didReceivePkExit;

@end

@interface NTESLiveAnchorHandler : NSObject

@property (nonatomic,weak) id<NTESLiveAnchorHandlerDelegate> delegate;

- (instancetype)initWithChatroom:(NIMChatroom *)chatroom;

- (void)dealWithNotificationMessage:(NIMMessage *)message;

- (void)dealWithBypassCustomNotification:(NIMCustomSystemNotification *)notification;

#pragma mark - 多主播PK


@end
