//
//  LoadingHelper.m
//  PuChi
//
//  Created by Veeco on 08/03/2018.
//  Copyright © 2018 Chance. All rights reserved.
//

#import "LoadingHelper.h"
#import "UtilHeader.h"
#import "ColorHeader.h"
#import "Masonry/Masonry.h"

// 主体
static UIView *kBG;
// 遮罩计数器
static int kCount;

@implementation LoadingHelper

#pragma mark - <Lazy>

+ (UIView *)kBG {
    if (!kBG) {
        
        kBG = [[UIView alloc] initWithFrame:DELEGATE_WINDOW.bounds];
        kBG.backgroundColor = UIColorMakeFromRGBA(0x000000, 0.3f);
        
        UIImageView *imageView = [UIImageView new];
        [kBG addSubview:imageView];
        
        UIImage *image1 = [UIImage imageNamed:@"londing_run01"];
        UIImage *image2 = [UIImage imageNamed:@"londing_run01"];
        UIImage *image3 = [UIImage imageNamed:@"londing_run01"];
        UIImage *image4 = [UIImage imageNamed:@"londing_run02"];
        UIImage *image5 = [UIImage imageNamed:@"londing_run03"];
        UIImage *image6 = [UIImage imageNamed:@"londing_run04"];
        UIImage *image7 = [UIImage imageNamed:@"londing_run04"];
        UIImage *image8 = [UIImage imageNamed:@"londing_run04"];
        UIImage *image9 = [UIImage imageNamed:@"londing_run03"];
        UIImage *image10 = [UIImage imageNamed:@"londing_run02"];
        imageView.animationImages = @[image1, image2, image3, image4, image5, image6, image7, image8, image9, image10];
        imageView.animationDuration = 0.6f;
        [imageView startAnimating];
        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            
            make.center.mas_equalTo(0);
        }];
    }
    return kBG;
}

#pragma mark - <Normal>

/**
 显示
 */
+ (void)show {
    
    [DELEGATE_WINDOW addSubview:[self kBG]];
    
    kCount++;
}

/**
 隐藏
 */
+ (void)hide {
    
    if (--kCount < 0) {
        
        kCount = 0;
    }
    if (!kCount) [kBG removeFromSuperview];
}

@end
