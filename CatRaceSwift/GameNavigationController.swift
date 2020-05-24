//
//  GameNavigationController.swift
//  CatRaceSwift
//
//  Created by Aaron Hicks on 5/16/20.
//  Copyright © 2020 Aaron Hicks. All rights reserved.
//

import Foundation
import UIKit

class GameNavigationController: UINavigationController{
    
    let PresentAuthenticationViewController = "present_authentication_view_controller"
    let RemoveAuthenticationViewController = "remove_authentication_view_controller"
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("GameNavigationController viewDidAppear activated")
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showAuthenticationViewController),
            name: NSNotification.Name(rawValue: PresentAuthenticationViewController),
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(removeAuthenticationViewController),
            name: NSNotification.Name(rawValue: RemoveAuthenticationViewController),
            object: nil)

        GameKitHelper.sharedGameKitHelper().authenticateLocalPlayer()
    }
    
    @objc func removeAuthenticationViewController() {
        let gameKitHelper = GameKitHelper.sharedGameKitHelper()
        print("removeAuthenticationViewController activated in GameNavigationController")
        gameKitHelper.authenticationViewController?.dismiss(animated: true)
    }
    
    @objc func showAuthenticationViewController() {
        let gameKitHelper = GameKitHelper.sharedGameKitHelper()

        if let authenticationViewController = gameKitHelper.authenticationViewController {
            topViewController?.present(
                authenticationViewController,
                animated: true)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
