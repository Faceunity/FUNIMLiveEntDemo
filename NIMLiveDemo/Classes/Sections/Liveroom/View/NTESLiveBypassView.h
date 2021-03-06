//
//  NTESLiveBypassView.h
//  NIMLiveDemo
//
//  Created by chris on 16/7/26.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
@class NTESMicConnector;

typedef NS_ENUM(NSInteger, NTESLiveBypassViewStatus){
    NTESLiveBypassViewStatusNone,
    NTESLiveBypassViewStatusPlaying,
    NTESLiveBypassViewStatusPlayingAndBypassingAudio,
    NTESLiveBypassViewStatusLoading,
    NTESLiveBypassViewStatusStreamingVideo,
    NTESLiveBypassViewStatusStreamingAudio,
    NTESLiveBypassViewStatusLocalVideo,
    NTESLiveBypassViewStatusLocalAudio,
    NTESLiveBypassViewStatusExitConfirm,
};

@protocol NTESLiveBypassViewDelegate <NSObject>

- (void)didConfirmExitBypassWithUid:(NSString *)uid;

@end

@interface NTESLiveBypassView : UIView

@property (nonatomic, assign) BOOL isAnchor;

@property (nonatomic, copy) NSString *uid;

@property (nonatomic, assign) UInt16 volume;

@property (nonatomic, weak) id<NTESLiveBypassViewDelegate> delegate;

@property (nonatomic, strong) UIView *localVideoDisplayView;

- (void)refresh:(NTESMicConnector *)connector status:(NTESLiveBypassViewStatus)status;

- (void)addRemoteView:(UIView *)remoteView;
@end
