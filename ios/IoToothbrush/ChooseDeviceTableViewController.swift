//
//  ChooseDeviceTableViewController.swift
//  IoToothbrush
//
//  Created by Matthew Lewinski on 5/4/16.
//  Copyright © 2016 Matthew Lewinski. All rights reserved.
//

import UIKit
import Bean_iOS_OSX_SDK

class ChooseDeviceTableViewController: UITableViewController, ToothbrushDiscoveryDelegate {
    var toothbrushDiscovery = ToothbrushDiscovery.sharedInstance
    var beans = [PTDBean]()

    
    @IBAction func refreshBeans(sender: AnyObject) {
        toothbrushDiscovery.restartScan()
    }
    
    @IBAction func cancel(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - View lifecycle

    override func viewWillAppear(animated: Bool) {
        toothbrushDiscovery.delegate = self
        toothbrushDiscovery.restartScan()
    }
    
    override func viewWillDisappear(animated: Bool) {
        toothbrushDiscovery.stopScan()
        toothbrushDiscovery.delegate = nil
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "selectDeviceSegue" {
            if let selectedRow = tableView.indexPathForSelectedRow {
                let settingsViewController = segue.destinationViewController as! SettingsViewController
                settingsViewController.device = beans[selectedRow.row]
            }
        }
    }

    // MARK: - Toothbrush discovery delegate

    func didDiscoverBean(bean: PTDBean) {
        beans.append(bean)
        tableView.reloadData()
        refreshControl?.endRefreshing()
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
