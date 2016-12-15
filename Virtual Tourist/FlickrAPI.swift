//
//  FlickrAPI.swift
//  Virtual Tourist
//
//  Created by Nikhil on 12/12/16.
//  Copyright © 2016 Nikhil. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class FetchImages{
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var ImageRequest: NSFetchRequest<Image> = Image.fetchRequest()
    var pinRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
    
    func getImages(completionHandler: @escaping(_ success: Bool,_ error: String?) -> Void)
    {
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback]
        let url = flickrURLFromParameters(methodParameters as [String : AnyObject])
        print(url)
        let session = URLSession.shared
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { (data, response, error) in
            guard error == nil else
            {
                print("Error with the request")
                completionHandler(false,error?.localizedDescription)
                return
            }
            
            guard let data = data else
            {
                print("Cannot get data")
                return completionHandler(false,error?.localizedDescription) //
            }

            let parsedResult: NSDictionary!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! NSDictionary
            } catch {
                print("Unable to parse the data")
                return
            }
          
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
               print("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            guard let totalPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                print("Cannot find key '\(Constants.FlickrResponseKeys.Pages)' in \(photosDictionary)")
                return
            }
            
            let pageLimit = min(totalPages, 40)
            print("total pages: \(totalPages)")
            print("page limit\(pageLimit)")
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            print("random page:\(randomPage)")
            self.getImageFromFlickr(methodParameters as [String : AnyObject], withPageNumber: randomPage,completionHandler: {(success, error) in
                completionHandler(success,error)
                })
        }
        task.resume()
    }
    
  
    private func getImageFromFlickr(_ methodParameters: [String: AnyObject], withPageNumber: Int, completionHandler: @escaping(_ success: Bool,_ error: String?)-> Void ) {
        
        var methodParametersWithPageNumber = methodParameters
        methodParametersWithPageNumber[Constants.FlickrParameterKeys.Page] = withPageNumber as AnyObject?
        
        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        
               let task = session.dataTask(with: request) { (data, response, error) in
            
            guard (error == nil) else {
                print("error while making request")
                completionHandler(false,error?.localizedDescription)
                return
            }
            
            guard let data = data else {
              print("No data returned")
            return
            }
            
                var parsedResult: NSDictionary!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! NSDictionary
            } catch {
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
                
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                print("Cannot find key '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
                guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                print("Cannot get key Phoyo")
                return
            }
            var count: Int
            count = 0
            for _ in photosArray
            {
               if count < 30
                {
                let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
                    
                    guard let imageUrlString = photoDictionary[Constants.FlickrResponseKeys.MediumURL] as? String else
                    {
                        print("Cannot get image url")
                        return
                    }
                
                    guard let imageID = photoDictionary[Constants.FlickrResponseKeys.ID] as? String else{
                        print("cannot get photo ID")
                       return completionHandler(false,"unable to get photo ID")
                    }
                    
                let imageURL = URL(string: imageUrlString)!
                if let imageData = NSData(contentsOf: imageURL)
                {
                Constants.Image.imageData.append(imageData)
                Constants.Image.imageId.append(imageID)
                let imageDescription = NSEntityDescription.entity(forEntityName: "Image", in: self.context)
                let image = Image(entity: imageDescription!, insertInto: self.context)
                image.image = imageData
                image.imageID = imageID
                Constants.Image.imageId2 = imageID
                    do{
                        try self.context.save()
                    }
                    catch{
                        print("Cannot save data")
                        return
                    }
                } else {
                    print("Cannot save data")
                   return completionHandler(false,"Image does not exist at \(imageURL)")
                   
                    }
                    count+=1
                    print("for loop executed \(count)")
                    self.getModelData()
            }
        }
            return completionHandler(true,"")
        }
        task.resume()
    }
    
     private func bboxString() -> String {
        if let latitude = Constants.locationData.latitude ,let longitude = Constants.locationData.longitude {
            let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
            let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
            let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
            let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
            return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        } else {
            return "0,0,0,0"
        }
    }
    
    
    private func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        return components.url!
    }

    
   func getModelData()
    {
        var imageData:[Image]!
        do{
            imageData = try self.context.fetch(self.ImageRequest)
            print("Images present in data base is \(imageData.count)")
        }
        catch{
            print("Cannot Retrieve Image Data")
            return
        }
        
        var pinData:[Pin] = []
        do{
            pinData = try self.context.fetch(self.pinRequest)
        }
        catch
        {
            print("Cannot Retrieve Pin data")
        }
        
        for items in pinData
        {
            if items.latitude == Constants.locationData.latitude  && items.longitude == Constants.locationData.longitude
            {
                do{
                    imageData = try self.context.fetch(self.ImageRequest)
                    print("total Images present in data base are \(imageData.count)")
                    
                }
                catch{
                    
                    print("unable to retrieve data")
                    return
                }
                
                for item in imageData
                {
                    if item.imageID == Constants.Image.imageId2
                    {
                        print("found the photo")
                        item.pin = pinData[pinData.index(of: items)!]
                        (UIApplication.shared.delegate as! AppDelegate).saveContext()
                    }
                }
                
            }
        }
        appDelegate.saveContext()
    }
}
