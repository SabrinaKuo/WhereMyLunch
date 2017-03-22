//
//  Store.swift
//  WhereMyLunch
//
//  Created by sabrina.kuo on 2017/3/21.
//  Copyright © 2017年 sabrinaApp. All rights reserved.
//

import UIKit
import MapKit

class Store {
    let address: String!
    let latitude: Double!
    let longitude: Double!
    let name: String!
    let phone: String!
    let photo: URL!
    let rating: Float!

    init(data: [String: Any]) {
        address = data["address"] as! String
        latitude = data["latitude"] as! Double
        longitude = data["longitude"] as! Double
        name = data["name"] as! String
        phone = data["phone"] as! String
        photo = URL(string: data["photo"] as! String)
        rating = data["rating"] as! Float
    }
}
