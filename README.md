"Virtual Tourist" Flickr Explorer
=================================

Programmed by Chris Leung


Installation
------------
1. Update Flickr API key (VTNetConstants.swift: VTNetClient.Constants.ApiKey)
2. Compile and run.(Developed and tested with XCode 8+ and iOS 10+)

Optional Settings
-----------------
1. Photos per page - Default is 18. Edit this value in VTNetConstants.swift: VTNetClient.Constants.PhotosPerPage
2. Latitude/Longitude bounding box for photo search - Default is approximately 2km*2km or 0.02 degrees * 0.02 degrees. Edit these two values in VTNetConstants.swift: VTNetClient.Constants.SearchBBoxHalfWidth and SearchBBoxHalfHeight

How to Use
----------
Requires Internet connection.  

* Press and hold to drop a pin on the map
* Tap on the tip to view photos at that location
* Tap "Edit" to delete pins or photos from the map or pin respectively
* In a Pin collection view, tap "Get New Photos" to download the next page of Flickr results for photos in this area
* Note: Edit buttons are disabled when downloading data in order to prevent invalid states such as when deleting a pin or photos while its the photo images are still downloading. For a solution to this, see developer notes below.

Developer Notes
---------------
* The terms "Collection" and "Pin" may be used interchangeably. "Pin" likely refers to map annotations, while "collection" likely refers to the photos and/or underlying "Photo" model associated with a "Pin".
* If the PhotosPerPage constant is changed, you may need to the app's clear persistent data before running the application again
* To allow the user to edit collections/delete photos while they are downloading in the background, a solution using notifications has been implemented. The VTViewController class keeps track of active downloads so we know when we can enable/disable the UI elements, and this should be expanded to include context saves.

Questions & Issues
------------------
* Create new issues on [GitHub repo](https://github.com/chrislzm/VirtualTourist) for any bugs found.
* Contact [Chris Leung](https://github.com/chrislzm)
