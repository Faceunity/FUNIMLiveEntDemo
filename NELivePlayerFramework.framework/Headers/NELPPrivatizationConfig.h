//
//  NELPPrivatizationConfig.h
//  NELivePlayerFramework
//
//  Created by Netease on 2018/9/11.
//  Copyright © 2018年 netease. All rights reserved.
//  私有化配置管理类

#import <Foundation/Foundation.h>

@interface NELPPrivatizationConfig : NSObject

/**
 gslb私有化开关。YES：开启私有化  NO：关闭私有化
 */
@property (nonatomic, assign) BOOL openGslbConfig;

/**
 gslb私有化请求地址。openGslbConfig为YES时，使用该地址进行gslb调度，如为nil，关闭gslb调度功能。
 */
@property (nonatomic, copy) NSString *gslbRequestAddress;

/**
 统计上报私有化开关。YES：开启私有化  NO：关闭私有化
 */
@property (nonatomic, assign) BOOL openStatisticsConfig;

/**
 统计上报私有化请求地址。openStatisticsConfig为YES时，使用该地址进行统计上报，如为nil，关闭统计上报功能。
 */
@property (nonatomic, copy) NSString *statisticsReportAddress;

/**
 日志上传私有化开关。YES：开启私有化  NO：关闭私有化。
 */
@property (nonatomic, assign) BOOL openLoggerConfig;

/**
 日志上传请求地址。isOpenLoggerUpdatePrivatization为YES时，使用该地址进行日志上传，如为nil，关闭日志上传功能。
 */
@property (nonatomic, copy) NSString *loggerUploadAddress;

/**
 加密视频密钥请求私有化开关。YES：开启私有化  NO：关闭私有化
 */
@property (nonatomic, assign) BOOL openKeyConfig;

/**
 加密视频密钥私有化请求地址。openKeyConfig为YES时，使用该地址进行密钥请求，如为nil，关闭密钥请求功能。
 */
@property (nonatomic, copy) NSString *keyRequestAddress;

+ (instancetype)shareConfig;

@end
