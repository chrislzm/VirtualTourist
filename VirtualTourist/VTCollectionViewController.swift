//
//  VTCollectionViewController.swift
//  VirtualTourist
//
//  Displays a MapView and Collection View for a given Pin's location and photos respectively. Allows the user to get a new set of photos for the pin and remove individual photos from the pin.
//
//  Created by Chris Leung on 5/11/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class VTCollectionViewController : VTViewController,UICollectionViewDelegate,UICollectionViewDataSource {
    
    // MARK: Properties
    var pin:Pin? // Stores the pin whose collection we are displaying
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>?
    var blockOperations = [BlockOperation]() // Stores operations for CollectView performBatchUpdates method
    var editingPhotos = false // True when "edit" mode has been enabled by user (and photos can be removed)
    let MAPVIEW_BBOX_SIZE:CLLocationDistance = 1000 // Size of the box displayed in the MapView (in meters)
    
    // MARK: Properties for flow layout
    private let cellsPerRow:CGFloat = 3.0
    private let cellsPerColumn:CGFloat = 6.0
    private let cellSpacing:CGFloat = 1.0
    private var cellWidthAndHeightForVerticalOrientation:CGFloat!
    private var cellWidthAndHeightForHorizontalOrientation:CGFloat!

    // MARK: Outlets, UI Objects
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var getNewPhotosButton: UIButton!
    @IBOutlet weak var tapPhotoToRemoveLabel: UILabel!
    @IBOutlet weak var noPhotosHereLabel: UILabel!
    var editPhotosButton:UIBarButtonItem?
    
    // MARK: Actions

    // Downloads a new set of photos into the collection
    @IBAction func getNewPhotosButtonPressed(_ sender: Any) {

        // 1. Notifies controllers to disable user's ability to update the model until downloads complete
        NotificationCenter.default.post(name: Notification.Name("willDownloadData"), object: nil)
        
        // 2. Remove our photos from the model
        let photosToRemove = fetchedResultsController?.fetchedObjects as! [Photo]
        VTModel.sharedInstance().deleteAll(photosToRemove)
        
        // 3. Load new set of photos for our pin into the model
        VTModel.sharedInstance().loadNewPhotosFor(pin!) { (newPhotos, error) in
            guard error == nil else {
                self.displayErrorAlert(error)
                return
            }
        
            // 4. Tell the model to download these photos' image data
            VTModel.sharedInstance().loadImagesFor(newPhotos) { (error) in
                guard error == nil else {
                    self.displayErrorAlert(error)
                    return
                }
                
                // 5. Now done loading photo images. Notify controllers immediately.
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name("didDownloadData"), object: nil)
                }
            }
        }
    }

    // MARK: View Manipulation Methods
    
    func hideTapToRemovePhotoLabel() {
        tapPhotoToRemoveLabel.fadeOut()
        tapPhotoToRemoveLabel.isHidden = true
    }
    
    func showTapToRemovePhotoLabel() {
        tapPhotoToRemoveLabel.fadeIn()
        tapPhotoToRemoveLabel.isHidden = false
    }
    
    func hideGetNewPhotosButton() {
        getNewPhotosButton.fadeOut()
        getNewPhotosButton.isHidden = true
    }
    func showGetNewPhotosButton() {
        getNewPhotosButton.fadeIn()
        getNewPhotosButton.isHidden = false
    }
    
    func disablePhotoButtons() {
        getNewPhotosButton.isEnabled = false
        editPhotosButton!.isEnabled = false
    }
    
    func enablePhotoButtons() {
        getNewPhotosButton.isEnabled = true
        editPhotosButton!.isEnabled = true
    }

    func toggleEditingPhotos() {
        if editingPhotos {
            editingPhotos = false
            editPhotosButton!.title = "Edit"
            hideTapToRemovePhotoLabel()
            showGetNewPhotosButton()
        } else {
            editingPhotos = true
            editPhotosButton!.title = "Finish"
            showTapToRemovePhotoLabel()
            hideGetNewPhotosButton()
        }
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add the pin as an annotation to the MapView
        let annotation = MKPointAnnotation()
        let coordinate = CLLocationCoordinate2D(latitude: pin!.latitude, longitude: pin!.longitude)
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        // Set our MapView to a 1km * 1km box around the geocoded location
        let viewRegion = MKCoordinateRegionMakeWithDistance(coordinate, MAPVIEW_BBOX_SIZE, MAPVIEW_BBOX_SIZE);
        mapView.setRegion(viewRegion, animated: true)

        // Setup and add the Edit button
        editPhotosButton = UIBarButtonItem(title: "Edit", style: UIBarButtonItemStyle.plain, target:self, action: #selector(VTCollectionViewController.toggleEditingPhotos))
        navigationItem.rightBarButtonItem = editPhotosButton

        // If there are photos available at this location
        if pin!.photosTotalPages > 0 {
            
            // Notifies controllers to disable user's ability to update the model until downloads complete
            NotificationCenter.default.post(name: Notification.Name("willDownloadData"), object: nil)

            // Get a Fetch Results Controller containing this pin's photos
            fetchedResultsController = VTModel.sharedInstance().createFrcFor(pin!)
            fetchedResultsController?.delegate = self
            
            // Load the photo image data
            if let photos = fetchedResultsController?.fetchedObjects as? [Photo] {
                VTModel.sharedInstance().loadImagesFor(photos) { (error) in
                    guard error == nil else {
                        self.displayErrorAlert(error)
                        return
                    }
                    
                    // Notify controllers we're done loading data and it's safe to modify the model
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name("didDownloadData"), object: nil)
                    }
                }
            }
        } else {
            // Display message that there are no photos here
            noPhotosHereLabel.isHidden = false
            
            // Disable buttons for getting new photos, editing
            disablePhotoButtons()
        }
    }
    
    // Sets up flow layout, accounting for screen rotation
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
    
    // On screen rotation, updates the flowLayout
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if size.height > size.width {
            setFlowLayoutForVerticalOrientation()
        } else {
            setFlowLayoutForHorizontalOrientation()
        }
    }
    
    // MARK: Notification Response Methods
    
    override func willLoadFromNetwork(_ notification: Notification) {
        DispatchQueue.main.async {
            super.willLoadFromNetwork(notification)
            self.disablePhotoButtons()
        }
    }
    
    override func didLoadFromNetwork(_ notification: Notification) {
        DispatchQueue.main.async {
            super.didLoadFromNetwork(notification)
            if !self.downloadsActive {
                self.enablePhotoButtons()
            }
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

        // Save the Photo object into the cell so we can easily delete it from Core Data if we need to
        cell.photo = photo
        
        // If the photo image data is available, display it
        if let binaryPhoto = photo.imageData {
            cell.photoImageView.image = UIImage(data: binaryPhoto as Data)
            cell.stopLoadingAnimation()
        } else {
            cell.photoImageView.image = nil
            cell.startLoadingAnimation()
        }
        
        return cell
    }
    
    // Handles user removing photos from the collection by tapping it. Note that user must tap Edit button first in order to enable editing mode.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:IndexPath) {

        if editingPhotos {
            let cell = collectionView.cellForItem(at: indexPath) as! VTCollectionViewCell
            let photo = cell.photo!

            // Check first that photo has completely finished loading
            if photo.imageData != nil {
                VTModel.sharedInstance().deletePhoto(photo)
            }
        }
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
}

// MARK: - NSFetchedResultsControllerDelegate methods that will be used to automatically update our collectionview

extension VTCollectionViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        blockOperations.removeAll(keepingCapacity: false)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let set = IndexSet(integer: sectionIndex)
        
        switch (type) {
        case .insert:
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertSections(set)
                    }
                })
            )
        case .delete:
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteSections(set)
                    }
                })
            )
        case .update:
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadSections(set)
                    }
                })
            )
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch(type) {
        case .insert:
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertItems(at: [newIndexPath!])
                    }
                })
            )
        case .delete:
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteItems(at: [indexPath!])
                    }
                })
            )
        case .update:
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadItems(at: [indexPath!])
                    }
                })
            )
        case .move:
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.moveItem(at: indexPath!, to: newIndexPath!)
                    }
                })
            )
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView!.performBatchUpdates({ () -> Void in
            for operation: BlockOperation in self.blockOperations {
                operation.start()
            }
        }, completion: { (finished) -> Void in
            self.blockOperations.removeAll(keepingCapacity: false)
        })
    }
}
