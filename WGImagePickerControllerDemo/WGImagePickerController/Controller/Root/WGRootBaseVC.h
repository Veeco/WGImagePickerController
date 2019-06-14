//
//  WGRootBaseVC.h
//  PuChi
//
//  Created by Veeco on 2019/2/1.
//  Copyright © 2019 Chance. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGRootBaseVC : UIViewController

/**
 即将展示
 */
- (void)pcViewDidAppear;

/**
 即将消失
 */
- (void)pcViewDidDisappear;

@end

NS_ASSUME_NONNULL_END
