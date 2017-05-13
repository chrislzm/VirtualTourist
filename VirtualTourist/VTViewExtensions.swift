//
//  VTViewExtensions.swift
//  VirtualTourist
//
//  Created by Chris Leung on 5/12/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

extension UIView {
    
    func fadeIn(duration: TimeInterval = 0.25, delay: TimeInterval = 0.0) {
        UIView.animate(withDuration: duration, animations: { self.alpha = 1.0 }, completion: nil)
    }
    
    func fadeOut(duration: TimeInterval = 0.25, delay: TimeInterval = 0.0) {
        UIView.animate(withDuration: duration, animations: { self.alpha = 0.0 }, completion: nil)
    }
    
}
