//
//  BeaconRegionsViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/16/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class BeaconRegionsViewController: UITableViewController {

    var stopScanBarButtonItem   : UIBarButtonItem!
    var startScanBarButtonItem  : UIBarButtonItem!
    var beaconsViewController   : BeaconsViewController?

    var isRanging               = false
    var isInRegion              = true
    
    struct MainStoryBoard {
        static let beaconRegionCell         = "BeaconRegionCell"
        static let beaconsSegue             = "Beacons"
        static let beaconRegionAddSegue     = "BeaconRegionAdd"
        static let beaconRegionEditSegue    = "BeaconRegionEdit"
    }
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
        self.stopScanBarButtonItem = UIBarButtonItem(barButtonSystemItem:.Stop, target:self, action:"toggleMonitoring:")
        self.startScanBarButtonItem = UIBarButtonItem(barButtonSystemItem:.Refresh, target:self, action:"toggleMonitoring:")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
        self.navigationItem.title = "Beacon Regions"
        self.setScanButton()
        self.beaconsViewController = nil
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
    }
    
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if segue.identifier == MainStoryBoard.beaconsSegue {
            let selectedIndexPath = sender as NSIndexPath
            self.beaconsViewController = segue.destinationViewController as? BeaconsViewController
            if let beaconsViewController = self.beaconsViewController {
                beaconsViewController.beaconRegion = BeaconStore.getBeaconNames()[selectedIndexPath.row]
            }
        } else if segue.identifier == MainStoryBoard.beaconRegionAddSegue {
        } else if segue.identifier == MainStoryBoard.beaconRegionEditSegue {
            let selectedIndexPath = sender as NSIndexPath
            let viewController = segue.destinationViewController as BeaconRegionViewController
            viewController.regionName = BeaconStore.getBeaconNames()[selectedIndexPath.row]
        }
    }
    
    func toggleMonitoring(sender:AnyObject) {
        if BeaconManager.sharedInstance().isRanging() {
            BeaconManager.sharedInstance().stopRangingAllBeacons()
            BeaconManager.sharedInstance().stopMonitoringAllRegions()
            self.setScanButton()
            self.isRanging = false
        } else {
            self.startMonitoring()
        }
        self.tableView.reloadData()
    }
    
    func setScanButton() {
        if BeaconManager.sharedInstance().isRanging() {
            self.navigationItem.setLeftBarButtonItem(self.stopScanBarButtonItem, animated:false)
        } else {
            self.navigationItem.setLeftBarButtonItem(self.startScanBarButtonItem, animated:false)
        }
    }
    
    func startMonitoring() {
        for (name, uuid) in BeaconStore.getBeacons() {
            let beacon = BeaconRegion(proximityUUID:uuid, identifier:name) {(beaconRegion) in
                beaconRegion.startMonitoringRegion = {
                    BeaconManager.sharedInstance().startRangingBeaconsInRegion(beaconRegion)
                    self.setScanButton()
                    Logger.debug("BeaconRegionsViewController#startMonitoring: started monitoring region \(name)")
                }
                beaconRegion.enterRegion = {
                    let beaconManager = BeaconManager.sharedInstance()
                    if !beaconManager.isRangingRegion(beaconRegion.identifier) {
                        beaconManager.startRangingBeaconsInRegion(beaconRegion)
                        self.updateDisplay()
                    }
                    self.isInRegion = true
                    Notify.withMessage("Entering region '\(name)'. Started ranging beacons.")
                }
                beaconRegion.exitRegion = {
                    BeaconManager.sharedInstance().stopRangingBeaconsInRegion(beaconRegion)
                    self.isRanging = false
                    self.isInRegion = false
                    self.updateDisplay()
                    Notify.withMessage("Exited region '\(name)'. Stoped ranging beacons.")
                }
                beaconRegion.errorMonitoringRegion = {(error) in
                    BeaconManager.sharedInstance().stopRangingBeaconsInRegion(beaconRegion)
                    self.updateDisplay()
                    self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
                }
                beaconRegion.rangedBeacons = {(beacons) in
                    for beacon in beacons {
                        Logger.debug("major:\(beacon.major), minor: \(beacon.minor), rssi: \(beacon.rssi)")
                    }
                    if !self.isRanging {
                        self.isRanging = true
                        self.updateDisplay()
                    }
                    if UIApplication.sharedApplication().applicationState == .Active {
                        if let beaconsViewController = self.beaconsViewController {
                            beaconsViewController.updateBeacons(beacons)
                        }
                    }
                }
            }
            BeaconManager.sharedInstance().startMonitoringForRegion(beacon)
        }
    }
    
    func updateDisplay() {
        if UIApplication.sharedApplication().applicationState == .Active {
            self.tableView.reloadData()
        }
    }

    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BeaconStore.getBeacons().count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryBoard.beaconRegionCell, forIndexPath: indexPath) as BeaconRegionCell
        let name = BeaconStore.getBeaconNames()[indexPath.row]
        let beaconRegions = BeaconStore.getBeacons()
        cell.rangingActivityIndicator.stopAnimating()
        if let beaconRegionUUID = beaconRegions[name] {
            cell.nameLabel.text = name
            cell.uuidLabel.text = beaconRegionUUID.UUIDString
        }
        if BeaconManager.sharedInstance().isRangingRegion(name) {
            if let region = BeaconManager.sharedInstance().beaconRegion(name) {
                if region.beacons.count == 0 {
                    cell.accessoryType = .None
                    cell.rangingActivityIndicator.startAnimating()
                } else {
                    cell.accessoryType = .DetailButton
                }
            } else {
                cell.accessoryType = .DisclosureIndicator
            }
        } else {
            if self.isInRegion {
                cell.accessoryType = .DisclosureIndicator
            } else {
                cell.accessoryType = .None
                cell.rangingActivityIndicator.startAnimating()
            }
        }
        return cell
    }
    
    override func tableView(tableView:UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView:UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath:NSIndexPath) {
        if editingStyle == .Delete {
            let name = BeaconStore.getBeaconNames()[indexPath.row]
            BeaconStore.removeBeacon(name)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:.Fade)
        }
    }
    
    // UITableViewDelegate
    override func tableView(tableView:UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        let name = BeaconStore.getBeaconNames()[indexPath.row]
        if BeaconManager.sharedInstance().isRangingRegion(name) {
            self.performSegueWithIdentifier(MainStoryBoard.beaconsSegue, sender:indexPath)
        } else {
            self.performSegueWithIdentifier(MainStoryBoard.beaconRegionEditSegue, sender:indexPath)
        }
    }
    
}
