//
//  YTTMediaPlayerTools.h
//  YTTPlayerDemo
//
//  Created by qiuweniOS on 2019/2/20.
//  Copyright © 2019 AndyCuiYTT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

@interface YTTMediaPlayerTools : NSObject


/**
 强行修改屏幕方向

 @param orientation 屏幕方向
 */
+ (void)setInterfaceOrientation: (UIInterfaceOrientation)orientation;


@end

NS_ASSUME_NONNULL_END
