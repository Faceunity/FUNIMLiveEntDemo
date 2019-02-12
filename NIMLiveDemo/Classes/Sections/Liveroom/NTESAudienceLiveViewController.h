//
//  NTESAudienceLiveViewController.h
//  NIMLiveDemo
//
//  Created by chris on 16/8/15.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESLivePlayerViewController.h"

@interface NTESAudienceLiveViewController : NTESLivePlayerViewController

- (instancetype)initWithChatroomId:(NSString *)chatroomId streamUrl:(NSString *)url;

@end
