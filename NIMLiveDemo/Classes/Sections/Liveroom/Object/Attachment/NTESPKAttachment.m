//
//  NTESPKAttachment.m
//  NIMLiveDemo
//
//  Created by Simon Blue on 2018/10/30.
//  Copyright © 2018年 Netease. All rights reserved.
//

#import "NTESPKAttachment.h"
#import "NSDictionary+NTESJson.h"
#import "NTESCustomKeyDefine.h"

@implementation NTESPKStartedAttachment

- (NSString *)encodeAttachment
{
    NSDictionary *encode = @{
                             NTESCMType : @(NTESCustomAttachTypePKStarted),
                             NTESCMData : @{
                                     NTESCMPKStartedInviter    : self.inviter.length ? self.inviter : @"unknown",
                                     NTESCMPKStartedInvitee   : self.invitee.length ? self.invitee : @"unknown",
                                     },
                             };
    return [encode jsonBody];
}

@end


@implementation NTESPKExitedAttachment

- (NSString *)encodeAttachment
{
    NSDictionary *attach = @{
                             NTESCMType:@(NTESCustomAttachTypePKExited),
                             };
    NSData *data = [NSJSONSerialization dataWithJSONObject:attach options:0 error:nil];
    NSString *str = @"{}";
    if (data) {
        str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return str;
}
@end
