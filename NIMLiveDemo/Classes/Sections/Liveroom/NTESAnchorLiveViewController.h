//
//  NTESAnchorLiveViewController.h
//  NIM
//
//  Created by chris on 15/12/16.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTESMediaCapture.h"

@protocol NTESAnchorLiveViewControllerDelegate <NSObject>

-(void)onCloseLiveView;

@end


@interface NTESFiterStatusModel : NSObject

@property (nonatomic) NSInteger filterIndex;

@property (nonatomic) CGFloat smoothValue;

@property (nonatomic) CGFloat constrastValue;

@end

@interface NTESAnchorLiveViewController : UIViewController

@property (nonatomic) NIMVideoOrientation orientation;

@property (nonatomic ,strong ) NTESFiterStatusModel *filterModel;

- (instancetype)initWithChatroom:(NIMChatroom *)chatroom currentMeeting:(NIMNetCallMeeting*)currentMeeting capture:(NTESMediaCapture*)capture delegate:(id<NTESAnchorLiveViewControllerDelegate>)delegate;

- (instancetype)initWithChatroom:(NIMChatroom *)chatroom;

@end

