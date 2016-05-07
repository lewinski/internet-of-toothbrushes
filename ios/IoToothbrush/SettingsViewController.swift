//
//  SettingsViewController.swift
//  IoToothbrush
//
//  Created by Matthew Lewinski on 5/1/16.
//  Copyright © 2016 Matthew Lewinski. All rights reserved.
//

import UIKit
import Bean_iOS_OSX_SDK

class SettingsViewController: UIViewController, ToothbrushDiscoveryDelegate, PTDBeanDelegate {

    var toothbrushDiscovery = ToothbrushDiscovery.sharedInstance

    var selectedBean : PTDBean? {
        didSet {
            if (selectedBean != nil) {
                if (!connected) {
                    connectButton.enabled = true
                }

                deviceLabel.text = selectedBean!.identifier.UUIDString
            }
        }
    }

    var connected = false {
        didSet {
            if (connected) {
                connectionStatusLabel.text = "Connected"
                connectButton.enabled = false
            } else {
                if (selectedBean == nil) {
                    connectionStatusLabel.text = ""
                } else {
                    connectionStatusLabel.text = "Not Connected"
                    connectButton.enabled = true
                }
            }
        }
    }

    @IBOutlet weak var connectButton: UIBarButtonItem!
    @IBOutlet weak var deviceLabel: UILabel!
    @IBOutlet weak var connectionStatusLabel: UILabel!
    @IBOutlet weak var lastConnectionLabel: UILabel!
    @IBOutlet weak var signalStrengthLabel: UILabel!
    @IBOutlet weak var batteryLabel: UILabel!

    @IBAction func unwindToSettingsViewController(segue: UIStoryboardSegue) {
    }

    @IBAction func connectToBean(sender: AnyObject) {
        connectionStatusLabel.text = "Connecting"
        connectButton.enabled = false

        toothbrushDiscovery.delegate = self
        toothbrushDiscovery.connectTo(selectedBean!)
    }

    func didConnectToBean(bean: PTDBean) {
        connected = true
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .MediumStyle
        let date = NSDate()
        lastConnectionLabel.text = dateFormatter.stringFromDate(date)
        
        bean.delegate = self
        bean.releaseSerialGate()
        bean.sendSerialString("GetRTC\n")
        bean.readBatteryVoltage()
        bean.readRSSI()
    }

    func didDisconnectFromBean(bean: PTDBean) {
        connected = false
    }

    func beanDidUpdateRSSI(bean: PTDBean!, error: NSError!) {
        signalStrengthLabel.text = String(bean.RSSI)
    }

    func beanDidUpdateBatteryVoltage(bean: PTDBean!, error: NSError!) {
        batteryLabel.text = String(bean.batteryVoltage) + " V"
    }
    
    func bean(bean: PTDBean!, serialDataReceived data: NSData!) {
        let string = String(data: data, encoding: NSASCIIStringEncoding)
        print(string)
    }
}

