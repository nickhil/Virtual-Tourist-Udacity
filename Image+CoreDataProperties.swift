//
//  Image+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Nikhil on 12/12/16.
//  Copyright © 2016 Nikhil. All rights reserved.
//

import Foundation
import CoreData
import 

extension Image {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Image> {
        return NSFetchRequest<Image>(entityName: "Image");
    }

    @NSManaged public var imageID: String?
    @NSManaged public var image: NSData?
    @NSManaged public var pin: Pin?

}
