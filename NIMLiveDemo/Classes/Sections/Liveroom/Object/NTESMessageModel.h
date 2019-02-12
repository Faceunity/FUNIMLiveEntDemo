//
//  NTESMessageModel.h
//  NIMLiveDemo
//
//  Created by chris on 16/3/28.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NTESMessageModel : NSObject

@property (nonatomic,strong) NIMMessage *message;

@property (nonatomic,assign) CGFloat height;

@property (nonatomic,readonly) NSAttributedString *formatMessage;

@property (nonatomic,assign,readonly) NSRange nickRange;

@property (nonatomic,assign,readonly) NSRange textRange;

- (void)caculate:(CGFloat)width;

@end