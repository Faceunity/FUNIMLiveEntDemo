//
//  NTESRoomBypassLiveViewController.h
//  NIMLiveDemo
//
//  Created by Simon Blue on 2019/10/24.
//  Copyright © 2019 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTESMediaCapture.h"
#import "NTESBypassLiveViewController.h"

@class NTESFiterStatusModel;


@interface NTESRoomBypassLiveViewController : NTESBypassLiveViewController

@property (nonatomic) NIMVideoOrientation orientation;

@property (nonatomic ,strong ) NTESFiterStatusModel *filterModel;

- (instancetype)initWithChatroom:(NIMChatroom *)chatroom currentMeeting:(NIMNetCallMeeting*)currentMeeting capture:(NTESMediaCapture*)capture delegate:(id<NTESAnchorLiveViewControllerDelegate>)delegate;

- (instancetype)initWithChatroom:(NIMChatroom *)chatroom;

@end

