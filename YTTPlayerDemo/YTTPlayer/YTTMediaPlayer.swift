
//
//  YTTMediaPlayer.swift
//  YTTPlayer
//
//  Created by qiuweniOS on 2019/2/20.
//  Copyright © 2019 AndyCuiYTT. All rights reserved.
//

import UIKit
import AVFoundation

// 视频横竖屏
public enum YTTDeviceOrientation {
    case horizontal // 横向
    case vertical // 竖向
}

// 播放器状态
public enum YTTPlayerState {
    case buffering // 缓冲
    case playing // 播放中
    case stopped // 停止播放
    case pause // 暂停
    
}


public class YTTMediaPlayer: UIView {
    
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
    private var mask_View: YTTMediaPlayerMaskView!
    private var smallFrame: CGRect = CGRect.zero
    private var bigFrame: CGRect =  CGRect(x: 0, y: 0, width: UIScreen.main.bounds.height, height: UIScreen.main.bounds.width)
    private var deviceOrientation: YTTDeviceOrientation?
    

    private var playState: YTTPlayerState? {
        
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
        
        mask_View = YTTMediaPlayerMaskView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        self.addSubview(mask_View)
        
        addTargets()
        addNotifications()
        setProgressOfPlayTime()
    }
    
    public func setVideoUrl(_ url: URL) {
        playerItem?.removeObserver(self, forKeyPath: "status")
        playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        playerItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        playerItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        playerItem = nil
        
        playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(videoPlayDidEnd(_:)), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        playerItem?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        player.play()
        mask_View.playBtn.isSelected = true
        playState = .playing
        mask_View.activity.startAnimating()
        
    }
    
    private func addTargets() {
        // 全屏事件
        mask_View.fullScreenBtn.addTarget(self, action: #selector(enterFullScreen(_:)), for: .touchUpInside)
        // 暂停播放
        mask_View.playBtn.addTarget(self, action: #selector(playOrPauseAction(_:)), for: .touchUpInside)
    }
    
    private func addNotifications() {
        // 开启设备方向通知
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        // 设备旋转通知
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    /// 设置进度条与时间
    private func setProgressOfPlayTime() {
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1.0, preferredTimescale: 1), queue: DispatchQueue.main) { [weak self] (cmTime) in
            
            if let item = self?.playerItem {
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
        print(change?[NSKeyValueChangeKey.newKey])
        print(player.status.rawValue)
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
        YTTMediaPlayerTools.setInterfaceOrientation(sender.isSelected ? .landscapeRight : .portrait)
    }
    
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
    }
    
    
}
