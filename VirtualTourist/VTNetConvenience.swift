//
//  OTMConvenience.swift
//  OnTheMap
//
//  OTM Client convenience methods - Utilizes OTM core client methods to exchange information with Facebook, Udacity and Parse over the network. Acts as an interface for the ViewController methods to the model.
//
//  Created by Chris Leung on 4/27/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import Foundation
import UIKit

extension VTNetClient {
    
    // Returns a list of Flickr photo URLs from this latitude and longitude, returning page 1 of results unless otherwise specified
    func getPhotoURLs(lat:Double, long:Double, pageNumber:Int, completionHandler: @escaping (_ error: String?, _ photoURLs:[String]?) -> Void) {
        
        /* 1. Set up parameters for Flickr REST API Method Call */
        let methodParameters = [
            FlickrParameterKeys.Method: FlickrParameterValues.SearchMethod,
            FlickrParameterKeys.ApiKey: FlickrParameterValues.ApiKey,
            FlickrParameterKeys.BoundingBox: bboxString(lat,long),
            FlickrParameterKeys.SafeSearch: FlickrParameterValues.UseSafeSearch,
            FlickrParameterKeys.Extras: FlickrParameterValues.SmallURL,
            FlickrParameterKeys.Format: FlickrParameterValues.ResponseFormat,
            FlickrParameterKeys.NoJSONCallback: FlickrParameterValues.DisableJSONCallback,
            FlickrParameterKeys.PerPage: FlickrParameterValues.PhotosPerPage,
            FlickrParameterKeys.Page: pageNumber
        ] as [String : Any]
        
        /* 2. Run the method on the Flickr REST API */
        let _ = taskForHTTPMethod(apiParameters: methodParameters) { (results,httpError) in
            
            /* 2. Check for error response */
            if let httpError = httpError {
                completionHandler(self.getUserFriendlyErrorMessageFor(httpError),nil)
                return
            }
            
            /* 3. Verify we received a reponse dictionary */
            guard let response = results as? [String:AnyObject] else {
                completionHandler("Error creating session",nil)
                return
            }
            
            /* 4: Verify Flickr status is ok */
            guard let stat = response[FlickrResponseKeys.Status] as? String, stat == FlickrResponseValues.OKStatus else {
                completionHandler("Flickr API returned an error. See error code and message in \(response)",nil)
                return
            }
            
            /* 5: Verify "photos" key is in our result */
            guard let photosDictionary = response[FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                completionHandler("Cannot find keys '\(FlickrResponseKeys.Photos)' in \(response)",nil)
                return
            }
            
            /* 6: Verify "photo" key is in photosDictionary */
            guard let photosArray = photosDictionary[FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                completionHandler("Cannot find key '\(FlickrResponseKeys.Photo)' in \(photosDictionary)",nil)
                return
            }
            
            var photoURLs = [String]()
            
            for photo in photosArray {
                
                /* 7: Does our photo have a key for the small image URL? */
                guard let photoURLString = photo[FlickrResponseKeys.SmallURL] as? String else {
                    completionHandler("Cannot find key '\(FlickrResponseKeys.SmallURL)' in \(photo)",nil)
                    return
                }
                
                photoURLs.append(photoURLString)
            }
            
            /* 8: Success! Return the photo URLs to the completion handler */
            completionHandler(nil,photoURLs)
        }
    }

    // Handles NSErrors -- Turns them into user-friendly messages before sending them to the controller's completion handler
    private func getUserFriendlyErrorMessageFor(_ error:NSError) -> String {

        let errorString = error.userInfo[NSLocalizedDescriptionKey].debugDescription

        // TODO: Remove debug statement
        print(errorString)
        
        if errorString.contains("timed out") {
            return "Couldn't reach server (timed out)"
        } else if errorString.contains("Status code returned: 403"){
            return "API key invalid"
        } else if errorString.contains("network connection was lost"){
            return "The network connection was lost"
        } else if errorString.contains("Internet connection appears to be offline") {
            return "The Internet connection appears to be offline"
        } else {
            return "Please try again."
        }
    }
    
    // Substitute a key for the value that is contained within the string
    private func substituteKey(_ string: String, key: String, value: String) -> String? {
        if string.range(of: key) != nil {
            return string.replacingOccurrences(of: key, with: value)
        } else {
            return nil
        }
    }
    
    // Create a bounding box string
    private func bboxString(_ latitude:Double,_ longitude:Double) -> String {
        // ensure bbox is bounded by minimum and maximums
        let minimumLon = max(longitude - Constants.SearchBBoxHalfWidth, Constants.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.SearchBBoxHalfHeight, Constants.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.SearchBBoxHalfWidth, Constants.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.SearchBBoxHalfHeight, Constants.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
}
