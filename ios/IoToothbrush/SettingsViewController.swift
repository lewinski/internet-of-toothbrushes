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
            if (!connected && selectedBean != nil) {
                connectButton.enabled = true
            } else {
                connectButton.enabled = false
            }
        }
    }

    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var deviceLabel: UILabel!
    @IBOutlet weak var batteryLabel: UILabel!

    @IBAction func unwindToSettingsViewController(segue: UIStoryboardSegue) {
    }

    @IBAction func connectToBean(sender: AnyObject) {
        batteryLabel.text = "connecting"

        toothbrushDiscovery.delegate = self
        toothbrushDiscovery.connectTo(selectedBean!)
    }

    func didConnectToBean(bean: PTDBean) {
        connected = true
        batteryLabel.text = "fetching"
        
        bean.delegate = self
        bean.readBatteryVoltage()
    }

    func didDisconnectFromBean(bean: PTDBean) {
        connected = false
    }

    func beanDidUpdateBatteryVoltage(bean: PTDBean!, error: NSError!) {
        batteryLabel.text = String(bean.batteryVoltage)
    }
}

