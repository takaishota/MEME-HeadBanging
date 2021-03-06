//
//  ViewController.swift
//  JinsMemeDemo
//
//  Created by matz on 2015/11/21.
//  Copyright © 2015年 matz. All rights reserved.
//

import UIKit

final class ViewController: UITableViewController, MEMELibDelegate {

    var peripherals:NSMutableArray!
    var dataViewCtl:MusicPlayerViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MEMELib.sharedInstance().delegate = self
        self.peripherals = []
        self.title = "MEME Demo"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Scan", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("scanButtonPressed"))
    }
    
    func scanButtonPressed(){
        let status:MEMEStatus = MEMELib.sharedInstance().startScanningPeripherals()
        self.checkMEMEStatus(status)
    }
    
    func memePeripheralFound(peripheral: CBPeripheral!, withDeviceAddress address: String!) {
        
        var alreadyFound = false
        for p in self.peripherals {
            if p.identifier == peripheral.identifier {
                alreadyFound = true
                break
            }
        }
        
        if !alreadyFound {
            print("New Peripheral found \(peripheral.identifier.UUIDString) \(address)")
            self.peripherals.addObject(peripheral)
            self.tableView.reloadData()
        }
    }
    
    func memePeripheralConnected(peripheral: CBPeripheral!) {
        
        print("MEME Device Connected")
        self.navigationItem.rightBarButtonItem?.enabled = false
        self.tableView.userInteractionEnabled = false
        self.performSegueWithIdentifier("DataViewSegue", sender: self)

        // Set Data Mode to Standard Mode
        MEMELib.sharedInstance().startDataReport()
    }
    
    func memePeripheralDisconnected(peripheral: CBPeripheral!) {
        
        print("MEME Device Disconnected")
        self.navigationItem.rightBarButtonItem?.enabled = true
        self.tableView.userInteractionEnabled = true
        self.dismissViewControllerAnimated(true) { () -> Void in
            self.dataViewCtl = nil
            print("MEME Device Disconnected")
        }
    }
    
    func memeRealTimeModeDataReceived(data: MEMERealTimeData!) {
        
        if (self.dataViewCtl != nil) {
            self.dataViewCtl.memeRealTimeModeDataReceived(data)
//            RealtimeData.sharedInstance.memeRealTimeModeDataReceived(data)
        }
    }
    
    func memeAppAuthorized(status: MEMEStatus) {
        self.checkMEMEStatus(status)
    }
    
    
    func memeCommandResponse(response: MEMEResponse) {
        
        print("Command Response - eventCode: \(response.eventCode) - commandResult: \(response.commandResult)")
        
        switch (response.eventCode) {
        case 0x02:
            print("Data Report Started");
            break;
        case 0x04:
            print("Data Report Stopped");
            break;
        default:
            break;
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.peripherals.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("DeviceCellIdentifier", forIndexPath: indexPath)
        let peripheral:CBPeripheral = self.peripherals.objectAtIndex(indexPath.row) as! CBPeripheral
        cell.textLabel?.text = peripheral.identifier.UUIDString
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let peripheral:CBPeripheral = self.peripherals.objectAtIndex(indexPath.row) as! CBPeripheral
        let status:MEMEStatus = MEMELib.sharedInstance().connectPeripheral(peripheral)
        self.checkMEMEStatus(status)
        
        print("Start connecting to MEME Device...")
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "DataViewSegue" {
            
            let naviCtl = segue.destinationViewController as! UINavigationController
            self.dataViewCtl = naviCtl.topViewController as! MusicPlayerViewController
        }
    }

    
    func checkMEMEStatus(status:MEMEStatus) {
        
        if status == MEME_ERROR_APP_AUTH {
            UIAlertView(title: "App Auth Failed", message: "Invalid Application ID or Client Secret ", delegate: nil, cancelButtonTitle: "OK").show()
        } else if status == MEME_ERROR_SDK_AUTH{
            UIAlertView(title: "SDK Auth Failed", message: "Invalid SDK. Please update to the latest SDK.", delegate: nil, cancelButtonTitle: "OK").show()
        } else if status == MEME_CMD_INVALID {
            UIAlertView(title: "SDK Error", message: "Invalid Command", delegate: nil, cancelButtonTitle: "OK").show()
        } else if status == MEME_ERROR_BL_OFF {
            UIAlertView(title: "Error", message: "Bluetooth is off.", delegate: nil, cancelButtonTitle: "OK").show()
        } else if status == MEME_OK {
            print("Status: MEME_OK")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

