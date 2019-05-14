//
//  CXGMediaPlayerDelegate.swift
//  CXGPlayerDemo
//
//  Created by qiuweniOS on 2019/5/5.
//  Copyright © 2019 CuiXg. All rights reserved.
//

import UIKit

public protocol CXGMediaPlayerDelegate: class {
    
    /// 播放失败
    ///
    /// - Parameter player: 播放器
    func mediaPlayerLoadFailed(_ player: CXGMediaPlayer)
    
    /// 播放结束
    ///
    /// - Parameter player: 播放器
    func mediaPlayerEnd(_ player: CXGMediaPlayer)
    
    /// 开始播放
    ///
    /// - Parameter player: 播放器
    func mediaPlayerPlay(_ player: CXGMediaPlayer)

    /// 播放暂停
    ///
    /// - Parameter player: 播放器
    func mediaPlayerPause(_ player: CXGMediaPlayer)
    
    /// 缓存不足够播放
    ///
    /// - Parameter player: 播放器
    func mediaPlayerBufferEmpty(_ player: CXGMediaPlayer)
    
    
    /// 缓存足够
    ///
    /// - Parameter player: 
    func mediaPlayerBufferEnough(_ player: CXGMediaPlayer)
    
    /// 缓存加载进度
    ///
    /// - Parameters:
    ///   - player: 播放器
    ///   - progress: 加载进度
    func mediaPlayer(_ player: CXGMediaPlayer, loadProgress progress: Float)
    
    /// 播放进度
    ///
    /// - Parameters:
    ///   - player: 播放器
    ///   - progress: 播放进度
    ///   - currentTime: 当前播放时间
    ///   - totalTime: 总时长
    func mediaPlayer(_ player: CXGMediaPlayer, playedProgress progress: Float, currentTime: TimeInterval, totalTime: TimeInterval)
       
}
