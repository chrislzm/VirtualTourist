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
    
    func createNewPin(lat:Double, long:Double) -> Pin  {
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        // Create new pin
        let newPin = Pin(lat: lat,long: long,context: stack.context)
        
        // Save the pin
        stack.save()
        
        return newPin
    }
    
    func loadNewPhotoURLsFor(_ pin: Pin, completionHandler: @escaping (_ error: String?) -> Void) {
        
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        // If we have more pages we can get, set to the next page
        if (pin.photosPageNum < pin.photosTotalPages) {
            pin.photosPageNum += 1
        } else {
            // Otherwise set back to getting photos on page 1
            pin.photosPageNum = 1
        }

        // Get photo URLs from the network client class
        VTNetClient.sharedInstance().getPhotoURLs(lat: pin.latitude, long: pin.longitude, pageNumber: Int(pin.photosPageNum)) { (error,photoURLs,totalPages) in
            
            // If there was an error, pass the message to the controller
            guard error == nil else {
                completionHandler(error)
                return
            }
            
            // If there was no error message, we can safely unwrap the URL
            let photoURLs = photoURLs!
            
            // Update the total number of pages
            pin.photosTotalPages = Int16(totalPages!)
            
            if photoURLs.count > 0 {
                // Create model objects for each photo, and attach it to the pin
                for photoURL in photoURLs {
                    let newPhoto = Photo(url: photoURL, context: stack.context)
                    newPhoto.pin = pin
                    print("Added photoURL into Pin! \(photoURL)")
                }
                // Save the URLs
                stack.save()
                
                completionHandler(nil)
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
    
    func getFrcFor(_ pin: Pin) -> NSFetchedResultsController<NSFetchRequestResult> {
        
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        // Create Fetch Request
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        
        fr.sortDescriptors = [NSSortDescriptor(key: "url", ascending: false)]
        
        let pred = NSPredicate(format: "pin = %@", argumentArray: [pin])
        fr.predicate = pred
        
        // Create FetchedResultsController
        let frc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext:stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let e as NSError {
            print("Error while trying to perform a search: \n\(e)\n\(frc)")
        }

        // Return the FetchedResultsController
        return frc
    }
    
    func loadImagesFor(_ frc:NSFetchedResultsController<NSFetchRequestResult>) {
        
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        let photos = frc.fetchedObjects as! [Photo]
        
        stack.performBackgroundBatchOperation { (context) in
            for photo in photos {
                if photo.imageData == nil {
                    let imageURL = URL(string: photo.url!)
                    if let imageData = try? Data(contentsOf: imageURL!) {
                        print("Downloaded image successfully")
                        photo.imageData = imageData as NSData
                    } else {
                        print("Image does not exist at \(imageURL)")
                    }
                } else {
                    print("Image already in persistence")
                }
            }
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
