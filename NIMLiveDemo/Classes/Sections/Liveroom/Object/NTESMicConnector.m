//
//  NTESMicConnector.m
//  NIMLiveDemo
//
//  Created by chris on 16/7/22.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESMicConnector.h"
#import "NSString+NTES.h"
#import "NSDictionary+NTESJson.h"
#import "NTESLiveManager.h"

@implementation NTESMicConnector

- (instancetype) initWithDictionary:(NSDictionary *)pair
{
    self = [super init];
    if (self) {
        if ([pair.allKeys.firstObject isKindOfClass:[NSString class]] && [pair.allValues.firstObject isKindOfClass:[NSString class]]) {
            NSString *userId  = pair.allKeys.firstObject;
            NSDictionary *ext = [pair.allValues.firstObject jsonObject];
            NSDictionary *info = [ext jsonDict:@"info"];
            _uid    = userId;
            _type   = [ext jsonInteger:@"style"];
            _state  = [ext jsonInteger:@"state"];
            _avatar = [info jsonString:@"avatar"];
            _nick   = [info jsonString:@"nick"];
            _meetingUid = [info jsonUnsignedLongLong:@"meetingUid"];
        }
    }
    return self;
}

+ (instancetype)me:(NSString *)roomId
{
    NTESMicConnector *instance = [[NTESMicConnector alloc] init];
    instance.uid   = [[NIMSDK sharedSDK].loginManager currentAccount];
    instance.type  = [NTESLiveManager sharedInstance].bypassType;
    instance.meetingUid = [[NIMAVChatSDK sharedSDK].netCallManager getMeetingIdWithUserUid:instance.uid];
    NIMChatroomMember *member = [[NTESLiveManager sharedInstance] myInfo:roomId];
    instance.avatar = member.roomAvatar;
    instance.nick   = member.roomNickname;
    return instance;
}

@end
