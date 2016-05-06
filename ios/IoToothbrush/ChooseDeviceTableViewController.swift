//
//  ChooseDeviceTableViewController.swift
//  IoToothbrush
//
//  Created by Matthew Lewinski on 5/4/16.
//  Copyright © 2016 Matthew Lewinski. All rights reserved.
//

import UIKit
import Bean_iOS_OSX_SDK

class ChooseDeviceTableViewController: UITableViewController, PTDBeanManagerDelegate {

    var beanManager: PTDBeanManager?
    var beans = [PTDBean]()
    var beansSeen = Set<NSUUID>()

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        beanManager = appDelegate.beanManager
        beanManager!.delegate = self
        beanManager!.disconnectFromAllBeans(nil)
    }

    override func viewWillAppear(animated: Bool) {
        startScan()
    }
    
    override func viewWillDisappear(animated: Bool) {
        stopScan()
    }

    @IBAction func refreshBeans(sender: AnyObject) {
        startScan()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "selectDeviceSegue" {
            if let selectedRow = tableView.indexPathForSelectedRow {
                let bean = beans[selectedRow.row]
                var error : NSError?
                beanManager?.connectToBean(bean, error: &error)
                
                let settingsViewController = segue.destinationViewController as! SettingsViewController
                settingsViewController.selectedBean = bean
            }
        }
    }

    // MARK: - Bluetooth

    func startScan() {
        beans.removeAll()
        beansSeen.removeAll()
        tableView.reloadData()

        var error : NSError?
        beanManager!.startScanningForBeans_error(&error)
        if let e = error {
            print(e)
        }
    }

    func stopScan() {
        var error : NSError?
        beanManager!.stopScanningForBeans_error(&error)
        if let e = error {
            print(e)
        }
    }

    // MARK: - Bean manager delegate

    func beanManager(beanManager: PTDBeanManager!, didDiscoverBean bean: PTDBean!, error: NSError!) {
        if (bean.name == "IoToothbrush" && !beansSeen.contains(bean.identifier)) {
            beansSeen.insert(bean.identifier)
            beans.append(bean)
            tableView.reloadData()
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return beans.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("deviceCell", forIndexPath: indexPath) as! ChooseDeviceTableViewCell
        
        let bean = beans[indexPath.row]
        cell.nameLabel!.text = bean.name
        cell.uuidLabel!.text = bean.identifier.UUIDString
        cell.rssiLabel!.text = "\(bean.RSSI)"

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("selectDeviceSegue", sender: self)
    }
}
