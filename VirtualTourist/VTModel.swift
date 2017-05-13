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

        let coreDataStack = getCoreDataStack()
        
        // Create new pin
        let newPin = Pin(lat: lat,long: long,context: coreDataStack.context)
        
        // Save the pin
        coreDataStack.save()
        
        return newPin
    }
    
    func loadNewPhotosFor(_ pin: Pin, completionHandler: @escaping (_ error: String?) -> Void) {
        
        let coreDataStack = getCoreDataStack()
        
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
                    let newPhoto = Photo(url: photoURL, context: coreDataStack.context)
                    newPhoto.pin = pin
                    print("Added photoURL into Pin! \(photoURL)")
                }
                // Save the URLs
                coreDataStack.save()
                
                completionHandler(nil)
            } else {
                // TODO: Remove debug statement, do we need to do something if there are no photos?
                print("No photos in this area")
            }
        }
    }
    
    func getSavedPins() -> [Pin]? {
        
        let coreDataStack = getCoreDataStack()
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        
        // Execute the request
        var results:[Any]?
        do {
            results = try coreDataStack.context.fetch(fr)
        } catch {
            fatalError("Error retrieving saved pins")
        }
        
        if let savedPins = results as? [Pin] {
            return savedPins
        } else {
            return nil
        }
    }
    
    func createFrcFor(_ pin: Pin) -> NSFetchedResultsController<NSFetchRequestResult> {

        let coreDataStack = getCoreDataStack()
        
        // Create Fetch Request
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        
        fr.sortDescriptors = [NSSortDescriptor(key: "url", ascending: false)]
        
        let pred = NSPredicate(format: "pin = %@", argumentArray: [pin])
        fr.predicate = pred
        
        // Create FetchedResultsController
        let frc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext:coreDataStack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try frc.performFetch()
        } catch let e as NSError {
            print("Error while trying to perform a search: \n\(e)\n\(frc)")
        }

        // Return reference to the FetchedResultsController
        return frc
    }

    // Returns the Core Data Stack
    func getCoreDataStack() -> CoreDataStack {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.stack
    }
    
    // Delete all photos in given array of photos from Core Data Stack
    func deleteAll(_ photos:[Photo]) {
        let coreDataStack = getCoreDataStack()
        let context = coreDataStack.context
        for photo in photos {
            context.delete(photo)
        }
        coreDataStack.save()
    }
    
    // Deletes existing photos and loads new photos in a given a pin and its fetched results controller
    func getNewPhotosFor (_ pin:Pin, _ frc:NSFetchedResultsController<NSFetchRequestResult>, completionHandler: @escaping (_ error: String?) -> Void) {
        print("1. Deleting all photos")
        
        // 1. Delete all photos
        if let photos = frc.fetchedObjects as? [Photo] {
            let context = frc.managedObjectContext
            for photo in photos {
                context.delete(photo)
            }
            do {
                try context.save()
            } catch {
                fatalError("Unable to delete photos")
            }
        }
        
        print("2. Loading new photo URLs")
        // 2. Load new photo URLs
        VTModel.sharedInstance().loadNewPhotosFor(pin) { (error) in
            guard error == nil else {
                completionHandler("Error loading new photo URLs")
                return
            }
            
            print("3. Downloading new images")
            // 3. Load images
            VTModel.sharedInstance().loadImagesFor(frc, completionHandler: completionHandler)
        }
    }
    
    func deletePhoto(_ photo:Photo)
    {
        let coreDataStack = getCoreDataStack()
        let context = coreDataStack.context
        context.delete(photo)
        coreDataStack.save()
    }
    
    func deletePin(_ pin:Pin) {
        let coreDataStack = getCoreDataStack()
        let context = coreDataStack.context    
        context.delete(pin)
        coreDataStack.save()
    }
    
    func loadImagesFor(_ photos:[Photo], completionHandler: @escaping (_ error: String?) -> Void) {

        let coreDataStack = getCoreDataStack()
        
        coreDataStack.performBackgroundBatchOperation { (context) in
            
            var error:String? = nil
            
            for photo in photos {
                if photo.imageData == nil {
                    let imageURL = URL(string: photo.url!)
                    if let imageData = try? Data(contentsOf: imageURL!) {
                        photo.imageData = imageData as NSData
                    } else {
                        error = "Was unable to download one or more photos"
                    }
                }
            }
            completionHandler(error)
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
