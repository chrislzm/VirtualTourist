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
    var selectedPin:Pin?
    var editingEnabled = false
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tapPinToDeleteLabel: UILabel!

    @IBAction func editButtonPressed(_ sender: Any) {
        if editingEnabled {
            tapPinToDeleteLabel.fadeOut()
            editingEnabled = false
            navigationItem.rightBarButtonItem?.title = "Edit"
        } else {
            tapPinToDeleteLabel.fadeIn()
            editingEnabled = true
            navigationItem.rightBarButtonItem?.title = "Finish"
        }
    }
    
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
            let newPin = VTModel.sharedInstance().createNewPin(lat: newCoordinates.latitude, long: newCoordinates.longitude)
            annotation.pin = newPin
            
            VTModel.sharedInstance().loadNewPhotosFor(newPin) { (error) in
                if let error = error {
                    DispatchQueue.main.async {
                        self.displayAlertWithOKButton("Error downloading photos URLs from Flickr",error)
                    }
                }
            }
        }
    }
    
    // Setup annotation (pin) appearance and behavior on the MapView
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = .red
            pinView?.animatesDrop = true
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    
    // Delegate method that respond to taps on pins
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        // Deselect the annotation so we can select it again after, if we want
        mapView.deselectAnnotation(view.annotation, animated: true)

        // Extract the Pin object from the annotation
        let vtAnnotation = view.annotation as! VTMKPointAnnotation
        let pin = vtAnnotation.pin!

        if editingEnabled {
            // First clear saved selected pins, so that we can remove all possible references to this pin
            selectedPin = nil
            
            VTModel.sharedInstance().deletePin(pin)
            mapView.removeAnnotation(vtAnnotation)
        } else {
            // Save the pin for the segue
            selectedPin = pin
            
            // Display the pin's collection
            performSegue(withIdentifier: "showPinCollection", sender: self)
        }
    }
    
    // Send the pin to the collection view
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller = segue.destination as! VTCollectionViewController
        controller.pin = selectedPin
    }
}

