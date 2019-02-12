//
//  NTESChatroomMaker.m
//  NIM
//
//  Created by chris on 16/1/19.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESChatroomMaker.h"
#import "NSDictionary+NTESJson.h"
#import "NTESLiveUtil.h"

@implementation NTESChatroomMaker

+ (NIMChatroom * _Nonnull )makeChatroom:(nonnull NSDictionary *)dict;
{
    BOOL status = [dict jsonInteger:@"status"];
    if (status)
    {
        NIMChatroom *chatroom = [[NIMChatroom alloc] init];
        chatroom.roomId  = [dict jsonString:@"roomid"];
        chatroom.name    = [dict jsonString:@"name"];
        chatroom.creator = [dict jsonString:@"creator"];
        chatroom.announcement = [dict jsonString:@"announcement"];
        chatroom.onlineUserCount = [dict jsonInteger:@"onlineusercount"];
        return chatroom;
    }
    else
    {
        return nil;
    }
}

@end
