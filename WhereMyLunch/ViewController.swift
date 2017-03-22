//
//  ViewController.swift
//  WhereMyLunch
//
//  Created by Kuo Sabrina on 2017/3/6.
//  Copyright © 2017年 sabrinaApp. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {
    
    let myLocationManager = MyLocationManager()
    
    var suggestStore: Store!
    
    var mStorePhoneNumber: String!
    
    var mDestCoordinate:CLLocationCoordinate2D!
    
    var mCurrentCoordinate:CLLocationCoordinate2D!
    
    @IBOutlet weak var mDistanceLabel: UILabel!
    
    @IBOutlet weak var mSlider: UISlider!
    
    @IBOutlet weak var mStoreNameLabel: UILabel!

    @IBOutlet weak var mRatingLabel: UILabel!

    @IBOutlet weak var mRestaurantDistanceLabel: UILabel!
    
    @IBOutlet weak var mTimeLabel: UILabel!
    
    @IBOutlet weak var mAddressLabel: UILabel!
    
    @IBOutlet weak var mMap: MKMapView!
    
    @IBOutlet weak var mImageView: UIImageView!
    
    @IBOutlet weak var mGoogleMapBtn: UIButton!
    
    @IBOutlet var mView: UIView!
    
    @IBOutlet weak var ratingtitle: UILabel!
    
    @IBOutlet weak var callbuttonUI: UIButton!
    
    @IBOutlet weak var mActInd: UIActivityIndicatorView!
    
    @IBAction func mCallButton(_ sender: Any) {
        // schema tel:// will immediate dial out, telprompt:// will ask before dial
        guard let number = URL(string: "telprompt://" + mStorePhoneNumber) else { return }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(number, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        
        let value = String(format: "%.1f", sender.value)
        mDistanceLabel.text = "\(value) km"
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showGoogleMap" {
            let googleMapVC = segue.destination as! GoogleMapViewController
            googleMapVC.destCoordinate = self.mDestCoordinate
            googleMapVC.currentCoordinate = self.mCurrentCoordinate
            
            googleMapVC.store = self.suggestStore
        }
        
    }
    
    @IBAction func searchTapped(_ sender: Any) {
    
        self.searchResultHidden(isHidden: true)
        mActInd.startAnimating()
        
        myLocationManager.requestLocation(completionHandler:{ location in
            
            self.mCurrentCoordinate = location.coordinate
            let distance = self.mSlider.value
            let session = URLSession.shared
            let url = URL(string: "https://food-locator-dot-hpd-io.appspot.com/v1/location_query?latitude=\(location.coordinate.latitude)&longitude=\(location.coordinate.longitude)&distance=\(distance)")!
            
            let task = session.dataTask(with: url, completionHandler: { (data, response, error) in
                
                if let error = error {
                    self.showAlertDialog(message: "API download error : \(error)")
                    return
                }
                
                let data = data!
                if let jsonObject = try?JSONSerialization.jsonObject(with: data, options: .mutableContainers), let results = jsonObject as? [[String:Any]]{
                    
                    if results.count == 0 {
                        return
                    }
                    
                    let queue = OperationQueue()
                    let operation = BlockOperation(block: {
                        
                        self.suggestStore = self.getRandomStore(Stores: results)
                        
                        self.mDestCoordinate = CLLocationCoordinate2D(latitude: self.suggestStore.latitude, longitude: self.suggestStore.longitude)
                        self.caculateMap(location: location, destCoordinate: self.mDestCoordinate)
                        self.downloadImage(photoUrl: self.suggestStore.photo)
                        
                        OperationQueue.main.addOperation({
                            self.mStoreNameLabel.text = self.suggestStore.name
                            self.mRatingLabel.text = String(self.suggestStore.rating!)
                            self.mAddressLabel.text = self.suggestStore.address
                            self.mStorePhoneNumber = self.suggestStore.phone
                        })
                    })
                    
                    operation.completionBlock = {
                        print("operation Main complete")
                        self.mActInd.stopAnimating()
                        self.searchResultHidden(isHidden: false)
                    }
                    
                    queue.addOperation(operation)

                }
            })
            
            task.resume()
        })
    }
    
    func caculateMap(location: CLLocation, destCoordinate: CLLocationCoordinate2D){
        
        let currentLocationPlacemark  = MKPlacemark(coordinate: location.coordinate, addressDictionary: nil)
        let currentMapItem = MKMapItem(placemark: currentLocationPlacemark)
        
        let destinationPlacemark = MKPlacemark(coordinate: destCoordinate, addressDictionary: nil)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        let request = MKDirectionsRequest()
        request.source = currentMapItem
        request.destination = destinationMapItem
        request.transportType = .walking
        
        let directions = MKDirections(request: request)
        
        directions.calculate(completionHandler: {response, error in
            if let error = error {
                self.showAlertDialog(message: "路徑規劃錯誤\(error)")
                return
            }
            self.mMap.removeOverlays(self.mMap.overlays)
            
            for route in (response?.routes)! {
                self.mMap.add(route.polyline, level:MKOverlayLevel.aboveRoads)
                
                let time = Int(route.expectedTravelTime/60)
                let distance = Int(route.distance)
                
                DispatchQueue.main.async {
                    self.mRestaurantDistanceLabel.text = "\(distance) 公尺"
                    self.mTimeLabel.text = "\(time) 分鐘"
                    self.mMap.isHidden = false
                }
                
                let point = MKPointAnnotation()
                point.coordinate = destCoordinate
                self.mMap.removeAnnotations(self.mMap.annotations)
                self.mMap.addAnnotation(point)
                
                // set restaurant location in map center
                let delta = (1/111)*0.5
                let span:MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
                let region = MKCoordinateRegion(center: destCoordinate, span: span)
                self.mMap.setRegion(region, animated: true)
                
                self.mMap.showsUserLocation = true
                
            }
        })
        
        self.mMap.delegate = self
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        // draw the track
        let polyLine = overlay
        let polyLineRenderer = MKPolylineRenderer(overlay: polyLine)
        polyLineRenderer.strokeColor = UIColor.blue
        polyLineRenderer.lineWidth = 2.0
        
        return polyLineRenderer
    }
    
    func downloadImage(photoUrl: URL){

        let image = UIImage(data: NSData(contentsOf: photoUrl)as! Data)
        DispatchQueue.main.async {
            self.mImageView.image = image
        }
    }
    
    func showAlertDialog(message: String){
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func searchResultHidden(isHidden: Bool){
        self.mStoreNameLabel.isHidden = isHidden
        self.mRatingLabel.isHidden = isHidden
        self.mAddressLabel.isHidden = isHidden
        self.mRestaurantDistanceLabel.isHidden = isHidden
        self.mTimeLabel.isHidden = isHidden
        self.mMap.isHidden = isHidden
        self.mImageView.isHidden = isHidden
        self.mGoogleMapBtn.isHidden = isHidden
        self.ratingtitle.isHidden = isHidden
        self.callbuttonUI.isHidden = isHidden
    }
    
    func getRandomStore(Stores: [[String: Any]]) -> Store {
        let index = Int(arc4random_uniform(UInt32(Stores.count)))
        let store = Store(data: Stores[index])
        
        return store
    }

}


