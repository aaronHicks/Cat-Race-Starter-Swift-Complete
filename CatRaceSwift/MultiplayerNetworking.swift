//
//  MultiplayerNetworking.swift
//  CatRaceSwift
//
//  Created by Aaron Hicks on 5/16/20.
//  Copyright © 2020 Aaron Hicks. All rights reserved.
//

import Foundation
import GameKit

class MultiplayerNetworking: NSObject, GameKitHelperDelegate {
    
    let playerIdKey = "PlayerId"
    let randomNumberKey = "randomNumber"
    var _ourRandomNumber:UInt32 = arc4random()
    var _gameState:GameState = .kGameStateWaitingForMatch
    var _isPlayer1:Bool?
    var _receivedAllRandomNumbers:Bool = false
    var _orderOfPlayers:NSMutableArray!
    var _delegate: MultiplayerNetworkingProtocol!
    var _localPlayerDict:Dictionary<String, Any>?
    
    enum GameState : Int {
        case kGameStateWaitingForMatch = 0,
        kGameStateWaitingForRandomNumber,
        kGameStateWaitingForStart,
        kGameStateActive,
        kGameStateDone
    }
    
    enum MessageType : Int {
        case kMessageTypeRandomNumber = 0,
        kMessageTypeGameBegin,
        kMessageTypeMove,
        kMessageTypeGameOver
    }
    
    typealias Message = (MessageType)
    typealias MessageRandomNumber = (message: Message, randomNumber: UInt32)
    typealias MessageGameBegin = (Message)
    typealias MessageMove = (Message)
    typealias MessageGameOver = (message: Message, player1Won: Bool)
    
    override init(){
        //super.init()
        _ourRandomNumber = arc4random()
        _gameState = .kGameStateWaitingForMatch
        
        print("MultiplayerNetworking init _orderOfPlayers = \(_orderOfPlayers)")
        _orderOfPlayers = NSMutableArray()
        _localPlayerDict = [playerIdKey: GKLocalPlayer.local.playerID,
                            randomNumberKey: Int(_ourRandomNumber)]
        _orderOfPlayers.add(_localPlayerDict! as Dictionary<String,Any>)
        print("MultiplayerNetworking init post-add  _orderOfPlayers = \(_orderOfPlayers)")
        
        
    }
    
    func sendData(data:NSData){
        var error:NSError
        var gameKitHelper:GameKitHelper = GameKitHelper.sharedGameKitHelper()
        var success = false
        do {
            try gameKitHelper.match?.sendData(
                toAllPlayers: data as Data,
                with: .reliable)
            success = true
        } catch {
        }
        
        if(!success){
            print("error sending data:")
            matchEnded()
        }
    }
    
    func sendMove() {
        var messageMove: MessageMove
        messageMove = .kMessageTypeMove
        let data = Data(
            bytes: &messageMove,
            count: MemoryLayout<MessageMove>.size)
        sendData(data: data as NSData)
    }
    
    func sendRandomNumber() {
        var message: MessageRandomNumber
        message.message = .kMessageTypeRandomNumber
        message.randomNumber = _ourRandomNumber
        let data = Data(
            bytes: &message,
            count: MemoryLayout<MessageRandomNumber>.size)
        sendData(data: data as NSData)
    }
    
    func sendGameBegin() {
        print("sendGameBegin activated")
        var message: MessageGameBegin
        message = .kMessageTypeGameBegin
        let data = Data(
            bytes: &message,
            count: MemoryLayout<MessageGameBegin>.size)
        sendData(data: data as NSData)
    }
    
    func sendGameEnd(player1Won:Bool){
        var message: MessageGameOver
        message.message = .kMessageTypeGameOver
        message.player1Won = player1Won
        let data = Data(
            bytes: &message,
            count: MemoryLayout<MessageGameOver>.size)
        sendData(data: data as NSData)
    }
    
    func indexForLocalPlayer() -> Int {
        let playerId = GKLocalPlayer.local.playerID

        return indexForPlayer(withId: playerId)
    }
    
    func indexForPlayer(withId playerId: String?) -> Int {
        var index = -1
        
        if(_orderOfPlayers != nil){
            _orderOfPlayers?.enumerateObjects({obj, idx, stop in
//            var pId = obj[playerIdKey] as? String
                var _dictionaryEntry = (_orderOfPlayers[idx] as! Dictionary<String, Any>)
                //var pId = (_orderOfPlayers?[idx] as AnyObject).object(forKey: "playerIdKey") as? String
                let dictionaryPlayerId = _dictionaryEntry["PlayerId"] as! String
            if (dictionaryPlayerId == playerId) {
                index = idx
                stop.pointee = true
            }
        })
        
    }
        return index
    }
    

    
    func tryStartGame(){
        print("tryStartGame activated")
        _isPlayer1 = isLocalPlayerPlayer1()
        print("_isPlayer1 = \(_isPlayer1)")
        print("_gameState = \(_gameState)")
        if(_isPlayer1! && _gameState == .kGameStateWaitingForStart) {
            print("conditional satisfied")
            _gameState = .kGameStateActive
            sendGameBegin()
            
            //first player
            _delegate.setCurrentPlayerIndex(index: 0)
            processPlayerAliases()
        }
    }
    
    func allRandomNumbersAreReceived() -> Bool {
        var receivedRandomNumbers:NSMutableArray = []
        print("_orderOfPlayers = \(_orderOfPlayers)")
        if(_orderOfPlayers != nil){
        for dict in _orderOfPlayers! {
               
                    receivedRandomNumbers.add(dict)
                
            }
        }
        print("receivedRandomNumbers.count = \(receivedRandomNumbers.count)")
        print("(GameKitHelper.sharedGameKitHelper().match?.players.count)! = \((GameKitHelper.sharedGameKitHelper().match?.players.count)!)")

        if (receivedRandomNumbers.count == (GameKitHelper.sharedGameKitHelper().match?.players.count)! + 1) {
            print("allRandomNumbersReceived = true")
            return true
        }
        print("allRandomNumbersReceived = false")
        return false
    }
    
    func processReceivedRandomNumber(_ randomNumberDetails:Dictionary<String,Any>?) {
        //1

        //2
        if let _randomNumberDetails = randomNumberDetails {
            if(_orderOfPlayers != nil){
                _orderOfPlayers?.add(_randomNumberDetails)
            }
        }

        //3
        let sortByRandomNumber = NSSortDescriptor(
            key: "randomNumberKey",
            ascending: true)
        let sortDescriptors = [sortByRandomNumber]
        
        if(_orderOfPlayers != nil){
            print("orderOfPlayers in processedReceivedNumber = \(_orderOfPlayers)")
            
            //var _orderOfPlayersTemp = (_orderOfPlayers?.sortedArray(using: [NSSortDescriptor(key: "randomNumberKey", ascending: true)]) ?? []) as NSMutableArray
            
            let _dictionaryEntry0 = (_orderOfPlayers[0] as! Dictionary<String, Any>)
            let _dictionaryEntry1 = (_orderOfPlayers[1] as! Dictionary<String, Any>)
            print("_dictionaryEntry0 = \(_dictionaryEntry0)")
            print("_dictionaryEntry0[randomNumberKey] = \(_dictionaryEntry0[randomNumberKey])")
            let dictionaryRandomNumber0 = _dictionaryEntry0[randomNumberKey] as! Int
            let dictionaryRandomNumber1 = _dictionaryEntry1[randomNumberKey] as! Int
            print("dictionaryRandomNumber0 = \(dictionaryRandomNumber0)")
            print("dictionaryRandomNumber1 = \(dictionaryRandomNumber1)")
            if (dictionaryRandomNumber0 > dictionaryRandomNumber1){
                _orderOfPlayers[0] = _dictionaryEntry1
                _orderOfPlayers[1] = _dictionaryEntry0
            }
            
            
            //_orderOfPlayersTemp.sorted(by: {($0["randomNumberKey"] as! UInt32) > ($1["randomNumberKey"] as! UInt32)})
//            let _orderOfPlayersTemp = (_orderOfPlayers?.sortedArray(using: [NSSortDescriptor(key: "randomNumberKey", ascending: true)]) ?? []) as NSMutableArray
            //print("orderOfPlayersTemp = \(_orderOfPlayersTemp)")
            //_orderOfPlayers = _orderOfPlayersTemp as? NSMutableArray
            print("orderOfPlayers post-sort = \(_orderOfPlayers)")
        }
        //4
        if allRandomNumbersAreReceived() {
            _receivedAllRandomNumbers = true
        }
    }

    func processPlayerAliases() {
        if allRandomNumbersAreReceived() {

            var playerAliases:NSMutableArray = []// = ["player1","player2"]
            var index:Int
            if(_orderOfPlayers != nil){
                for i in _orderOfPlayers!{
                    
                    let _dictionaryEntry = (i as! Dictionary<String, Any>)
                    print("i = \(i)")
                    print("_dictionaryEntry = \(_dictionaryEntry)")

                    let dictionaryPlayerId = _dictionaryEntry["PlayerId"] as! String
                    //need to find an entry in playersDict that has a playerID value matching dictionaryPlayerId
                    let dict = GameKitHelper.sharedGameKitHelper().playersDict!
                    
                    print("dictionaryPlayerId = \(dictionaryPlayerId)")
                    print("sharedGameKitHelper().playersDict = \( GameKitHelper.sharedGameKitHelper().playersDict)")
                    print("player = \((GameKitHelper.sharedGameKitHelper().playersDict?[dictionaryPlayerId] as? GKPlayer))")
                    print("alias = \((GameKitHelper.sharedGameKitHelper().playersDict?[dictionaryPlayerId] as? GKPlayer)?.alias)")
                    print("alias (string describing) = \(String(describing: (GameKitHelper.sharedGameKitHelper().playersDict?[dictionaryPlayerId] as? GKPlayer)?.displayName))")
                   
                    playerAliases.add((GameKitHelper.sharedGameKitHelper().playersDict?[dictionaryPlayerId] as? GKPlayer)?.alias ?? "")
                    

                }
                
            }
            print("playerAliases = \(playerAliases)")
            if playerAliases.count > 0 {
                _delegate.setPlayerAliases(playerAliases: playerAliases as NSArray)
            }
        }
    }

    //GOOD
    func isLocalPlayerPlayer1() -> Bool {
        //let dictionary = _orderOfPlayers?[0]
        //print("isLocalPlayerPlayer 1 _orderOfPlayers = \(_orderOfPlayers)")
        //print("isLocalPlayerPlayer 1 _orderOfPlayers[0] = \(_orderOfPlayers[0])")
        //print("[0] as dictionary<string, any> = \((_orderOfPlayers[0] as! Dictionary<String, Any>))")
        //print("GKLocalPlayer.local.gamePlayerID = \(GKLocalPlayer.local.gamePlayerID)")
        if(_orderOfPlayers != nil){

            var _dictionaryEntry = (_orderOfPlayers[0] as! Dictionary<String, Any>)

            let dictionaryPlayerIdValues = _dictionaryEntry.values as? [String:Any]
            //print("dictionaryPlayerIdValues = \(dictionaryPlayerIdValues)")
            let dictionaryPlayerId = _dictionaryEntry["PlayerId"] as! String
            
            print("dictionaryPlayerId isLocalPlayerPlayer1 = \(dictionaryPlayerId)")
            print("GKLocalPlayer.local.playerID = \(GKLocalPlayer.local.playerID)")
            
            if (dictionaryPlayerId == GKLocalPlayer.local.playerID as? String) {
                print("I'm player 1")
                return true
            }
            else {
                print("I'm player 2")
            }
        }
        

        return false
    }
    
    func matchStarted() {
        print("Match has started successfully")
        if _receivedAllRandomNumbers {
            _gameState = .kGameStateWaitingForStart
        } else {
            _gameState = .kGameStateWaitingForRandomNumber
        }
        sendRandomNumber()
        tryStartGame()
    }
    
    func matchEnded() {
        _delegate?.matchEnded()
    }
    
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        var message = data.withUnsafeBytes{ $0.load(as: Message.self) }
        if (message == .kMessageTypeRandomNumber) {
            let messageRandomNumber = data.withUnsafeBytes{ $0.load(as: MessageRandomNumber.self) }
            print("received random number: \(messageRandomNumber)")
            
            var tie:Bool = false
            if (messageRandomNumber.randomNumber == _ourRandomNumber){
                print("tie")
                tie = true
                _ourRandomNumber = arc4random()
                sendRandomNumber()
            }
            else{
                var dictionary = [
                    playerIdKey: player.playerID,
                    randomNumberKey: NSNumber(value: messageRandomNumber.randomNumber)
                    ] as NSDictionary
                print("dictionary didReceive data = \(dictionary)")
                processReceivedRandomNumber(dictionary as! Dictionary<String, Any>)
            }
            
            if (_receivedAllRandomNumbers){
                print("_receivedAllRandomNumbers true in didReceiveData")
                _isPlayer1 = isLocalPlayerPlayer1()
            }
            
            if (!tie && _receivedAllRandomNumbers == true){
                if (_gameState == .kGameStateWaitingForRandomNumber){
                    _gameState = .kGameStateWaitingForStart
                }
                print("tryStartGame didReceive data")
                tryStartGame()
            }
        }
        else if (message == .kMessageTypeGameBegin){
            print("begin game message received")
            _gameState = .kGameStateActive
            _delegate?.setCurrentPlayerIndex(index: UInt(indexForLocalPlayer()))
            processPlayerAliases()
        }
        else if (message == .kMessageTypeMove){
            print("move message received")
            var messageMove = data.withUnsafeBytes{ $0.load(as: MessageMove.self) }
            _delegate?.movePlayerAtIndex(index: UInt(indexForPlayer(withId: player.playerID)))
        }
        else if(message == .kMessageTypeGameOver){
            var messageGameOver = data.withUnsafeBytes{ $0.load(as: MessageGameOver.self)}
            _delegate?.gameOver(player1Won: messageGameOver.player1Won)
        }
    }
    
    func inviteReceived() {
        print("inviteReceived() activated")
    }
    
    
}

//protocol MultiplayerNetworkingProtocol {
//    func matchEnded()
//    func setCurrentPlayerIndex(index:UInt)
//    func movePlayerAtIndex(index:UInt)
//    func gameOver(player1Won:Bool)
//    func setPlayerAliases(playerAliases:NSArray)
//}
