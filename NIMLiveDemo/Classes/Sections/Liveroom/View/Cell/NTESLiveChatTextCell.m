//
//  NTESLiveChatTextCell.m
//  NIMLiveDemo
//
//  Created by chris on 16/3/28.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESLiveChatTextCell.h"
#import "M80AttributedLabel.h"
#import "UIView+NTES.h"

@interface NTESLiveChatTextCell()

@property (nonatomic,strong) M80AttributedLabel *attributedLabel;

@end

@implementation NTESLiveChatTextCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:self.attributedLabel];
    }
    return self;
}

- (void)refresh:(NTESMessageModel *)model
{
    [self.attributedLabel setAttributedText:model.formatMessage];
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.attributedLabel.frame = CGRectInset(self.bounds, 10, 0);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{

}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    
}

#pragma mark - Get
- (M80AttributedLabel *)attributedLabel
{
    if (!_attributedLabel) {
        _attributedLabel = [[M80AttributedLabel alloc] init];
        _attributedLabel.numberOfLines = 0;
        _attributedLabel.font = Chatroom_Message_Font;
        _attributedLabel.backgroundColor = [UIColor clearColor];
        _attributedLabel.lineBreakMode = kCTLineBreakByCharWrapping;
    }
    return _attributedLabel;
}

@end
