//
//  NTESTextInputView.m
//  NIMLiveDemo
//
//  Created by chris on 16/3/28.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESTextInputView.h"
#import "UIView+NTES.h"

@interface NTESTextInputView()<NTESGrowingTextViewDelegate>

@end

@implementation NTESTextInputView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        [self addSubview:self.textView];
        [self addSubview:self.sendButton];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat spacing = 10.f;
    CGFloat sendbuttonWidth = 70.f;
    CGFloat textViewWidth = self.width - spacing * 2 - sendbuttonWidth;
    
    self.textView.width = textViewWidth;
    self.textView.left  = spacing;
    self.textView.centerY = self.height * .5f;
    
    self.sendButton.width  = sendbuttonWidth;
    self.sendButton.right  = self.width;
    self.sendButton.height = self.height;
}

#pragma mark - NTESGrowingTextViewDelegate
- (void)willChangeHeight:(CGFloat)height
{
    CGFloat bottom = self.bottom;
    self.size = [self measureViewSize:height];
    self.bottom = bottom;
    
    if ([self.delegate respondsToSelector:@selector(willChangeHeight:)]) {
        [self.delegate willChangeHeight:height];
    }
}

- (void)didChangeHeight:(CGFloat)height
{
    if ([self.delegate respondsToSelector:@selector(didChangeHeight:)]) {
        [self.delegate didChangeHeight:height];
    }
}

- (BOOL)shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)replacementText
{
    if ([replacementText isEqualToString:@"\n"]) {
        [self onSend:self.textView.text];
        return NO;
    }
    return YES;
}


#pragma mark - Get
- (NTESGrowingTextView *)textView
{
    if (!_textView) {
        _textView = [[NTESGrowingTextView alloc] initWithFrame:CGRectMake(0, 0, 0, 36.f)];
        _textView.textViewDelegate  = self;
    }
    return _textView;
}


- (UIButton *)sendButton
{
    if (!_sendButton) {
        _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_sendButton setBackgroundColor:UIColorFromRGB(0x2294ff)];
        _sendButton.titleLabel.font = [UIFont systemFontOfSize:14.f];
        [_sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_sendButton setTitle:@"发送" forState:UIControlStateNormal];
        [_sendButton addTarget:self action:@selector(onSend:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sendButton;
}


- (void)onSend:(id)sender
{
    NSString *text = self.textView.text;
    if (!text.length) {
        return;
    }
    self.textView.text = @"";
    if ([self.delegate respondsToSelector:@selector(didSendText:)]) {
        [self.delegate didSendText:text];
    }
}


#pragma mark - Private
- (CGSize)measureViewSize:(CGFloat)newTextViewHeight
{
    CGFloat topSpacing = (self.height - self.textView.height) / 2;
    CGFloat height = topSpacing * 2 + newTextViewHeight;
    return CGSizeMake(self.width, height);
}


@end
