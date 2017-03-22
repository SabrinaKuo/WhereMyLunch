//
//  GoogleMapViewController.swift
//  WhereMyLunch
//
//  Created by Kuo Sabrina on 2017/3/18.
//  Copyright © 2017年 sabrinaApp. All rights reserved.
//

import UIKit
import GoogleMaps
import SwiftMessages
import AlamofireImage

class GoogleMapViewController: UIViewController {
    
    var destCoordinate:CLLocationCoordinate2D!
    var currentCoordinate:CLLocationCoordinate2D!
    var store: Store!
    var mapView:GMSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let camera = GMSCameraPosition.camera(withLatitude: destCoordinate.latitude,longitude: destCoordinate.longitude, zoom: 16)
        mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        mapView.isMyLocationEnabled = true
        
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2DMake(destCoordinate.latitude, destCoordinate.longitude)
        marker.map = mapView

        drawPath()
        showStoreDetail()
        self.view = mapView
    }
    
    func showStoreDetail(){
        
        SwiftMessages.defaultConfig.presentationStyle = .bottom
        var config = SwiftMessages.defaultConfig
        config.duration = .forever
        config.dimMode = .color(color: UIColor(white: 1, alpha: 0), interactive: true)
        
        let view = MessageView.viewFromNib(layout: .MessageView)
        view.backgroundColor = UIColor(white: 1, alpha: 0.8)
        view.titleLabel?.text = store.name
        view.bodyLabel?.text = store.address
        view.button?.setTitle("Call Now", for: .normal)
        view.titleLabel?.lineBreakMode = .byWordWrapping
        view.iconLabel?.isHidden = true
        view.button?.addTarget(self, action: #selector(callNow), for: .touchUpInside)
        
        let image = UIImage(data: NSData(contentsOf: store.photo)as! Data)
        let size = CGSize(width: 80, height: 80)
        let scledImage = image?.af_imageAspectScaled(toFit: size)
        DispatchQueue.main.async {
            view.iconImageView?.image = scledImage
            SwiftMessages.show(config: config, view: view)
        }
        
    }
    
    func callNow(sender: UIButton!){
        
        guard let number = URL(string: "telprompt://" + store.phone) else { return }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(number, options: [:], completionHandler: nil)
        }
    }
    
    
    func drawPath()
    {
        let origin = "\(currentCoordinate.latitude),\(currentCoordinate.longitude)"
        let destination = "\(destCoordinate.latitude),\(destCoordinate.longitude)"
        
        let url = URL(string: "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=walking")!
        let session = URLSession.shared
        
        let task = session.dataTask(with: url) { data, response, error in
            
            if let error = error{
                print("download api failed : error \(error)")
                return
            }
            
            let data = data!
            if let jsonObject = try?JSONSerialization.jsonObject(with: data, options: .mutableContainers), let result = jsonObject as? [String: Any] {
                
                if result.count == 0 {
                    return
                }
                
                let route = (result["routes"] as! [[String: Any]]).first!
                let overviewPolyline = route["overview_polyline"] as! [String: Any]
                let points = overviewPolyline["points"] as! String
                let path = GMSPath.init(fromEncodedPath: points)
                let polyline = GMSPolyline.init(path: path)
                polyline.strokeWidth = 5.0
                polyline.strokeColor = UIColor.blue
                polyline.map = self.mapView
            }
        }

        task.resume()

    }
    
    func showAlertDialog(message: String){
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

}
