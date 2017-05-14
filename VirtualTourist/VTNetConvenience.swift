//
//  VTNetConvenience.swift
//  Virtual Tourist
//
//  Virtual Tourist Net Client convenience methods - Utilizes core VT net client methods to exchange information with Flickr over the network. Used as an interface to the network by the VTModel class.
//
//  Created by Chris Leung on 4/27/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import Foundation
import UIKit

extension VTNetClient {
    
    // Returns a page of Flickr search results and total number of pages, given a latitude, longitude and page #
    func getPhotoURLs(lat:Double, long:Double, pageNumber:Int, completionHandler: @escaping (_ error: String?, _ photoURLs:[String]?, _ totalPages:Int?) -> Void) {
        
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
            
            /* 3. Check for error response */
            if let httpError = httpError {
                completionHandler(self.getUserFriendlyErrorMessageFor(httpError),nil,nil)
                return
            }
            
            /* 4. Verify we received a reponse dictionary */
            guard let response = results as? [String:AnyObject] else {
                completionHandler("Error creating session",nil,nil)
                return
            }
            
            /* 5: Verify Flickr status is ok */
            guard let stat = response[FlickrResponseKeys.Status] as? String, stat == FlickrResponseValues.OKStatus else {
                completionHandler("Flickr API returned an error. See error code and message in \(response)",nil,nil)
                return
            }
            
            /* 6: Verify "photos" key is in our result */
            guard let photosDictionary = response[FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                completionHandler("Cannot find keys '\(FlickrResponseKeys.Photos)' in \(response)",nil,nil)
                return
            }
            
            /* 7: Verify "pages" key is in photosDictionary */
            guard let pages = photosDictionary[FlickrResponseKeys.Pages] as? Int else {
                completionHandler("Cannot find key '\(FlickrResponseKeys.Pages)' in \(photosDictionary)",nil,nil)
                return
            }
            
            /* 8: Verify "photo" key is in photosDictionary */
            guard let photosArray = photosDictionary[FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                completionHandler("Cannot find key '\(FlickrResponseKeys.Photo)' in \(photosDictionary)",nil,nil)
                return
            }
            
            var photoURLs = [String]()
            
            for photo in photosArray {
                
                /* 9: Verify "small image URL" key is in photo dictionary */
                guard let photoURLString = photo[FlickrResponseKeys.SmallURL] as? String else {
                    completionHandler("Cannot find key '\(FlickrResponseKeys.SmallURL)' in \(photo)",nil,nil)
                    return
                }
                
                /* 10: Append the URL to photoURLs */
                photoURLs.append(photoURLString)
            }
            
            /* 9: Success! Return the photo URLs to the completion handler */
            completionHandler(nil,photoURLs,pages)
        }
    }

    // Handles NSErrors -- Turns them into user-friendly messages before sending them to the completion handler
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
    
    // Create a bounding box string given a latitude and longitude
    private func bboxString(_ latitude:Double,_ longitude:Double) -> String {
        // ensure bbox is bounded by minimum and maximums
        let minimumLon = max(longitude - Constants.SearchBBoxHalfWidth, Constants.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.SearchBBoxHalfHeight, Constants.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.SearchBBoxHalfWidth, Constants.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.SearchBBoxHalfHeight, Constants.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
}
