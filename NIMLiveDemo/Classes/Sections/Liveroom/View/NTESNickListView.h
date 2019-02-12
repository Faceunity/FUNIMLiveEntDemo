//
//  NTESNickListView.h
//  NIMLiveDemo
//
//  Created by Netease on 2018/9/18.
//  Copyright © 2018年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTESNickListView : UIView

@property (nonatomic, strong) NSMutableArray <NSString *> *nicks;

@property (nonatomic, readonly) CGFloat estimationHeight;

@end
