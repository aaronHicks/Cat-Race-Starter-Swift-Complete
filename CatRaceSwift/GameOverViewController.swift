//
//  GameOverViewController.swift
//  CatRaceSwift
//
//  Created by Aaron Hicks on 5/16/20.
//  Copyright © 2020 Aaron Hicks. All rights reserved.
//

import Foundation
import UIKit

class GameOverViewController: UIViewController {
    var didWin:Bool?
    @IBOutlet private weak var outcomeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        outcomeLabel.text = didWin! ? "You Won!" : "You Loose!"
    }
    
    @IBAction func restartButtonPressed(_ sender: Any) {
        let window = view.window

        let gameNavController = self.storyboard?.instantiateViewController(withIdentifier: "GameNavigationController") as? GameNavigationController
        window?.rootViewController = gameNavController
    }
}
