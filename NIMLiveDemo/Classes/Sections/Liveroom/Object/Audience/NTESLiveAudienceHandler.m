//
//  NTESLiveAudienceHandler.m
//  NIMLiveDemo
//
//  Created by chris on 16/8/17.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESLiveAudienceHandler.h"
#import "NSDictionary+NTESJson.h"
#import "NSString+NTES.h"
#import "NTESLiveViewDefine.h"
#import "NTESMicConnector.h"
#import "NTESLiveManager.h"
#import "NTESSessionMsgConverter.h"
#import "NTESUserUtil.h"
#import "NTESCustomKeyDefine.h"
#import "NTESMicAttachment.h"
#import "NTESMediaCapture.h"
#import "NTESPKInfo.h"

@interface NTESLiveAudienceHandler()

@property (nonatomic,strong) NIMChatroom *chatroom;

@property (nonatomic,copy)   NSString *meetingName;

@property (nonatomic, strong) NTESMediaCapture *capture;

@end

@implementation NTESLiveAudienceHandler

- (instancetype)initWithChatroom:(NIMChatroom *)room
{
    self = [super init];
    if (self) {
        _chatroom = room;
        _meetingName = [NTESUserUtil meetingName:self.chatroom];
        _capture = [[NTESMediaCapture alloc]init];
    }
    return self;
}

- (void)callDidStopByPassWithUid:(NSString *)uid
{
    if ([self.delegate respondsToSelector:@selector(didStopByPassingWithUid:)]) {
        [self.delegate didStopByPassingWithUid:uid];
    }
}

- (void)callUpdateUserOnMicWithUid:(NSString *)uid
{
    if ([self.delegate respondsToSelector:@selector(didUpdateUserOnMicWithUid:)]) {
        [self.delegate didUpdateUserOnMicWithUid:uid];
    }
}

- (void)dealWithBypassMessage:(NIMMessage *)message
{
    NIMCustomObject *object = message.messageObject;
    id<NIMCustomAttachment> attachment = object.attachment;
    
    DDLogInfo(@"audience: on receive bypass message");
    
    if ([attachment isKindOfClass:[NTESMicConnectedAttachment class]]) {
        DDLogInfo(@"audience: bypass message type is mic connected");
        //这个消息是主播发出的全局广播，主播自己不会收到
        NTESMicConnectedAttachment *attach = (NTESMicConnectedAttachment *)attachment;
        NSString *onMicUid = attach.connectorId;
        NTESMicConnector *connector = [[NTESMicConnector alloc] init];
        connector.uid    = onMicUid;
        connector.state  = NTESLiveMicStateConnected;
        connector.nick   = attach.nick;
        connector.avatar = attach.avatar;
        connector.type   = attach.type;
        connector.meetingUid = attach.meetingUid;
        [[NTESLiveManager sharedInstance] addConnectorOnMic:connector];
        [self callUpdateUserOnMicWithUid:onMicUid];
    }
    else if ([attachment isKindOfClass:[NTESDisConnectedAttachment class]]) {
        DDLogInfo(@"audience: bypass message type is mic disconnected");
        NTESDisConnectedAttachment *attach = (NTESDisConnectedAttachment *)attachment;
        NSString *onMicUid = attach.connectorId;
        
        if (onMicUid) {
            [[NTESLiveManager sharedInstance] delConnectorOnMicWithUid:onMicUid];
        }

        [self callUpdateUserOnMicWithUid:onMicUid];
    }
}


- (void)dealWithBypassCustomNotification:(NIMCustomSystemNotification *)notification
{
    //只有连麦的人会收到这条消息
    NSString *content  = notification.content;
    NSDictionary *dict = [content jsonObject];
    NSString *roomId = [dict jsonString:@"roomid"];
    NTESLiveCustomNotificationType type = [dict jsonInteger:@"command"];
    
    DDLogInfo(@"audience: on receive custom notification");
    
    if (![self shouldDealWithNotification:notification]) {
        return;
    }
    switch (type) {
        case NTESLiveCustomNotificationTypeAgreeConnectMic:{
            NIMNetCallMediaType callType = [dict jsonInteger:NTESCMCallStyle];
            [NTESLiveManager sharedInstance].bypassType = callType;
            DDLogInfo(@"audience: notification type is NTESLiveCustomNotificationTypeAgreeConnectMic , call type is %zd", callType);
            NIMNetCallMeeting *meeting = [[NIMNetCallMeeting alloc] init];
            meeting.name  = self.meetingName;
            meeting.actor = YES;
            meeting.type  = callType;
            NIMNetCallOption *option = [NTESUserUtil fillNetCallOption:meeting];
            
            if (callType == NIMNetCallMediaTypeVideo) {
                //开启摄像头
                NIMNetCallVideoCaptureParam *param = [NTESUserUtil videoCaptureParam];
                param.videoCaptureOrientation = [NTESLiveManager sharedInstance].orientation;
                param.videoHandler = self.capture.videoHandler;
                param.preferredVideoQuality = NIMNetCallVideoQualityDefault;
                option.videoCaptureParam = param;
            }
            
            //先关闭播放器 再连麦 防止底层音频资源共用引发问题
            if ([self.delegate respondsToSelector:@selector(willStartByPassing:)]) {
                [self.delegate willStartByPassing:^{
                    __weak typeof(self) weakSelf = self;
                    [[NIMAVChatSDK sharedSDK].netCallManager joinMeeting:meeting completion:^(NIMNetCallMeeting * _Nonnull currentMeeting, NSError * _Nonnull error) {
                        if (error) {
                            DDLogError(@"agree connect mic -> join meeting error : %@",error);
                            if ([weakSelf.delegate respondsToSelector:@selector(joinMeetingError:)]) {
                                [weakSelf.delegate joinMeetingError:error];
                            }
                        }else{
                            //                            //这个是主播发给连麦者的同意连麦消息
                            //                            if ([self.delegate respondsToSelector:@selector(willStartByPassing)]) {
                            //                                [self.delegate willStartByPassing];
                            //                            }
                            weakSelf.isWaitingForAgreeConnect = NO;
                            weakSelf.currentMeeting = currentMeeting;
                            NTESMicConnector *connector = [NTESMicConnector me:roomId];
                            connector.state = NTESLiveMicStateConnected;
                            [[NTESLiveManager sharedInstance] addConnectorOnMic:connector];
                            
                            //[NTESLiveManager sharedInstance].connectorOnMic = connector;
                            [[NIMAVChatSDK sharedSDK].netCallManager setSpeaker:YES];
                            if ([weakSelf.delegate respondsToSelector:@selector(didStartByPassingWithUid:)]) {
                                [weakSelf.delegate didStartByPassingWithUid:connector.uid];
                            }
                        }
                    }];
                    
                }];
            }
            break;
        }
        
        case NTESLiveCustomNotificationTypeForceDisconnect: {
            
            NSString *myUid = [[NIMSDK sharedSDK].loginManager currentAccount];
            DDLogInfo(@"audience: notification type is NTESLiveCustomNotificationTypeForceDisconnect, dstUid = %@", myUid);
            //只有连麦的人会收到这条消息，直接退出会议即可
            [[NIMAVChatSDK sharedSDK].netCallManager leaveMeeting:self.currentMeeting];
            self.currentMeeting = nil;
            [self callDidStopByPassWithUid:myUid];
            break;
        }
        default:
            DDLogError(@"audience: notification type is UNKNOWN!");
            break;
    }
}


- (void)dealWithNotificationMessage:(NIMMessage *)message
{
    DDLogInfo(@"audience: on receive chatroom notification message");
    NIMNotificationObject *object = (NIMNotificationObject *)message.messageObject;
    switch (object.notificationType) {
        case NIMNotificationTypeChatroom:{
            NIMChatroomNotificationContent *content = (NIMChatroomNotificationContent *)object.content;
            switch (content.eventType) {
                case NIMChatroomEventTypeEnter:{
                    DDLogInfo(@"audience: notification type is NIMChatroomEventTypeEnter");
                    NSString *enterUserId = content.targets.firstObject.userId;
                    DDLogInfo(@"enter user is %@",enterUserId);
                    if (_delegate && [_delegate respondsToSelector:@selector(didUpdateChatroomMemebers:userId:)]) {
                        [_delegate didUpdateChatroomMemebers:YES userId:enterUserId];
                    }
                    if ([enterUserId isEqualToString:self.chatroom.creator]
                        && ![[[NIMSDK sharedSDK].loginManager currentAccount] isEqualToString:self.chatroom.creator]) {
                        NSDictionary *dict = [content.notifyExt jsonObject];
                        if ([dict isKindOfClass:[NSDictionary class]]){
                            if ([self.delegate respondsToSelector:@selector(didUpdateLiveType:)]) {
                                NTESLiveType type = [dict jsonInteger:NTESCMType];
                                [self.delegate didUpdateLiveType:type];

                            }
                            if ([self.delegate respondsToSelector:@selector(didUpdateLiveOrientation:)]) {
                                NIMVideoOrientation orientation =[dict jsonInteger:NTESCMOrientation] == 1 ? NIMVideoOrientationPortrait:NIMVideoOrientationLandscapeRight;
                                [self.delegate didUpdateLiveOrientation:orientation];

                            }
                            NSString *meetingName = [dict jsonString:NTESCMMeetingName];
                            self.meetingName = meetingName;
                            
                            if ([self.delegate respondsToSelector:@selector(didUpdateLiveBypassType:)]) {
                                NTESBypassType type = [dict jsonInteger:NTESCMPushType] == 1 ? NTESBypassTypeAnchor:NTESBypassTypeRoom;
                                [self.delegate didUpdateLiveBypassType:type];
                            }
                        }
                    }
                    break;
                }
                case NIMChatroomEventTypeInfoUpdated:{
                    DDLogInfo(@"audience: notification type is NIMChatroomEventTypeInfoUpdated");
                    DDLogInfo(@"update info: %@",content.notifyExt);
                    NSDictionary *dict = [content.notifyExt jsonObject];
                    if ([dict isKindOfClass:[NSDictionary class]]){
                        if (dict[NTESCMPKState]) {
                            if ([self.delegate respondsToSelector:@selector(didUpdateToastWithPkInfo:)]) {
                                NTESPKInfo *info = [[NTESPKInfo alloc] init];
                                info.isPking = [dict jsonInteger:NTESCMPKState];
                                info.inviter = [dict jsonString:NTESCMPKStartedInviter];
                                info.invitee = [dict jsonString:NTESCMPKStartedInvitee];
                                [self.delegate didUpdateToastWithPkInfo:info];
                            }
                        }
                        
                        if (dict[NTESCMType]) {
                            if ([self.delegate respondsToSelector:@selector(didUpdateLiveType:)]) {
                                NTESLiveType type = [dict jsonInteger:NTESCMType];
                                [self.delegate didUpdateLiveType:type];
                            }
                        }
                        
                        if (dict[NTESCMMeetingName]) {
                            NSString *meetingName = [dict jsonString:NTESCMMeetingName];
                            self.meetingName = meetingName;
                        }
                    }
                    break;
                }
                case NIMChatroomEventTypeExit: {
                    NSString *exitUserId = content.targets.firstObject.userId;
                    DDLogInfo(@"exit user is %@",exitUserId);
                    if (_delegate && [_delegate respondsToSelector:@selector(didUpdateChatroomMemebers:userId:)]) {
                        [_delegate didUpdateChatroomMemebers:NO userId:exitUserId];
                    }
                    break;
                }
                default:
                    DDLogError(@"audience: chatroom notification type is uncatch! type is %zd",content.eventType);
                    break;
            }
            break;
        }
        default:
            DDLogError(@"audience:  message type is UNKNOWN!");
            break;
    }
}



- (BOOL)shouldDealWithNotification:(NIMCustomSystemNotification *)notification
{
    NSString *content  = notification.content;
    NSDictionary *dict = [content jsonObject];
    NSString *roomId = [dict jsonString:@"roomid"];
    NTESLiveCustomNotificationType type = [dict jsonInteger:@"command"];
    BOOL validRoom = [roomId isEqualToString:self.chatroom.roomId];
    BOOL shouldRejectAgreeMic = type == NTESLiveCustomNotificationTypeAgreeConnectMic && (!self.isWaitingForAgreeConnect || !validRoom);
    if (shouldRejectAgreeMic) {
        DDLogDebug(@"reject agree mic ! current room id %@",self.chatroom.roomId);

        NIMCustomSystemNotification *notification = [NTESSessionCustomNotificationConverter notificationWithRejectAgree:self.chatroom.roomId];
        NIMSession *session = [NIMSession session:notification.sender type:NIMSessionTypeP2P];
        [[NIMSDK sharedSDK].systemNotificationManager sendCustomNotification:notification toSession:session completion:nil];
    }
    return validRoom || shouldRejectAgreeMic;
}

@end
