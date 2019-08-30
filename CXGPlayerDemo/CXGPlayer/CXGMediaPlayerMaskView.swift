//
//  CXGMediaPlayerMaskView.swift
//  CXGPlayerDemo
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

class CXGMediaPlayerMaskView: UIView {
    
    let player = CXGMediaPlayer()
    private var isDragingSlider: Bool = false
    private var totalTime: TimeInterval = 0
    
    private var smallFrame: CGRect = CGRect.zero
    private var bigFrame: CGRect =  CGRect(x: 0, y: 0, width: UIScreen.main.bounds.height, height: UIScreen.main.bounds.width)
    private var deviceOrientation: CXGDeviceOrientation?


    /// 播放按钮
    private let playBtn: UIButton = UIButton(type: .custom)
    
    /// 当前播放时间
    private let currentTimeLabel: UILabel = UILabel(frame: CGRect(x: 50, y: 10, width: 60, height: 30))
    
    /// 总时长
    private let totalTimeLabel: UILabel = UILabel()
    
    /// 缓冲进度条
    private let progressView: UIProgressView = UIProgressView()
    
    /// 滑竿
    private let videoSlider: UISlider = UISlider()
    
    /// 全屏按钮
    private let fullScreenBtn: UIButton = UIButton(type: .custom)
    
    /// 锁屏
    private var lockBtn: UIButton?
    
    /// 音量
//    let volumeProgress: UIProgressView = UIProgressView(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
    
    /// 菊花转
    private let activity: UIActivityIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)
    
    /// bottom渐变层
    private let bottomGradientLayer: CAGradientLayer = CAGradientLayer()
    
    /// top渐变层
    private let topGradientLayer: CAGradientLayer = CAGradientLayer()
    
    /// bottom
    private let bottomImageView: UIImageView = UIImageView()
    
    /// top
    private let topImageView: UIImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        smallFrame = frame
        setSubviews()
        do {
            try AVAudioSession.sharedInstance().setActive(true, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
        } catch {
            
        }
        addTargets()
        addNotifications()
//        setNotification()
    }
    
    private func setSubviews() {
        bottomImageView.isUserInteractionEnabled = true
        
        playBtn.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        playBtn.setImage(UIImage(named: "player_play"), for: .normal)
        playBtn.setImage(UIImage(named: "player_pause"), for: .selected)
        
        fullScreenBtn.setImage(UIImage(named: "player_fullscreen"), for: .normal)
        
        currentTimeLabel.text = "00:00"
        currentTimeLabel.textColor = UIColor.white
        currentTimeLabel.textAlignment = .center
        currentTimeLabel.font = UIFont.systemFont(ofSize: 15)
        
        totalTimeLabel.text = "00:00"
        totalTimeLabel.textColor = UIColor.white
        totalTimeLabel.textAlignment = .center
        totalTimeLabel.font = UIFont.systemFont(ofSize: 15)
        
        progressView.progressTintColor = UIColor(hue: 1, saturation: 1, brightness: 1, alpha: 0.3)
        progressView.trackTintColor = UIColor.clear
        
//        volumeProgress.transform = CGAffineTransform(rotationAngle: -CGFloat(Double.pi * 0.5))
//        volumeProgress.trackTintColor = UIColor(hue: 1, saturation: 1, brightness: 1, alpha: 0.3)
//        volumeProgress.progressTintColor = UIColor.clear
        
        videoSlider.setThumbImage(UIImage(named: "slider"), for: .normal)
        videoSlider.minimumTrackTintColor = UIColor.white
        videoSlider.maximumTrackTintColor = UIColor(hue: 0.3, saturation: 0.3, brightness: 0.3, alpha: 0.3)
        
        self.addSubview(topImageView)
        self.addSubview(bottomImageView)
        setCAGradientLayer()
        
        bottomImageView.addSubview(playBtn)
        bottomImageView.addSubview(fullScreenBtn)
        bottomImageView.addSubview(currentTimeLabel)
        bottomImageView.addSubview(totalTimeLabel)
        bottomImageView.addSubview(progressView)
        bottomImageView.addSubview(videoSlider)
//        self.addSubview(volumeProgress)
        self.addSubview(activity)
        
        if let lay = player.playerlayer {
            self.layer.insertSublayer(lay, at: 0)
        }
        
        
    }
    
    private func setCAGradientLayer() {
        self.bottomImageView.layer.addSublayer(bottomGradientLayer)
        bottomGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        bottomGradientLayer.endPoint = CGPoint(x: 0, y: 1)
        bottomGradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        bottomGradientLayer.locations = [0.0, 1.0]
        
        self.topImageView.layer.addSublayer(topGradientLayer)
        topGradientLayer.startPoint = CGPoint(x: 1, y: 0)
        topGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        topGradientLayer.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
        topGradientLayer.locations = [0.0, 1.0]
    }
    
//    private func setNotification() {
//        NotificationCenter.default.addObserver(self, selector: #selector(volumeChanged(_:)), name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"), object: nil)
//    }
//
//    @objc private func volumeChanged(_ notification: Notification) {
//        if let valueStr = notification.userInfo?["AVSystemController_AudioVolumeNotificationParameter"] as? String {
//            volumeProgress.progress = Float(valueStr) ?? 0
//        }
//
//    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let width = self.frame.width
        let height = self.frame.height
        
        topImageView.frame = CGRect(x: 0, y: 0, width: width, height: 50)
        bottomImageView.frame = CGRect(x: 0, y: height - 50, width: width, height: 50)
        bottomGradientLayer.frame = bottomImageView.bounds
        topGradientLayer.frame = topImageView.bounds
        
        fullScreenBtn.frame = CGRect(x: width - 50, y: 0, width: 50, height: 50)
        
        progressView.frame = CGRect(x: 0, y: 0, width: width - 220, height: 30)
        progressView.center = CGPoint(x: width / 2, y: 25)
        totalTimeLabel.frame = CGRect(x: width - 110, y: 10, width: 60, height: 30)
        videoSlider.frame = progressView.frame
        activity.frame = CGRect(x: width / 2 - 25, y: height / 2 - 25, width: 50, height: 50)
//        volumeProgress.center = CGPoint(x: 40, y: height / 2)
        
//        player.resetPlayerLayerFrame(self.bounds)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        // 关闭设备方向通知
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
    

}

extension CXGMediaPlayerMaskView {
    private func addTargets() {
        // 全屏事件
        fullScreenBtn.addTarget(self, action: #selector(enterFullScreen(_:)), for: .touchUpInside)
        // 暂停播放
        playBtn.addTarget(self, action: #selector(playOrPauseAction(_:)), for: .touchUpInside)
        // 开始按压滑条
        videoSlider.addTarget(self, action: #selector(videoSliderTouchBegan(_:)), for: .touchDown)
        // 滑条值改变
        videoSlider.addTarget(self, action: #selector(videoSliderValueChanged(_:)), for: .valueChanged)
        // 开始按压滑条
        videoSlider.addTarget(self, action: #selector(videoSliderTouchEnd(_:)), for: .touchUpInside)
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
}

extension CXGMediaPlayerMaskView {
    
    /// 播放,暂停按钮
    ///
    /// - Parameter sender: 按钮
    @objc private func playOrPauseAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            player.play()
        }else {
            player.pause()
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
        
        let currentTime = Float(totalTime) * sender.value
        if currentTime > 0 {
            currentTimeLabel.text = String(format: "%02d:%02d", Int(currentTime) / 60, Int(currentTime) % 60)
        }
    }
    
    /// 结束滑动视频滑条
    ///
    /// - Parameter sender: 滑条
    @objc private func videoSliderTouchEnd(_ sender: UISlider) {
        
        let currentTime = Float(totalTime) * sender.value
        player.pause()
        activity.startAnimating()
        player.seekToTime(TimeInterval(currentTime))
        isDragingSlider = false
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
//        if playState == .playing {
            player.play()
//        }
    }
}

