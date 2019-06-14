//
//  WGAssetModel.h
//  Puchi
//
//  Created by Veeco on 2019/1/15.
//  Copyright © 2019 Chance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

// 资源类型
typedef NS_ENUM(NSUInteger, WGAssetModelMediaType) {
    WGAssetModelMediaTypeUnknow, // 未知
    WGAssetModelMediaTypePhoto, // 图片
    WGAssetModelMediaTypeLivePhoto, // Live图
    WGAssetModelMediaTypeGif, // Gif
    WGAssetModelMediaTypeVideo, // 视频
    WGAssetModelMediaTypeAudio // 音频
};

@interface WGAssetModel : NSObject

/** 资源 */
@property (nonatomic, strong) PHAsset *asset;
/** 资源类型 */
@property (nonatomic, assign) WGAssetModelMediaType type;
/** 视频时间描述 */
@property (nonatomic, copy) NSString *timeLength;
/** 资源ID */
@property (nullable, nonatomic, strong) NSString *ID;

/** 是否可选(多选状态下) */
@property (assign, nonatomic) BOOL isCanSelect;
/** 选中状态 */
@property (nonatomic, assign) BOOL isSelected;
/** 是否支持多选 */
@property (assign, nonatomic) BOOL isMulti;
/** 多选序号 */
@property (assign, nonatomic) NSUInteger multiNum;
/** IP */
@property (nullable, nonatomic, strong) NSIndexPath *IP;
/** 缓存封面图 */
@property (nullable, nonatomic, strong) UIImage *cover;
/** 放大比例 */
@property (nullable, nonatomic, strong) NSNumber *scale;
/** 资源容器比例(举例 图片资源宽50像素 容器为25 比例为2:1 视频类型此属性无意义) */
@property (assign, nonatomic) CGFloat assetContentScale;
/** 偏移量 */
@property (nullable, nonatomic, strong) NSNumber *contentOffsetX;
@property (nullable, nonatomic, strong) NSNumber *contentOffsetY;
/** 预览图资源 */
@property (nullable, nonatomic, strong) UIImage *image;
@property (nullable, nonatomic, strong) AVPlayerItem *video;
@property (nullable, nonatomic, strong) UIImage *gif;
@property (nullable, nonatomic, strong) UIImage *live;
// 截取后的资源
@property (nullable, nonatomic, strong) UIImage *cropImage;
@property (nullable, nonatomic, strong) AVPlayerItem *cropVideo;
@property (nullable, nonatomic, strong) UIImage *cropGif;
@property (nullable, nonatomic, strong) UIImage *cropLive;

/**
 初始化
 
 @param asset 资源
 @param type 资源类型
 @param timeLength 视频时间描述
 @return 模型
 */
+ (instancetype)modelWithAsset:(nonnull PHAsset *)asset type:(WGAssetModelMediaType)type timeLength:(NSString *)timeLength;

/**
 初始化
 
 @param asset 资源
 @param type 资源类型
 @return 模型
 */
+ (instancetype)modelWithAsset:(nonnull PHAsset *)asset type:(WGAssetModelMediaType)type;

@end

NS_ASSUME_NONNULL_END
