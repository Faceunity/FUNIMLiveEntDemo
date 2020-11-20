//
//  NTESLiveAnchorHandler.m
//  NIMLiveDemo
//
//  Created by chris on 16/8/15.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESLiveAnchorHandler.h"
#import "NSString+NTES.h"
#import "NSDictionary+NTESJson.h"
#import "NTESLiveViewDefine.h"
#import "NTESMicConnector.h"
#import "NTESLiveManager.h"

@interface NTESLiveAnchorHandler ()

@property (nonatomic,strong) NIMChatroom *chatroom;

@end

@implementation NTESLiveAnchorHandler

- (instancetype)initWithChatroom:(NIMChatroom *)chatroom
{
    self = [super init];
    if (self) {
        _chatroom = chatroom;
    }
    return self;
}

- (void)dealWithBypassCustomNotification:(NIMCustomSystemNotification *)notification
{
    NSString *content  = notification.content;
    NSString *from     = notification.sender;
    NSDictionary *dict = [content jsonObject];
    NTESLiveCustomNotificationType type = [dict jsonInteger:@"command"];
    switch (type) {
        case NTESLiveCustomNotificationTypePushMic:
        case NTESLiveCustomNotificationTypePopMic:
        case NTESLiveCustomNotificationTypeAgreeConnectMic:
        case NTESLiveCustomNotificationTypeForceDisconnect:
        case NTESLiveCustomNotificationTypeRejectAgree:
            [self doProcessOnMicNoticationType:type from:from dict:dict];
            break;
        case NTESLiveCustomNotificationTypePkOnlineRequest:
        case NTESLiveCustomNotificationTypePkOnlineResponse:
        case NTESLiveCustomNotificationTypePkRequest:
        case NTESLiveCustomNotificationTypePkCancel:
        case NTESLiveCustomNotificationTypePkAgree:
        case NTESLiveCustomNotificationTypePkReject:
        case NTESLiveCustomNotificationTypePkInvalid:
        case NTESLiveCustomNotificationTypePkBusy:
        case NTESLiveCustomNotificationTypePkDidExit:
        case NTESLiveCustomNotificationTypePkRoomByapssOnlineRequest:
            [self doProcessPkNoticationType:type from:from dict:dict];
            break;
        default:
            break;
    }
}

- (void)doProcessOnMicNoticationType:(NTESLiveCustomNotificationType)type
                                from:(NSString *)from
                                dict:(NSDictionary *)dict {
    if (![self shouldDealWithDict:dict]) {
        return;
    }
    switch (type) {
        case NTESLiveCustomNotificationTypePushMic:{
            //这个是连麦者发来的请求
            DDLogInfo(@"anchor: on receive notification NTESLiveCustomNotificationTypePushMic");
            NSDictionary *info = [dict jsonDict:@"info"];
            NSString *nick   = [info jsonString:@"nick"];
            NSString *avatar = [info jsonString:@"avatar"];
            NIMNetCallMediaType callType = [dict jsonInteger:@"style"];
            
            NTESMicConnector *connector = [[NTESMicConnector alloc] init];
            connector.uid    = from;
            connector.state  = NTESLiveMicStateWaiting;
            connector.nick   = nick;
            connector.avatar = avatar;
            connector.type   = callType;
            
            [[NTESLiveManager sharedInstance] updateConnectors:connector];
            if ([self.delegate respondsToSelector:@selector(didUpdateConnectors)]) {
                [self.delegate didUpdateConnectors];
            }
            break;
        }
        case NTESLiveCustomNotificationTypePopMic:
            //这个是连麦者发来的请求，处于等待->取消状态
            DDLogInfo(@"anchor: on receive notification NTESLiveCustomNotificationTypePopMic");
            [[NTESLiveManager sharedInstance] removeConnectors:from];
            if ([self.delegate respondsToSelector:@selector(didUpdateConnectors)]) {
                [self.delegate didUpdateConnectors];
            }
            break;
        case NTESLiveCustomNotificationTypeRejectAgree:
            //这个只有主播会收到，是连麦者拒绝主播连麦，因连麦过期造成，非用户触发
            DDLogInfo(@"anchor: on receive notification NTESLiveCustomNotificationTypeRejectAgree");
            //[NTESLiveManager sharedInstance].connectorOnMic = nil;
            [[NTESLiveManager sharedInstance] delConnectorOnMicWithUid:from];
            [[NTESLiveManager sharedInstance] removeConnectors:from];
            if ([self.delegate respondsToSelector:@selector(didUpdateConnectors)]) {
                [self.delegate didUpdateConnectors];
            }
            break;
        default:
            break;
    }
}

- (void)dealWithNotificationMessage:(NIMMessage *)message {
    DDLogInfo(@"audience: on receive chatroom notification message");
    NIMNotificationObject *object = (NIMNotificationObject *)message.messageObject;
    switch (object.notificationType) {
        case NIMNotificationTypeChatroom:{
            NIMChatroomNotificationContent *content = (NIMChatroomNotificationContent *)object.content;
            switch (content.eventType) {
                case NIMChatroomEventTypeEnter:{
                    if (_delegate && [_delegate respondsToSelector:@selector(didUpdateChatroomMemebers:)]) {
                        [_delegate didUpdateChatroomMemebers:YES];
                    }
                    break;
                }
                case NIMChatroomEventTypeExit: {
                    if (_delegate && [_delegate respondsToSelector:@selector(didUpdateChatroomMemebers:)]) {
                        [_delegate didUpdateChatroomMemebers:NO];
                    }
                    break;
                }
                default:
                    DDLogError(@"audience: chatroom notification type is uncatch! type is %zd",content.eventType);
                    break;
            }
            
        }
            break;
        default:
            DDLogError(@"audience:  message type is UNKNOWN!");
            break;
    }
}

- (BOOL)shouldDealWithDict:(NSDictionary *)dict
{
    NSString *roomId = [dict jsonString:@"roomid"];
    BOOL validRoom = [roomId isEqualToString:self.chatroom.roomId];
    return validRoom;
}

#pragma mark - 多主播PK
- (void)doProcessPkNoticationType:(NTESLiveCustomNotificationType)type
                             from:(NSString *)from
                             dict:(NSDictionary *)dict {
    switch (type) {
        case NTESLiveCustomNotificationTypePkOnlineRequest:{
            NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:_chatroom.roomId];
            DDLogInfo(@"YAT 收到 PkOnlineRequest：[%@] -> [%@]", from, member.userId);
            NTESMicConnector *connector = [self connectorWithFrom:from dict:dict];
            if (_delegate && [_delegate respondsToSelector:@selector(didReceivePkOnlineRequestFromUser:)]) {
                [_delegate didReceivePkOnlineRequestFromUser:connector];
            }
            break;
        }
        case NTESLiveCustomNotificationTypePkOnlineResponse:{
            
            NTESAnchorPKStatus pkStatus = [NTESLiveManager sharedInstance].pkStatus;
            if (pkStatus != NTESAnchorPKStatusPingInteractive) {
                DDLogWarn(@"YAT 当前状态 %d，不再接收 OnlineResponse 请求", (int)pkStatus);
                return;
            }
            NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:_chatroom.roomId];
            DDLogInfo(@"YAT 收到 PkOnlineResponse：[%@] -> [%@]", from, member.userId);
            NTESMicConnector *connector = [self connectorWithFrom:from dict:dict];
            [NTESLiveManager sharedInstance].dstPkAnchor = connector;
            if (_delegate && [_delegate respondsToSelector:@selector(didReceivePkOnlineResponse)]) {
                [_delegate didReceivePkOnlineResponse];
            }
            break;
        }
        case NTESLiveCustomNotificationTypePkRequest:{
            NTESAnchorPKStatus pkStatus = [NTESLiveManager sharedInstance].pkStatus;
            if (pkStatus != NTESAnchorPKStatusPingInteractive) {
                DDLogWarn(@"当前状态 %d，不再接收 OnlineResponse 请求", (int)pkStatus);
                return;
            }
            NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:_chatroom.roomId];
            DDLogInfo(@"YAT 收到 PkRequest：[%@] -> [%@]", from, member.userId);
            
            NSDictionary *info = [dict jsonDict:@"info"];
            NSString *pushUrl = [info objectForKey:@"push_url"];
            NSString *layoutParam = [info objectForKey:@"layout_param"];

            if (_delegate && [_delegate respondsToSelector:@selector(didReceivePkRequest:layoutParam:)]) {
                [_delegate didReceivePkRequest:pushUrl layoutParam:layoutParam];
            }
            break;
        }
        case NTESLiveCustomNotificationTypePkCancel:{
            NTESAnchorPKStatus pkStatus = [NTESLiveManager sharedInstance].pkStatus;
            if (pkStatus == NTESAnchorPKStatusIdle) {
                DDLogWarn(@"当前状态 %d，不再接收 cancelPk 请求", (int)pkStatus);
                return;
            }
            if (_delegate && [_delegate respondsToSelector:@selector(didReceivePkCancel)]) {
                [_delegate didReceivePkCancel];
            }
            break;
        }
        case NTESLiveCustomNotificationTypePkInvalid: {
            NTESAnchorPKStatus pkStatus = [NTESLiveManager sharedInstance].pkStatus;
            if (pkStatus != NTESAnchorPKStatusPingInteractive && pkStatus != NTESAnchorPKStatusPkInteractive) {
                DDLogWarn(@"当前状态 %d，不再接收 PkInvalid 请求", (int)pkStatus);
                return;
            }
            NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:_chatroom.roomId];
            DDLogInfo(@"YAT 收到 PkInvalid：[%@] -> [%@]", from, member.userId);
            if (_delegate && [_delegate respondsToSelector:@selector(didReceivePkInvalid)]) {
                [_delegate didReceivePkInvalid];
            }
            break;
        }
        case NTESLiveCustomNotificationTypePkBusy: {
            NTESAnchorPKStatus pkStatus = [NTESLiveManager sharedInstance].pkStatus;
            if (pkStatus != NTESAnchorPKStatusPingInteractive) {
                DDLogWarn(@"YAT 当前状态 %d，不再接收 PkBusy 请求", (int)pkStatus);
                return;
            }
            NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:_chatroom.roomId];
            DDLogInfo(@"YAT 收到 PkBusy：[%@] -> [%@]", from, member.userId);
            if (_delegate && [_delegate respondsToSelector:@selector(didReceivePkBusy)]) {
                [_delegate didReceivePkBusy];
            }
            break;
        }
        case NTESLiveCustomNotificationTypePkDidExit: {
            NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:_chatroom.roomId];
            DDLogInfo(@"YAT 收到 exit：[%@] -> [%@]", from, member.userId);

            if (_delegate && [_delegate respondsToSelector:@selector(didReceivePkExit)]) {
                [_delegate didReceivePkExit];
            }
            break;
        }
        case NTESLiveCustomNotificationTypePkAgree: {
            NTESAnchorPKStatus pkStatus = [NTESLiveManager sharedInstance].pkStatus;
            if (pkStatus != NTESAnchorPKStatusPkInteractive) {
                DDLogWarn(@"YAT 当前状态 %d，不再接收 PkAgree 请求", (int)pkStatus);
                return;
            }
            NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:_chatroom.roomId];
            DDLogInfo(@"YAT 收到 PkAgree：[%@] -> [%@]", from, member.userId);
            NSString *roomName = [dict jsonString:@"room_name"];
            if (_delegate && [_delegate respondsToSelector:@selector(didReceivePkAgreeWithRoomName:)]) {
                [_delegate didReceivePkAgreeWithRoomName:roomName];
            }
            break;
        }
        case NTESLiveCustomNotificationTypePkReject: {
            NTESMicConnector *connector = [self connectorWithFrom:from dict:dict];
            [NTESLiveManager sharedInstance].dstPkAnchor = connector;
            NTESAnchorPKStatus pkStatus = [NTESLiveManager sharedInstance].pkStatus;
            if (pkStatus != NTESAnchorPKStatusPkInteractive && pkStatus != NTESAnchorPKStatusPingInteractive) {
                DDLogWarn(@"YAT 当前状态 %d，不再接收 PkReject 请求", (int)pkStatus);
                return;
            }
            NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:_chatroom.roomId];
            DDLogInfo(@"YAT 收到 PkReject：[%@] -> [%@]", from, member.userId);
            if (_delegate && [_delegate respondsToSelector:@selector(didReceivePkReject)]) {
                [_delegate didReceivePkReject];
            }
            break;
        }
        case NTESLiveCustomNotificationTypePkRoomByapssOnlineRequest: {
            NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:_chatroom.roomId];
            DDLogInfo(@"YAT 收到 Room Bypass PkOnlineRequest：[%@] -> [%@]", from, member.userId);
            NTESMicConnector *connector = [self connectorWithFrom:from dict:dict];
            if (_delegate && [_delegate respondsToSelector:@selector(didReceivePkOnlineRequestFromUser:)]) {
                [_delegate didReceivePkRoomBypassOnlineRequestFromUser:connector];
            }
            break;
            break;
        }

        default:
            break;
    }
}

- (NTESMicConnector *)connectorWithFrom:(NSString *)from dict:(NSDictionary *)dict {
    NSDictionary *info = [dict jsonDict:@"info"];
    NSString *nick   = [info jsonString:@"nick"];
    NSString *avatar = [info jsonString:@"avatar"];
    NIMNetCallMediaType callType = [dict jsonInteger:@"style"];
    
    NTESMicConnector *connector = [[NTESMicConnector alloc] init];
    connector.uid    = from;
    connector.state  = NTESLiveMicStateWaiting;
    connector.nick   = nick;
    connector.avatar = avatar;
    connector.type   = callType;
    return connector;
}

@end
