//
//  GameViewController.swift
//  CatRaceSwift
//
//  Created by Aaron Hicks on 5/15/20.
//  Copyright © 2020 Aaron Hicks. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    let LocalPlayerIsAuthenticated = "local_player_authenticated"
    var _networkingEngine:MultiplayerNetworking?
    
    override func viewDidAppear(_ animated: Bool) {
        print("GameViewController viewDidAppear activated")
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(playerAuthenticated), name: NSNotification.Name(rawValue: LocalPlayerIsAuthenticated), object: nil)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let skView = view as? SKView
        skView?.showsFPS = true
        skView?.showsNodeCount = true
        
        let scene = GameScene(size: (skView?.bounds.size)!)
        scene.scaleMode = SKSceneScaleMode.aspectFill
        
        scene.gameEndedBlock = {

        }
        
        scene.gameOverBlock = { didWin in
            let gameOverViewController = self.storyboard?.instantiateViewController(withIdentifier: "GameOverViewController") as? GameOverViewController
            gameOverViewController?.didWin = didWin
            if let gameOverViewController = gameOverViewController {
                self.navigationController?.pushViewController(gameOverViewController, animated: true)
            }
        }
        
        skView?.presentScene(scene)
    }
    
    @objc func playerAuthenticated() {
        print("playerAuthenticated activated in GameViewController")

        let skView = view as? SKView
        let scene = skView?.scene as? GameScene

        _networkingEngine = MultiplayerNetworking()
        _networkingEngine?._delegate = scene as? MultiplayerNetworkingProtocol
        scene?.networkingEngine = _networkingEngine

        GameKitHelper.sharedGameKitHelper().findMatch(minPlayers: 2, maxPlayers: 2, viewController: self, delegate: _networkingEngine)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load 'GameScene.sks' as a GKScene. This provides gameplay related content
        // including entities and graphs.
        if let scene = GKScene(fileNamed: "GameScene") {
            
            // Get the SKScene from the loaded GKScene
            if let sceneNode = scene.rootNode as! GameScene? {
                
                // Copy gameplay related content over to the scene
                sceneNode.entities = scene.entities
                sceneNode.graphs = scene.graphs
                
                // Set the scale mode to scale to fit the window
                sceneNode.scaleMode = .aspectFill
                
                // Present the scene
                if let view = self.view as! SKView? {
                    view.presentScene(sceneNode)
                    
                    view.ignoresSiblingOrder = true
                    
                    view.showsFPS = true
                    view.showsNodeCount = true
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
