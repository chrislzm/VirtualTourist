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
    var pinToShow:Pin?
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // If we have saved pins
        if let savedPins = VTModel.sharedInstance().getSavedPins() {
            
            // Add them to our MapView
            var annotations = [VTMKPointAnnotation]()
            
            for savedPin in savedPins {
                let annotation = VTMKPointAnnotation()
                let coordinate = CLLocationCoordinate2D(latitude: savedPin.latitude, longitude: savedPin.longitude)
                annotation.coordinate = coordinate
                annotation.pin = savedPin
                annotations.append(annotation)
            }
            mapView.addAnnotations(annotations)
        }
    }

    @IBAction func longPressOnMap(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let annotation = VTMKPointAnnotation()
            annotation.coordinate = newCoordinates
            mapView.addAnnotation(annotation)
            print(newCoordinates)
            VTModel.sharedInstance().createNewPin(lat: newCoordinates.latitude, long: newCoordinates.longitude) { (error,pin) in
                
                if let pin = pin {
                    annotation.pin = pin
                    print("Saved pin to the annotation")
                }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.displayAlertWithOKButton("Error downloading photos from Flickr",error)
                    }
                }
            }
        }
    }
    
    // Delegate method that respond to taps on pins
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // Get the pin stored in the annotation and save it
        let vtAnnotation = view.annotation as! VTMKPointAnnotation
        pinToShow = vtAnnotation.pin
        performSegue(withIdentifier: "showPinCollection", sender: self)
    }
    
    // Send the pin to the collection view
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller = segue.destination as! VTCollectionViewController
        controller.pin = pinToShow
    }
    
    // MARK: Helper methods
    
    // Displays an alert with a single OK button, takes a title and message as arguemnts
    func displayAlertWithOKButton(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

