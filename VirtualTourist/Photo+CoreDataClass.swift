//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Chris Leung on 5/11/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)
public class Photo: NSManagedObject {

    convenience init(url:String, context:NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: ent, insertInto: context)
            self.url = url
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
}
