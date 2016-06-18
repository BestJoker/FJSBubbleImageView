//
//  ViewController.m
//  FJSBubbleImageView
//
//  Created by 付金诗 on 16/6/18.
//  Copyright © 2016年 www.fujinshi.com. All rights reserved.
//

#import "ViewController.h"
#import "FJSBubbleImageView.h"
@interface ViewController ()<FJSBubbleImageViewDelegate>
@property (nonatomic,assign)CGPoint center;
@property (nonatomic,assign)CGRect bubbleViewFrame;
@property (nonatomic,strong)NSString * textString;
@property (nonatomic,assign)CGFloat angle;
@property(nonatomic) CGAffineTransform bubbleTransform;
@property (nonatomic,strong)FJSBubbleImageView *bubbleView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationController.navigationBar.translucent = NO;
    self.navigationItem.title = @"点击屏幕生成气泡";
    self.view.backgroundColor = [UIColor whiteColor];
    
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [self.view addGestureRecognizer:tap];

}

- (void)tapAction:(UITapGestureRecognizer *)tap
{
    [self.bubbleView removeFromSuperview];
    CGPoint point = [tap locationInView:self.view];
    NSLog(@"------%@",NSStringFromCGPoint(point));
    self.bubbleView = [[FJSBubbleImageView alloc] initWithFrame:CGRectMake(0, 0, 124.5, 100) andSize:self.view.bounds.size andPoint:point andText:@"请点击输入内容"];
//    self.bubbleView.backgroundColor = [UIColor orangeColor];
    self.bubbleView.bubbleDelegate = self;
    [self.view addSubview:self.bubbleView];
}

-(void)bubbleViewDidClose:(FJSBubbleImageView *)bubbleView
{
    NSLog(@"关闭气泡");
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
