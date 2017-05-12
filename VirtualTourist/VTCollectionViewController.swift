//
//  VTCollectionViewController.swift
//  VirtualTourist
//
//  Created by Chris Leung on 5/11/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class VTCollectionViewController : UIViewController,UICollectionViewDelegate,UICollectionViewDataSource {
    
    // MARK: Properties
    var pin:Pin?
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>?
    
    // MARK: Properties for flow layout
    private let cellsPerRow:CGFloat = 3.0
    private let cellsPerColumn:CGFloat = 5.0
    private let cellSpacing:CGFloat = 1.0
    private var cellWidthAndHeightForVerticalOrientation:CGFloat!
    private var cellWidthAndHeightForHorizontalOrientation:CGFloat!

    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add the coordinate as an annotation to the map
        let annotation = MKPointAnnotation()
        let coordinate = CLLocationCoordinate2D(latitude: pin!.latitude, longitude: pin!.longitude)
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        // Set the MapView to a 1km * 1km box around the geocoded location
        let viewRegion = MKCoordinateRegionMakeWithDistance(coordinate, 1000, 1000);
        mapView.setRegion(viewRegion, animated: true)
        
        // Create Fetch Request Controller for this Pin by calling the model with the coordinates, it should return FRC to us, then we should use that to display everything...
        
        fetchedResultsController = VTModel.sharedInstance().getFRCAndLoadImagesFor(pin!)
        
        fetchedResultsController?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Setup flowLayout
        flowLayout.minimumInteritemSpacing = cellSpacing
        flowLayout.minimumLineSpacing = cellSpacing
        
        if view.frame.size.height > view.frame.size.width {
            // If the height is greater, then the screen is oriented vertically
            cellWidthAndHeightForVerticalOrientation = (view.frame.size.width - (cellSpacing*(cellsPerRow-1))) / cellsPerRow
            cellWidthAndHeightForHorizontalOrientation = (view.frame.size.height - (cellSpacing*(cellsPerColumn-1))) / cellsPerColumn
            setFlowLayoutForVerticalOrientation()
        } else {
            // Else, the screen is oriented horizontally, and the "width" is actually the longer side
            cellWidthAndHeightForVerticalOrientation = (view.frame.size.height - (cellSpacing*(cellsPerRow-1))) / cellsPerRow
            cellWidthAndHeightForHorizontalOrientation = (view.frame.size.width - (cellSpacing*(cellsPerColumn-1))) / cellsPerColumn
            setFlowLayoutForHorizontalOrientation()
        }

    }
    
    // MARK: CollectionView Methods
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fc = fetchedResultsController {
            return fc.sections![section].numberOfObjects
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VTCollectionViewCell", for: indexPath) as! VTCollectionViewCell
        let photo = fetchedResultsController!.object(at: indexPath) as! Photo

        // If the photo image data is available
        if let binaryPhoto = photo.imageData {
            cell.photo.image = UIImage(data: binaryPhoto as Data)
        } else {
            // TODO: Show an loading animation
        }
        
        return cell
    }
    
    // MARK: Helper methods
    
    func setFlowLayoutForVerticalOrientation() {
        if let _ = flowLayout {
            flowLayout.itemSize = CGSize(width: cellWidthAndHeightForVerticalOrientation, height: cellWidthAndHeightForVerticalOrientation)
        }
    }
    
    func setFlowLayoutForHorizontalOrientation() {
        if let _ = flowLayout {
            flowLayout.itemSize = CGSize(width: cellWidthAndHeightForHorizontalOrientation, height: cellWidthAndHeightForHorizontalOrientation)
        }
    }
    
    // TODO: Abstract this duplicate code into a VTViewController
    // Displays an alert with a single OK button, takes a title and message as arguemnts
    func displayAlertWithOKButton(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}


// MARK: - CoreDataTableViewController: NSFetchedResultsControllerDelegate

extension VTCollectionViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("Collection view content will change")
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        print("Collection view section(s) - modifying")
        let set = IndexSet(integer: sectionIndex)
        
        switch (type) {
        case .insert:
            collectionView?.insertSections(set)
        case .delete:
            collectionView?.deleteSections(set)
        default:
            // irrelevant in our case
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        print("Collection view cell(s) - modifying")
        switch(type) {
        case .insert:
            collectionView?.insertItems(at: [newIndexPath!])
        case .delete:
            collectionView?.deleteItems(at: [indexPath!])
        case .update:
            collectionView?.reloadItems(at: [indexPath!])
        case .move:
            collectionView?.deleteItems(at: [indexPath!])
            collectionView?.insertItems(at: [newIndexPath!])
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("Collection view content did change")
    }
}
