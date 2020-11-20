//
//  NTESAudioInfo.h
//  NIMLiveDemo
//
//  Created by Netease on 2019/4/15.
//  Copyright © 2019年 Netease. All rights reserved.
//  http://doc.hz.netease.com/pages/viewpage.action?pageId=183927235 模型定义

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class NTESAudioNodeInfo;

@interface NTESAudioInfo : NSObject

@property (nonatomic, strong) NSMutableArray <NTESAudioNodeInfo *>*nodesInfo; //节点音频信息

@property (nonatomic, assign) NSInteger selectMember; //ASL出来混音的人数

@property (nonatomic, assign) NSInteger totalMember; //当前音频总人数

- (instancetype)initWithJsonString:(NSString *)json;

@end

@interface NTESAudioNodeInfo : NSObject

@property (nonatomic, copy) NSString *uid; //用户id

@property (nonatomic, assign) NSInteger energy; //音频量能

- (instancetype)initWithDic:(NSDictionary *)dic;

@end

NS_ASSUME_NONNULL_END
