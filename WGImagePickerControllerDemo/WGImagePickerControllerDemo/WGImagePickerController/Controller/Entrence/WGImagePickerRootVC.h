//
//  WGImagePickerRootVC.h
//  Puchi
//
//  Created by Veeco on 2019/1/16.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "WGImagePickerBaseVC.h"
@class WGAssetModel;

NS_ASSUME_NONNULL_BEGIN

@interface WGImagePickerRootVC : WGImagePickerBaseVC

/** 选择完成回调 */
@property (nullable, nonatomic, copy) void (^didPickHandle)(NSArray<WGAssetModel *> * _Nullable models);
/** 是否直接进入相机状态(默认为NO) */
@property (assign, nonatomic) BOOL cameraMode;

/**
 等到权限时调用
 */
- (void)didGetAuth;

@end

NS_ASSUME_NONNULL_END
