//
//  NTESRoomBypassAttachment.m
//  NIMLiveDemo
//
//  Created by Simon Blue on 2019/11/6.
//  Copyright © 2019 Netease. All rights reserved.
//

#import "NTESRoomBypassAttachment.h"
#import "NSDictionary+NTESJson.h"
#import "NTESCustomKeyDefine.h"

@implementation NTESRoomBypassJoinAttachment

- (NSString *)encodeAttachment
{
    NSDictionary *attach = @{
                             NTESCMType:@(NTESCustomAttachTypeAnchorJoined),
                             };
    NSData *data = [NSJSONSerialization dataWithJSONObject:attach options:0 error:nil];
    NSString *str = @"{}";
    if (data) {
        str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return str;
}

@end

@implementation NTESRoomBypassleaveAttachment

- (NSString *)encodeAttachment
{
    NSDictionary *attach = @{
                             NTESCMType:@(NTESCustomAttachTypeAnchorLeft),
                             };
    NSData *data = [NSJSONSerialization dataWithJSONObject:attach options:0 error:nil];
    NSString *str = @"{}";
    if (data) {
        str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return str;
}
@end
