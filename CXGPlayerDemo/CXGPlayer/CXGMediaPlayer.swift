
//
//  CXGMediaPlayer.swift
//  CXGPlayer
//
//  Created by CuiXg on 2019/2/20.
//  Copyright © 2019 CuiXg. All rights reserved.
//

import UIKit
import AVFoundation



// 播放器状态
public enum CXGPlayerState {
    case buffering // 缓冲
    case playing // 播放中
    case stopped // 停止播放
    case pause // 暂停
    case failed // 错误
    
}


public class CXGMediaPlayer: NSObject {
    
    
    private let player: AVPlayer = AVPlayer()
    private var playerItem: AVPlayerItem?
    private var mask_View: CXGMediaPlayerMaskView!

    private let playerLoader: CXGMediaPlayerLoader = CXGMediaPlayerLoader()

    private var playState: CXGPlayerState = .pause
    
    /// 是否加载本地
    private var isCacheFile: Bool = false
    
    public var delegate: CXGMediaPlayerDelegate?
    
    private var timeObserver: Any?
    
    var playerlayer: AVPlayerLayer?
    
    
   
    
    override init() {
        super.init()
        
        playerlayer = AVPlayerLayer(player: player)
        playerlayer?.videoGravity = .resizeAspect
        
//        delegate?.mediaPlayer(self, playerLayer: layer!)

        
        setProgressOfPlayTime()
    }
    
    
    func play(withVideoURL urlStr: String) {
        self.playerLoader.setCancel()
        playerItem?.removeObserver(self, forKeyPath: "status")
        playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        playerItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        playerItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        playerItem = nil
        
        guard var url = URL(string: urlStr) else {
            return
        }
        
        
        /// 判断是否有缓存文件
        if let path = CXGMediaPlayerFileHandle.cacheFilePath(withURL: url) {
            self.playerItem = AVPlayerItem(url: URL(fileURLWithPath: path))
            isCacheFile = true
        } else {
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            urlComponents?.scheme = "streaming"
            if let u = urlComponents?.url {
                url = u
            }
            let asset = AVURLAsset(url: url, options: nil)
            asset.resourceLoader.setDelegate(playerLoader, queue: DispatchQueue.main)
            self.playerItem = AVPlayerItem(asset: asset)
            playerItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
            playerItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
            isCacheFile = false
        }
        
        player.replaceCurrentItem(with: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(videoPlayDidEnd(_:)), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        playerItem?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        playerItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
    }
    
    func play() {
        player.play()
        playState = .playing
    }
    
    
    func pause(_ isChangeStatus: Bool = true) {
        player.pause()
        if isChangeStatus {
            playState = .pause
        }
    }
    
    
    /// 设置进度条与时间
    private func setProgressOfPlayTime() {
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1.0, preferredTimescale: 1), queue: DispatchQueue.main) { [weak self] (cmTime) in
            
            if let item = self?.playerItem {
                let currentTime = CMTimeGetSeconds(cmTime)
                let totalTime = CMTimeGetSeconds(item.duration)
                if  totalTime > 0, let sSelf = self {
                    sSelf.delegate?.mediaPlayer(sSelf, playedProgress: Float(currentTime / totalTime), currentTime: currentTime, totalTime: totalTime)
                }
            }
        }
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "status" {
            if let item = playerItem {
                switch item.status {
                
                case .readyToPlay:
                    let currentTime = CMTimeGetSeconds(item.currentTime())
                    let totalTime = CMTimeGetSeconds(item.duration)

                    if totalTime > 0 {
                        delegate?.mediaPlayer(self, playedProgress: Float(currentTime / totalTime), currentTime: currentTime, totalTime: totalTime)
                    }

                    if isCacheFile {
                        play()
                        delegate?.mediaPlayerBufferEnough(self)
                    }
                case .failed:
                    playState = .failed
                    delegate?.mediaPlayerLoadFailed(self)
                    print("load error")
                    break
                case .unknown:
                    break
                }
            }
        }else if keyPath == "loadedTimeRanges" {
            if let item = playerItem {
                if let timeRange = item.loadedTimeRanges.first as? CMTimeRange {
                    let startTime = CMTimeGetSeconds(timeRange.start)
                    let durationTime = CMTimeGetSeconds(timeRange.duration)
                    let loadedTime = startTime + durationTime
                    let totalTime = CMTimeGetSeconds(item.duration)
                    delegate?.mediaPlayer(self, loadProgress: Float(loadedTime) / Float(totalTime))
                }
            }
        }else if keyPath == "playbackBufferEmpty" {
            pause(false)
            delegate?.mediaPlayerBufferEmpty(self)

        }else if keyPath == "playbackLikelyToKeepUp" {
            if playState == .playing {
                play()
            }
            delegate?.mediaPlayerBufferEnough(self)
        }
    }
    
 
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
   
    
    
    
    /// 滑动快进
    ///
    /// - Parameter sender: 滑条
    func seekToTime(_ time: TimeInterval) {
        pause()
        self.playerLoader.isSeekRequired = true
        player.seek(to: CMTime(seconds: time, preferredTimescale: 1)) { [weak self] (finish) in
            self?.play()
        }
    }
    
    
    
    
    
    /// 视频播放结束
    ///
    /// - Parameter notification: 通知消息
    @objc private func videoPlayDidEnd(_ notification: Notification) {
        
        player.seek(to: CMTime(value: 0, timescale: 1)) { [weak self] (finish) in
            if let sSelf = self {
                sSelf.delegate?.mediaPlayerEnd(sSelf)
            }
        }
        playState = .stopped        
    }

    deinit {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
        }
        
        NotificationCenter.default.removeObserver(self)
        playerItem?.removeObserver(self, forKeyPath: "status")
        playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        playerItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        playerItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
    }
    
    
}

