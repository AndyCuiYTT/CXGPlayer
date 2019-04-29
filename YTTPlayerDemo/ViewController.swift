//
//  ViewController.swift
//  YTTPlayerDemo
//
//  Created by qiuweniOS on 2019/2/20.
//  Copyright © 2019 AndyCuiYTT. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.backgroundColor = UIColor.gray

        let player = YTTMediaPlayer(frame: CGRect(x: 0, y: 20, width: UIScreen.main.bounds.width, height: 300))
        
        player.setVideoUrl("https://media.w3.org/2010/05/bunny/trailer.mp4")
        
        
        
        self.view.addSubview(player)
        
        
        
    }


}

