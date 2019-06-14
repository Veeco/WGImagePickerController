//
//  WGAlbumPickerVC.h
//  Puchi
//
//  Created by Veeco on 2019/1/15.
//  Copyright © 2019 Chance. All rights reserved.
//

#import <UIKit/UIKit.h>
@class WGAlbumPickerVC;
@class WGAssetModel;
@class WGAlbumModel;

@protocol WGAlbumPickerVCDelegate <NSObject>

@optional

/**
 选中相册后回调

 @param albumPickerVC 自身
 @param albumModel 相册模型
 */
- (void)albumPickerVC:(nonnull __kindof WGAlbumPickerVC *)albumPickerVC didSelectAlbumWithAlbumModel:(nonnull WGAlbumModel *)albumModel;

@end

NS_ASSUME_NONNULL_BEGIN

@interface WGAlbumPickerVC : UIViewController

/** 代理 */
@property (nullable, nonatomic, weak) NSObject<WGAlbumPickerVCDelegate> *delegate;

/**
 设置TB
 */
- (void)setupUI;

@end

NS_ASSUME_NONNULL_END
