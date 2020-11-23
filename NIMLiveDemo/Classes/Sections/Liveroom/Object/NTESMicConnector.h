//
//  NTESMicConnector.h
//  NIMLiveDemo
//
//  Created by chris on 16/7/22.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTESLiveViewDefine.h"

@interface NTESMicConnector : NSObject

@property (nonatomic,copy)   NSString *uid;

@property (nonatomic,assign) NIMNetCallMediaType type;

@property (nonatomic,assign) NTESLiveMicState state;

@property (nonatomic,copy)   NSString *avatar;

@property (nonatomic,copy)   NSString *nick;

@property (nonatomic,assign) UInt64 meetingUid;

@property (nonatomic,assign) BOOL isSelected;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

+ (instancetype)me:(NSString *)roomId;

@end
