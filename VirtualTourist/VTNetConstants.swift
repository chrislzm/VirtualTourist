//
//  VTNetConstants.swift
//  Virtual Tourist
//
//  Constants used in the Virtual Tourist network classes
//
//  Created by Chris Leung on 5/11/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

extension VTNetClient {
    
    // MARK: Constants
    struct Constants {
        
        // MARK: HTTP Constants
        static let ApiScheme = "https"
        static let ApiHost = "api.flickr.com"
        static let ApiPath = "/services/rest"

        // The number of photos per page downloaded from Flickr and thus also the max number of cells displayed in Pin collections
        static let PhotosPerPage = 21
        
        // Properties for bounding lat/long searches in Flickr
        static let SearchBBoxHalfWidth = 0.01 // 0.01 degrees is about 1KM
        static let SearchBBoxHalfHeight = 0.01 // 0.01 degrees is about 1KM
        static let SearchLatRange = (-90.0, 90.0)
        static let SearchLonRange = (-180.0, 180.0)
    }

    // MARK: Flickr Parameter Keys
    struct FlickrParameterKeys {
        static let Method = "method"
        static let ApiKey = "api_key"
        static let GalleryID = "gallery_id"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let SafeSearch = "safe_search"
        static let Text = "text"
        static let BoundingBox = "bbox"
        static let Page = "page"
        static let PerPage = "per_page"
    }
    
    
    // MARK: Flickr Parameter Values
    struct FlickrParameterValues {
        static let SearchMethod = "flickr.photos.search"
        static let ApiKey = "466ba576338b36037d63c2bd8286832e"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1" /* 1 means "yes" */
        static let GalleryPhotosMethod = "flickr.galleries.getPhotos"
        static let GalleryID = "5704-72157622566655097"
        static let SmallURL = "url_n"
        static let UseSafeSearch = "1"
        static let PhotosPerPage = Constants.PhotosPerPage
    }
    
    // MARK: Flickr Response Keys
    struct FlickrResponseKeys {
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let Title = "title"
        static let SmallURL = "url_n"
        static let Pages = "pages"
        static let Total = "total"
    }
    
    // MARK: Flickr Response Values
    struct FlickrResponseValues {
        static let OKStatus = "ok"
    }
}
