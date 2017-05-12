//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Chris Leung on 5/10/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class VTMapViewController: UIViewController, MKMapViewDelegate {

    // MARK: Properties
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>?
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // If we have saved pins
        if let savedPins = VTModel.sharedInstance().getSavedPins() {
            
            // Add them to our MapView
            var annotations = [MKPointAnnotation]()
            
            for savedPin in savedPins {
                let annotation = MKPointAnnotation()
                let coordinate = CLLocationCoordinate2D(latitude: savedPin.latitude, longitude: savedPin.longitude)
                annotation.coordinate = coordinate
                annotations.append(annotation)
            }
            mapView.addAnnotations(annotations)
        }
    }

    @IBAction func longPressOnMap(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            mapView.addAnnotation(annotation)
            print(newCoordinates)
            VTModel.sharedInstance().createNewPin(lat: newCoordinates.latitude, long: newCoordinates.longitude) { (error) in
                if let error = error {
                    DispatchQueue.main.async {
                        self.displayAlertWithOKButton("Error creating pin",error)
                    }
                }
            }
        }
    }
    
    // Delegate method that respond to taps. Opens the system browser to the URL specified in the annotationViews subtitle property.
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print ("User tapped on annotation view")
    }
    
    // MARK: Helper methods
    
    // Displays an alert with a single OK button, takes a title and message as arguemnts
    func displayAlertWithOKButton(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

