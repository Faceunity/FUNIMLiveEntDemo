//
//  NTESBypassLiveViewController.h
//  NIMLiveDemo
//
//  Created by Simon Blue on 2019/10/25.
//  Copyright © 2019 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@class NTESFiterStatusModel;

@protocol NTESAnchorLiveViewControllerDelegate <NSObject>

- (void)onCloseLiveView;

@optional

- (void)onExitRoom;

@end

@interface NTESBypassLiveViewController : UIViewController

@property (nonatomic) NIMVideoOrientation orientation;

@property (nonatomic ,strong ) NTESFiterStatusModel *filterModel;

@end

NS_ASSUME_NONNULL_END
