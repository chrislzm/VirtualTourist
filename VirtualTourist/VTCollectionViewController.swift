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
    var blockOperations = [BlockOperation]()
    var editPhotosButton:UIBarButtonItem?
    var editingPhotos = false
    
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
    @IBOutlet weak var getNewPhotosButton: UIButton!
    @IBOutlet weak var tapPhotoToRemoveLabel: UILabel!
    @IBOutlet weak var noPhotosHereLabel: UILabel!
    
    // MARK: Actions
    @IBAction func getNewPhotos(_ sender: Any) {

        // Disable photo-related buttons until photos are done loading
        disablePhotoButtons()
        
        // 1. Remove our photos from the model
        let photosToRemove = fetchedResultsController?.fetchedObjects as! [Photo]
        VTModel.sharedInstance().deleteAll(photosToRemove)
        
        // 2. Load new page of photo URLs for our pin into the model
        VTModel.sharedInstance().loadNewPhotosFor(pin!) { (error) in
            
            // TODO: Abstract this method
            DispatchQueue.main.async {
                self.enablePhotoButtons()
                guard error == nil else {
                    self.displayAlertWithOKButton("Error getting new photos", error!)
                    return
                }
            }
            
            // 3. Get the new photos from the model
            let newPhotos = self.fetchedResultsController?.fetchedObjects as! [Photo]
            
            // 4. Tell the model to download the photo image data
            VTModel.sharedInstance().loadImagesFor(newPhotos) { (error) in
                DispatchQueue.main.async {
                    self.enablePhotoButtons()
                    guard error == nil else {
                        self.displayAlertWithOKButton("Error getting new photos", error!)
                        return
                    }
                }
            }
        }
    }

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
    
    func removePhotos() {
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

        // Add the pin as an annotation to the map
        let annotation = MKPointAnnotation()
        let coordinate = CLLocationCoordinate2D(latitude: pin!.latitude, longitude: pin!.longitude)
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        // Set our MapView to a 1km * 1km box around the geocoded location
        let viewRegion = MKCoordinateRegionMakeWithDistance(coordinate, 1000, 1000);
        mapView.setRegion(viewRegion, animated: true)

        // Setup the Edit button
        editPhotosButton = UIBarButtonItem(title: "Edit", style: UIBarButtonItemStyle.plain, target:self, action: #selector(VTCollectionViewController.removePhotos))
        navigationItem.rightBarButtonItem = editPhotosButton
        
        // Disable photo-related buttons until we're done loading everything
        disablePhotoButtons()

        // If there are photos available at this location
        if pin!.photosTotalPages > 0 {
            // Get a Fetch Results Controller containing this pin's photos
            fetchedResultsController = VTModel.sharedInstance().createFrcFor(pin!)
            fetchedResultsController?.delegate = self
            
            // Get the fetched photos, if any
            if let photos = fetchedResultsController?.fetchedObjects as? [Photo] {
                VTModel.sharedInstance().loadImagesFor(photos) { (error) in
                    DispatchQueue.main.async {
                        guard error == nil else {
                            self.displayAlertWithOKButton("Error getting new photos", error!)
                            return
                        }
                        self.enablePhotoButtons()
                    }
                }
            }
        } else {
            // Display message that there are no photos here
            noPhotosHereLabel.isHidden = false
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

        // Save the photo in the cell so we can easily delete the photo later if we need to
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
    
    // TODO: Abstract this duplicate code into a VTViewController
    // Displays an alert with a single OK button, takes a title and message as arguemnts
    func displayAlertWithOKButton(_ title: String?, _ message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}


// MARK: - CoreDataTableViewController: NSFetchedResultsControllerDelegate

extension VTCollectionViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("Collection view content will change")
        blockOperations.removeAll(keepingCapacity: false)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        print("Collection view section(s) - modifying")
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
        print("Collection view cell(s) - modifying - Type: \(type)")
        switch(type) {
        case .insert:
            print("Inserting")
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertItems(at: [newIndexPath!])
                    }
                })
            )
        case .delete:
            print("Deleting")
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteItems(at: [indexPath!])
                    }
                })
            )
        case .update:
            print("Updating")
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadItems(at: [indexPath!])
                    }
                })
            )
        case .move:
            print("Moving")
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
        print("Collection view content did change")
        collectionView!.performBatchUpdates({ () -> Void in
            for operation: BlockOperation in self.blockOperations {
                operation.start()
            }
        }, completion: { (finished) -> Void in
            self.blockOperations.removeAll(keepingCapacity: false)
        })
    }
}
