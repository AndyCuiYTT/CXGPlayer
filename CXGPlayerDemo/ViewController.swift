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

        let player = CXGMediaPlayerMaskView(frame: CGRect(x: 0, y: 20, width: UIScreen.main.bounds.width, height: 300))
        
//        player.setVideoUrl("https://media.w3.org/2010/05/bunny/movie.mp4")

//        player.setVideoUrl("https://media.w3.org/2010/04/html5-meetup-paris-avril-2010.mp4")
//        player.setVideoUrl("http://download.lingyongqian.cn/music/AdagioSostenuto.mp3")
//        player.player.setVideoUrl("http://video.qiuwenxinli.com/SHKfmzh12.mp4?e=1557888353&token=cA5ED2E4upQ99lBkEsMGdnFwGjb-_3ooO1GgRfe5:eH-24eZxpkoUS7IgU-MlQNxbTto=")
        
        self.view.addSubview(player)
        
        
        
    }


}

