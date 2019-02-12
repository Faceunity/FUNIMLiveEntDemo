//
//  NTESAlertSheetView.h
//  NIMLiveDemo
//
//  Created by Netease on 2018/10/19.
//  Copyright © 2018年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NTESAlertSheetView;
@protocol NTESAlertSheetViewDelegate <NSObject>

- (void)NTESAlertSheetDidSeletedInputSure:(NTESAlertSheetView *)alert
                                    input:(NSString *)input;

- (void)NTESAlertSheetDidWaitingCancel:(NTESAlertSheetView *)alert;

- (void)NTESAlertSheetDidSeletedEnd:(NTESAlertSheetView *)alert;

@end

@interface NTESAlertSheetView : UIControl

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, strong) NSString *imageUrl;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, weak) id <NTESAlertSheetViewDelegate> delegate;

//显示信息类型框
+ (instancetype)showMessageWithTitle:(nullable NSString *)title
                             message:(nullable NSString *)message;

//显示输入类型框
+ (instancetype)showInputWithTitle:(nullable NSString *)title
                          subtitle:(nullable NSString *)subtitle
                          delegate:(nullable id<NTESAlertSheetViewDelegate>)delegate;

//显示等待类型框
+ (instancetype)showWaitWithTitle:(nullable NSString *)title
                            image:(nullable NSString *)imageUrl
                             name:(nullable NSString *)name
                         delegate:(nullable id<NTESAlertSheetViewDelegate>)delegate;

//显示结束类型框
+ (instancetype)showEndWithTitle:(nullable NSString *)title
                           image:(nullable NSString *)imageUrl
                            name:(nullable NSString *)name
                        delegate:(nullable id<NTESAlertSheetViewDelegate>)delegate;

//显示
- (void)show;

//隐藏
- (void)dismiss;

//隐藏
- (void)dismissWithCompletion:(nullable void (^)())completion;

@end



NS_ASSUME_NONNULL_END
