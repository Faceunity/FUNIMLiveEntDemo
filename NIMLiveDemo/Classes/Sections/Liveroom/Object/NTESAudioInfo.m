//
//  NTESAudioInfo.m
//  NIMLiveDemo
//
//  Created by Netease on 2019/4/15.
//  Copyright © 2019年 Netease. All rights reserved.
//

#import "NTESAudioInfo.h"
#import "NSDictionary+NTESJson.h"

@implementation NTESAudioInfo

- (instancetype)initWithJsonString:(NSString *)json {
    if (self = [super init]) {
        NSDictionary *dic = [NSDictionary dictionaryWithJsonString:json];
        if (!dic) {
            return nil;
        }
        
        NSString *mixAudioInfoString = [dic jsonString:@"MixAudioInfo"];
        NSDictionary *micAudioInfoDic = [NSDictionary dictionaryWithJsonString:mixAudioInfoString];
        if (!micAudioInfoDic) {
            return nil;
        }
        
        _selectMember = [micAudioInfoDic jsonInteger:@"SelectMember"];
        _totalMember = [micAudioInfoDic jsonInteger:@"TotalMember"];
        NSArray *nodeDics = [micAudioInfoDic jsonArray:@"NodesInfo"];
        _nodesInfo = [NSMutableArray array];
        for (NSDictionary *obj in nodeDics) {
            NTESAudioNodeInfo *info = [[NTESAudioNodeInfo alloc] initWithDic:obj];
            if (info) {
                [_nodesInfo addObject:info];
            }
        }
    }
    return self;
}

@end

@implementation NTESAudioNodeInfo
- (instancetype)initWithDic:(NSDictionary *)dic {
    if (self = [super init]) {
        if (!dic) {
            return nil;
        }
        _energy = [dic jsonInteger:@"Energy"];
        _uid = [dic jsonString:@"Uid"];
    }
    return self;
}

@end
