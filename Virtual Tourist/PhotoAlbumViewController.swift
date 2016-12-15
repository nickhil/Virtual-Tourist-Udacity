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

class PhotoAlbumViewController: UIViewController,MKMapViewDelegate,UICollectionViewDelegate,UICollectionViewDataSource,NSFetchedResultsControllerDelegate{
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var albumView: UICollectionView!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    var toRemoveData: NSData!
    var pinData: Pin!
    var imageData: [NSData] = []
    var limit = 30
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var imageRequest: NSFetchRequest<Image> = Image.fetchRequest()
    var pinRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
    var fRController: NSFetchedResultsController<Image>!
    
    override func viewWillAppear(_ animated: Bool) {
        let space:CGFloat = 3.0
        let dimension = (view.frame.size.width - (5 * space)) / 3.0
        flowLayout.minimumInteritemSpacing = space
        flowLayout.itemSize = CGSize(width:dimension,height:dimension)
        let coordinate = Constants.locationData.coordinates!
        let region = MKCoordinateRegionMake(coordinate, MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
        mapView.setRegion(region, animated: true)
        fRController = self.fetchResultsController()
        self.getImage()
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
                        Error.sharedInstance.showError(controller: self, title: "Error", message: "Cannot download images.")
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
        Constants.PinData = self.pinData
    }
    
    func refreshImages(completionHandler: @escaping(_ success: Bool,_ error: String) -> Void){
        setUIEnable(enable: false)
        let fetchImages = FetchImages()
        fetchImages.getImages{(success,error) in
        if error != ""{
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
            self.albumView.allowsSelection = true
            self.mapView.alpha = 1.0
         }
        }
            else
            {
                performUIUpdatesOnMain {
                    self.refreshButton.isEnabled = false
                    self.doneButton.isEnabled = false
                    self.albumView.allowsSelection = false
                    self.mapView.alpha = 0.6
                }
            }
    }
    
    func makeAnnotations(){
    let annotation = MKPointAnnotation()
        annotation.coordinate = Constants.locationData.coordinates!
        mapView.addAnnotation(annotation)
    }
    
    func getImage(){
        self.imageData = []
        guard let data = fRController.fetchedObjects else
        {
            print("Cannot move fetched objects")
            return
        }
        for items in data
        {
        self.imageData.append(items.image!)
        }
    }
    
    func fetchResultsController() -> NSFetchedResultsController<Image>
    {
        self.imageRequest.predicate = NSPredicate(format: "pin == %@", self.pinData)
        self.imageRequest.sortDescriptors = [NSSortDescriptor(key: "imageID", ascending: true)]
        let fRController = NSFetchedResultsController(fetchRequest: self.imageRequest, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: nil)
        fRController.delegate = self
        do
        {
            print("Fetch Performed")
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
        return limit
    }
    
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! photoAlbumViewCell
            cell.activityIndicator.startAnimating()
            cell.alpha = 0.5
        if indexPath.row < imageData.count
        {
            let data = imageData[indexPath.row]
            cell.image.image = UIImage(data: data as Data)
            cell.activityIndicator.stopAnimating()
            cell.alpha = 1.0
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
        if type == .update{
            print("data is getting updated")
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        limit = limit - 1
        toRemoveData = imageData[indexPath.row]
        imageData.remove(at: indexPath.row)
        collectionView.deleteItems(at: [indexPath])
        let image:[Image]
        do{
        image = try self.context.fetch(self.imageRequest)
            for items in image{
                if items.image == self.toRemoveData{
                context.delete(image[image.index(of: items)!])
                }
            }
        }
        catch{
        print("cannot find ImageData")
        }
        appDelegate.saveContext()
    }
}
