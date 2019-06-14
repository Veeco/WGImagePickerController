//
//  WGPreView.h
//  Puchi
//
//  Created by Veeco on 2019/1/29.
//  Copyright © 2019 Chance. All rights reserved.
//

#import <UIKit/UIKit.h>
@class WGAssetModel;
@class WGPreView;

@protocol WGPreViewDelegate <NSObject>

@optional

/**
 多选按钮点击回调

 @param preView 自身
 */
- (void)didClickMultiInPreView:(nonnull __kindof WGPreView *)preView;

@end

NS_ASSUME_NONNULL_BEGIN

@interface WGPreView : UIView

/** 模型 */
@property (nullable, nonatomic, strong) WGAssetModel *model;
/** 是否处于多选模式 */
@property (assign, nonatomic) BOOL isMulti;
/** 是否处于缩小显示模式 */
@property (assign, nonatomic, readonly) BOOL isZoomMin;
/** 获取SV的尺寸 */
@property (assign, nonatomic, readonly) CGSize svSize;
/** 代理 */
@property (nullable, nonatomic, weak) NSObject<WGPreViewDelegate> *delegate;

/**
 展示蒙板

 @param show 是否展示蒙板
 */
- (void)maskShow:(BOOL)show;

/**
 暂停播放
 */
- (void)playerPause;

/**
 继续播放
 */
- (void)playerStart;

/**
 停止播放
 */
- (void)playerStop;

/**
 检测SV是否在操作
 
 @return 是否在操作
 */
- (BOOL)checkSVISHandle;

@end

NS_ASSUME_NONNULL_END
