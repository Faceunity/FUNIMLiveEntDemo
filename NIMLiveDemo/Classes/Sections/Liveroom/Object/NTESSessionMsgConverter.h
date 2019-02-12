//
//  NTESSessionMsgConverter.h
//  NIMDemo
//
//  Created by ght on 15-1-28.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <NIMSDK/NIMSDK.h>

@class NTESPresent;
@class NTESMicConnector;
@class NTESPKInfo;

@interface NTESSessionMsgConverter : NSObject

+ (NIMMessage *)msgWithText:(NSString*)text;

+ (NIMMessage *)msgWithTip:(NSString *)tip;

+ (NIMMessage *)msgWithPresent:(NTESPresent *)present;

+ (NIMMessage *)msgWithLike;

+ (NIMMessage *)msgWithConnectedMic:(NTESMicConnector *)connector;

+ (NIMMessage *)msgWithDisconnectedMic:(NTESMicConnector *)connector;

+ (NIMMessage *)msgWithPKStartedInfo:(NTESPKInfo *)info;

+ (NIMMessage *)msgWithPKExited;

@end


@interface NTESSessionCustomNotificationConverter : NSObject

+ (NIMCustomSystemNotification *)notificationWithPushMic:(NSString *)roomId style:(NIMNetCallMediaType)style;

+ (NIMCustomSystemNotification *)notificationWithPopMic:(NSString *)roomId;

+ (NIMCustomSystemNotification *)notificationWithAgreeMic:(NSString *)roomId
                                                    style:(NIMNetCallMediaType)style;

+ (NIMCustomSystemNotification *)notificationWithRejectAgree:(NSString *)roomId;

+ (NIMCustomSystemNotification *)notificationWithForceDisconnect:(NSString *)roomId uid:(NSString *)uid;


//主播PK
+ (NIMCustomSystemNotification *)notificationWithPkOnlineRequest:(NSString *)roomId;
+ (NIMCustomSystemNotification *)notificationWithPkOnlineResponse:(NSString *)roomId;
+ (NIMCustomSystemNotification *)notificationWithPkRequest:(NSString *)roomId;
+ (NIMCustomSystemNotification *)notificationWithPkCancel:(NSString *)roomId;
+ (NIMCustomSystemNotification *)notificationWithPkAgreeWithRoomName:(NSString *)roomName roomId:(NSString *)roomId;
+ (NIMCustomSystemNotification *)notificationWithPkReject:(NSString *)roomId;
+ (NIMCustomSystemNotification *)notificationWithPkInvalid:(NSString *)roomId;
+ (NIMCustomSystemNotification *)notificationWithPkBusy:(NSString *)roomId;
+ (NIMCustomSystemNotification *)notificationWithPkDidExit:(NSString *)roomId;

@end
