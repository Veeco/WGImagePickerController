//
//  WGImagePickerConfig.h
//  Puchi
//
//  Created by Veeco on 2019/1/15.
//  Copyright © 2019 Chance. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGImagePickerConfig : NSObject

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
/** 最大可选数 */
@property (assign, nonatomic) NSInteger maxImagesCount;
/** 默认是200，如果一个GIF过大，里面图片个数可能超过1000，会导致内存飙升而崩溃 */
@property (assign, nonatomic, readonly) NSInteger gifPreviewMaxImagesCount;
/** 元素尺寸 */
@property (assign, nonatomic) CGSize itemSize;

/**
 单例

 @return 实例
 */
+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
