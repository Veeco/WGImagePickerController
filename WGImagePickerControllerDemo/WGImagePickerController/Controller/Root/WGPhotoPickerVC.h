//
//  WGPhotoPickerVC.h
//  Puchi
//
//  Created by Veeco on 2019/1/18.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "WGRootBaseVC.h"
@class WGAssetModel;
@class WGAlbumModel;
@class WGPhotoPickerVC;

@protocol WGPhotoPickerVCDelegate <NSObject>

@optional

/**
 点击多选按钮回调

 @param photoPickerVC 自身
 @param multi 是否多选
 */
- (void)photoPickerVC:(nonnull __kindof WGPhotoPickerVC *)photoPickerVC didSelectMulti:(BOOL)multi;

@end

NS_ASSUME_NONNULL_BEGIN

@interface WGPhotoPickerVC : WGRootBaseVC

/** 代理 */
@property (nullable, nonatomic, weak) NSObject<WGPhotoPickerVCDelegate> *delegate;

/**
 选择相册后调用
 
 @param album 相册模型
 */
- (void)didSelectAlbum:(nonnull WGAlbumModel *)album;

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
 剪切
 
 @return 所选的资源
 */
- (nullable NSArray<WGAssetModel *> *)cropAsset;

/**
 检测预览图SV是否在操作
 
 @return 是否在操作
 */
- (BOOL)checkPreviewSVISHandle;

@end

@interface PCCollectionView : UICollectionView

@end

NS_ASSUME_NONNULL_END
