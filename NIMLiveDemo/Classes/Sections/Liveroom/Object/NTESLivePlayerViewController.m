//
//  NTESLivePlayerViewController.m
//  NIMLiveDemo
//
//  Created by chris on 16/3/2.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESLivePlayerViewController.h"
#import <NELivePlayerFramework/NELivePlayerFramework.h>
#import "NTESBundleSetting.h"
#import "NTESLiveManager.h"
#import "UIView+NTES.h"
#import "NTESAudioInfo.h"

///播放器第一帧视频显示时的消息通知
NSString *const NTESLivePlayerFirstVideoDisplayedNotification = @"NELivePlayerFirstVideoDisplayedNotification";
///播放器第一帧音频播放时的消息通知
NSString *const NTESLivePlayerFirstAudioDisplayedNotification = @"NELivePlayerFirstAudioDisplayedNotification";
///播放器加载状态发生改变时的消息通知
NSString *const NTESLivePlayerLoadStateChangedNotification = @"NELivePlayerLoadStateChangedNotification";
///播放器播放完成或播放发生错误时的消息通知
NSString *const NTESLivePlayerPlaybackFinishedNotification = @"NELivePlayerPlaybackFinishedNotification";
///播放器播放状态发生改变时的消息通知
NSString *const NTESLivePlayerPlaybackStateChangedNotification = @"NELivePlayerPlaybackStateChangedNotification";


@interface NTESLivePlayerInfo : NSObject

@property (nonatomic,copy) NSString *streamUrl;

@property (nonatomic,weak) UIView *container;

@end

@interface NTESLivePlayerViewController()
{
    BOOL _isShutdowning;
    NTESLivePlayerInfo *_nextPlayerInfo;
}

@property (nonatomic,copy)   NSString *playUrl;

@property (nonatomic,weak)   UIView *container;

@property (nonatomic,assign) BOOL isMute;

@property (nonatomic,assign) BOOL isAnchorPKing;

@property (nonatomic,strong) NELivePlayerController *player;

@property (nonatomic,assign) NELPMovieScalingMode scalingMode;

@property (nonatomic,strong) NSMutableSet<NTESLivePlayerShutdownHandler> *shutdownHandlers;

@end

@implementation NTESLivePlayerViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _shutdownHandlers = [[NSMutableSet alloc] init];
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(livePlayerDidPreparedToPlay:)
                                                 name:NELivePlayerDidPreparedToPlayNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(livePlayerPlayBackFinished:)
                                                 name:NELivePlayerPlaybackFinishedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(livePlayerReleaseSueecssed:)
                                                 name:NELivePlayerReleaseSueecssNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(livePlayerWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidPlay) name:NELivePlayerFirstVideoDisplayedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidPlay) name:NELivePlayerFirstAudioDisplayedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(livePlayerWillBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.player.view removeFromSuperview];
    [self shutdown];
}


- (void)startPlay:(NSString *)streamUrl inView:(UIView *)view;
{
    _nextPlayerInfo = [[NTESLivePlayerInfo alloc] init];
    _nextPlayerInfo.streamUrl = streamUrl;
    _nextPlayerInfo.container = view;
    
    if (self.player) {
        [self.player.view removeFromSuperview];
        [self shutdown];
    }else{
        [self startPlay:_nextPlayerInfo];
    }
    [self setScalingMode:NELPMovieScalingModeAspectFit];
}

- (void)startPlay:(NTESLivePlayerInfo *)info
{
    self.playUrl = info.streamUrl;
    self.container = info.container;
    self.player = [self makePlayer:info.streamUrl];
    DDLogInfo(@"player %@ try to start play url %@",self.player,info.streamUrl);
    [info.container addSubview:self.player.view];
    if (![self.player isPreparedToPlay]) {
        [self.player prepareToPlay];
    }
    _nextPlayerInfo = nil;
}

- (void)adjustPlayerView
{
    NELPVideoInfo info;
    [self.player getVideoInfo:&info];
    CGSize size = CGSizeMake(info.width, info.height);
    if (!CGSizeEqualToSize(size, CGSizeZero)) {
        DDLogInfo(@"get video info complete, width:%zd, height:%zd",info.width,info.height);
        if ([self videoInfoIsFromPC:size])
        {
            [self adjustPlayerViewFromPC:size];
        }
        else
        {
            [self adjustPlayerViewFromMobile:size];
        }
    }
    self.player.view.userInteractionEnabled = NO;
}

- (BOOL)videoInfoIsFromPC:(CGSize)size
{
    return size.width/size.height >= 4/3;  //大于等于4:3的屏幕，都认为是PC屏
}

- (void)adjustPlayerViewFromMobile:(CGSize)size
{
    UIView *superview = self.player.view.superview;
    
    if (self.isAnchorPKing) {
        CGFloat width  = superview.width;
        CGFloat height = superview.height;
        self.player.view.frame = CGRectMake(0, 0, width, height);
    }
    else
    {
        CGFloat scaleW = superview.width/size.width;
        CGFloat scaleH = superview.height/size.height;
        CGFloat scale  = scaleW > scaleH? scaleW : scaleH;
        CGFloat width  = size.width * scale;
        CGFloat height = size.height * scale;
        self.player.view.frame = CGRectMake(0, 0, width, height);
    }
    //放到右下角，保证小屏幕不会被裁掉
    self.player.view.bottom = superview.bottom;
    self.player.view.right  = superview.width;
}

- (void)adjustPlayerViewFromPC:(CGSize)size
{
    //因为 ScalingMode 本身是 NELPMovieScalingModeAspectFit，会黑边填充，所以放大到和 superview 一样大就好了
    UIView *superview = self.player.view.superview;
    self.player.view.frame = superview.bounds;
}


- (void)livePlayerDidPreparedToPlay:(NSNotification *)notification
{
    [self.player setMute:self.isMute];
    [self.player play];
}

- (void)livePlayerWillEnterForeground:(NSNotification *)notification
{
    [self.player play];
}

- (void)livePlayerWillBecomeActive:(NSNotification *)notification
{
    [self.player play];
}


- (void)onToggleScaleMode:(BOOL)fullScreen
{
    if ([self.delegate respondsToSelector:@selector(onToggleScaleMode:)]) {
        [self.delegate onToggleScaleMode:fullScreen];
    }
}


- (void)livePlayerPlayBackFinished:(NSNotification*)notification
{
    switch ([[[notification userInfo] valueForKey:NELivePlayerPlaybackDidFinishReasonUserInfoKey] intValue])
    {
        case NELPMovieFinishReasonPlaybackEnded:{
            DDLogDebug(@"playback end, will retry in 10 sec.");
            [self retry:10];
            break;
        }
        case NELPMovieFinishReasonPlaybackError:
        {
            DDLogDebug(@"playback error, will retry in 5 sec.");
            [self retry:5];
            break;
        }
        case NELPMovieFinishReasonUserExited:
            DDLogDebug(@"playback user exited.");
            break;
            
        default:
            break;
    }
}


- (void)playerDidPlay
{
    [self adjustPlayerView];
}


- (void)livePlayerReleaseSueecssed:(NSNotification *)notification
{
    DDLogInfo(@"player resource has release successed! notification is main thread %zd",[[NSThread currentThread] isMainThread]);
    dispatch_async_main_safe(^{
        _isShutdowning = NO;
        [self fireShutdownHandlers];
        
        if (_nextPlayerInfo) {
            DDLogInfo(@"find next player info");
            [self startPlay:_nextPlayerInfo];
        }
    });
}

- (void)shutdown:(NTESLivePlayerShutdownHandler)handler
{
    if (handler) {
        [self.shutdownHandlers addObject:handler];
    }
    [self shutdown];
}

- (BOOL)shutdown
{
    if (!self.player) {
        DDLogInfo(@"player is not initialized, may be called in dealloc function, ignore the shutdown request");
        [self fireShutdownHandlers];
        return NO;
    }
    if (_isShutdowning) {
        DDLogInfo(@"player %@ is now shutdowning, ignore the shutdown request",self.player);
        return NO;
    }
    _isShutdowning = YES;
    DDLogInfo(@"player %@ is now shutdowning",self.player);
    [self.player shutdown];
    self.player = nil;
    return YES;
}


- (void)fireShutdownHandlers{
    DDLogInfo(@"try to fire shut down handlers, handler count %zd",self.shutdownHandlers.count);
    for (NTESLivePlayerShutdownHandler handler in self.shutdownHandlers) {
        handler();
    }
    [self.shutdownHandlers removeAllObjects];
    DDLogInfo(@"try to fire shut down handlers,completion");

}


- (void)retry:(NSTimeInterval)delay
{
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (weakSelf) {
            DDLogInfo(@"start retry, url: %@, container:%@",weakSelf.playUrl,weakSelf.container);
            [weakSelf startPlay:weakSelf.playUrl inView:weakSelf.container];
        }
    });
}

#pragma mark - Get
- (NELivePlayerController *)makePlayer:(NSString *)streamUrl
{
    NELivePlayerController *player;
    NSURL *url = [NSURL URLWithString:streamUrl];
    player = [[NELivePlayerController alloc] initWithContentURL:url error:nil];
    DDLogInfo(@"live player start version %@",[NELivePlayerController getSDKVersion]);
    player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    NELPBufferStrategy strategy  = [[NTESBundleSetting sharedConfig] preferredBufferStrategy];
    [player setBufferStrategy:strategy];
    DDLogInfo(@"live player set buffer strategy %zd",strategy);
    [player setHardwareDecoder:NO];
    [player setOpenReceiveSyncData:YES];
    
    __weak typeof(self) weakSelf = self;
    [player registerSyncContentCB:^(NELivePlayerSyncContent *content) {
        //DDLogInfo(@"%@", content);
        [weakSelf didProcessSyncContent:content];
    }];
    
    if (!player) {
        [self retry:5];
    }
    return player;
}

- (void)didProcessSyncContent:(NELivePlayerSyncContent *)content {
    for (NSString *jsonStr in content.contents) {
        NTESAudioInfo *info = [[NTESAudioInfo alloc] initWithJsonString:jsonStr];
        for (NTESAudioNodeInfo *obj in info.nodesInfo) {
            [self didUpdateVolume:obj.energy meetingUid:[obj.uid longLongValue]];
        }
    }
}

- (void)didUpdateVolume:(UInt16)volume meetingUid:(UInt64)meetingUid {}

- (void)setScalingMode:(NELPMovieScalingMode)aScalingMode
{
    _scalingMode = aScalingMode;
    [self.player setScalingMode:aScalingMode];
}

@end


@implementation NTESLivePlayerInfo

@end
