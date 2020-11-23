//
//  NTESSessionMsgHelper.m
//  NIMDemo
//
//  Created by ght on 15-1-28.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESSessionMsgConverter.h"
#import "NSString+NTES.h"
#import "NTESPresentAttachment.h"
#import "NTESLikeAttachment.h"
#import "NTESPresent.h"
#import "NSDictionary+NTESJson.h"
#import "NTESLiveViewDefine.h"
#import "NTESLiveManager.h"
#import "NTESMicConnector.h"
#import "NTESMicAttachment.h"
#import "NTESPKAttachment.h"
#import "NTESPKInfo.h"
#import "NTESRoomBypassAttachment.h"

@implementation NTESSessionMsgConverter


+ (NIMMessage*)msgWithText:(NSString*)text
{
    NIMMessage *textMessage = [[NIMMessage alloc] init];
    textMessage.text        = text;
    return textMessage;
}

+ (NIMMessage *)msgWithTip:(NSString *)tip
{
    NIMMessage *message        = [[NIMMessage alloc] init];
    NIMTipObject *tipObject    = [[NIMTipObject alloc] init];
    message.messageObject      = tipObject;
    message.text               = tip;
    NIMMessageSetting *setting = [[NIMMessageSetting alloc] init];
    setting.apnsEnabled        = NO;
    message.setting            = setting;
    return message;
}

+ (NIMMessage *)msgWithPresent:(NTESPresent *)present
{
    NIMMessage *message        = [[NIMMessage alloc] init];
    NIMCustomObject *object    = [[NIMCustomObject alloc] init];
    NTESPresentAttachment *attachment = [[NTESPresentAttachment alloc] init];
    attachment.presentType     = present.type;
    attachment.count           = 1;
    object.attachment          = attachment;
    message.messageObject      = object;
    return message;
}

+ (NIMMessage *)msgWithLike
{
    NIMMessage *message        = [[NIMMessage alloc] init];
    NIMCustomObject *object    = [[NIMCustomObject alloc] init];
    NTESLikeAttachment *attachment = [[NTESLikeAttachment alloc] init];
    object.attachment          = attachment;
    message.messageObject      = object;
    return message;
}

+ (NIMMessage *)msgWithConnectedMic:(NTESMicConnector *)connector
{
    NIMMessage *message        = [[NIMMessage alloc] init];
    NIMCustomObject *object    = [[NIMCustomObject alloc] init];
    NTESMicConnectedAttachment *attachment = [[NTESMicConnectedAttachment alloc] init];
    attachment.type            = connector.type;
    attachment.nick            = connector.nick;
    attachment.avatar          = connector.avatar;
    attachment.connectorId     = connector.uid;
    attachment.meetingUid      = connector.meetingUid;
    object.attachment          = attachment;
    message.messageObject      = object;
    return message;
}

+ (NIMMessage *)msgWithDisconnectedMic:(NTESMicConnector *)connector
{
    NIMMessage *message        = [[NIMMessage alloc] init];
    NIMCustomObject *object    = [[NIMCustomObject alloc] init];
    NTESDisConnectedAttachment *attachment = [[NTESDisConnectedAttachment alloc] init];
    attachment.connectorId     = connector.uid;
    object.attachment          = attachment;
    message.messageObject      = object;
    return message;
}

+ (NIMMessage *)msgWithPKStartedInfo:(NTESPKInfo *)info
{
    NIMMessage *message        = [[NIMMessage alloc] init];
    NIMCustomObject *object    = [[NIMCustomObject alloc] init];
    NTESPKStartedAttachment *attachment = [[NTESPKStartedAttachment alloc] init];
    attachment.inviter         = info.inviter;
    attachment.invitee         = info.invitee;
    object.attachment          = attachment;
    message.messageObject      = object;
    return message;
}

+ (NIMMessage *)msgWithPKExited
{
    NIMMessage *message        = [[NIMMessage alloc] init];
    NIMCustomObject *object    = [[NIMCustomObject alloc] init];
    NTESPKExitedAttachment *attachment = [[NTESPKExitedAttachment alloc] init];
    object.attachment          = attachment;
    message.messageObject      = object;
    return message;
}

+ (NIMMessage *)msgWithAnchorJoined
{
    NIMMessage *message        = [[NIMMessage alloc] init];
    NIMCustomObject *object    = [[NIMCustomObject alloc] init];
    NTESRoomBypassJoinAttachment *attachment = [[NTESRoomBypassJoinAttachment alloc] init];
    object.attachment          = attachment;
    message.messageObject      = object;
    return message;
}

+ (NIMMessage *)msgWithAnchorLeft
{
    NIMMessage *message        = [[NIMMessage alloc] init];
    NIMCustomObject *object    = [[NIMCustomObject alloc] init];
    NTESRoomBypassleaveAttachment *attachment = [[NTESRoomBypassleaveAttachment alloc] init];
    object.attachment          = attachment;
    message.messageObject      = object;
    return message;
}

@end

@implementation NTESSessionCustomNotificationConverter

+ (NSDictionary *)contentWithRoomId:(NSString *)roomId style:(NIMNetCallMediaType)style command:(NTESLiveCustomNotificationType)command
{
    NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:roomId];
    NSDictionary *contentDic = @{
                                    @"command" : @(command),
                                    @"roomid" : roomId ? : @"",
                                    @"style"  : @(style),
                                    @"info"   : @{
                                            @"nick"   : member.roomNickname ? : @"",
                                            @"avatar" : member.roomAvatar.length? member.roomAvatar : @"avatar_default"
                                            },
            } ;

    return contentDic;
}

+ (NIMCustomSystemNotification *)notificationWithPushMic:(NSString *)roomId style:(NIMNetCallMediaType)style
{
    NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:roomId];
    if (member) {
        NSString *content = [ @{
                                @"command"   : @(NTESLiveCustomNotificationTypePushMic),
                                @"roomid" : roomId,
                                @"style"  : @(style),
                                @"info"   : @{
                                                @"nick"   : member.roomNickname,
                                                @"avatar" : member.roomAvatar.length? member.roomAvatar : @"avatar_default"
                                            }
                                } jsonBody];
        NIMCustomSystemNotification *notification = [[NIMCustomSystemNotification alloc] initWithContent:content];
        notification.sendToOnlineUsersOnly = YES;
        return notification;
    }
    return nil;
}


+ (NIMCustomSystemNotification *)notificationWithPopMic:(NSString *)roomId
{
    NSString *content = [@{@"command":@(NTESLiveCustomNotificationTypePopMic),@"roomid" : roomId} jsonBody];
    NIMCustomSystemNotification *notification = [[NIMCustomSystemNotification alloc] initWithContent:content];
    notification.sendToOnlineUsersOnly = YES;
    return notification;
}

+ (NIMCustomSystemNotification *)notificationWithAgreeMic:(NSString *)roomId
                                                    style:(NIMNetCallMediaType)style
{
    NSString *content = [@{@"command":@(NTESLiveCustomNotificationTypeAgreeConnectMic),@"roomid" : roomId, @"style":@(style)} jsonBody];
    NIMCustomSystemNotification *notification = [[NIMCustomSystemNotification alloc] initWithContent:content];
    notification.sendToOnlineUsersOnly = YES;
    return notification;
}

+ (NIMCustomSystemNotification *)notificationWithRejectAgree:(NSString *)roomId
{
    NSString *content = [@{@"command":@(NTESLiveCustomNotificationTypeRejectAgree),@"roomid" : roomId} jsonBody];
    NIMCustomSystemNotification *notification = [[NIMCustomSystemNotification alloc] initWithContent:content];
    notification.sendToOnlineUsersOnly = YES;
    return notification;
}


+ (NIMCustomSystemNotification *)notificationWithForceDisconnect:(NSString *)roomId uid:(NSString *)uid
{
    NSString *content = [@{@"command":@(NTESLiveCustomNotificationTypeForceDisconnect),@"roomid" : roomId, @"uid":uid} jsonBody];
    NIMCustomSystemNotification *notification = [[NIMCustomSystemNotification alloc] initWithContent:content];
    notification.sendToOnlineUsersOnly = NO;
    return notification;
}

+ (NIMCustomSystemNotification *)notificationWithPkOnlineRequest:(NSString *)roomId  {
    NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:roomId];
    NIMNetCallMediaType type =  (NIMNetCallMediaType)[NTESLiveManager sharedInstance].type;
    if (member) {
        NSDictionary *contentDic = [self contentWithRoomId:roomId style:type command:NTESLiveCustomNotificationTypePkOnlineRequest];
        NSString *content = [contentDic jsonBody];
        NIMCustomSystemNotification *notification = [[NIMCustomSystemNotification alloc] initWithContent:content];
        notification.sendToOnlineUsersOnly = YES;
        return notification;
    }
    return nil;
}

+ (NIMCustomSystemNotification *)notificationWithPkRoomBypassOnlineRequest:(NSString *)roomId  {
    NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:roomId];
    NIMNetCallMediaType type =  (NIMNetCallMediaType)[NTESLiveManager sharedInstance].type;
    if (member) {
        NSDictionary *contentDic = [self contentWithRoomId:roomId style:type command:NTESLiveCustomNotificationTypePkRoomByapssOnlineRequest];
        NSString *content = [contentDic jsonBody];
        NIMCustomSystemNotification *notification = [[NIMCustomSystemNotification alloc] initWithContent:content];
        notification.sendToOnlineUsersOnly = YES;
        return notification;
    }
    return nil;
}


+ (NIMCustomSystemNotification *)notificationWithPkOnlineResponse:(NSString *)roomId {
    NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:roomId];
    NIMNetCallMediaType type =  (NIMNetCallMediaType)[NTESLiveManager sharedInstance].type;
    if (member) {
        NSDictionary *contentDic = [self contentWithRoomId:roomId style:type command:NTESLiveCustomNotificationTypePkOnlineResponse];
        NSString *content = [contentDic jsonBody];
        NIMCustomSystemNotification *notification = [[NIMCustomSystemNotification alloc] initWithContent:content];
        notification.sendToOnlineUsersOnly = YES;
        return notification;
    }
    return nil;
}

+ (NIMCustomSystemNotification *)notificationWithPkRequest:(NSString *)roomId pushUrl:(NSString *)pushUrl layoutParam:(NSString *)layoutParam{
    NIMNetCallMediaType type =  (NIMNetCallMediaType)[NTESLiveManager sharedInstance].type;
    NSMutableDictionary *contentDic = [[self contentWithRoomId:roomId style:type command:NTESLiveCustomNotificationTypePkRequest] mutableCopy];
    NSMutableDictionary *contentInfoDic = [[contentDic objectForKey:@"info"]mutableCopy];
    
    if (pushUrl) {
        [contentInfoDic setObject:pushUrl forKey:@"push_url"];
    }
    if (layoutParam) {
        [contentInfoDic setObject:layoutParam forKey:@"layout_param"];
    }
    [contentDic setObject:contentInfoDic forKey:@"info"];
    
    NSString *content = [contentDic jsonBody];

    NIMCustomSystemNotification *notification = [[NIMCustomSystemNotification alloc] initWithContent:content];
    notification.sendToOnlineUsersOnly = YES;
    return notification;
}

+ (NIMCustomSystemNotification *)notificationWithPkCancel:(NSString *)roomId {
    NIMNetCallMediaType type =  (NIMNetCallMediaType)[NTESLiveManager sharedInstance].type;
    NSDictionary *contentDic = [self contentWithRoomId:roomId style:type command:NTESLiveCustomNotificationTypePkCancel];
    NSString *content = [contentDic jsonBody];
    NIMCustomSystemNotification *notification = [[NIMCustomSystemNotification alloc] initWithContent:content];
    notification.sendToOnlineUsersOnly = YES;
    return notification;
}

+ (NIMCustomSystemNotification *)notificationWithPkAgreeWithRoomName:(NSString *)roomName roomId:(NSString *)roomId {
    if (roomName.length == 0) {
        return nil;
    }
    NIMNetCallMediaType type =  (NIMNetCallMediaType)[NTESLiveManager sharedInstance].type;
    NSDictionary *contentDic = [self contentWithRoomId:roomId style:type command:NTESLiveCustomNotificationTypePkAgree];
    NSMutableDictionary * pkAgreeContentDic = [contentDic mutableCopy];
    [pkAgreeContentDic setObject:roomName forKey:@"room_name"];
    NSString *content = [pkAgreeContentDic jsonBody];

    NIMCustomSystemNotification *notification = [[NIMCustomSystemNotification alloc] initWithContent:content];
    notification.sendToOnlineUsersOnly = YES;
    return notification;
}

+ (NIMCustomSystemNotification *)notificationWithPkReject:(NSString *)roomId {
    NIMNetCallMediaType type =  (NIMNetCallMediaType)[NTESLiveManager sharedInstance].type;
    NSDictionary *contentDic = [self contentWithRoomId:roomId style:type command:NTESLiveCustomNotificationTypePkReject];
    NSString *content = [contentDic jsonBody];
    NIMCustomSystemNotification *notification = [[NIMCustomSystemNotification alloc] initWithContent:content];
    notification.sendToOnlineUsersOnly = YES;
    return notification;
}

+ (NIMCustomSystemNotification *)notificationWithPkBusy:(NSString *)roomId {
    NIMNetCallMediaType type =  (NIMNetCallMediaType)[NTESLiveManager sharedInstance].type;
    NSDictionary *contentDic = [self contentWithRoomId:roomId style:type command:NTESLiveCustomNotificationTypePkBusy];
    NSString *content = [contentDic jsonBody];
    NIMCustomSystemNotification *notification = [[NIMCustomSystemNotification alloc] initWithContent:content];
    notification.sendToOnlineUsersOnly = YES;
    return notification;
}

+ (NIMCustomSystemNotification *)notificationWithPkInvalid:(NSString *)roomId {
    NIMNetCallMediaType type =  (NIMNetCallMediaType)[NTESLiveManager sharedInstance].type;
    NSDictionary *contentDic = [self contentWithRoomId:roomId style:type command:NTESLiveCustomNotificationTypePkInvalid];
    NSString *content = [contentDic jsonBody];
    NIMCustomSystemNotification *notification = [[NIMCustomSystemNotification alloc] initWithContent:content];
    notification.sendToOnlineUsersOnly = YES;
    return notification;
}

+ (NIMCustomSystemNotification *)notificationWithPkDidExit:(NSString *)roomId {
    NIMNetCallMediaType type =  (NIMNetCallMediaType)[NTESLiveManager sharedInstance].type;
    NSDictionary *contentDic = [self contentWithRoomId:roomId style:type command:NTESLiveCustomNotificationTypePkDidExit];
    NSString *content = [contentDic jsonBody];
    NIMCustomSystemNotification *notification = [[NIMCustomSystemNotification alloc] initWithContent:content];
    notification.sendToOnlineUsersOnly = YES;
    return notification;
}

@end
