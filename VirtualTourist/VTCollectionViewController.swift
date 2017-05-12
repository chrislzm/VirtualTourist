//
//  VTCollectionViewController.swift
//  VirtualTourist
//
//  Created by Chris Leung on 5/11/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit
import MapKit

class VTCollectionViewController : UIViewController {
    
    // MARK: Properties
    var coordinate:CLLocationCoordinate2D?
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!

    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add the coordinate as an annotation to the map
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate!
        mapView.addAnnotation(annotation)
        
        // Set the MapView to a 1km * 1km box around the geocoded location
        let viewRegion = MKCoordinateRegionMakeWithDistance(coordinate!, 1000, 1000);
        mapView.setRegion(viewRegion, animated: true)
    }
}
