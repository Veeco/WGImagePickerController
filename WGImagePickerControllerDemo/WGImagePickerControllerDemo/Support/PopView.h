//
//  PopView.h
//  PuChi
//
//  Created by Veeco on 2018/5/26.
//  Copyright © 2018 Chance. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PopView : UIView

/**
 弹出
 
 @param title 标题
 @param content 内容
 @param items 按钮描述数组
 @param forever 是否不消失
 @param didClickItemHandler 点击元素回调
 */
+ (void)popWithTitle:(nullable NSString *)title content:(nonnull NSString *)content items:(nonnull NSArray<NSString *> *)items forever:(BOOL)forever didClickItemHandler:(void (^_Nullable)(NSUInteger itemIndex))didClickItemHandler;

/**
 弹出只有一个确定按钮且点击后消失(经常调用故另外封装)

 @param content 内容
 */
+ (void)popWithContent:(nonnull NSString *)content;

/**
 弹出(自动消失)

 @param content 内容
 */
+ (void)popAutoFadeWithContent:(nonnull NSString *)content;

@end
