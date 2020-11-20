//
//  NTESLiveViewDefine.h
//  NIMLiveDemo
//
//  Created by chris on 16/4/5.
//  Copyright © 2016年 Netease. All rights reserved.
//

#ifndef NTESLiveViewDefine_h
#define NTESLiveViewDefine_h

typedef NS_ENUM(NSInteger, NTESLiveRole){
    NTESLiveRoleAnchor,
    NTESLiveRoleAudience,
};

typedef NS_ENUM(NSInteger, NTESLiveType){
    NTESLiveTypeInvalid = -1,  //直播未开始
    NTESLiveTypeAudio = NIMNetCallMediaTypeAudio,    //音频直播
    NTESLiveTypeVideo = NIMNetCallMediaTypeVideo,    //视频直播
};

typedef NS_ENUM(NSInteger, NTESBypassType){
    NTESBypassTypeRoom,
    NTESBypassTypeAnchor,
};



typedef NS_ENUM(NSInteger, NTESLiveActionType)
{
    
    NTESLiveActionTypeLive,     //点直播按钮
    NTESLiveActionTypeLike,     //点赞
    NTESLiveActionTypePresent,  //礼物
    NTESLiveActionTypeShare,    //分享
    NTESLiveActionTypeCamera,   //旋转摄像头
    NTESLiveActionTypeQuality,  //分辨率
    NTESLiveActionTypeInteract, //互动
    NTESLiveActionTypeBeautify, //美颜
    NTESLiveActionTypeMixAudio,  //混音
    NTESLiveActionTypeSnapshot,  //截图
    NTESLiveActionTypeChat,      //聊天
    NTESLiveActionTypeMoveUp,    //点上移按钮
    NTESLiveActionTypeMirror,    //镜像
    NTESLiveActionTypeWaterMark, //水印
    NTESLiveActionTypeFlash,   //闪光灯
    NTESLiveActionTypeZoom,      //焦距调节
    NTESLiveActionTypeFocus,     //开启手动对焦
    NTESLiveActionTypePk,        //主播PK

};

typedef NS_ENUM(NSInteger, NTESLiveQuality)
{
    NTESLiveQualityHigh,      //高清
    NTESLiveQualityNormal,    //流畅
};


typedef NS_ENUM(NSInteger, NTESLiveMicState)
{
    NTESLiveMicStateNone,       //初始状态
    NTESLiveMicStateWaiting,    //队列等待
    NTESLiveMicStateConnecting, //连接中
    NTESLiveMicStateConnected,  //已连接
};


typedef NS_ENUM(NSInteger, NTESLiveCustomNotificationType)
{
    NTESLiveCustomNotificationTypePushMic = 1,    //加入连麦队列通知
    NTESLiveCustomNotificationTypePopMic  = 2,    //退出连麦队列通知
    NTESLiveCustomNotificationTypeAgreeConnectMic  = 3,  //同意连麦
    NTESLiveCustomNotificationTypeForceDisconnect  = 4,  //主播强制让连麦者断开
    NTESLiveCustomNotificationTypeRejectAgree      = 5,  //拒绝主播的同意连麦
    
    NTESLiveCustomNotificationTypePkOnlineRequest = 6, //主播推流请求在线状态
    NTESLiveCustomNotificationTypePkOnlineResponse = 7, //在线响应
    NTESLiveCustomNotificationTypePkRequest = 8, //PK请求
    NTESLiveCustomNotificationTypePkCancel = 9, //PK取消
    NTESLiveCustomNotificationTypePkAgree = 10, //同意PK
    NTESLiveCustomNotificationTypePkReject = 11,//拒绝PK
    NTESLiveCustomNotificationTypePkInvalid = 12,//无效用户
    NTESLiveCustomNotificationTypePkBusy = 13,//正在PK
    NTESLiveCustomNotificationTypePkDidExit = 14,//用户已经退出音视频房间
    NTESLiveCustomNotificationTypePkRoomByapssOnlineRequest = 15,//房间推流请求在线状态

};

typedef NS_ENUM(NSUInteger, NTESFilterType) {
    NTESFilterTypeNormal = 0,        //无滤镜.
    NTESFilterTypeSepia,             //黑白
    NTESFilterTypeZiran,             //自然
    NTESFilterTypeMeiyan1,           //粉嫩
    NTESFilterTypeMeiyan2,           //怀旧
};


typedef NS_ENUM(NSUInteger, NTESWaterMarkType) {
    NTESWaterMarkTypeNone = 0,            //无水印.
    NTESWaterMarkTypeNormal,              //静态水印
    NTESWaterMarkTypeDynamic,             //动态水印
};


typedef NS_ENUM(NSUInteger, NTESWaterMarkLocation) {
    NTESWaterMarkLocationRect = 0,      //由rect的origin定位置
    NTESWaterMarkLocationLeftUp,        //左上
    NTESWaterMarkLocationLeftDown,      //左下
    NTESWaterMarkLocationRightUp,       //右上
    NTESWaterMarkLocationRightDown,     //右下
    NTESWaterMarkLocationCenter         //中间
};


/**
 *  应用服务器错误码
 */
typedef NS_ENUM(NSInteger, NTESRemoteErrorCode) {
    /**
     *  数量超过上限
     */
    NTESRemoteErrorCodeOverFlow            = 419,
};


typedef NS_ENUM(NSInteger,NTESAnchorPKStatus)
{
    NTESAnchorPKStatusIdle = 0,   //空闲状态
    NTESAnchorPKStatusPingInteractive, //Ping阶段
    NTESAnchorPKStatusPkInteractive,   //pk请求阶段
    NTESAnchorPKStatusComplete,        //完成阶段
};


#endif /* NTESLiveViewDefine_h */
