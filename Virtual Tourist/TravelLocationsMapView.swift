//
//  TravelLocationsMapView.swift
//  Virtual Tourist
//
//  Created by Nikhil on 12/12/16.
//  Copyright © 2016 Nikhil. All rights reserved.
//

import Foundation
import MapKit
import CoreData
import UIKit


class TravelLocationsMapViewController: UIViewController,MKMapViewDelegate,NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet var longPress: UILongPressGestureRecognizer!
   // var lat : Double!
    //var lon : Double!
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var pinRequest: NSFetchRequest<Pin> = Pin.fetchRequest()

    override func viewDidLoad() {
        longPress.isEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let pinInfo:[Pin]!
        do{
            pinInfo = try self.context.fetch(self.pinRequest)
        }
        catch{
            print("Cannot retrieve data")
            return
        }
        if pinInfo.count > 0{
            for info in pinInfo{
                let lat = info.latitude
                let lon = info.longitude
                let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lon )
               // let coordinates = CLLocationCoordinate2D(latitude: info.latitude, longitude: info.longitude )
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinates
                map.removeAnnotation(annotation)
                map.addAnnotation(annotation)
                
            }
        }
        map.reloadInputViews()
    }
    
    @IBAction func longPressDropsPin(_ touch: AnyObject) {
        print("in longPressDropsPin")
        if longPress.state == .began{
            let fetchImages = FetchImages()
            let location = touch.location(in: map)
            let coordinates = map.convert(location, toCoordinateFrom: map)
            let anotation = MKPointAnnotation()
            anotation.coordinate = coordinates
            Constants.locationData.latitude = coordinates.latitude
            Constants.locationData.longitude = coordinates.longitude
            Constants.locationData.coordinates = coordinates
            map.addAnnotation(anotation)
            let pinDescription = NSEntityDescription.entity(forEntityName: "Pin", in: self.context)
            let pin = Pin(entity: pinDescription!, insertInto: self.context)
            pin.latitude = coordinates.latitude
            pin.longitude = coordinates.longitude
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            
           fetchImages.getImages{(success, error) in
           // if error != nil{
            if error != nil
            {
                    performUIUpdatesOnMain {
                    Error.sharedInstance.showError(controller: self, title: "Network Problem_nil", message: "Cannot Download the images")
                }
            }
                do{
                    try self.context.save()
                }
                catch{
                    print("cannot save")
                    return
                }
                self.longPress.isEnabled = true
            self.getPinInfo()
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
                    Constants.locationData.latitude = view.annotation?.coordinate.latitude
                    Constants.locationData.longitude = view.annotation?.coordinate.longitude
                    Constants.locationData.coordinates = view.annotation?.coordinate
                let pinInfo = getPinInfo()
                for info in pinInfo
                {
                    if info.latitude == Constants.locationData.latitude && info.longitude == Constants.locationData.longitude{
                        Constants.Image.index = pinInfo.index(of: info)
                    }
                    
                }
            let finalInfo = pinInfo[Constants.Image.index]
            print("expected lat lon \(Constants.locationData.latitude) \(Constants.locationData.longitude). obtained lat lon \(finalInfo.latitude) \(finalInfo.longitude)")
            let controller = self.storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
            controller.pinData = finalInfo
            present(controller, animated: true, completion: nil)
        }
        
        func getPinInfo() -> [Pin]
        {
            let pinInfo:[Pin]!
            do{
                pinInfo = try self.context.fetch(self.pinRequest)
            }
            catch{
                print("Cannot retrieve data")
                return []
            }
            for info in pinInfo
            {
                let lat = info.latitude
                let long = info.longitude
                let count = info.image?.count
                print("lat: \(lat) long: \(long) total photos: \(count)" )
                
            }
            return pinInfo
        }
}
