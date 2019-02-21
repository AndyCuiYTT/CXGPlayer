//
//  YTTMediaPlayerMaskView.swift
//  YTTPlayerDemo
//
//  Created by qiuweniOS on 2019/2/20.
//  Copyright © 2019 AndyCuiYTT. All rights reserved.
//

import UIKit
import AVFoundation

class YTTMediaPlayerMaskView: UIView {

    /// 播放按钮
    let playBtn: UIButton = UIButton(type: .custom)
    
    /// 当前播放时间
    let currentTimeLabel: UILabel = UILabel(frame: CGRect(x: 50, y: 10, width: 60, height: 30))
    
    /// 总时长
    let totalTimeLabel: UILabel = UILabel()
    
    /// 缓冲进度条
    let progressView: UIProgressView = UIProgressView()
    
    /// 滑竿
    let videoSlider: UISlider = UISlider()
    
    /// 全屏按钮
    let fullScreenBtn: UIButton = UIButton(type: .custom)
    
    /// 锁屏
    var lockBtn: UIButton?
    
    /// 音量
    let volumeProgress: UIProgressView = UIProgressView(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
    
    /// 菊花转
    let activity: UIActivityIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.white)
    
    /// bottom渐变层
    let bottomGradientLayer: CAGradientLayer = CAGradientLayer()
    
    /// top渐变层
    let topGradientLayer: CAGradientLayer = CAGradientLayer()
    
    /// bottom
    let bottomImageView: UIImageView = UIImageView()
    
    /// top
    let topImageView: UIImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setSubviews()
        do {
            try AVAudioSession.sharedInstance().setActive(true, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
        } catch {
            
        }
        
        setNotification()
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
        
        volumeProgress.transform = CGAffineTransform(rotationAngle: -CGFloat(Double.pi * 0.5))
        volumeProgress.trackTintColor = UIColor(hue: 1, saturation: 1, brightness: 1, alpha: 0.3)
        volumeProgress.progressTintColor = UIColor.clear
        
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
        self.addSubview(volumeProgress)
        self.addSubview(activity)
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
    
    private func setNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(volumeChanged(_:)), name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"), object: nil)
    }
    
    @objc private func volumeChanged(_ notification: Notification) {
        if let valueStr = notification.userInfo?["AVSystemController_AudioVolumeNotificationParameter"] as? String {
            volumeProgress.progress = Float(valueStr) ?? 0
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let width = self.frame.width
        let height = self.frame.height
        
        topImageView.frame = CGRect(x: 0, y: 0, width: width, height: 50)
        bottomImageView.frame = CGRect(x: 0, y: height - 50, width: width, height: 50)
        bottomGradientLayer.frame = bottomImageView.bounds
        topGradientLayer.frame = topImageView.bounds
        
        fullScreenBtn.frame = CGRect(x: width - 50, y: 0, width: 50, height: 50)
        
        
        progressView.frame = CGRect(x: 0, y: 0, width: width - 220, height: 20)
        progressView.center = CGPoint(x: width / 2, y: 25)
        totalTimeLabel.frame = CGRect(x: width - 110, y: 10, width: 60, height: 30)
        videoSlider.frame = progressView.frame
        activity.center = CGPoint(x: width / 2, y: height / 2)
        volumeProgress.center = CGPoint(x: 40, y: height / 2)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    

}
