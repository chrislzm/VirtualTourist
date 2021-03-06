//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Managed object that implements Photo object for Virtual Tourist. Provides convenience initializer for storing properties.
//
//  Created by Chris Leung on 5/11/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)
public class Photo: NSManagedObject {

    convenience init(pin:Pin, url:String, context:NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: ent, insertInto: context)
            self.pin = pin
            self.url = url
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
}
