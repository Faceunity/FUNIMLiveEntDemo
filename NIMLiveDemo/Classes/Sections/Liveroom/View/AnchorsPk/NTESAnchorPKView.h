//
//  NTESAnchorPKView.h
//  NIMLiveDemo
//
//  Created by Netease on 2018/10/22.
//  Copyright © 2018年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class NTESAnchorPKView;

@protocol NTESAnchorPKViewDelegate <NSObject>

- (void)NTESAnchorPKViewDidExit:(NTESAnchorPKView *)pkView;

@end

typedef NS_ENUM(NSInteger, NTESLivePKViewStatus){
    NTESPKViewStatusNone,
    NTESPKViewStatusLoading,
    NTESPKViewStatusVideoPlaying,
    NTESPKViewStatusAudioPlaying,
    NTESPKViewStatusAudioEnd
};

@interface NTESAnchorPKView : UIView

@property (nonatomic, assign) NTESLivePKViewStatus status;

@property (nonatomic, copy) NSString *nick;

@property (nonatomic, copy) NSString *uid;

@property (nonatomic, weak) id <NTESAnchorPKViewDelegate> delegate;

- (void)updateRemoteView:(NSData *)yuvData
                   width:(NSUInteger)width
                  height:(NSUInteger)height;

@end

NS_ASSUME_NONNULL_END
