//
//  SettingsViewController.swift
//  IoToothbrush
//
//  Created by Matthew Lewinski on 5/1/16.
//  Copyright © 2016 Matthew Lewinski. All rights reserved.
//

import UIKit
import Bean_iOS_OSX_SDK

class SettingsViewController: UIViewController, PTDBeanDelegate {

    var selectedBean : PTDBean? {
        didSet {
            reloadBean()
        }
    }

    @IBOutlet weak var deviceLabel: UILabel!
    @IBOutlet weak var batteryLabel: UILabel!

    @IBAction func unwindToSettingsViewController(segue: UIStoryboardSegue) {
    }

    func reloadBean() {
        selectedBean?.delegate = self
        selectedBean?.readBatteryVoltage()

        deviceLabel.text = selectedBean?.identifier.UUIDString
        batteryLabel.text = "fetching"
    }

    func beanDidUpdateBatteryVoltage(bean: PTDBean!, error: NSError!) {
        batteryLabel.text = String(bean.batteryVoltage)
    }
}

