//
//  FJSBubbleImageView.m
//  FJSBubbleImageView
//
//  Created by 付金诗 on 16/6/18.
//  Copyright © 2016年 www.fujinshi.com. All rights reserved.
//

#import "FJSBubbleImageView.h"

#define IS_IOS_7 ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0f)
#define IMAGE_ICON_SIZE   20
#define MAX_FONT_SIZE     500


CG_INLINE CGPoint CGRectGetCenter(CGRect rect)
{
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

CG_INLINE CGFloat CGPointGetDistance(CGPoint point1, CGPoint point2)
{
    //Saving Variables.
    CGFloat fx = (point2.x - point1.x);
    CGFloat fy = (point2.y - point1.y);
    
    return sqrt((fx*fx + fy*fy));
}

CG_INLINE CGFloat CGAffineTransformGetAngle(CGAffineTransform t)
{
    return atan2(t.b, t.a);
}

@interface FJSBubbleImageView ()
{
    CGPoint prevPoint;
    CGPoint touchLocation;
    
    CGPoint beginningPoint;
    CGPoint beginningCenter;
    
    CGRect beginBounds;
    
    CGRect initialBounds;
    CGFloat initialDistance;
    
    CGFloat deltaAngle;
    
}
@property (strong, nonatomic) UIImageView *resizingControl;//旋转图片
@property (strong, nonatomic) UIImageView *deleteControl;//删除图片
@property (nonatomic,strong)UITextView * textView;
@property (nonatomic,assign)BOOL isDeleting;
@property (nonatomic,assign)NSInteger directionIndex;

@end
@implementation FJSBubbleImageView

- (instancetype)initWithFrame:(CGRect)frame andSize:(CGSize)superSize andPoint:(CGPoint)point andText:(NSString *)text
{
    self = [super initWithFrame:frame];
    if (self) {
        //计算出所在的位置   0 左上 1 右上 2左下 3右下
        
        
        self.userInteractionEnabled = YES;
        UIFont * font = [UIFont systemFontOfSize:14];
        self.curFont = font;
        self.minFontSize = font.pointSize;
        [self createTextViewWithFrame:CGRectZero text:nil font:nil];
        
        NSInteger xIndex = point.x >= superSize.width * 0.5?1:0;
        NSInteger yIndex = point.y >= superSize.height * 0.5?2:0;
        self.directionIndex = xIndex + yIndex;
        
        self.resizingControl = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, IMAGE_ICON_SIZE, IMAGE_ICON_SIZE)];
        self.resizingControl.image = [UIImage imageNamed:@"rotate"];
//        self.resizingControl.backgroundColor = [UIColor redColor];
        self.resizingControl.userInteractionEnabled = YES;
        [self addSubview:self.resizingControl];
        
        self.deleteControl = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, IMAGE_ICON_SIZE, IMAGE_ICON_SIZE)];
        self.deleteControl.image = [UIImage imageNamed:@"delete"];
//        self.deleteControl.backgroundColor = [UIColor purpleColor];
        self.deleteControl.userInteractionEnabled = YES;
        [self addSubview:self.deleteControl];
        
        UITapGestureRecognizer *closeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(deleteControlTapAction:)];
        [self.deleteControl addGestureRecognizer:closeTap];
        
        UIPanGestureRecognizer *moveGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveGestureAction:)];
        [self addGestureRecognizer:moveGesture];
        
        UIPanGestureRecognizer *panRotateGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rotateViewPanGesture:)];
        [self.resizingControl addGestureRecognizer:panRotateGesture];
        
        [moveGesture requireGestureRecognizerToFail:closeTap];
        
        [self layoutSubViewWithFrame:frame];
        
        
        //计算整体的中心点,根据方向来进行判断 并且统计出箭头的偏差
        CGFloat signX = xIndex > 0?-1.0:1.0;
        CGFloat signY = yIndex > 0?-1.0:1.0;
        point.x = point.x + self.bounds.size.width * 0.5 * signX - 18 * signX;
        point.y = point.y + self.bounds.size.height * 0.5 * signY - 3 * signY;
        self.center = point;
        
        CGFloat cFont = 1;
        self.textView.text = text;
        self.minSize = CGSizeMake(IMAGE_ICON_SIZE, IMAGE_ICON_SIZE);
        if (self.minSize.height >  frame.size.height ||
            self.minSize.width  >  frame.size.width  ||
            self.minSize.height <= 0 || self.minSize.width <= 0)
        {
            self.minSize = CGSizeMake(frame.size.width/3.f, frame.size.height/3.f);
        }
        CGSize  tSize = IS_IOS_7?[self textSizeWithFont:cFont text:[text length]?nil:@"点击输入内容"]:CGSizeZero;
        do
        {
            if (IS_IOS_7)
            {
                tSize = [self textSizeWithFont:++cFont text:[text length]?nil:@"点击输入内容"];
            }
            else
            {
                [self.textView setFont:[self.curFont fontWithSize:++cFont]];
            }
        }
        while (![self isBeyondSize:tSize] && cFont < MAX_FONT_SIZE);
        if (cFont < /*self.minFontSize*/0) return nil;
        cFont = (cFont < MAX_FONT_SIZE) ? cFont : self.minFontSize;
        [self.textView setFont:[self.curFont fontWithSize:--cFont]];
        [self centerTextVertically];
    }
    return self;
}


#pragma  mark -- 旋转手势
- (void)rotateViewPanGesture:(UIPanGestureRecognizer *)recognizer
{
    touchLocation = [recognizer locationInView:self.superview];
    
    CGPoint center = CGRectGetCenter(self.frame);
    
    if ([recognizer state] == UIGestureRecognizerStateBegan) {
        //求出反正切角
        deltaAngle = atan2(touchLocation.y-center.y, touchLocation.x-center.x)-CGAffineTransformGetAngle(self.transform);
        initialBounds = self.bounds;
        initialDistance = CGPointGetDistance(center, touchLocation);
        //        if([self.bubbleDelegate respondsToSelector:@selector(bubbleViewDidBeginEditing:)]) {
        //            [self.bubbleDelegate bubbleViewDidBeginEditing:self];
        //        }
    } else if ([recognizer state] == UIGestureRecognizerStateChanged) {
        BOOL increase = NO;
        if (self.bounds.size.width < self.minSize.width || self.bounds.size.height < self.minSize.height)
        {
            self.bounds = CGRectMake(self.bounds.origin.x,
                                     self.bounds.origin.y,
                                     self.minSize.width,
                                     self.minSize.height);
            self.resizingControl.frame =CGRectMake(self.bounds.size.width-IMAGE_ICON_SIZE,self.bounds.size.height-IMAGE_ICON_SIZE,
                                                   IMAGE_ICON_SIZE,
                                                   IMAGE_ICON_SIZE);
            self.deleteControl.frame = CGRectMake(0, 0,
                                                  IMAGE_ICON_SIZE, IMAGE_ICON_SIZE);
            prevPoint = [recognizer locationInView:self];
        } else {
            CGPoint point = [recognizer locationInView:self];
            float wChange = 0.0, hChange = 0.0;
            wChange = (point.x - prevPoint.x);
            hChange = (point.y - prevPoint.y);
            if (ABS(wChange) > 20.0f || ABS(hChange) > 20.0f) {
                prevPoint = [recognizer locationInView:self];
                return;
            }
            if (YES) {
                if (wChange < 0.0f && hChange < 0.0f) {
                    float change = MIN(wChange, hChange);
                    wChange = change;
                    hChange = change;
                }
                if (wChange < 0.0f) {
                    hChange = wChange;
                } else if (hChange < 0.0f) {
                    wChange = hChange;
                } else {
                    float change = MAX(wChange, hChange);
                    wChange = change;
                    hChange = change;
                }
            }
            increase = wChange > 0?YES:NO;
            self.bounds = CGRectMake(self.bounds.origin.x, self.bounds.origin.y,
                                     self.bounds.size.width + (wChange),
                                     self.bounds.size.height + (hChange));
            
            [self layoutSubViewWithFrame:self.bounds];
            
            self.resizingControl.frame =CGRectMake(self.bounds.size.width-IMAGE_ICON_SIZE,
                                                   self.bounds.size.height-IMAGE_ICON_SIZE,
                                                   IMAGE_ICON_SIZE, IMAGE_ICON_SIZE);
            self.deleteControl.frame = CGRectMake(0, 0,
                                                  IMAGE_ICON_SIZE, IMAGE_ICON_SIZE);
            prevPoint = [recognizer locationInView:self];
        }
        /* Rotation */
        float ang = atan2([recognizer locationInView:self.superview].y - self.center.y,
                          [recognizer locationInView:self.superview].x - self.center.x);
        float angleDiff = deltaAngle - ang;
        self.transform = CGAffineTransformMakeRotation(-angleDiff);
        
        if (IS_IOS_7)
        {
            self.textView.textContainerInset = UIEdgeInsetsZero;
        }
        else
        {
            self.textView.contentOffset = CGPointZero;
        }
        
        if ([self.textView.text length])
        {
            CGFloat cFont = self.textView.font.pointSize;
            CGSize  tSize = IS_IOS_7?[self textSizeWithFont:cFont text:nil]:CGSizeZero;
            if (increase)
            {
                do
                {
                    if (IS_IOS_7)
                    {
                        tSize = [self textSizeWithFont:++cFont text:nil];
                    }
                    else
                    {
                        [self.textView setFont:[self.curFont fontWithSize:++cFont]];
                    }
                }
                while (![self isBeyondSize:tSize] && cFont < MAX_FONT_SIZE);
                cFont = (cFont < MAX_FONT_SIZE) ? cFont : self.minFontSize;
                [self.textView setFont:[self.curFont fontWithSize:--cFont]];
            }
            else
            {
                while ([self isBeyondSize:tSize] && cFont > 0)
                {
                    if (IS_IOS_7)
                    {
                        tSize = [self textSizeWithFont:--cFont text:nil];
                    }
                    else
                    {
                        [self.textView setFont:[self.curFont fontWithSize:--cFont]];
                    }
                }
                [self.textView setFont:[self.curFont fontWithSize:cFont]];
            }
        }
        [self centerTextVertically];
        //        if([self.bubbleDelegate respondsToSelector:@selector(bubbleViewDidChangeEditing:)]) {
        //            [self.bubbleDelegate bubbleViewDidChangeEditing:self];
        //        }
    } else if ([recognizer state] == UIGestureRecognizerStateEnded) {
        //        if([self.bubbleDelegate respondsToSelector:@selector(bubbleViewDidEndEditing:)]) {
        //            [self.bubbleDelegate bubbleViewDidEndEditing:self];
        //        }
    }
}

- (NSString *)textString
{
    return self.textView.text;
}



#pragma mark -- 移动手势
- (void)moveGestureAction:(UIPanGestureRecognizer * )recognizer
{
    touchLocation = [recognizer locationInView:self.superview];
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        beginningPoint = touchLocation;
        beginningCenter = self.center;
        [self setCenter:CGPointMake(beginningCenter.x+(touchLocation.x-beginningPoint.x), beginningCenter.y+(touchLocation.y-beginningPoint.y))];
        beginBounds = self.bounds;
        //        if([_delegate respondsToSelector:@selector(labelViewDidBeginEditing:)]) {
        //            [_delegate labelViewDidBeginEditing:self];
        //        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        [self setCenter:CGPointMake(beginningCenter.x+(touchLocation.x-beginningPoint.x), beginningCenter.y+(touchLocation.y-beginningPoint.y))];
        //        if([_delegate respondsToSelector:@selector(labelViewDidChangeEditing:)]) {
        //            [_delegate labelViewDidChangeEditing:self];
        //        }
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self setCenter:CGPointMake(beginningCenter.x+(touchLocation.x-beginningPoint.x), beginningCenter.y+(touchLocation.y-beginningPoint.y))];
        //        if([_delegate respondsToSelector:@selector(labelViewDidEndEditing:)]) {
        //            [_delegate labelViewDidEndEditing:self];
        //        }
    }
    
    prevPoint = touchLocation;
}

#pragma mark -- 删除点击手势
- (void)deleteControlTapAction:(UITapGestureRecognizer *)tap
{
    [self removeFromSuperview];
    if([self.bubbleDelegate respondsToSelector:@selector(bubbleViewDidClose:)]) {
        [self.bubbleDelegate bubbleViewDidClose:self];
    }
}

- (void)createTextViewWithFrame:(CGRect)frame text:(NSString *)text font:(UIFont *)font
{
    UITextView *textView = [[UITextView alloc] initWithFrame:frame];
    
    textView.scrollEnabled = NO;
    textView.delegate = self;
    textView.keyboardType  = UIKeyboardTypeASCIICapable;
    textView.returnKeyType = UIReturnKeyDone;
    textView.textAlignment = NSTextAlignmentCenter;
    [textView setBackgroundColor:[UIColor whiteColor]];
    [textView setTextColor:[UIColor redColor]];
    [textView setText:text]; [textView setFont:font];
    [textView setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self addSubview:textView];
    [self sendSubviewToBack:textView];
    
    if (IS_IOS_7)
    {
        textView.textContainerInset = UIEdgeInsetsZero;
    }
    else
    {
        textView.contentOffset = CGPointZero;
    }
    [self setTextView:textView];
}
- (void)layoutSubViewWithFrame:(CGRect)frame
{
    CGRect tRect = frame;
    //根据传入的整体view的frame 计算出内部textView的位置.
    //宽度减去两个一半的图标 == 一个整个的图标 减去线的宽度
    //    tRect.size.width  = self.bounds.size.width - IMAGE_ICON_SIZE;
    //    tRect.size.height = self.bounds.size.height - IMAGE_ICON_SIZE;
    //    tRect.origin.x = (self.bounds.size.width - tRect.size.width) /2.f;
    //    tRect.origin.y = (self.bounds.size.height- tRect.size.height) /2.f;
    
    tRect.size.width = self.bounds.size.width * 0.73;
    tRect.size.height = self.bounds.size.height * 0.46;
    tRect.origin.x = (self.bounds.size.width - tRect.size.width) * 0.5;
    //如果是下半部分 就是0.18 上半部分 0.35
    CGFloat orignY = self.directionIndex > 1?0.18:0.35;
    tRect.origin.y = self.bounds.size.height * orignY;
    [self.textView setFrame:tRect];
    //计算编辑按钮的位置
    [self.deleteControl setFrame:CGRectMake(0, 0,IMAGE_ICON_SIZE, IMAGE_ICON_SIZE)];
    //计算放大缩小按钮的位置
    [self.resizingControl  setFrame:CGRectMake(self.bounds.size.width-IMAGE_ICON_SIZE, self.bounds.size.height-IMAGE_ICON_SIZE, IMAGE_ICON_SIZE, IMAGE_ICON_SIZE)];
}


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"])
    {
        [self endEditing:YES];
        //        if (self.delegate && [self.delegate respondsToSelector:@selector(textViewDidEndEditing:)])
        //        {
        //            [self.delegate textViewDidEndEditing:self];
        //        }
        return NO;
    }
    _isDeleting = (range.length >= 1 && text.length == 0);
    
    if (textView.font.pointSize <= self.minFontSize && !_isDeleting) return NO;
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    NSString *calcStr = textView.text;
    
    if (![textView.text length]) [self.textView setText:@"点击输入内容"];
    CGFloat cFont = self.textView.font.pointSize;
    CGSize  tSize = IS_IOS_7?[self textSizeWithFont:cFont text:nil]:CGSizeZero;
    
    if (IS_IOS_7)
    {
        self.textView.textContainerInset = UIEdgeInsetsZero;
    }
    else
    {
        self.textView.contentOffset = CGPointZero;
    }
    
    if (_isDeleting)
    {
        do
        {
            if (IS_IOS_7)
            {
                tSize = [self textSizeWithFont:++cFont text:nil];
            }
            else
            {
                [self.textView setFont:[self.curFont fontWithSize:++cFont]];
            }
        }
        while (![self isBeyondSize:tSize] && cFont < MAX_FONT_SIZE);
        
        cFont = (cFont < MAX_FONT_SIZE) ? cFont : self.minFontSize;
        [self.textView setFont:[self.curFont fontWithSize:--cFont]];
    }
    else
    {
        NSLog(@"---%d",[self isBeyondSize:tSize]);
        
        while ([self isBeyondSize:tSize] && cFont > 0)
        {
            if (IS_IOS_7)
            {
                tSize = [self textSizeWithFont:--cFont text:nil];
            }
            else
            {
                [self.textView setFont:[self.curFont fontWithSize:--cFont]];
            }
        }
        
        [self.textView setFont:[self.curFont fontWithSize:cFont]];
    }
    [self centerTextVertically];
    [self.textView setText:calcStr];
}

- (CGSize)textSizeWithFont:(CGFloat)font text:(NSString *)string
{
    NSString *text = string ? string : self.textView.text;
    
    CGFloat pO = self.textView.textContainer.lineFragmentPadding * 2;
    CGFloat cW = self.textView.frame.size.width - pO;
    
    CGSize  tH = [text sizeWithFont:[self.curFont fontWithSize:font]
                  constrainedToSize:CGSizeMake(cW, MAXFLOAT)
                      lineBreakMode:NSLineBreakByWordWrapping];
    return  tH;
}

- (BOOL)isBeyondSize:(CGSize)size
{
    if (IS_IOS_7)
    {
        CGFloat ost = _textView.textContainerInset.top + _textView.textContainerInset.bottom;
        return size.height + ost > self.textView.frame.size.height;
    }
    else
    {
        return self.textView.contentSize.height > self.textView.frame.size.height;
    }
}

- (void)centerTextVertically
{
    if (IS_IOS_7)
    {
        CGSize  tH     = [self textSizeWithFont:self.textView.font.pointSize text:nil];
        CGFloat offset = (self.textView.frame.size.height - tH.height)/2.f;
        
        self.textView.textContainerInset = UIEdgeInsetsMake(offset, 0, offset, 0);
    }
    else
    {
        CGFloat fH = self.textView.frame.size.height;
        CGFloat cH = self.textView.contentSize.height;
        [self.textView setContentOffset:CGPointMake(0, (cH-fH)/2.f)];
    }
    
#if TEST_CENTER_ALIGNMENT
    [self.indicatorView setFrame:CGRectMake(0, offset, self.frame.size.width, tH.height)];
#else
    // ...
#endif
}


-(void)layoutSubviews
{
    [super layoutSubviews];
    
    UIImage * image = [UIImage imageNamed:[NSString stringWithFormat:@"%ld",(long)self.directionIndex]];
    self.image = image;
    //    self.image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(20, 20, 20, 20) resizingMode:UIImageResizingModeStretch];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
