//
//  MyLocationManager.swift
//  WhereMyLunch
//
//  Created by Kuo Sabrina on 2017/3/9.
//  Copyright © 2017年 sabrinaApp. All rights reserved.
//

import UIKit
import CoreLocation

class MyLocationManager: NSObject, CLLocationManagerDelegate {
    
    let mLocationManager = CLLocationManager()
    var completionHandler: ((CLLocation) -> Void)?
    var isRequestingLocation = false
    
    override init(){
        super.init()
        mLocationManager.delegate = self
    }
    
    func requestLocation(completionHandler: @escaping (CLLocation) -> Void ){
        
        self.completionHandler = completionHandler
        isRequestingLocation = true
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            mLocationManager.requestWhenInUseAuthorization()
        }
        
        mLocationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        mLocationManager.requestLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if !isRequestingLocation {
            return
        }
        
        isRequestingLocation = false
        let location = locations.first!
        completionHandler?(location)
        
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        print("didFailWithError")
        
    }
    
}
