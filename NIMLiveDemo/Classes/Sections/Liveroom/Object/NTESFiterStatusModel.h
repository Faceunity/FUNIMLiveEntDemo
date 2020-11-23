//
//  NTESFilterModel.h
//  NIMLiveDemo
//
//  Created by Simon Blue on 2019/10/24.
//  Copyright © 2019 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NTESFiterStatusModel : NSObject

@property (nonatomic) NSInteger filterIndex;

@property (nonatomic) CGFloat smoothValue;

@property (nonatomic) CGFloat constrastValue;

@end

NS_ASSUME_NONNULL_END
