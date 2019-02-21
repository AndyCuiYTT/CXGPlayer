//
//  YTTMediaPlayerTools.m
//  YTTPlayerDemo
//
//  Created by qiuweniOS on 2019/2/20.
//  Copyright © 2019 AndyCuiYTT. All rights reserved.
//

#import "YTTMediaPlayerTools.h"

@implementation YTTMediaPlayerTools

+ (void)setInterfaceOrientation: (UIInterfaceOrientation)orientation {
    if([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val                  = orientation;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}


@end
