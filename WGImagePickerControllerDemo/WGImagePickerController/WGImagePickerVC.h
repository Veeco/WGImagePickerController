//
//  WGImagePickerVC.h
//  Puchi
//
//  Created by Veeco on 2019/1/15.
//  Copyright © 2019 Chance. All rights reserved.
//

#import <UIKit/UIKit.h>
@class WGAssetModel;

NS_ASSUME_NONNULL_BEGIN

@interface WGImagePickerVC : UINavigationController

/** 是否允许图片(默认为YES) */
@property(nonatomic, assign) BOOL allowPickingImage;
/** 是否允许视频(默认为YES) */
@property (nonatomic, assign) BOOL allowPickingVideo;
/** 是否允许多选类型(默认为NO) */
@property (nonatomic, assign) BOOL allowMultiType;
/** 是否允许多选视频(默认为NO) */
@property (nonatomic, assign) BOOL allowMultiVideo;
/** 展示列数(默认为3) */
@property (assign, nonatomic) NSUInteger colCount;
/** 展示元素间隙(默认为2) */
@property (assign, nonatomic) CGFloat itemMargin;
/** 选择完成回调 */
@property (nullable, nonatomic, copy) void (^didPickHandle)(NSArray<WGAssetModel *> * _Nullable models);
/** 是否直接进入相机状态(默认为NO) */
@property (assign, nonatomic) BOOL cameraMode;

/**
 实例化

 @param maxImagesCount 最大值
 @return 实例
 */
+ (instancetype)imagePickerWithMaxImagesCount:(NSInteger)maxImagesCount;

@end

NS_ASSUME_NONNULL_END
