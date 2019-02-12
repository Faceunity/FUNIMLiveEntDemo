//
//  NTESLiveTypeSelectViewController.m
//  NIMLiveDemo
//
//  Created by chris on 16/7/14.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESLiveTypeSelectViewController.h"
#import "NTESAnchorLiveViewController.h"
#import "NTESDemoService.h"
#import "SVProgressHUD.h"
#import "UIView+Toast.h"
#import "NTESLiveManager.h"
#import "NSDictionary+NTESJson.h"
#import "NTESCustomKeyDefine.h"
#import "NTESAnchorPreviewController.h"
#import "NTESLiveUtil.h"

@interface NTESLiveTypeSelectViewController ()

@end

@implementation NTESLiveTypeSelectViewController

NTES_USE_CLEAR_BAR

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configNav];
    [self configStatusBar];
}

- (IBAction)selectVideoLive:(id)sender
{
    [NTESLiveManager sharedInstance].type = NIMNetCallMediaTypeVideo;
    [NTESLiveManager sharedInstance].liveQuality = NTESLiveQualityHigh;
    [self startVideoPreview];
}

- (IBAction)selectAudioLive:(id)sender
{
    [NTESLiveManager sharedInstance].type = NIMNetCallMediaTypeAudio;
    [NTESLiveManager sharedInstance].liveQuality = NTESLiveQualityNormal;
    [self requestLiveRoom];
}

- (void)startVideoPreview
{
    NTESAnchorPreviewController *vc = [[NTESAnchorPreviewController alloc]init];
    [self.navigationController presentViewController:vc animated:YES completion:nil];
}

- (void)requestLiveRoom
{
    [SVProgressHUD show];
    __weak typeof(self) wself = self;
    NSString *errorToast = @"进入失败，请重试";
    NSString *meetingName = [NSUUID UUID].UUIDString;
    [[NTESDemoService sharedService] requestLiveStream:meetingName completion:^(NSError *error, NIMChatroom *chatroom) {
        if (!error)
        {
            NIMChatroomEnterRequest *request = [[NIMChatroomEnterRequest alloc] init];
            request.roomId = chatroom.roomId;
            request.roomNotifyExt = [@{
                                       NTESCMType  : @([NTESLiveManager sharedInstance].type),
                                       NTESCMMeetingName: meetingName
                                      } jsonBody];
            
            [[NIMSDK sharedSDK].chatroomManager enterChatroom:request completion:^(NSError *error, NIMChatroom *room, NIMChatroomMember *me) {
                [SVProgressHUD dismiss];
                if (!error) {
                    //这里拿到的是应用服务器的人数，没有把自己加进去，手动添加。
                    chatroom.onlineUserCount++;
                    //将room的扩展也加进去
                    chatroom.ext =[NTESLiveUtil jsonString:chatroom.ext addJsonString:request.roomNotifyExt];
                    
                    [[NTESLiveManager sharedInstance] cacheMyInfo:me roomId:request.roomId];
                    [[NTESLiveManager sharedInstance] cacheChatroom:chatroom];
                    
                    NTESAnchorLiveViewController *vc = [[NTESAnchorLiveViewController alloc]initWithChatroom:chatroom];

                    [wself.navigationController presentViewController:vc animated:YES completion:nil];
                    
                }
                else
                {
                    DDLogError(@"enter chat room error , code : %zd",error.code);
                    [wself.view makeToast:errorToast duration:2.0 position:CSToastPositionCenter];
                }
            }];
        }
        else
        {
            [SVProgressHUD dismiss];
            DDLogError(@"request stream error , code : %zd",error.code);
            [wself.view makeToast:errorToast duration:2.0 position:CSToastPositionCenter];
        }
    }];
}


- (void)configNav{
    self.navigationItem.title = @"云信娱乐直播Demo";
    self.navigationController.navigationBar.titleTextAttributes =@{NSFontAttributeName:[UIFont boldSystemFontOfSize:17],
                                                                   NSForegroundColorAttributeName:[UIColor whiteColor]};
    
    NSShadow *shadow = [[NSShadow alloc]init];
    shadow.shadowOffset = CGSizeMake(0, 0);
    self.navigationController.navigationBar.titleTextAttributes =@{NSFontAttributeName:[UIFont boldSystemFontOfSize:17],
                                                                   NSForegroundColorAttributeName:[UIColor whiteColor]};
}

- (void)configStatusBar{
    UIStatusBarStyle style = [self preferredStatusBarStyle];
    [[UIApplication sharedApplication] setStatusBarStyle:style
                                                animated:NO];
}

@end
