//
//  VTMapViewController.swift
//  VirtualTourist
//
//  Contains a MapView and allows user to create pins on the map and visit them. When editing mode is enabled, allows user to remove pins. Syncs any changes made on the UI with the model, using the VTModel class.
//
//  Created by Chris Leung on 5/10/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class VTMapViewController: UIViewController, MKMapViewDelegate {

    // MARK: Properties
    var selectedPin:Pin? // For temporarily storing pin when segueing
    var editingEnabled = false // When true, user can delete pins
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tapPinToDeleteLabel: UILabel!

    // MARK: Actions
    
    // Toggles editing mode on/off. Editing allows user to delete pins.
    @IBAction func editButtonPressed(_ sender: Any) {
        
        // Toggle off
        if editingEnabled {
            editingEnabled = false
            navigationItem.rightBarButtonItem?.title = "Edit"
            tapPinToDeleteLabel.fadeOut()
        } else {
            // Toggle on
            editingEnabled = true
            navigationItem.rightBarButtonItem?.title = "Finish"
            tapPinToDeleteLabel.fadeIn()
        }
    }

    // Handles adding a pin to the map (on long press)
    @IBAction func longPressOnMap(_ gestureRecognizer: UIGestureRecognizer) {

        if gestureRecognizer.state == .began {

            // Get the coordinates
            let touchPoint = gestureRecognizer.location(in: mapView)
            let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            // Add annotation to the map
            let annotation = VTMKPointAnnotation()
            annotation.coordinate = newCoordinates
            mapView.addAnnotation(annotation)
            
            // Create a new pin in the model
            let newPin = VTModel.sharedInstance().createNewPin(lat: newCoordinates.latitude, long: newCoordinates.longitude)
            
            // Save the pin into the annotation so we can use it later
            annotation.pin = newPin

            // Tell model to load photos for the newly created pin
            VTModel.sharedInstance().loadNewPhotosFor(newPin) { (error) in
                guard error == nil else {
                    DispatchQueue.main.async {
                        self.displayAlertWithOKButton("Error retrieving photos from Flickr", error)
                    }
                    return
                }
            }
        }
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // If we have any saved pins
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

    // MARK: UIMapViewDelegate Methods
    
    // Sets up annotation appearance on the MapView
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
    
    // Delegate method that respond to taps on annotations
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        // Deselect the annotation so we can select it again after, if we want
        mapView.deselectAnnotation(view.annotation, animated: true)

        // Extract the Pin object from the annotation
        let vtAnnotation = view.annotation as! VTMKPointAnnotation
        let pin = vtAnnotation.pin!

        if editingEnabled {
            
            // First clear saved selected pins, so that we can remove all possible references to this pin
            selectedPin = nil
            
            // Delete the pin from the model
            VTModel.sharedInstance().deletePin(pin)
            
            mapView.removeAnnotation(vtAnnotation)
            
        } else {
            // Save the pin for the segue
            selectedPin = pin
            
            // Display the pin's collection
            performSegue(withIdentifier: "showPinCollection", sender: self)
        }
    }
    
    // Send the pin to the Collection View
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller = segue.destination as! VTCollectionViewController
        controller.pin = selectedPin
    }
}

