//
//  GameScene.swift
//  CatRaceSwift
//
//  Created by Aaron Hicks on 5/15/20.
//  Copyright © 2020 Aaron Hicks. All rights reserved.
//

import SpriteKit
import GameplayKit
import GameKit

class GameScene: SKScene, MultiplayerNetworkingProtocol {

    
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
    private var lastUpdateTime : TimeInterval = 0
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    var _players:NSMutableArray?
    var _currentPlayerIndex:Int = -1
    var _cat:SKSpriteNode?
    var networkingEngine:MultiplayerNetworking?
    var gameOverBlock: ((_ didWin: Bool) -> Void)?
    var gameEndedBlock: (() -> Void)?
        
    override func sceneDidLoad() {

        self.lastUpdateTime = 0
        
        // Get label node from scene and store it for use later
//        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
//        if let label = self.label {
//            label.alpha = 0.0
//            label.run(SKAction.fadeIn(withDuration: 2.0))
//        }
//
//        // Create shape node to use during mouse interaction
//        let w = (self.size.width + self.size.height) * 0.05
//        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
//
//        if let spinnyNode = self.spinnyNode {
//            spinnyNode.lineWidth = 2.5
//
//            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
//            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
//                                              SKAction.fadeOut(withDuration: 0.5),
//                                              SKAction.removeFromParent()]))
//        }
        
        let background = SKSpriteNode(imageNamed: "bg")
        background.anchorPoint = CGPoint(x: 0, y: 0)
        background.xScale = 1.15
        background.yScale = 1.15
        addChild(background)
        
        _players = NSMutableArray()
        
        let player1 = PlayerSprite(type: .kPlayerSpriteDog)
        let player2 = PlayerSprite(type: .kPlayerSpriteKid)
        let maxWidth = max(player1.size.width, player2.size.width)
        let playersYOffset: CGFloat = 50
        let playersXOffset = -(maxWidth - min(player1.size.width, player2.size.width))
        player1.position = CGPoint(x: maxWidth - player1.size.width + player1.size.width / 2 + playersXOffset, y: player1.size.height / 2)
        player2.position = CGPoint(x: maxWidth - player2.size.width + player2.size.width / 2 + playersXOffset, y: player1.size.height / 2 + playersYOffset)
        //player1.position = CGPoint(x: 100, y: 100)
        //player2.position = CGPoint(x: 100, y: 200)
        player1.zPosition = 999
        player2.zPosition = 999

        let gameAtlas = SKTextureAtlas(named: "sprites")
        _cat = SKSpriteNode(texture: gameAtlas.textureNamed("cat_stand_1"))
        _cat?.position = CGPoint(x: size.width - (_cat?.size.width)! / 2, y: (_cat?.size.height)! / 2 + 20)
        
        _players?.add(player1)
        _players?.add(player2)
        
        addChild(player1)
        addChild(player2)
        addChild(_cat!)
        
        _currentPlayerIndex = -1
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.green
            self.addChild(n)
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue
            self.addChild(n)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red
            self.addChild(n)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesBegan activated")
        if let label = self.label {
            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
        }
        
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
        print("currentPlayerIndex = \(_currentPlayerIndex)")
        if(_currentPlayerIndex == -1){
            return
        }
        print("currentPlayerIndex after -1 check = \(_currentPlayerIndex)")
        ((_players?[_currentPlayerIndex]) as! PlayerSprite).moveForward()
        networkingEngine?.sendMove()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if (self.isPaused && _currentPlayerIndex == -1) {
            return
        }
        if (_currentPlayerIndex == 0){
            _players?.enumerateObjects({ playerSprite, idx, stop in
                var halfPlayerSprite = ((playerSprite as! PlayerSprite).size.width) / 2
                var playerSpriteAdjPos = (playerSprite as! PlayerSprite).position.x
                
                if ((playerSpriteAdjPos + halfPlayerSprite) > (_cat?.position.x)!) {
                    var didWin = false
                    if (idx == _currentPlayerIndex as Int) {
                        print("Won")
                        didWin = true
                    } else {
                        //you lost
                        print("Lost")
                    }
                    self.isPaused = true
                    _currentPlayerIndex = -1
                    stop.pointee = true

                    networkingEngine?.sendGameEnd(player1Won: didWin)
                    if (self.gameOverBlock != nil) {
                        self.gameOverBlock!(didWin)
                    }
                }
            })

        }


        // Initialize _lastUpdateTime if it has not already been
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime
        
        // Update entities
        for entity in self.entities {
            entity.update(deltaTime: dt)
        }
        
        self.lastUpdateTime = currentTime
    }
    
    //MultiplayerNetworkingProtocol
    
    func matchEnded(){
        if((self.gameEndedBlock) != nil){
            self.gameEndedBlock!()
        }
    }
    
    func setCurrentPlayerIndex(index:UInt){
        _currentPlayerIndex = Int(index)
    }
    
   
    
    
    func movePlayerAtIndex(index:UInt){
        ((_players?[Int(index)])! as! PlayerSprite).moveForward()
    }
    
    func gameOver(player1Won:Bool){
        var didLocalPlayerWin = true
        if (player1Won) {
            didLocalPlayerWin = false
        }
        if((self.gameOverBlock) != nil) {
            self.gameOverBlock!(didLocalPlayerWin)
        }
    }
    
    func setPlayerAliases(playerAliases:NSArray){
        playerAliases.enumerateObjects({ playerAlias, idx, stop in
            (_players?[idx] as! PlayerSprite).playerAlias.text = playerAlias as? String
        })
    }
}
