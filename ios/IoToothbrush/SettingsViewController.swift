//
//  SettingsViewController.swift
//  IoToothbrush
//
//  Created by Matthew Lewinski on 5/1/16.
//  Copyright © 2016 Matthew Lewinski. All rights reserved.
//

import UIKit
import Bean_iOS_OSX_SDK

class SettingsViewController: UIViewController, ToothbrushDiscoveryDelegate, ToothbrushConnectionDelegate, PTDBeanDelegate {
    struct DefaultsKeys {
        static let deviceIdentifier = "DeviceIdentifier"
    }

    struct ConnectionStatus {
        static let notConfigured = ""
        static let searching = "Searching"
        static let disconnected = "Not Connected"
        static let connecting = "Connecting"
        static let connected = "Connected"
    }

    let dateFormatter = NSDateFormatter()

    var toothbrushDiscovery = ToothbrushDiscovery.sharedInstance
    var toothbrushConnection: ToothbrushConnection?

    var deviceIdentifier : NSUUID? {
        didSet {
            if deviceIdentifier != nil {
                let defaults = NSUserDefaults.standardUserDefaults()
                defaults.setValue(deviceIdentifier!.UUIDString, forKey: DefaultsKeys.deviceIdentifier)
                deviceLabel.text = deviceIdentifier!.UUIDString
            }
        }
    }

    var device : PTDBean? {
        didSet {
            if (device != nil) {
                if (!connected) {
                    connectionStatusLabel.text = ConnectionStatus.disconnected
                    connectButton.enabled = true
                }
                deviceIdentifier = device!.identifier
            }
        }
    }

    var connected = false {
        didSet {
            if (connected) {
                connectionStatusLabel.text = ConnectionStatus.connected
                connectButton.enabled = false
            } else if (device == nil) {
                connectionStatusLabel.text = ConnectionStatus.notConfigured
                connectButton.enabled = false
            } else {
                connectionStatusLabel.text = ConnectionStatus.disconnected
                connectButton.enabled = true
            }
        }
    }

    @IBOutlet weak var connectButton: UIBarButtonItem!

    @IBOutlet weak var deviceLabel: UILabel!
    @IBOutlet weak var connectionStatusLabel: UILabel!

    @IBOutlet weak var brushingStartedLabel: UILabel!
    @IBOutlet weak var brushingStoppedLabel: UILabel!
    @IBOutlet weak var brushingDurationLabel: UILabel!

    @IBOutlet weak var lastConnectionLabel: UILabel!
    @IBOutlet weak var batteryLabel: UILabel!
    @IBOutlet weak var signalStrengthLabel: UILabel!
    @IBOutlet weak var rtcLabel: UILabel!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .MediumStyle
    }

    override func viewWillAppear(animated: Bool) {
        if deviceIdentifier == nil {
            let defaults = NSUserDefaults.standardUserDefaults()
            if let uuidString = defaults.stringForKey(DefaultsKeys.deviceIdentifier) {
                deviceIdentifier = NSUUID(UUIDString: uuidString)
                if device == nil {
                    toothbrushDiscovery.delegate = self
                    toothbrushDiscovery.restartScan()
                    connectionStatusLabel.text = ConnectionStatus.searching
                }
            }
        }
    }

    override func viewWillDisappear(animated: Bool) {
        toothbrushDiscovery.stopScan()
        if let device = device {
            toothbrushDiscovery.disconnectFrom(device)
            toothbrushDiscovery.delegate = nil
            connected = false
        }
    }

    @IBAction func unwindToSettingsViewController(segue: UIStoryboardSegue) {
    }

    @IBAction func connectToBean(sender: AnyObject) {
        connectionStatusLabel.text = ConnectionStatus.connecting
        connectButton.enabled = false

        toothbrushDiscovery.delegate = self
        toothbrushDiscovery.connectTo(device!)
    }

    // MARK: PTDBeanDelegate

    func beanDidUpdateRSSI(bean: PTDBean!, error: NSError!) {
        signalStrengthLabel.text = String(bean.RSSI)
    }

    func beanDidUpdateBatteryVoltage(bean: PTDBean!, error: NSError!) {
        batteryLabel.text = "\(bean.batteryVoltage) V"
    }

    func bean(bean: PTDBean!, serialDataReceived data: NSData!) {
        toothbrushConnection?.handleIncomingData(data)
    }

    // MARK: ToothbrushDiscoveryDelegate

    func didDiscoverBean(bean: PTDBean) {
        if (bean.identifier == deviceIdentifier) {
            device = bean
            toothbrushDiscovery.stopScan()
        }
    }

    func didConnectToBean(bean: PTDBean) {
        connected = true

        let date = NSDate()
        lastConnectionLabel.text = dateFormatter.stringFromDate(date)

        toothbrushConnection = ToothbrushConnection()
        toothbrushConnection?.delegate = self

        bean.delegate = self
        bean.releaseSerialGate()

        toothbrushConnection?.sync()
        bean.readBatteryVoltage()
        bean.readRSSI()
    }

    func didDisconnectFromBean(bean: PTDBean) {
        connected = false
    }

    // MARK: ToothbrushConnectionDelegate

    func sendCommand(command: String) {
        device?.sendSerialString(command)
    }

    func brushingEventReceived(start: NSDate, end: NSDate, duration: Int) {
        brushingStartedLabel.text = dateFormatter.stringFromDate(start)
        brushingStoppedLabel.text = dateFormatter.stringFromDate(end)
        brushingDurationLabel.text = "\(duration) seconds"
    }

    func timeReceived(date: NSDate) {
        rtcLabel.text = dateFormatter.stringFromDate(date)
    }
}

