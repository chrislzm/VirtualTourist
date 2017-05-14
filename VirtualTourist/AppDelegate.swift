//
//  AppDelegate.swift
//  VirtualTourist
//
//  Stores the Core Data Stack.
//  No auto-saving here because we save whenever we need to within the app.
//
//  Created by Chris Leung on 5/10/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let stack = CoreDataStack(modelName: "Model")!
}
