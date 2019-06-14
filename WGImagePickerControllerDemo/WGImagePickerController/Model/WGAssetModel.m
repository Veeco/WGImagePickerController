//
//  WGAssetModel.m
//  Puchi
//
//  Created by Veeco on 2019/1/15.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "WGAssetModel.h"

@implementation WGAssetModel

#pragma mark - <Get & Set>

- (NSString *)ID {
    
    return self.asset.localIdentifier;
}

#pragma mark - <Normal>

/**
 初始化

 @param asset 资源
 @param type 资源类型
 @param timeLength 视频时间描述
 @return 模型
 */
+ (instancetype)modelWithAsset:(nonnull PHAsset *)asset type:(WGAssetModelMediaType)type timeLength:(NSString *)timeLength {
    
    WGAssetModel *model = [self modelWithAsset:asset type:type];
    model.timeLength = timeLength;
    
    return model;
}

/**
 初始化

 @param asset 资源
 @param type 资源类型
 @return 模型
 */
+ (instancetype)modelWithAsset:(nonnull PHAsset *)asset type:(WGAssetModelMediaType)type {
    
    WGAssetModel *model = [WGAssetModel new];
    model.asset = asset;
    model.isSelected = NO;
    model.type = type;
    model.isCanSelect = YES;
    
    return model;
}

@end
