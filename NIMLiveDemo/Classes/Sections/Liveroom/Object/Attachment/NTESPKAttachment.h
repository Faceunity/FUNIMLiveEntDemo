//
//  NTESPKAttachment.h
//  NIMLiveDemo
//
//  Created by Simon Blue on 2018/10/30.
//  Copyright © 2018年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NTESPKStartedAttachment : NSObject<NIMCustomAttachment>

@property (nonatomic, copy) NSString *inviter;

@property (nonatomic, copy) NSString *invitee;

@end


@interface NTESPKExitedAttachment : NSObject<NIMCustomAttachment>

@end
