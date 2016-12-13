//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Nikhil on 13/12/16.
//  Copyright © 2016 Nikhil. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController,MKMapViewDelegate,UICollectionViewDelegate,NSFetchedResultsControllerDelegate{
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var albumView: UICollectionView!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    
    var pinData: Pin!
    var imageData: [NSData] = []
        var itemCount = 20
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var imageRequest: NSFetchRequest<Image> = Image.fetchRequest()
    var pinRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
    var fRController: NSFetchedResultsController<Image>!
    
    override func viewWillAppear(_ animated: Bool) {
        self.viewWillAppear(true)
        let space:CGFloat = 1.0
        let dimension = (albumView.frame.size.width - (2*space))/3.0
        flowLayout.minimumLineSpacing = space
        flowLayout.minimumInteritemSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        
        let coordinate = Constants.locationData.coordinates!
        let region = MKCoordinateRegionMake(coordinate, MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
        mapView.setRegion(region, animated: true)
        fRController = self.fetchResultsController()
        self.fetchImage()
        makeAnnotations()
        if pinData.image?.count == nil || pinData.image?.count == 0
        {
            setUIEnable(enable: false)
            refreshImages(completionHandler: { (success, error) in
                
                if success{
                    self.setUIEnable(enable: true)
                }
                else{
                    performUIUpdatesOnMain {
                        Error.sharedInstance.showError(controller: self, title: "Internet Connection Problem", message: "Cannot download images, please check internet connection")
                        self.setUIEnable(enable: true)
                    }
                }
            })
        }
        print("the images loaded are: \(self.imageData.count)")
    }
    
    @IBAction func doneButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
        
    @IBAction func refreshButtonPressed(_ sender: AnyObject) {
        self.setUIEnable(enable: false)
        self.deleteCurrentAlbum()
        refreshImages{(success,error) in
        if success{
            self.setUIEnable(enable: true)
        }
        else{
            performUIUpdatesOnMain {
                Error.sharedInstance.showError(controller: self, title: "Network Problem_refresh", message: "Cannot Download Images")
            }
        self.setUIEnable(enable: true)
        }
        }
    }
    
    func deleteCurrentAlbum(){
        for images in fRController.fetchedObjects!{
            context.delete(images)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
        }
    
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        albumView.reloadData()
        Constants.loadedData = self.pinData
    }
    
    func refreshImages(completionHandler: @escaping(_ success: Bool,_ error: String) -> Void){
        setUIEnable(enable: false)
        let fetchImages = FetchImages()
    
        fetchImages.getImages{(success,error) in
        
        if error != nil{
                return completionHandler(success,error!)
            }
        else
        {
            return completionHandler(success,error!)
            }
        }
    }
    
    
    func setUIEnable(enable: Bool){
        if enable{
        performUIUpdatesOnMain {
            self.refreshButton.isEnabled = true
            self.doneButton.isEnabled = true
         }
        }
            else
            {
                performUIUpdatesOnMain {
                    self.refreshButton.isEnabled = false
                    self.doneButton.isEnabled = false
                }
            }
        
    }
    
    func makeAnnotations(){
    
    let annotation = MKPointAnnotation()
        annotation.coordinate = Constants.locationData.coordinates!
        mapView.addAnnotation(annotation)
    }
    
    func fetchImage(){
        self.imageData = []
        
        guard let data = fRController.fetchedObjects else
        {
            print("Cannot move fetched objects")
            return
        }
        print("data count in collectionView is\(data.count)")
        for items in data
        {
        self.imageData.append(items.image!)
        }
        print("In collection view:\(data.count) . Images fetched: \(imageData.count)")
        
    }
    
    
    
    func fetchResultsController() -> NSFetchedResultsController<Image>
    {
        self.imageRequest.predicate = NSPredicate(format: "pin == %@", self.pinData)
        self.imageRequest.sortDescriptors = [NSSortDescriptor(key: "imageID", ascending: true)]
        let fRController = NSFetchedResultsController(fetchRequest: self.imageRequest, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: nil)
        fRController.delegate = self
        do
        {
            print("fetch executed")
            try fRController.performFetch()
        }
        catch
        {
            print("Cannot fetch data by Controller")
            return fRController
        }
        return fRController
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("The total fetched object is \(self.fRController.fetchedObjects?.count)")
        return itemCount
    }
    
    private func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
       
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! photoAlbumViewCell
        if indexPath.row < imageData.count
        {
            guard let data = imageData[indexPath.row] as? Data else
            {
                return cell
            }
            cell.image.image = UIImage(data: data as Data)
            return cell
        }
        else
        {
            return cell
        }
        
    }

        
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if type  == .delete{
            print("Deleted !! Count:\(imageData.count)")
            albumView.reloadData()
        }
        if type == .insert{
            self.imageData = []
            print("data is getting inserted")
            let objectData = fRController.fetchedObjects
            print("fetched object after inserting is \(objectData?.count)")
            for data in objectData! {
            self.imageData.append(data.image!)
            }
            self.albumView.reloadData()
            print("count after inserting:\(imageData.count)")
        }
        
    }
    
    
}
