//
//  VTCollectionViewCell.swift
//  VirtualTourist
//
//  Cell for the Virtual Tourist Collection View class
//
//  Created by Chris Leung on 5/11/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class VTCollectionViewCell : UICollectionViewCell {
    
    // MARK: Properites
    var photo:Photo? // Stores a copy of the Photo object that it displays
    
    // MARK: Outlets
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    // MARK: Activity View Indicator methods
    
    func startLoadingAnimation() {
        activityView.startAnimating()
    }
    
    func stopLoadingAnimation() {
        activityView.stopAnimating()
    }
}
