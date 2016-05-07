//
//  ToothbrushDiscovery.swift
//  IoToothbrush
//
//  Created by Matthew Lewinski on 5/6/16.
//  Copyright © 2016 Matthew Lewinski. All rights reserved.
//

import Foundation
import Bean_iOS_OSX_SDK

@objc protocol ToothbrushDiscoveryDelegate: class {
    optional func didDiscoverBean(bean: PTDBean)
    optional func didConnectToBean(bean: PTDBean)
}

class ToothbrushDiscovery: NSObject, PTDBeanManagerDelegate {
    static let sharedInstance = ToothbrushDiscovery()

    weak var delegate: ToothbrushDiscoveryDelegate?

    private var beanManager: PTDBeanManager
    private var beansSeen = Set<NSUUID>()
    private var scanning = false

    override init() {
        beanManager = PTDBeanManager()
        super.init()
        beanManager.delegate = self
    }

    func restartScan() {
        beansSeen.removeAll()

        var error : NSError?
        beanManager.disconnectFromAllBeans(&error)
        if let e = error {
            print("disconnectFromAllBeans: \(e)")
        }

        startScan()
    }

    func startScan() {
        scanning = true

        if (beanManager.state == .PoweredOn) {
            var error : NSError?
            beanManager.startScanningForBeans_error(&error)
            if let e = error {
                print("startScanningForBeans_error: \(e)")
            }
        }
    }

    func stopScan() {
        scanning = false

        var error : NSError?
        beanManager.stopScanningForBeans_error(&error)
        if let e = error {
            print("stopScanningForBeans_error: \(e)")
        }
    }

    func connectTo(bean: PTDBean) {
        var error : NSError?
        beanManager.connectToBean(bean, error: &error)
        if let e = error {
            print("connectToBean: \(e)")
        }
    }

    func beanManagerDidUpdateState(beanManager: PTDBeanManager!) {
        if (scanning && beanManager.state == .PoweredOn) {
            startScan()
        }
    }

    func beanManager(beanManager: PTDBeanManager!, didDiscoverBean bean: PTDBean!, error: NSError!) {
        if (bean.name == "IoToothbrush" && !beansSeen.contains(bean.identifier)) {
            beansSeen.insert(bean.identifier)
            delegate?.didDiscoverBean?(bean)
        }
    }
}
