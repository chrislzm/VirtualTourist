//
//  VTControllerExtensions.swift
//  VirtualTourist
//
//  Extensions related to the Virtual Tourist Controller classes
//
//  Created by Chris Leung on 5/11/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import MapKit

// Subclass the MapKit Point Annotation so that it can store the Pin object itself
class VTMKPointAnnotation : MKPointAnnotation {
    var pin:Pin?
}
