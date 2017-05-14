//
//  VTViewController.swift
//  VirtualTourist
//
//  Implements shared methods used by the View Controllers to update the UI in order to prevent the user from modifying the data model while it's still being updated elsewhere. For example, images may still be downloading in the background context, so we don't want to allow the user to delete items, which would cause the context to save while it's in a possibly invalid state.
//
//  Created by Chris Leung on 5/13/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class VTViewController: UIViewController {
    
    var numActiveDownloads = 0
    var downloadsActive = false
    
    override func viewDidLoad() {
        NotificationCenter.default.addObserver(self, selector: #selector(VTViewController.willLoadFromNetwork(_:)), name: Notification.Name("willDownloadData"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VTViewController.didLoadFromNetwork(_:)), name: Notification.Name("didDownloadData"), object: nil)
    }
    
    func willLoadFromNetwork(_ notification:Notification) {
        numActiveDownloads += 1
        downloadsActive = true
    }
    
    func didLoadFromNetwork(_ notification:Notification) {
        numActiveDownloads -= 1
        
        if numActiveDownloads == 0 {
            downloadsActive = false
        }
    }
}
