//
//  ViewController.swift
//  CXGPlayerDemo
//
//  Created by CuiXg on 2019/2/20.
//  Copyright © 2019 CuiXg. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.backgroundColor = UIColor.gray

        let player = CXGMediaPlayer(frame: CGRect(x: 0, y: 20, width: UIScreen.main.bounds.width, height: 300))
        
//        player.setVideoUrl("https://media.w3.org/2010/05/bunny/movie.mp4")

//        player.setVideoUrl("https://media.w3.org/2010/04/html5-meetup-paris-avril-2010.mp4")
//        player.setVideoUrl("http://download.lingyongqian.cn/music/AdagioSostenuto.mp3")
        player.setVideoUrl("http://video.qiuwenxinli.com/tsjszibeiyuchaoyue.mp4?e=1557470552&token=cA5ED2E4upQ99lBkEsMGdnFwGjb-_3ooO1GgRfe5:8yKF32_3gRgfqobc2ktyb9CLhjE=")
        
        self.view.addSubview(player)
        
        
        
    }


}

