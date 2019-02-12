//
//  NTESMessageModel.m
//  NIMLiveDemo
//
//  Created by chris on 16/3/28.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESMessageModel.h"
#import "M80AttributedLabel.h"
#import "NTESUserUtil.h"
#import "NTESLiveManager.h"

@implementation NTESMessageModel

- (void)caculate:(CGFloat)width
{
    M80AttributedLabel *label = NTESCaculateLabel();
    [label setAttributedText:self.formatMessage];
    CGSize size = [label sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    self.height = size.height;
}

- (NSAttributedString *)formatMessage
{
    NSString *showMessage = [self showMessage];
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:showMessage];
    
    NIMChatroom *room = [[NTESLiveManager sharedInstance] roomInfo:self.message.session.sessionId];
    
    BOOL isCreator = [room.creator isEqualToString:self.message.from];
    UIColor *nickColor = isCreator? UIColorFromRGB(0xfaec55) : UIColorFromRGB(0xc2ff9a);
    
    [text setAttributes:@{NSForegroundColorAttributeName:nickColor,NSFontAttributeName:Chatroom_Message_Font} range:self.nickRange];
    [text setAttributes:@{NSForegroundColorAttributeName:UIColorFromRGB(0xffffff),NSFontAttributeName:Chatroom_Message_Font} range:self.textRange];

    
    return text;
}

- (NSRange)nickRange
{
    NSString *nickName = [NTESUserUtil showName:self.message.from withMessage:self.message];
    return NSMakeRange(0, nickName.length);
}

- (NSRange)textRange
{
    NSString *showMessage = [self showMessage];
    return NSMakeRange(showMessage.length - self.message.text.length, self.message.text.length);
}

- (NSString *)showMessage
{
    NSString *nickName = [NTESUserUtil showName:self.message.from withMessage:self.message];
    NSString *showMessage = [NSString stringWithFormat:@"%@  %@",nickName,self.message.text];
    return showMessage;
}

M80AttributedLabel *NTESCaculateLabel()
{
    static M80AttributedLabel *label;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        label = [[M80AttributedLabel alloc] init];
        label.font = Chatroom_Message_Font;
        label.numberOfLines = 0;
        label.lineBreakMode = kCTLineBreakByCharWrapping;
    });
    return label;
}

@end
