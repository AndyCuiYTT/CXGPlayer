//
//  CXGMediaPlayerTools.h
//  CXGPlayerDemo
//
//  Created by CuiXg on 2019/2/20.
//  Copyright © 2019 CuiXg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

@interface CXGMediaPlayerTools : NSObject


/**
 强行修改屏幕方向

 @param orientation 屏幕方向
 */
+ (void)setInterfaceOrientation: (UIInterfaceOrientation)orientation;


@end

NS_ASSUME_NONNULL_END
