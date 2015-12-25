//
//  SwingingHeadViewController.swift
//  JinsMemeDemo
//
//  Created by ShotaTakai on 2015/12/24.
//  Copyright © 2015年 matz. All rights reserved.
//

import UIKit

class SwingingHeadViewController: UIViewController, MemeRealTimeDataStreamDelegate {
    
    @IBOutlet weak var swingingHead: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(red:0.93, green:0.44, blue:0.48, alpha:0.9)
        self.swingingHead.center.y = self.view.center.y
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        let musicPlayerVC = self.presentingViewController?.childViewControllers[0] as! MusicPlayerViewController
        musicPlayerVC.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: MemeRealTimeDataStream Delegate
    func memeRealTimeModeDataReceivedPitch(dataPitch: Float) {
        
        // 角度に応じて顔の位置を上下に動かす（角度：-90〜90度ぐらい 最大20pt）
        let d: Float = 20
        self.swingingHead.center.y = self.view.center.y + CGFloat(d * sin(dataPitch * Float(M_PI/180)))
    }
}