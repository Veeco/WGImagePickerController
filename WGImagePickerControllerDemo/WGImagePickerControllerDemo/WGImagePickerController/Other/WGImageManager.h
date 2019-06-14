//
//  WGImageManager.h
//  Puchi
//
//  Created by Veeco on 2019/1/15.
//  Copyright © 2019 Chance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
@class WGAlbumModel;
@class WGAssetModel;

// 相册类型
typedef NS_ENUM(NSUInteger, AlbumType) {
    AlbumTypeAll = 1, // 全部
    AlbumTypeCam, // 相机相册
};

NS_ASSUME_NONNULL_BEGIN

@interface WGImageManager : NSObject

/** 对照片排序, 按修改时间升序, 默认是YES. 如果设置为NO, 最新的照片会显示在最前面, 内部的拍照按钮会排在第一个 */
@property (nonatomic, assign) BOOL sortAscendingByModificationDate;

/**
 实例化

 @return 实例
 */
+ (instancetype)manager;

/**
 验证授权
 
 @return 授权值
 */
+ (PHAuthorizationStatus)authorizationStatus;

/**
 验证授权
 
 @return 是否得到授权
 */
- (BOOL)authorizationStatusAuthorized;

/**
 获取相册数组
 
 @param type 相册类型
 @param allowPickingVideo 是否有视频
 @param allowPickingImage 是否有照片
 @param needFetchAssets 是否需要抓取相册内部元素资源
 @param completion 完成回调
 */
- (void)getAlbumWithType:(AlbumType)type allowPickingVideo:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage needFetchAssets:(BOOL)needFetchAssets completion:(void (^ _Nullable)(NSArray<WGAlbumModel *> * _Nonnull models))completion;

/**
 获取相册封面
 
 @param model 相册模型
 @param widthPixel 宽度像素个数
 @param completion 完成回调
 */
- (void)getPostImageWithAlbumModel:(WGAlbumModel *)model widthPixel:(CGFloat)widthPixel completion:(void (^ _Nullable)(UIImage * _Nullable image))completion;

/**
 获取资源封面
 
 @param asset 资源
 @param widthPixel 宽度像素个数
 @param completion 完成回调
 @return 错误码
 */
- (int32_t)getPhotoWithAsset:(nonnull PHAsset *)asset widthPixel:(CGFloat)widthPixel completion:(void (^ _Nullable)(UIImage * _Nullable image, NSDictionary * _Nullable info, BOOL isDegraded))completion;

/**
 获取相册内部元素资源
 
 @param album 相册模型
 @param allowPickingVideo 是否有视频
 @param allowPickingImage 是否有照片
 @param completion 完成回调
 */
- (void)getAssetWithAlbum:(nonnull WGAlbumModel *)album allowPickingVideo:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage completion:(void (^ _Nullable)(NSArray<WGAssetModel *> * _Nonnull models))completion;

/**
 获取视频数据
 
 @param asset 资源
 @param progressHandler 进度回调
 @param completion 完成回调
 */
- (void)getVideoWithAsset:(nonnull PHAsset *)asset progressHandler:(void (^ _Nullable)(double progress, NSError * _Nullable error, BOOL * _Nullable stop, NSDictionary * _Nullable info))progressHandler completion:(void (^ _Nullable)(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info))completion;

@end

NS_ASSUME_NONNULL_END
