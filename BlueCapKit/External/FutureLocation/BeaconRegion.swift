//
//  BeaconRegion.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/14/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import CoreLocation

public class BeaconRegion : Region, BeaconRegionWrappable {
    
    // BeaconRegionWrappable
    public let beaconPromise  : StreamPromise<[Beacon]>
    
    public func peripheralDataWithMeasuredPower(measuredPower:Int?) -> [String:AnyObject] {
        let power : [NSObject:AnyObject]
        if let measuredPower = measuredPower {
            power = self.clBeaconRegion.peripheralDataWithMeasuredPower(NSNumber(integer:measuredPower)) as [NSObject:AnyObject]
        } else {
            power = self.clBeaconRegion.peripheralDataWithMeasuredPower(nil) as [NSObject:AnyObject]
        }
        return power.keys.reduce([String:AnyObject]()){(var result, key) in
            if let keyPower = power[key], key = key as? String {
                result[key] = keyPower
            }
            return result
        }
    }
    // BeaconRegionWrappable
    
    internal var _beacons       = [Beacon]()

    internal  let clBeaconRegion : CLBeaconRegion
    
    public var beacons : [Beacon] {
        self._beacons.sortInPlace() {(b1:Beacon, b2:Beacon) -> Bool in
            switch b1.discoveredAt.compare(b2.discoveredAt) {
            case .OrderedSame:
                return true
            case .OrderedDescending:
                return false
            case .OrderedAscending:
                return true
            }
        }
        return self._beacons
    }
    
    public var proximityUUID : NSUUID? {
        return self.clBeaconRegion.proximityUUID
    }
    
    public var major : Int? {
        if let _major = self.clBeaconRegion.major {
            return _major.integerValue
        } else {
            return nil
        }
    }
    
    public var minor : Int? {
        if let _minor = self.clBeaconRegion.minor {
            return _minor.integerValue
        } else {
            return nil
        }
    }
    
    public var notifyEntryStateOnDisplay : Bool {
        get {
            return self.clBeaconRegion.notifyEntryStateOnDisplay
        }
        set {
            self.clBeaconRegion.notifyEntryStateOnDisplay = newValue
        }
    }
    
    internal init(region:CLBeaconRegion, capacity:Int? = nil) {
        self.clBeaconRegion = region
        if let capacity = capacity {
            self.beaconPromise = StreamPromise<[Beacon]>(capacity:capacity)
        } else {
            self.beaconPromise = StreamPromise<[Beacon]>()
        }
        super.init(region:region, capacity:capacity)
        self.notifyEntryStateOnDisplay = true
    }
    
    public convenience init(proximityUUID:NSUUID, identifier:String, capacity:Int? = nil) {
        self.init(region:CLBeaconRegion(proximityUUID:proximityUUID, identifier:identifier), capacity:capacity)
    }

    public convenience init(proximityUUID:NSUUID, identifier:String, major:UInt16, capacity:Int? = nil) {
        let beaconMajor : CLBeaconMajorValue = major
        let beaconRegion = CLBeaconRegion(proximityUUID:proximityUUID, major:beaconMajor, identifier:identifier)
        self.init(region:beaconRegion, capacity:capacity)
    }

    public convenience init(proximityUUID:NSUUID, identifier:String, major:UInt16, minor:UInt16, capacity:Int? = nil) {
        let beaconMinor : CLBeaconMinorValue = minor
        let beaconMajor : CLBeaconMajorValue = major
        let beaconRegion = CLBeaconRegion(proximityUUID:proximityUUID, major:beaconMajor, minor:beaconMinor, identifier:identifier)
        self.init(region:beaconRegion, capacity:capacity)
    }
    
    public override class func isMonitoringAvailableForClass() -> Bool {
        return CLLocationManager.isMonitoringAvailableForClass(CLBeaconRegion)
    }
    
}
