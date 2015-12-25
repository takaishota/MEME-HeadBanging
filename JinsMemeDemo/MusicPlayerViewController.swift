//
//  MusicPlayerViewController.swift
//  JinsMemeDemo
//
//  Created by ShotaTakai on 2015/12/23.
//  Copyright © 2015年 matz. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

protocol MemeRealTimeDataStreamDelegate {
    func memeRealTimeModeDataReceivedPitch(pitch: Float)
}

class MusicPlayerViewController: UIViewController, MPMediaPickerControllerDelegate, AVAudioPlayerDelegate {
    
    let realTimeDataFrequency:Int = 20
    let volumeUnit:Float = 0.125
    
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var rateSlider: UISlider!
    @IBOutlet weak var volumeSlider: UISlider!
    
    @IBOutlet weak var pitch: UILabel!
    @IBOutlet weak var accY: UILabel!
    
    var indicatorView:UIView?
    var audioPlayer: AVAudioPlayer?
    var modalView: UIViewController?
    
    var latestRealTimeData:MEMERealTimeData?
    var delegate:MemeRealTimeDataStreamDelegate?
    
    var minPitchValue: Float = 0
    var maxPitchValue: Float = 0
    var count : Int = 1
    var pitchValue:Float = 0 {
        willSet {
            
            if pitchValue > 0 && abs(newValue - pitchValue) > 2 && self.audioPlayer?.prepareToPlay() == true {
                // 曲が選択されているか、一時停止状態で頭を振ると曲が開始する
                self.didStartSwingingHead()
                
                if self.audioPlayer?.playing == false {
                    self.audioPlayer?.play()
                }
                
            } else if self.modalView != nil && abs(newValue - pitchValue) < 0.03 {
                // Swingが止まったら、モーダルビューを閉じる
                self.modalView!.dismissViewControllerAnimated(true, completion: {self.modalView = nil})
                self.audioPlayer?.pause()
                
                self.rateSlider.value = (self.audioPlayer?.rate)!
                self.volumeSlider.value = (self.audioPlayer?.volume)!
                
            }
            
            if count >= realTimeDataFrequency {
                // 1秒間（20Hz）の最大値/最小値から音量を決める（0〜1.0の間で0.125ずつの10段階）
                if self.audioPlayer != nil {
                    self.audioPlayer!.volume = ceilf(((abs(sin(self.minPitchValue * Float(M_PI/180))) + abs(sin(self.maxPitchValue * Float(M_PI/180)))) * 0.5)/volumeUnit) * volumeUnit
//                    print(NSString(format: "Volume: %0.3f", self.audioPlayer!.volume))
                    
                    self.maxPitchValue = 0
                    self.minPitchValue = 0
                    count = 1
                }
            }
            
            if newValue > self.maxPitchValue {
                self.maxPitchValue = newValue
                
            } else if newValue < self.minPitchValue {
                self.minPitchValue = newValue
                
            }
            count += 1
            
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "RealTime Data"
        self.indicatorView = UIView(frame: CGRectMake(0, 0, 24, 24))
        self.indicatorView?.alpha = 0.20
        self.indicatorView?.backgroundColor = UIColor.whiteColor()
        self.indicatorView?.layer.cornerRadius = (self.indicatorView?.frame.size.height)! * 0.5
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.indicatorView!)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Disconnect", style: UIBarButtonItemStyle.Plain, target: self, action:  Selector("disconnectButtonPressed"))
        
        audioPlayer?.rate = 1.0
        audioPlayer?.volume = 0.5
    }
    
    func disconnectButtonPressed(){
        MEMELib.sharedInstance().disconnectPeripheral()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func memeRealTimeModeDataReceived(data: MEMERealTimeData) {
        
        self.blinkIndicator()
        self.reloadData(data)
        
        self.delegate?.memeRealTimeModeDataReceivedPitch(data.pitch)
        
    }
    
    func blinkIndicator(){
        
        UIView.animateWithDuration(0.05, animations: { () -> Void in
            
            self.indicatorView?.backgroundColor = UIColor.redColor()
            
            }) { (finished:Bool) -> Void in
                
                UIView.animateWithDuration(0.05, delay: 0.02, options: UIViewAnimationOptions.AllowAnimatedContent, animations: { () -> Void in
                    
                    self.indicatorView?.backgroundColor = UIColor.whiteColor()
                    
                    }, completion: nil)
        }
    }
    
    func reloadData(data: MEMERealTimeData) {
        if data as MEMERealTimeData? != nil {
            // pitchの値を頭の振りの判定に使う
            self.pitch.text =  NSString(format: "pitch: %.2f", (data.pitch)) as String
            self.accY.text = NSString(format: "accY: %d", (data.accY)) as String
            
            self.pitchValue = data.pitch
        }
    }
    
    // MARK: Swinging Head
    func didStartSwingingHead() {
        if self.modalView == nil {
            self.modalView = self.storyboard?.instantiateViewControllerWithIdentifier("SwingingHeadView")
            self.modalView!.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
            self.presentViewController(modalView!, animated: true, completion: nil)
        }
    }
    
    // MARK: Media Picker
    @IBAction func pick(sender: AnyObject) {
        let picker = MPMediaPickerController()
        picker.delegate = self
        picker.allowsPickingMultipleItems = false

        presentViewController(picker, animated: true, completion: nil)
    }
    
    // メディアアイテムピッカーでアイテムを選択完了したときに呼び出される
    func mediaPicker(mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        
        // このfunctionを抜けるときにピッカーを閉じる
        defer {
            mediaPicker.dismissViewControllerAnimated(true, completion: nil)
        }
        
        let items = mediaItemCollection.items
        if items.count < 1 {
            songTitleLabel.text = "曲 名"
            return
        }
        
        let item = items[0]
        if let url = item.assetURL {
            audioPlayer = try? AVAudioPlayer(contentsOfURL: url)
            audioPlayer?.delegate = self
            
            if audioPlayer == nil {
                // 再生できません
                return
            }
            
            // 再生開始
            if let player = audioPlayer {

                songTitleLabel.text = item.title ?? ""
                
                player.enableRate = true
                player.rate = rateSlider.value
                player.volume = volumeSlider.value
                
                player.play()
            }
            
        } else {
            audioPlayer = nil
        }
    }
    
    //選択がキャンセルされた場合に呼ばれる
    func mediaPickerDidCancel(mediaPicker: MPMediaPickerController) {
        mediaPicker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Playback Rate Changed
    @IBAction func songRateValueChanged(sender: AnyObject) {
        let slider = sender as! UISlider
        
        if let player = audioPlayer {
            player.rate = slider.value
        }
    }
    
    // MARK: Volume Changed
    @IBAction func songVolumeChanged(sender: AnyObject) {
        let slider = sender as! UISlider
        
        if let player = audioPlayer {
            player.volume = slider.value
        }
    }
    
    // MARK: Play, Pause, Stop
    @IBAction func playBtnTapped(sender: AnyObject) {
        if let player = audioPlayer {
            player.play()
        }
    }
    
    @IBAction func pauseBtnTapped(sender: AnyObject) {
        if let player = audioPlayer {
            player.pause()
        }
    }
    
    @IBAction func stopBtnTapped(sender: AnyObject) {
        if let player = audioPlayer {
            player.stop()
        }
    }
    
    // MARK: AVAudioPlayer Delegate
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        self.modalView?.dismissViewControllerAnimated(true, completion: { self.modalView = nil})
    }
    
}

