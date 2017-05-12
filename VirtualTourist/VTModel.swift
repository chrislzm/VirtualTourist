//
//  VTModel.swift
//  VirtualTourist
//
//  Created by Chris Leung on 5/11/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class VTModel {
    
    func createNewPin(lat:Double, long:Double) {
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        // Create new pin
        let newPin = Pin(lat: lat,long: long,context: stack.context)
        
        // Get photos and add them in the background context
        
    }
}
