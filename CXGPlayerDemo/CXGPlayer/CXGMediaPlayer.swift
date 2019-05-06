
//
//  CXGMediaPlayer.swift
//  CXGPlayer
//
//  Created by CuiXg on 2019/2/20.
//  Copyright © 2019 CuiXg. All rights reserved.
//

import UIKit
import AVFoundation

// 视频横竖屏
public enum CXGDeviceOrientation {
    case horizontal // 横向
    case vertical // 竖向
}

// 播放器状态
public enum CXGPlayerState {
    case buffering // 缓冲
    case playing // 播放中
    case stopped // 停止播放
    case pause // 暂停
    
}


public class CXGMediaPlayer: UIView {
    
    var videoURLStr: String? {
        get {
            return videoURL?.absoluteString
        }
        set {
            if let urlStr = newValue {
                videoURL = URL(string: urlStr)
            }
        }
    }
    
    public var videoURL: URL?
    
    private let player: AVPlayer = AVPlayer()
    private var playerItem: AVPlayerItem?
    private var playerLayer: AVPlayerLayer!
    private var mask_View: CXGMediaPlayerMaskView!
    private var smallFrame: CGRect = CGRect.zero
    private var bigFrame: CGRect =  CGRect(x: 0, y: 0, width: UIScreen.main.bounds.height, height: UIScreen.main.bounds.width)
    private var deviceOrientation: CXGDeviceOrientation?
    private var isDragingSlider: Bool = false
    private let playerLoader: CXGMediaPlayerLoader = CXGMediaPlayerLoader()

    private var playState: CXGPlayerState? {
        
        willSet {
            
        }
        
        didSet {
            if playState != .buffering {
                mask_View.activity.stopAnimating()
            }
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        smallFrame = frame
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        self.layer.insertSublayer(playerLayer, at: 0)
        
        mask_View = CXGMediaPlayerMaskView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        self.addSubview(mask_View)
        
        addTargets()
        addNotifications()
        setProgressOfPlayTime()
    }
    
    public func setVideoUrl(_ urlStr: String) {
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
        } else {
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            urlComponents?.scheme = "streaming"
            if let u = urlComponents?.url {
                url = u
            }
            let asset = AVURLAsset(url: url, options: nil)
            asset.resourceLoader.setDelegate(playerLoader, queue: DispatchQueue.main)
            self.playerItem = AVPlayerItem(asset: asset)
        }
        
        player.replaceCurrentItem(with: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(videoPlayDidEnd(_:)), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        playerItem?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        playerItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
        playerItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
        playerItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
        
        player.play()
        mask_View.activity.startAnimating()
        
        
    }
 
    
    private func addTargets() {
        // 全屏事件
        mask_View.fullScreenBtn.addTarget(self, action: #selector(enterFullScreen(_:)), for: .touchUpInside)
        // 暂停播放
        mask_View.playBtn.addTarget(self, action: #selector(playOrPauseAction(_:)), for: .touchUpInside)
        // 开始按压滑条
        mask_View.videoSlider.addTarget(self, action: #selector(videoSliderTouchBegan(_:)), for: .touchDown)
        // 滑条值改变
        mask_View.videoSlider.addTarget(self, action: #selector(videoSliderValueChanged(_:)), for: .valueChanged)
        // 开始按压滑条
        mask_View.videoSlider.addTarget(self, action: #selector(videoSliderTouchEnd(_:)), for: .touchUpInside)
    }
    
    private func addNotifications() {
        // 开启设备方向通知
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        // 设备旋转通知
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        // 进入后台通知
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        // 返回前台通知
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    /// 设置进度条与时间
    private func setProgressOfPlayTime() {
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1.0, preferredTimescale: 1), queue: DispatchQueue.main) { [weak self] (cmTime) in
            
            if let isDraging = self?.isDragingSlider, !isDraging, let item = self?.playerItem {
                let currentTime = CMTimeGetSeconds(cmTime)
                let totalTime = CMTimeGetSeconds(item.duration)
                self?.mask_View.videoSlider.setValue(Float(currentTime / totalTime), animated: true)
                self?.mask_View.currentTimeLabel.text = String(format: "%02d:%02d", Int(currentTime) / 60, Int(currentTime) % 60)
                if totalTime > 0 {
                    self?.mask_View.totalTimeLabel.text = String(format: "%02d:%02d", Int(totalTime) / 60, Int(totalTime) % 60)
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
                    self.mask_View.videoSlider.setValue(Float(currentTime / totalTime), animated: true)
                    self.mask_View.currentTimeLabel.text = String(format: "%02d:%02d", Int(currentTime) / 60, Int(currentTime) % 60)
                    if totalTime > 0 {
                        self.mask_View.totalTimeLabel.text = String(format: "%02d:%02d", Int(totalTime) / 60, Int(totalTime) % 60)
                    }
               default:
                    self.mask_View.activity.startAnimating()
                    self.player.pause()
                    playState = .pause
                }
            }
        }else if keyPath == "loadedTimeRanges" {
            if let item = playerItem {
                if let timeRange = item.loadedTimeRanges.first as? CMTimeRange {
                    let startTime = CMTimeGetSeconds(timeRange.start)
                    let durationTime = CMTimeGetSeconds(timeRange.duration)
                    let loadedTime = startTime + durationTime
                    let totalTime = CMTimeGetSeconds(item.duration)
                    self.mask_View.progressView.setProgress(Float(loadedTime / totalTime), animated: true)
                }
            }
            
        }else if keyPath == "playbackBufferEmpty" {
            self.mask_View.activity.startAnimating()
            self.playState = .buffering
            player.pause()
            mask_View.playBtn.isSelected = false
        }else if keyPath == "playbackLikelyToKeepUp" {
            self.player.play()
            self.playState = .playing
            self.mask_View.activity.stopAnimating()
            mask_View.playBtn.isSelected = true
        }
        
        
        
    }
    
 
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 播放,暂停按钮
    ///
    /// - Parameter sender: 按钮
    @objc private func playOrPauseAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            player.play()
            playState = .playing
        }else {
            player.pause()
            playState = .pause
        }
    }
    
    // 进入全屏
    @objc private func enterFullScreen(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        CXGMediaPlayerTools.setInterfaceOrientation(sender.isSelected ? .landscapeRight : .portrait)
    }
    
    /// 开始滑动视频滑条
    ///
    /// - Parameter sender: 滑条
    @objc private func videoSliderTouchBegan(_ sender: UISlider) {
        isDragingSlider = true
    }
    
    /// 滑条值改变
    ///
    /// - Parameter sender: 滑条
    @objc private func videoSliderValueChanged(_ sender: UISlider) {
        
        if let item = self.playerItem {
            let currentTime = Float(CMTimeGetSeconds(item.duration)) * sender.value
            if currentTime > 0 {
                mask_View.currentTimeLabel.text = String(format: "%02d:%02d", Int(currentTime) / 60, Int(currentTime) % 60)
            }
        }
    }
    
    /// 结束滑动视频滑条
    ///
    /// - Parameter sender: 滑条
    @objc private func videoSliderTouchEnd(_ sender: UISlider) {
        
        mask_View.activity.startAnimating()
        if let item = self.playerItem {
            let currentTime = Float(CMTimeGetSeconds(item.duration)) * sender.value
            player.pause()
            
            player.seek(to: CMTime(seconds: Double(currentTime), preferredTimescale: 1)) { (finish) in
                    self.player.play()
                    self.playState = .playing
            }
        }
        isDragingSlider = false
    }
    
    
//    /// 缓存视频
//    private func bufferingSecond() {
//        self.mask_View.activity.startAnimating()
//        self.playState = .buffering
//        player.pause()
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
//            if self.mask_View.progressView.progress - self.mask_View.videoSlider.value > 0.01 {
//                self.player.play()
//                self.playState = .playing
//            }else {
//                self.bufferingSecond()
//            }
//        }
//    }
    
    
    
    
    /// 方向改变通知
    ///
    /// - Parameter notification: 通知消息
    @objc private func orientationChanged(_ notification: Notification) {
        switch UIDevice.current.orientation {
        case .landscapeLeft, .landscapeRight:
            self.frame = bigFrame
        case .portrait, .portraitUpsideDown:
            self.frame = smallFrame
        default:
            break
        }
    }
    
    /// app 进入后台
    ///
    /// - Parameter notification: 通知消息
    @objc private func appDidEnterBackground(_ notification: Notification) {
        player.pause()
    }
    
    /// app 变为活跃
    ///
    /// - Parameter notification: 通知消息
    @objc private func appDidBecomeActive(_ notification: Notification) {
        if let state = playState, state == .playing {
            player.play()
        }
    }
    
    /// 视频播放结束
    ///
    /// - Parameter notification: 通知消息
    @objc private func videoPlayDidEnd(_ notification: Notification) {
        
        player.seek(to: CMTime(value: 0, timescale: 1)) { (finish) in
            self.mask_View.videoSlider.setValue(0, animated: true)
            self.mask_View.currentTimeLabel.text = "00:00"
        }
        playState = .stopped
        mask_View.playBtn.isSelected = false
        
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = self.bounds
        mask_View.frame = self.bounds
    }
    
    
    deinit {
        // 关闭设备方向通知
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.removeObserver(self)
        playerItem?.removeObserver(self, forKeyPath: "status")
        playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        playerItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        playerItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
    }
    
    
}

