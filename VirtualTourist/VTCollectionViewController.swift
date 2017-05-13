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
    var selectedCellsToDelete = Set<VTCollectionViewCell>()
    let SELECTED_PHOTO_ALPHA:CGFloat = 0.3 // Indicates a photo is selected by the user
    var removePhotosButton:UIBarButtonItem?
    
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
    
    // MARK: Actions
    @IBAction func getNewPhotos(_ sender: Any) {

        // Disable until photos are done loading photos
        disablePhotoButtons()
        
        clearSelection()
        
        VTModel.sharedInstance().getNewPhotosFor(pin!, fetchedResultsController!) { (error) in
            DispatchQueue.main.async {
                guard error == nil else {
                    self.displayAlertWithOKButton("Error getting new photos", error!)
                    return
                }
                self.enablePhotoButtons()
            }
        }
    }

    func disablePhotoButtons() {
        getNewPhotosButton.isEnabled = false
        removePhotosButton!.isEnabled = false
        // Manually color the button (doesn't do this automatically when we disable the button)
        removePhotosButton!.setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.lightGray], for: .normal)
    }
    
    func enablePhotoButtons() {
        getNewPhotosButton.isEnabled = true
        removePhotosButton!.isEnabled = true
        removePhotosButton!.setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.red], for: .normal)
    }
    
    func clearSelection() {
        hideRemovePhotosButton()
        
        while !selectedCellsToDelete.isEmpty {
            let cell = selectedCellsToDelete.removeFirst()
            cell.photoImageView.alpha = 1.0
        }
    
    }
    
    func showRemovePhotosButton() {
        navigationItem.rightBarButtonItem = removePhotosButton
    }
    
    func hideRemovePhotosButton() {
        navigationItem.rightBarButtonItem = nil
    }
    
    func removePhotosButtonIsVisible() -> Bool {
        return navigationItem.rightBarButtonItem != nil
    }
    
    func removePhotos() {
        print("Delete photos here")
    }
    
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
        
        fetchedResultsController = VTModel.sharedInstance().getFrcFor(pin!)
        
        fetchedResultsController?.delegate = self
        
        // Setup the remove photos button
        removePhotosButton = UIBarButtonItem(title: "Remove Photos", style: UIBarButtonItemStyle.plain, target:self, action: #selector(VTCollectionViewController.removePhotos))
        removePhotosButton!.setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.red], for: .normal)

        // Disable get and remove photo buttons while we're loading photos
        disablePhotoButtons()
        
        VTModel.sharedInstance().loadImagesFor(fetchedResultsController!) { (error) in
            DispatchQueue.main.async {
                guard error == nil else {
                    self.displayAlertWithOKButton("Error getting new photos", error!)
                    return
                }
                self.enablePhotoButtons()
            }
        }
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

        // Save the photo in the cell so we can easily delete the photo later if we need to
        cell.photo = photo
        
        // If the photo image data is available
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

        // Get the cell
        let cell = collectionView.cellForItem(at: indexPath) as! VTCollectionViewCell

        // If the cell has finished loading (has a photo loaded into it)
        if cell.photoImageView.image != nil {
            
            // If it's been selected already, deselect it
            if selectedCellsToDelete.contains(cell) {
                selectedCellsToDelete.remove(cell)
                cell.photoImageView.alpha = 1
                // If no more items selected, remove the delete option
                if selectedCellsToDelete.isEmpty {
                    hideRemovePhotosButton()
                }
            } else {
                // Otherwise select the cell
                selectedCellsToDelete.insert(cell)
                cell.photoImageView.alpha = SELECTED_PHOTO_ALPHA
                
                // If the delete option is not available on the UI, make it visible
                if !removePhotosButtonIsVisible() {
                    showRemovePhotosButton()
                }
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
