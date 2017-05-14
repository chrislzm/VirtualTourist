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

class VTMapViewController: VTViewController, MKMapViewDelegate {

    // MARK: Properties
    var selectedPin:Pin? // For temporarily storing pin when segueing
    var editingEnabled = false // When true, user can delete pins
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tapPinToDeleteLabel: UILabel!
    @IBOutlet weak var editButton: UIBarButtonItem!

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

        if gestureRecognizer.state == .began && !editingEnabled && !downloadsActive {

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

            // Notify controllers to disable user's ability to update the model until downloads complete
            NotificationCenter.default.post(name: Notification.Name("willDownloadData"), object: nil)

            // Tell model to load photos for the newly created pin
            VTModel.sharedInstance().loadNewPhotosFor(newPin) { (newPhotos, error) in
                guard error == nil else {
                    self.displayErrorAlert(error)
                    return
                }
                
                // Tell the model to start downloading these photos' image data
                VTModel.sharedInstance().loadImagesFor(newPhotos!) { (error) in
                    guard error == nil else {
                        self.displayErrorAlert(error)
                        return
                    }
                    
                    // Done loading photo images. Notify controllers immediately.
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name("didDownloadData"), object: nil)
                    }
                }
            }
        }
    }
    
    // MARK: UI Manipulation Methods
    
    // These two methods prevent user from modifying the context while it's still being changed
    
    override func willLoadFromNetwork(_ notification: Notification) {
        DispatchQueue.main.async {
            super.willLoadFromNetwork(notification)
            self.editButton.isEnabled = false
        }
    }
    
    override func didLoadFromNetwork(_ notification: Notification) {
        DispatchQueue.main.async {
            super.didLoadFromNetwork(notification)
            if !self.downloadsActive {
                self.editButton.isEnabled = true
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

