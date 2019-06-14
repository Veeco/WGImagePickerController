//
//  WGAlbumModel.h
//  Puchi
//
//  Created by Veeco on 2019/1/15.
//  Copyright © 2019 Chance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/PHFetchResult.h>
@class WGAssetModel;

NS_ASSUME_NONNULL_BEGIN

@interface WGAlbumModel : NSObject

/** 相册资源 */
@property (nonatomic, strong) PHFetchResult *result;
/** 资源模型数组 */
@property (nonatomic, strong) NSArray<WGAssetModel *> *models;
/** 相册名 */
@property (nonatomic, strong) NSString *name;
/** 相册内的资源数量 */
@property (nonatomic, assign) NSInteger count;

@end

NS_ASSUME_NONNULL_END
