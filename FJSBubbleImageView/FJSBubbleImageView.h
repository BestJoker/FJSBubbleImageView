//
//  FJSBubbleImageView.h
//  FJSBubbleImageView
//
//  Created by 付金诗 on 16/6/18.
//  Copyright © 2016年 www.fujinshi.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FJSBubbleImageView;
@protocol FJSBubbleImageViewDelegate <NSObject>
@optional
- (void)bubbleViewDidBeginEditing:(FJSBubbleImageView *)bubbleView;
- (void)bubbleViewDidChangeEditing:(FJSBubbleImageView *)bubbleView;
- (void)bubbleViewDidEndEditing:(FJSBubbleImageView *)bubbleView;
- (void)bubbleViewDidClose:(FJSBubbleImageView *)bubbleView;
@end

@interface FJSBubbleImageView : UIImageView<UITextViewDelegate>
@property (assign, nonatomic) CGSize      minSize;
@property (assign, nonatomic) CGFloat     minFontSize;
@property (retain, nonatomic) UIFont      *curFont;
@property (nonatomic,assign)id<FJSBubbleImageViewDelegate> bubbleDelegate;

- (instancetype)initWithFrame:(CGRect)frame andSize:(CGSize)superSize andPoint:(CGPoint)point andText:(NSString *)text;

- (NSString *)textString;
@end
