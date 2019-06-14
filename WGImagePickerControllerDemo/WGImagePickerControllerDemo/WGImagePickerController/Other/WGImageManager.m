//
//  WGImageManager.m
//  Puchi
//
//  Created by Veeco on 2019/1/15.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "WGImageManager.h"
#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "WGAlbumModel.h"
#import "WGImagePickerConfig.h"
#import "WGAssetModel.h"
#import "UtilHeader.h"

// 单例
static WGImageManager *kManager;

@implementation WGImageManager

#pragma mark - <Normal>

/**
 实例化
 
 @return 实例
 */
+ (instancetype)manager {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        kManager = [[self alloc] init];
        kManager.sortAscendingByModificationDate = YES;
    });
    return kManager;
}

/**
 验证授权
 
 @return 是否得到授权
 */
- (BOOL)authorizationStatusAuthorized {
    
    PHAuthorizationStatus status = [self.class authorizationStatus];
    
    if (status == PHAuthorizationStatusNotDetermined) {
        
        // 当某些情况下AuthorizationStatus == AuthorizationStatusNotDetermined时，无法弹出系统首次使用的授权alertView，系统应用设置里亦没有相册的设置，此时将无法使用，故作以下操作，弹出系统首次使用的授权alertView
        [self requestAuthorizationWithCompletion:nil];
    }
    return status == PHAuthorizationStatusAuthorized;
}

/**
 验证授权
 
 @return 授权值
 */
+ (PHAuthorizationStatus)authorizationStatus {
    
    return [PHPhotoLibrary authorizationStatus];
}

/**
 请求验证
 
 @param completion 完成回调
 */
- (void)requestAuthorizationWithCompletion:(void (^)(void))completion {
    
    void (^callCompletionBlock)(void) = ^(){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            !completion ?: completion();
        });
    };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            
            callCompletionBlock();
        }];
    });
}

/**
 获取相册数组
 
 @param type 相册类型
 @param allowPickingVideo 是否有视频
 @param allowPickingImage 是否有照片
 @param needFetchAssets 是否需要抓取相册内部元素资源
 @param completion 完成回调
 */
- (void)getAlbumWithType:(AlbumType)type allowPickingVideo:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage needFetchAssets:(BOOL)needFetchAssets completion:(void (^ _Nullable)(NSArray<WGAlbumModel *> * _Nonnull models))completion {
    
    NSMutableArray *albumArr = [NSMutableArray array];
    
    PHFetchOptions *option = [PHFetchOptions new];
    if (!allowPickingVideo) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    if (!allowPickingImage) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
    if (!self.sortAscendingByModificationDate) {
        option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:self.sortAscendingByModificationDate]];
    }
    
    NSArray *allAlbums = nil;
    PHFetchResult *camera = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    PHFetchResult *video = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumVideos options:nil];
    PHFetchResult *shot = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumScreenshots options:nil];
    PHFetchResult *add = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumRecentlyAdded options:nil];
    PHFetchResult *userColl = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    if (type == AlbumTypeAll) {
        
        allAlbums = @[camera, video, shot, add, userColl];
    }
    else if (type == AlbumTypeCam) {
        
        allAlbums = @[camera];
    }
    for (PHFetchResult *fetchResult in allAlbums) {
        for (PHAssetCollection *collection in fetchResult) {
            
            // 过滤空相册
            if (![collection isKindOfClass:[PHAssetCollection class]] || collection.estimatedAssetCount <= 0) continue;
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
            if (fetchResult.count < 1) continue;
            
            if ([self isCameraRollAlbum:collection]) {
                
                [albumArr insertObject:[self modelWithResult:fetchResult name:collection.localizedTitle isCameraRoll:YES needFetchAssets:needFetchAssets] atIndex:0];
                
                if (type == AlbumTypeCam) {
                    
                    !completion ?: completion(albumArr);
                    
                    return;
                }
            }
            else {
                
                if (type == AlbumTypeCam) {
                 
                    continue;
                }
                [albumArr addObject:[self modelWithResult:fetchResult name:collection.localizedTitle isCameraRoll:NO needFetchAssets:needFetchAssets]];
            }
        }
    }
    !completion ?: completion(albumArr);
}

/**
 判断相机相册

 @param metadata 数据
 @return 是否为相机相册
 */
- (BOOL)isCameraRollAlbum:(nonnull PHAssetCollection *)metadata {
    
    return metadata.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary;
}

/**
 处理相册模型

 @param result 相册资源
 @param name 名称
 @param isCameraRoll 是否为相机相册
 @param needFetchAssets 是否需要抓取资源
 @return 相册模型
 */
- (WGAlbumModel *)modelWithResult:(nonnull PHFetchResult *)result name:(NSString *)name isCameraRoll:(BOOL)isCameraRoll needFetchAssets:(BOOL)needFetchAssets {
    
    WGAlbumModel *model = [WGAlbumModel new];
    model.result = result;
    if (needFetchAssets) {
        
        [self getAssetsFromFetchResult:result completion:^(NSArray<WGAssetModel *> * _Nonnull models) {
           
            model.models = models;
        }];
    }
    model.name = name;
    model.count = result.count;
    
    return model;
}

/**
 获取资源数组
 
 @param result 资源
 @param completion 完成回调
 */
- (void)getAssetsFromFetchResult:(nonnull PHFetchResult *)result completion:(void (^)(NSArray<WGAssetModel *> *models))completion {
    
    WGImagePickerConfig *config = [WGImagePickerConfig sharedInstance];
    
    return [self getAssetsFromFetchResult:result allowPickingVideo:config.allowPickingVideo allowPickingImage:config.allowPickingImage completion:completion];
}

/**
 获取资源数组

 @param result 资源
 @param allowPickingVideo 是否允许视频
 @param allowPickingImage 是否允许图片
 @param completion 完成回调
 */
- (void)getAssetsFromFetchResult:(nonnull PHFetchResult *)result allowPickingVideo:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage completion:(void (^)(NSArray<WGAssetModel *> *))completion {
    
    NSMutableArray *photoArr = [NSMutableArray array];
    
    [result enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        WGAssetModel *model = [self assetModelWithAsset:obj allowPickingVideo:allowPickingVideo allowPickingImage:allowPickingImage];
        
        if (model) {
            
            [photoArr addObject:model];
        }
    }];
    !completion ?: completion(photoArr);
}

/**
 处理资源模型

 @param asset 资源
 @param allowPickingVideo 是否允许视频
 @param allowPickingImage 是否允许图片
 @return 资源模型
 */
- (nullable WGAssetModel *)assetModelWithAsset:(nonnull PHAsset *)asset allowPickingVideo:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage {
    
    WGAssetModel *model;
    
    WGAssetModelMediaType type = [self getAssetType:asset];
    
    if (!allowPickingVideo && type == WGAssetModelMediaTypeVideo) {
        
        return nil;
    }
    if (!allowPickingImage && type == WGAssetModelMediaTypePhoto) {
        
        return nil;
    }
    if (!allowPickingImage && type == WGAssetModelMediaTypeGif) {
        
        return nil;
    }
    NSString *timeLength = type == WGAssetModelMediaTypeVideo ? [NSString stringWithFormat:@"%0.0f",asset.duration] : @"";
    timeLength = [self getNewTimeFromDurationSecond:timeLength.integerValue];
    model = [WGAssetModel modelWithAsset:asset type:type timeLength:timeLength];
    
    return model;
}

/**
 获取资源类型

 @param asset 资源
 @return 资源类型
 */
- (WGAssetModelMediaType)getAssetType:(nonnull PHAsset *)asset {
    
    WGAssetModelMediaType type = WGAssetModelMediaTypeUnknow;
    
    if (asset.mediaType == PHAssetMediaTypeVideo) {
        
        type = WGAssetModelMediaTypeVideo;
    }
    else if (asset.mediaType == PHAssetMediaTypeAudio) {
        
        type = WGAssetModelMediaTypeAudio;
    }
    else if (asset.mediaType == PHAssetMediaTypeImage) {
        
        type = WGAssetModelMediaTypePhoto;
        
        // Gif
        if ([[asset valueForKey:@"filename"] hasSuffix:@"GIF"]) {
            
            type = WGAssetModelMediaTypeGif;
        }
        // Live
        else if (IOS_SINCE(9.1)) {
            
            if (asset.mediaSubtypes & PHAssetMediaSubtypePhotoLive) {
                
                type = WGAssetModelMediaTypeLivePhoto;
            }
        }
    }
    return type;
}

/**
 获取视频时间描述

 @param duration 时长
 @return 时间描述
 */
- (NSString *)getNewTimeFromDurationSecond:(NSInteger)duration {
    
    NSString *newTime;
    
    if (duration < 10) {
        
        newTime = [NSString stringWithFormat:@"0:0%zd", duration];
    }
    else if (duration < 60) {
        
        newTime = [NSString stringWithFormat:@"0:%zd", duration];
    }
    else {
        
        NSInteger min = duration / 60;
        NSInteger sec = duration - (min * 60);
        
        if (sec < 10) {
            
            newTime = [NSString stringWithFormat:@"%zd:0%zd", min, sec];
        }
        else {
            
            newTime = [NSString stringWithFormat:@"%zd:%zd", min, sec];
        }
    }
    return newTime;
}

/**
 获取相册封面

 @param model 相册模型
 @param widthPixel 宽度像素个数
 @param completion 完成回调
 */
- (void)getPostImageWithAlbumModel:(WGAlbumModel *)model widthPixel:(CGFloat)widthPixel completion:(void (^ _Nullable)(UIImage * _Nullable image))completion {
    
        id asset = [model.result lastObject];
    
        if (!self.sortAscendingByModificationDate) {
            
            asset = [model.result firstObject];
        }
        [self getPhotoWithAsset:asset widthPixel:widthPixel completion:^(UIImage * _Nullable image, NSDictionary * _Nullable info, BOOL isDegraded) {
            
            !completion ?: completion(image);
        }];
}

/**
 获取资源封面

 @param asset 资源
 @param photoWidth 宽度像素个数
 @param completion 完成回调
 @return 错误码
 */
- (int32_t)getPhotoWithAsset:(nonnull PHAsset *)asset widthPixel:(CGFloat)widthPixel completion:(void (^ _Nullable)(UIImage * _Nullable image, NSDictionary * _Nullable info, BOOL isDegraded))completion {
    
    return [self getPhotoWithAsset:asset widthPixel:widthPixel completion:completion progressHandler:nil networkAccessAllowed:YES];
}

/**
 获取资源图片

 @param asset 资源
 @param widthPixel 宽度像素个数
 @param completion 完成回调
 @param progressHandler 进度回调
 @param networkAccessAllowed 是否允许访问网络
 @return 错误码
 */
- (int32_t)getPhotoWithAsset:(nonnull PHAsset *)asset widthPixel:(CGFloat)widthPixel completion:(void (^)(UIImage *photo, NSDictionary *info, BOOL isDegraded))completion progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler networkAccessAllowed:(BOOL)networkAccessAllowed {
    
    CGFloat aspectRatio = asset.pixelWidth / (CGFloat)asset.pixelHeight;
    
    if (widthPixel > asset.pixelWidth) {
        
        widthPixel = asset.pixelWidth;
    }
    CGFloat heightPixel = widthPixel / aspectRatio;
    
    const CGFloat maxWH = 828;
    
    if (widthPixel > heightPixel) {
        
        if (widthPixel > maxWH) {
            
            widthPixel = maxWH;
            heightPixel = widthPixel / aspectRatio;
        }
    }
    else {
        
        if (heightPixel > maxWH) {
            
            heightPixel = maxWH;
            widthPixel = heightPixel * aspectRatio;
        }
    }
    CGSize imageSize = CGSizeMake(widthPixel, heightPixel);
    
    // 修复获取图片时出现的瞬间内存过高问题
    PHImageRequestOptions *option = [PHImageRequestOptions new];
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    int32_t imageRequestID = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:imageSize contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
        
        if (downloadFinined && result) {
            
            !completion ?: completion(result, info, [[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
        }
        // 从iCloud下载图片
        else if ([info objectForKey:PHImageResultIsInCloudKey] && !result && networkAccessAllowed) {
            
            PHImageRequestOptions *options = [PHImageRequestOptions new];
            options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    !progressHandler ?: progressHandler(progress, error, stop, info);
                });
            };
            options.networkAccessAllowed = YES;
            options.resizeMode = PHImageRequestOptionsResizeModeFast;
            [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                
                UIImage *resultImage = [UIImage imageWithData:imageData scale:0.1f];
                resultImage = [self scaleImage:resultImage toSize:imageSize];
                
                if (!resultImage) {
                    
                    resultImage = result;
                }
                !completion ?: completion(resultImage, info, NO);
            }];
        }
    }];
    return imageRequestID;
}

/**
 缩放图片至新尺寸

 @param image 原图
 @param size 新尺寸
 @return 新图
 */
- (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)size {
    
    if (image.size.width > size.width) {
        
        UIGraphicsBeginImageContext(size);
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return newImage;
    }
    else {
        
        return image;
    }
}

/**
 获取相册内部元素资源
 
 @param album 相册模型
 @param allowPickingVideo 是否有视频
 @param allowPickingImage 是否有照片
 @param completion 完成回调
 */
- (void)getAssetWithAlbum:(nonnull WGAlbumModel *)album allowPickingVideo:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage completion:(void (^ _Nullable)(NSArray<WGAssetModel *> * _Nonnull models))completion {
    
    [self getAssetsFromFetchResult:album.result completion:^(NSArray<WGAssetModel *> * _Nonnull models) {
        
        !completion ?: completion(models);
    }];
}

/**
 获取视频数据

 @param asset 资源
 @param progressHandler 进度回调
 @param completion 完成回调
 */
- (void)getVideoWithAsset:(nonnull PHAsset *)asset progressHandler:(void (^ _Nullable)(double progress, NSError * _Nullable error, BOOL * _Nullable stop, NSDictionary * _Nullable info))progressHandler completion:(void (^ _Nullable)(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info))completion {
    
    PHVideoRequestOptions *option = [PHVideoRequestOptions new];
    option.networkAccessAllowed = YES;
    option.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            !progressHandler ?: progressHandler(progress, error, stop, info);
        });
    };
    [[PHImageManager defaultManager] requestPlayerItemForVideo:asset options:option resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
       
        dispatch_async(dispatch_get_main_queue(), ^{
            
            !completion ?: completion(playerItem, info);
        });
    }];
}

@end
