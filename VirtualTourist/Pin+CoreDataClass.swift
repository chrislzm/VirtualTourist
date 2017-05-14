//
//  Pin+CoreDataClass.swift
//  VirtualTourist
//
//  Managed object that implements Pin object for Virtual Tourist. Provides convenience initializer for storing properties.
//
//  Created by Chris Leung on 5/11/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import Foundation
import CoreData

@objc(Pin)
public class Pin: NSManagedObject {

    // MARK: Initializer
    
    convenience init(lat: Double, long: Double, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: ent, insertInto: context)
            self.latitude = lat
            self.longitude = long
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
}
