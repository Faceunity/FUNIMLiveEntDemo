//
//  NELivePlayerModel.h
//  NELivePlayerFramework
//
//  Created by Netease on 2018/9/27.
//  Copyright © 2018年 netease. All rights reserved.
//  播放器相关模型定义

#import <Foundation/Foundation.h>
#import "NELivePlayerDefine.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - 缓存配置模型
@interface NELPUrlCacheConfig : NSObject

/**
 是否缓存。默认：NO。
 */
@property (nonatomic, assign) BOOL isCache;

/**
 缓存路径。当isCache为YES时，如果配置该路径，则交由外部管理缓存文件。当isCache为NO时，由播放器内部管理缓存文件。
 */
@property (nullable, nonatomic, copy) NSString * cacheRootPath;

@end

#pragma mark - 解密配置模型
@interface NELPUrlDecryptionConfig : NSObject
/**
 * 解密类型
 */
@property (nonatomic, readonly) NELPUrlDecryptionType type;
/**
 * 原始密钥。Type 为 NELPUrlDecryptionOriginalKey 时需要设置
 */
@property (nonatomic, readonly) NSData *originalKey;

/**
 TransferToken.Type 为 NELPUrlDecryptionService 时需要设备
 */
@property (nonatomic, readonly) NSString *transferToken;

/**
 accid 为 NELPUrlDecryptionService 时需要设备
 */
@property (nonatomic, readonly) NSString *accid;

/**
 appKey 为 NELPUrlDecryptionService 时需要设备
 */
@property (nonatomic, readonly) NSString *appKey;

/**
 token 为 NELPUrlDecryptionService 时需要设备
 */
@property (nonatomic, readonly) NSString *token;

/**
 快速构造方法（原始密钥解密）

 @param originalKey 原始密钥
 @return 配置实例
 */
+ (instancetype)configWithOriginalKey:(NSData *)originalKey;

/**
 快速构造方法（服务端管理密钥解密）

 @param transferToken transferToken
 @param accid accid
 @param appKey appKey
 @param token token
 @return 配置实例
 */
+ (instancetype)configWithTransferToken:(NSString *)transferToken
                                  accid:(NSString *)accid
                                 appKey:(NSString *)appKey
                                  token:(NSString *)token;

@end

#pragma mark - 播放源 Url 相关配置模型
@interface NELPUrlConfig : NSObject

/**
 缓存配置
 */
@property (nullable, nonatomic, strong) NELPUrlCacheConfig *cacheConfig;

/**
 解密配置
 */
@property (nullable, nonatomic, strong) NELPUrlDecryptionConfig *decryptionConfig;

@end

#pragma mark - 失败重连配置模型
@interface NELPRetryConfig : NSObject

/**
 重试次数。默认值：0。 -1表示无限重试。
 */
@property (nonatomic, assign) NSTimeInterval count;

/**
 默认重试间隔时间。默认值：0。 0表示立即重试。单位：s
 */
@property (nonatomic, assign) NSTimeInterval defaultIntervalS;

/**
 自定义重试间隔时间。nil表示使用默认间隔。如果数组元素个数大于重试次数，取前面的重试次数个值；如果小于，后面未配置的值使用默认时间间隔。
 */
@property (nonatomic, strong) NSMutableArray <NSNumber *> *customIntervalS;

@end

#pragma mark - HTTP通知信息携带的模型
/**
 * HTTP通知信息携带的模型
 */
@interface NELivePlayerHttpCodeModel : NSObject
/**
 * http 请求返回状态码
 */
@property (nonatomic, assign) int code;
/**
 * http 请求返回Header
 */
@property (nonatomic, copy) NSString *header;
@end

#pragma mark - 自定义透传信息模型
/**
 * 自定义透传信息模型
 */
@interface NELivePlayerSyncContent : NSObject
/**
 * 透传的信息
 */
@property (nonatomic, strong) NSArray <NSString *>*contents;
@end

#pragma mark - 音轨信息模型类
/**
 音轨信息类
 */
@interface NELivePlayerAudioTrackInfo : NSObject

/**
 采样率
 */
@property (nonatomic, assign) NSInteger sampleRate;

/**
 码率
 */
@property (nonatomic, assign) NSInteger bitrate;

/**
 声道数
 */
@property (nonatomic, assign) NSInteger numOfChannels;

/**
 编码器类型
 */
@property (nonatomic, copy) NSString *codecName;

/**
 语言
 */
@property (nonatomic, copy) NSString *language;

/**
 标题
 */
@property (nonatomic, copy) NSString *title;

@end

#pragma mark - PCM配置模型类
/**
 PCM配置模型类
 */
@interface NELivePlayerPcmConfig : NSObject

/**
 通道数
 */
@property (nonatomic, assign) int channels;

/**
 采样率
 */
@property (nonatomic, assign) int sampleRate;

@end

NS_ASSUME_NONNULL_END
