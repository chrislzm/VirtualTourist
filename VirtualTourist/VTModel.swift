//
//  VTModel.swift
//  VirtualTourist
//
//  Implements an interface to the model -- convenience methods used by the controller classes to access and manipulate the model.
//
//  Created by Chris Leung on 5/11/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit
import CoreData

class VTModel {


    // Creates new Pin object with given latitude and longitude, saves it to the model and returns it

    func createNewPin(lat:Double, long:Double) -> Pin  {

        let coreDataStack = getCoreDataStack()
        
        let newPin = Pin(lat: lat,long: long,context: coreDataStack.context)
        
        coreDataStack.save()
        
        return newPin
    }

    // Loads new Photo objects for a given Pin. Note that this loads photo URLs from Flickr, creates and saves Photo objects, but does not load their image data. That is done by calling the loadImagesFor(::) method.
    // Calls completionHandler when finished. error will be nil if there was no error, otherwise it will contain the error message.
    
    func loadNewPhotosFor(_ pin: Pin, completionHandler: @escaping (_ error: String?) -> Void) {
        
        let coreDataStack = getCoreDataStack()
        
        // If we have more pages of photos we can get from Flickr, increment to the next page
        if (pin.photosPageNum < pin.photosTotalPages) {
            pin.photosPageNum += 1
        } else {
            // Otherwise set back to page 1
            pin.photosPageNum = 1
        }

        // Get photo URLs from Flickr using our network client
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
            
            // If there are photos in this area
            if photoURLs.count > 0 {
                // Create model objects for each photo, and attach it to the pin
                for photoURL in photoURLs {
                    let newPhoto = Photo(url: photoURL, context: coreDataStack.context)
                    newPhoto.pin = pin
                }
                // Save the URLs
                coreDataStack.save()
                
                // Return with no error
                completionHandler(nil)
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
