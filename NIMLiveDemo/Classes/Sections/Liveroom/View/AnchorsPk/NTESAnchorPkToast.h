//
//  NTESAnchorPkToast.h
//  NIMLiveDemo
//
//  Created by Netease on 2018/10/24.
//  Copyright © 2018年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NTESAnchorPkToast : UIView

@property (nonatomic, copy) NSString *srcNick;
@property (nonatomic, copy) NSString *dstNick;

//计时器类型toast
+ (instancetype)instanceTimerToast;

//PK昵称类型toast
+ (instancetype)instanceNickToastWithSrcName:(NSString *)srcNick
                                     dstNick:(NSString *)dstNick;

@end

NS_ASSUME_NONNULL_END
