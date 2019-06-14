//
//  NSTimer+WGExtension.m
//  PuChi
//
//  Created by Veeco on 07/03/2018.
//  Copyright © 2018 Chance. All rights reserved.
//

#import "NSTimer+WGExtension.h"

@implementation NSTimer (WGExtension)

/**
 生成计时器
 
 @param interval 计时间隔
 @param repeats 是否重复
 @param block 每次执行的操作
 @return 实例
 */
+ (nonnull NSTimer *)wg_weakTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(nullable void(^)(NSTimer * _Nonnull timer))block {
    
    return [self timerWithTimeInterval:interval target:self selector:@selector(executeBlock:) userInfo:[block copy] repeats:repeats];
}

+ (void)executeBlock:(nonnull NSTimer *)timer {
    
    void (^block)(NSTimer *timer) = timer.userInfo;
    !block ? : block(timer);
}

@end
