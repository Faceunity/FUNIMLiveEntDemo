//
//  NTESLivePresentCell.h
//  NIMLiveDemo
//
//  Created by chris on 16/3/30.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
@class NTESLivePresentCell;

@protocol NTESLivePresentCellDelegate <NSObject>

- (void)cellDidHide:(NTESLivePresentCell *)cell
            message:(NIMMessage *)message;

@end

@interface NTESLivePresentCell : UITableViewCell

@property (nonatomic,weak) id<NTESLivePresentCellDelegate> delegate;

- (void)refreshWithPresentMessage:(NIMMessage *)message;

- (void)show;
- (void)hide;

@end
