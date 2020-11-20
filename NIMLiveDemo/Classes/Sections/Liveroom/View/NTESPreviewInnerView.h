//
//  NTESPreviewInnerView.h
//  NIMLiveDemo
//
//  Created by Simon Blue on 17/3/21.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTESAnchorLiveViewController.h"
@protocol NTESPreviewInnerViewDelegate <NSObject>

@optional

- (void)onCloseLiving;
- (void)onStartLiving;
- (void)onRotate:(NIMVideoOrientation)orientation;
- (void)onCameraRotate;
- (BOOL)interactionDisabled;

@end

@interface NTESPreviewInnerView : UIView

@property (nonatomic,weak) id<NTESPreviewInnerViewDelegate> delegate;

- (instancetype)initWithChatroom:(NSString *)chatroomId
                           frame:(CGRect)frame;

- (void)switchToPreviewUI;

- (void)switchToWaitingUI;

- (void)switchToLinkingUI;

- (void)switchToEndUI;

- (NTESFiterStatusModel *)getFilterModel;

- (void)updateBeautifyButton:(BOOL)isOn;

@end
