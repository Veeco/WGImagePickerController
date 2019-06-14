//
//  WGImagePickerBaseVC.h
//  Puchi
//
//  Created by Veeco on 2019/1/16.
//  Copyright © 2019 Chance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UtilHeader.h"
#import "ColorHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface WGImagePickerBaseVC : UIViewController

/** 顶部 holdView */
@property (nullable, nonatomic, weak, readonly) UIView *holdView;
/** 导航栏 */
@property (nullable, nonatomic, weak, readonly) UIView *navBar;
/** 左上角 */
@property (nullable, nonatomic, weak, readonly) UILabel *navBack;
/** 右上角 */
@property (nullable, nonatomic, weak, readonly) UILabel *navNext;
/** 点击后收键盘(默认为NO) */
@property (assign, nonatomic) BOOL clickKBOff;
/** 编辑状态整体上移键盘1/3(默认为NO) */
@property (assign, nonatomic) BOOL upWhenEdit;

/**
 监听右上角点击
 专供重写
 */
- (void)didClickNext;

/**
 监听左上角点击
 专供重写
 */
- (void)didClickBack;


@end

// 获取导航标题字体
static inline UIFont *
getNavTitleFont() {
    
    return FONT_SIZE(16);
}

// 获取导航标题颜色
static inline UIColor *
getNavTitleColor() {
    
    return UIColorMakeFromRGB(0x222222);
}

NS_ASSUME_NONNULL_END
