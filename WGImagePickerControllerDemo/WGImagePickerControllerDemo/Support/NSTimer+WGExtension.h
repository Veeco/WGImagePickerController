//
//  NSTimer+WGExtension.h
//  PuChi
//
//  Created by Veeco on 07/03/2018.
//  Copyright © 2018 Chance. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSTimer (WGExtension)

/**
 生成计时器

 @param interval 计时间隔
 @param repeats 是否重复
 @param block 每次执行的操作
 @return 实例
 */
+ (nonnull NSTimer *)wg_weakTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(nullable void(^)(NSTimer * _Nonnull timer))block;

@end
