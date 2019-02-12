//
//  NTESCustomKeyDefine.h
//  NIMLiveDemo
//
//  Created by chris on 16/3/30.
//  Copyright © 2016年 Netease. All rights reserved.
//

#ifndef NTESCustomKeyDefine_h
#define NTESCustomKeyDefine_h

typedef NS_ENUM(NSInteger,NTESCustomAttachType)
{
    NTESCustomAttachTypePresent,
    NTESCustomAttachTypeLike,
    NTESCustomAttachTypeConnectedMic,
    NTESCustomAttachTypeDisconnectedMic,
    NTESCustomAttachTypePKStarted,
    NTESCustomAttachTypePKExited,
};


//key
#define NTESCMType             @"type"
#define NTESCMData             @"data"
#define NTESCMPresentType      @"present"
#define NTESCMPresentCount     @"count"
#define NTESCMConnectMicUid    @"uid"
#define NTESCMConnectMicNick   @"nick"
#define NTESCMConnectMicAvatar @"avatar"
#define NTESCMCallStyle        @"style"
#define NTESCMPKStartedInviter    @"pkinviter"
#define NTESCMPKStartedInvitee    @"pkinvitee"
#define NTESCMPKState            @"ispking"


#define NTESCMMeetingName      @"meetingName"

#define NTESCMOrientation      @"orientation"


#endif /* NTESCustomKeyDefine_h */
