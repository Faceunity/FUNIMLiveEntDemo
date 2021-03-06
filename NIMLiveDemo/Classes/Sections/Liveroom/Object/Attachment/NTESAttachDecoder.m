//
//  NTESAttachDecoder.m
//  NIMLiveDemo
//
//  Created by chris on 16/3/30.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESAttachDecoder.h"
#import "NSDictionary+NTESJson.h"
#import "NTESCustomKeyDefine.h"
#import "NTESPresentAttachment.h"
#import "NTESLikeAttachment.h"
#import "NTESMicAttachment.h"
#import "NTESPKAttachment.h"
#import "NTESRoomBypassAttachment.h"

@implementation NTESAttachDecoder

- (id<NIMCustomAttachment>)decodeAttachment:(NSString *)content
{
    id<NIMCustomAttachment> attachment = nil;
    
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    if (data) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data
                                                             options:0
                                                               error:nil];
        if ([dict isKindOfClass:[NSDictionary class]])
        {
            NSInteger type     = [dict jsonInteger:NTESCMType];
            NSDictionary *data = [dict jsonDict:NTESCMData];
            switch (type) {
                case NTESCustomAttachTypePresent:
                {
                    attachment = [[NTESPresentAttachment alloc] init];
                    ((NTESPresentAttachment *)attachment).presentType = [data jsonInteger:NTESCMPresentType];
                    ((NTESPresentAttachment *)attachment).count = [data jsonInteger:NTESCMPresentCount];
                }
                    break;
                case NTESCustomAttachTypeLike:
                {
                    attachment = [[NTESLikeAttachment alloc] init];
                }
                    break;
                case NTESCustomAttachTypeConnectedMic:
                {
                    attachment = [[NTESMicConnectedAttachment alloc] init];
                    ((NTESMicConnectedAttachment *)attachment).connectorId = [data jsonString:NTESCMConnectMicUid];
                    ((NTESMicConnectedAttachment *)attachment).type = [data jsonInteger:NTESCMCallStyle];
                    ((NTESMicConnectedAttachment *)attachment).nick = [data jsonString:NTESCMConnectMicNick];
                    ((NTESMicConnectedAttachment *)attachment).avatar = [data jsonString:NTESCMConnectMicAvatar];
                    ((NTESMicConnectedAttachment *)attachment).meetingUid = [data jsonString:NTESCMConnectMicMeetingUid].longLongValue;
                }
                    break;
                case NTESCustomAttachTypeDisconnectedMic:
                {
                    attachment = [[NTESDisConnectedAttachment alloc] init];
                    ((NTESDisConnectedAttachment *)attachment).connectorId = [data jsonString:NTESCMConnectMicUid];
                }
                    break;
                    
                case NTESCustomAttachTypePKStarted:
                {
                    attachment = [[NTESPKStartedAttachment alloc] init];
                    ((NTESPKStartedAttachment *)attachment).inviter = [data jsonString:NTESCMPKStartedInviter];
                    ((NTESPKStartedAttachment *)attachment).invitee = [data jsonString:NTESCMPKStartedInvitee];
                }
                    break;
                    
                case NTESCustomAttachTypePKExited:
                {
                    attachment = [[NTESPKExitedAttachment alloc] init];
                }
                    break;
                case NTESCustomAttachTypeAnchorJoined:
                {
                    attachment = [[NTESRoomBypassJoinAttachment alloc] init];
                }
                    break;
                case NTESCustomAttachTypeAnchorLeft:
                {
                    attachment = [[NTESRoomBypassleaveAttachment alloc] init];
                }
                    break;

                    
                default:
                    break;
            }
        }
    }
    return attachment;
}



@end
