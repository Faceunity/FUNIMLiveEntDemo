//
//  NTESAnchorLiveViewController.h
//  NIM
//
//  Created by chris on 15/12/16.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTESMediaCapture.h"
#import "NTESBypassLiveViewController.h"

@class NTESFiterStatusModel;

@interface NTESAnchorLiveViewController : NTESBypassLiveViewController

- (instancetype)initWithChatroom:(NIMChatroom *)chatroom currentMeeting:(NIMNetCallMeeting*)currentMeeting capture:(NTESMediaCapture*)capture delegate:(id<NTESAnchorLiveViewControllerDelegate>)delegate;

- (instancetype)initWithChatroom:(NIMChatroom *)chatroom;

@end

