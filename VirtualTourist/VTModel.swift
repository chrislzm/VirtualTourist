//
//  VTModel.swift
//  VirtualTourist
//
//  Created by Chris Leung on 5/11/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit
import CoreData

class VTModel {
    
    func createNewPin(lat:Double, long:Double, completionHandler: @escaping (_ error: String?) -> Void) {
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        // Create new pin
        let newPin = Pin(lat: lat,long: long,context: stack.context)
        
        // Save the pin
        stack.save()
        
        // Get photo URLs from the network client class
        VTNetClient.sharedInstance().getPhotoURLs(lat: lat, long: long, pageNumber: 1) { (error,photoURLs) in
            
            // If there was an error, pass the message to the controller
            guard error == nil else {
                completionHandler(error)
                return
            }

            // If there was no error message, we can safely unwrap
            let photoURLs = photoURLs!
            
            if photoURLs.count > 0 {
                // Create model objects for each photo, and attach it to the pin
                for photoURL in photoURLs {
                    let newPhoto = Photo(url: photoURL, context: stack.context)
                    newPhoto.pin = newPin
                    print("Added photoURL into Pin! \(photoURL)")
                }
                // Save the URLs
                stack.save()
            } else {
                // TODO: Remove debug statement, do we need to do something if there are no photos?
                print("No photos in this area")
            }
        }
    }
    
    func getSavedPins() -> [Pin]? {
        
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        
        // Execute the request
        var results:[Any]?
        do {
            results = try stack.context.fetch(fr)
        } catch {
            fatalError("Error retrieving saved pins")
        }
        
        if let savedPins = results as? [Pin] {
            return savedPins
        } else {
            return nil
        }
    }
    
    // MARK: Shared Instance
    
    class func sharedInstance() -> VTModel {
        struct Singleton {
            static var sharedInstance = VTModel()
        }
        return Singleton.sharedInstance
    }
}
