//
//  PlayerSprite.swift
//  CatRaceSwift
//
//  Created by Aaron Hicks on 5/16/20.
//  Copyright © 2020 Aaron Hicks. All rights reserved.
//

import Foundation
import GameKit

enum PlayerSpriteType : Int {
    case kPlayerSpriteDog
    case kPlayerSpriteKid
}

class PlayerSprite: SKSpriteNode {
    var _isMoving:Bool = false
    var _moveTarget:CGPoint?
    var _playerType: PlayerSpriteType!
    var moveAnimation: SKAction?
    let kPlayerAliasLabelName = "player_alias"
    let kMoveActionKey = "translate_action"
    let kMoveAnimationKey = "move_animation"
    var playerAlias:SKLabelNode = SKLabelNode(fontNamed: "Arial")
    
    convenience init(type playerType: PlayerSpriteType) {
        
        let gameAtlas = SKTextureAtlas(named: "sprites")
        var textureName = "dog_1"
        var textureFrames = ["dog_1", "dog_2", "dog_3", "dog_4"]
        
        if playerType == .kPlayerSpriteKid {
            textureName = "kid_on_trike_1"
            textureFrames = [
                "kid_on_trike_1",
                "kid_on_trike_2",
                "kid_on_trike_3",
                "kid_on_trike_4"
            ]
        }
        
        self.init(imageNamed: textureName)
        if(self != nil){
            _playerType = playerType
            var textures = NSMutableArray()
            for textureName in textureFrames {
                var texture = gameAtlas.textureNamed(textureName)
                textures.add(texture)
            }
            
            //let playerAlias = SKLabelNode(fontNamed: "Arial")
            playerAlias.fontSize = 20
            playerAlias.fontColor = SKColor.red
            playerAlias.position = CGPoint(x: 0, y: 40)
            playerAlias.name = kPlayerAliasLabelName
            playerAlias.zPosition = 1000
            addChild(playerAlias)
            moveAnimation = SKAction.repeatForever(SKAction.animate(with: textures as! [SKTexture], timePerFrame: 0.1))
        }
        //return self
    }
    
    func moveForward(){
        if !_isMoving {
            _isMoving = true
            run(moveAnimation!, withKey: kMoveAnimationKey)
        }
        removeAction(forKey: kMoveActionKey)
        // Set new position to move too and create new sequence
        let moveToAction = SKAction.move(to: CGPoint(x: position.x + 40, y: position.y), duration: 1)
        let moveToComplete = SKAction.perform(#selector(moveDone), onTarget: self)
        let sequence = SKAction.sequence([moveToAction, moveToComplete])
        
        run(sequence, withKey: kMoveActionKey)
    }
    
    @objc func moveDone(){
        _isMoving = false
        removeAction(forKey: kMoveAnimationKey)
    }
    
    func setPlayerAliasText(_ playerAlias: String?) {
        let playerAliasLabel = childNode(withName: kPlayerAliasLabelName) as? SKLabelNode
        playerAliasLabel?.text = playerAlias
    }

}
