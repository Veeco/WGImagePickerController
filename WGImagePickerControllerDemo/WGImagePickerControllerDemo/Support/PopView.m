//
//  PopView.m
//  PuChi
//
//  Created by Veeco on 2018/5/26.
//  Copyright © 2018 Chance. All rights reserved.
//

#import "PopView.h"
#import "UtilHeader.h"
#import "ColorHeader.h"
#import "UIView+WGExtension.h"

@interface PopView ()

/** 操作回调 */
@property (nullable, nonatomic, strong) NSMutableArray<void (^)(NSUInteger itemIndex)> *handlerArrM;;
/** 是否可消失 */
@property (nullable, nonatomic, strong) NSMutableArray<NSNumber *> *foreverArrM;;

@end

// 全局遮罩
static PopView *kMask;
static __weak UIView *kAutoMask;

@implementation PopView

#pragma mark - <Lazy>

- (NSMutableArray *)handlerArrM {
    if (!_handlerArrM) {
        
        self.handlerArrM = [NSMutableArray array];
    }
    return _handlerArrM;
}

- (NSMutableArray *)foreverArrM {
    if (!_foreverArrM) {
        
        self.foreverArrM = [NSMutableArray array];
    }
    return _foreverArrM;
}

#pragma mark - <Normal>

/**
 弹出(自动消失)
 
 @param content 内容
 */
+ (void)popAutoFadeWithContent:(nonnull NSString *)content {
    
    [kAutoMask removeFromSuperview];
    
    UIView *mask = [UIView new];
    [DELEGATE_WINDOW addSubview:mask];
    kAutoMask = mask;
    mask.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.6f];
    mask.layer.cornerRadius = 9;
    mask.layer.masksToBounds = YES;
    
    UILabel *lb = [UILabel new];
    [mask addSubview:lb];
    lb.numberOfLines = 2;
    lb.font = FONT_SIZE(14);
    lb.textColor = UIColor.whiteColor;
    lb.text = content;
    lb.textAlignment = NSTextAlignmentCenter;
    lb.size = [lb.text boundingRectWithSize:CGSizeMake(lb.font.pointSize * 8, lb.font.pointSize * 3) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : lb.font} context:nil].size;
    
    mask.width = lb.width + 36;
    mask.height = lb.height + 20;
    lb.center = CGPointMake(mask.width / 2, mask.height / 2);
    mask.center = CGPointMake(DELEGATE_WINDOW.width / 2, DELEGATE_WINDOW.height / 2);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [mask removeFromSuperview];
    });
}

/**
 隐藏遮罩
 */
+ (void)setMaskHidden {
    
    kMask.hidden = !kMask.subviews.count;
}

/**
 弹出
 
 @param title 标题
 @param content 内容
 @param items 按钮描述数组
 @param forever 是否不消失
 @param didClickItemHandler 点击元素回调
 */
+ (void)popWithTitle:(nullable NSString *)title content:(nonnull NSString *)content items:(nonnull NSArray<NSString *> *)items forever:(BOOL)forever didClickItemHandler:(void (^_Nullable)(NSUInteger itemIndex))didClickItemHandler {
    
    if (![content isKindOfClass:[NSString class]] || !content.length || items.count == 0 || items.count > 2) return;
    
    // 1. 背景
    if (!kMask) {
        
        PopView *popView = [[self alloc] initWithFrame:DELEGATE_WINDOW.bounds];
        [DELEGATE_WINDOW addSubview:popView];
        popView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3f];
        kMask = popView;
    }
    kMask.hidden = NO;
    [DELEGATE_WINDOW bringSubviewToFront:kMask];
    
    if (didClickItemHandler) {
        
        [kMask.handlerArrM addObject:didClickItemHandler];
    }
    else {
        
        [kMask.handlerArrM addObject:^(NSUInteger itemIndex) {}];
    }
    [kMask.foreverArrM addObject:@(forever)];
    
    // 2. 容器
    UIView *contentView = [UIView new];
    [kMask addSubview:contentView];
    contentView.backgroundColor = UIColor.whiteColor;
    contentView.layer.cornerRadius = 10;
    contentView.width = 270;
    contentView.centerX = kMask.width / 2;
    
    const CGFloat maxW = contentView.width - 60;
    const CGFloat topMagrin = 23;
    CGFloat bottom = 0;
    
    // 2.5 标题
    if (title.length) {
        
        UILabel *titleLabel = [UILabel new];
        [contentView addSubview:titleLabel];
        titleLabel.font = BOLD_SIZE(17);
        titleLabel.textColor = UIColorMakeFromRGB(0x222222);
        titleLabel.text = title;
        [titleLabel sizeToFit];
        titleLabel.width = titleLabel.width > maxW ? maxW : titleLabel.width;
        titleLabel.y = bottom + topMagrin;
        titleLabel.centerX = contentView.width / 2;
        
        bottom = CGRectGetMaxY(titleLabel.frame);
    }
    
    // 3. 内容
    UILabel *lb = [UILabel new];
    [contentView addSubview:lb];
    lb.font = FONT_SIZE(14);
    lb.text = content;
    lb.numberOfLines = 0;
    lb.textColor = UIColorMakeFromRGB(0x999999);
    lb.size = [lb.text boundingRectWithSize:CGSizeMake(maxW, SCREEN_HEIGHT / 2) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : lb.font} context:nil].size;
    lb.y = title.length ? bottom + 15 : bottom + topMagrin;
    lb.centerX = contentView.width / 2;
    lb.textAlignment = NSTextAlignmentCenter;
    
    // 4. 线
    UIView *line = [UIView new];
    [contentView addSubview:line];
    line.backgroundColor = UIColorMakeFromRGB(0xe5e5e5);
    line.width = contentView.width;
    line.height = 0.5f;
    line.y = CGRectGetMaxY(lb.frame) + topMagrin;
    
    if (items.count == 1) {
        
        UILabel *LB = [self createLB];
        [contentView addSubview:LB];
        LB.width = contentView.width;
        LB.y = CGRectGetMaxY(line.frame);
        [LB addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:kMask action:@selector(didClickFirstItem:)]];
        LB.text = items.lastObject;
        
        contentView.height = CGRectGetMaxY(LB.frame);
        contentView.centerY = kMask.height / 2;
    }
    else if (items.count == 2) {
        
        const CGFloat line2W = 0.5f;
        
        UILabel *left = [self createLB];
        [contentView addSubview:left];
        left.width = (contentView.width - line2W) / 2;
        left.y = CGRectGetMaxY(line.frame);
        [left addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:kMask action:@selector(didClickFirstItem:)]];
        left.text = items.firstObject;
        
        UIView *line2 = [UIView new];
        [contentView addSubview:line2];
        line2.backgroundColor = line.backgroundColor;
        line2.width = line2W;
        line2.height = left.height;
        line2.x = CGRectGetMaxX(left.frame);
        line2.y = left.y;
        
        UILabel *right = [self createLB];
        [contentView addSubview:right];
        right.width = left.width;
        right.x = CGRectGetMaxX(line2.frame);
        right.y = left.y;
        [right addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:kMask action:@selector(didClickSecondItem:)]];
        right.text = items.lastObject;
        
        contentView.height = CGRectGetMaxY(right.frame);
        contentView.centerY = kMask.height / 2;
    }
}

/**
 弹出只有一个确定按钮且点击后消失(经常调用故另外封装)
 
 @param content 内容
 */
+ (void)popWithContent:(nonnull NSString *)content {
    
    [self popWithTitle:nil content:content items:@[@"确认"] forever:NO didClickItemHandler:nil];
}

/**
 事件处理结束

 @param tap 手势
 */
- (void)handleFinishWithTap:(UITapGestureRecognizer *)tap {
    
    BOOL forever = self.foreverArrM.lastObject.boolValue;
    
    if (!forever) {
        
        [tap.view.superview removeFromSuperview];
        [self.class setMaskHidden];
        [self.foreverArrM removeLastObject];
        [self.handlerArrM removeLastObject];
    }
}

/**
 监听第一元素点击
 
 @param tap 手势
 */
- (void)didClickFirstItem:(UITapGestureRecognizer *)tap {
    
    void (^handler)(NSUInteger itemIndex) = self.handlerArrM.lastObject;
    [self handleFinishWithTap:tap];
    !handler ?: handler(0);
}

/**
 监听第二元素点击
 
 @param tap 手势
 */
- (void)didClickSecondItem:(UITapGestureRecognizer *)tap {
    
    void (^handler)(NSUInteger itemIndex) = self.handlerArrM.lastObject;
    [self handleFinishWithTap:tap];
    !handler ?: handler(1);
}

/**
 创建LB
 
 @return LB
 */
+ (nonnull UILabel *)createLB {
    
    UILabel *LB = [UILabel new];
    LB.height = 45;
    LB.textColor = UIColorMakeFromRGB(0x222222);
    LB.font = FONT_SIZE(16);
    LB.textAlignment = NSTextAlignmentCenter;
    LB.userInteractionEnabled = YES;
    
    return LB;
}

@end
