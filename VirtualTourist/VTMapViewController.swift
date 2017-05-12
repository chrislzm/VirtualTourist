//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Chris Leung on 5/10/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit
import MapKit

class VTMapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    // MARK: Helper methods
    
    // Displays an alert with a single OK button, takes a title and message as arguemnts
    func displayAlertWithOKButton(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

