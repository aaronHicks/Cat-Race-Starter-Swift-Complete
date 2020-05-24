//
//  GameKitHelper.swift
//  CatRaceSwift
//
//  Created by Aaron Hicks on 5/15/20.
//  Copyright © 2020 Aaron Hicks. All rights reserved.
//

import Foundation
import GameKit

class GameKitHelper: NSObject, GKLocalPlayerListener, GKMatchDelegate, GKMatchmakerViewControllerDelegate {
    var _enableGameCenter:Bool
    var _matchStarted:Bool
    var pendingInvite:GKInvite?
    var pendingPlayersToInvite:NSArray?
    //add GameViewController later
    var _mmvc:GKMatchmakerViewController?
    var lastError:NSError?
    var authenticationViewController:UIViewController?
    var match:GKMatch?
    var playerAliasArray:[GKPlayer] = []
    var playersDict:NSMutableDictionary?
    var _delegate: GameKitHelperDelegate?
    let PresentAuthenticationViewController = "present_authentication_view_controller"
    let RemoveAuthenticationViewController = "remove_authentication_view_controller"
    let LocalPlayerIsAuthenticated = "local_player_authenticated"
    
    static let sharedGameKitHelperVar: GameKitHelper = {
        var sharedGameKitHelper = GameKitHelper()
        return sharedGameKitHelper
    }()

//    class func sharedGameKitHelper() -> Self {
//        // `dispatch_once()` call was converted to a static variable initializer
//        return sharedGameKitHelperVar as! Self
//    }
    class func sharedGameKitHelper() -> GameKitHelper {
        // `dispatch_once()` call was converted to a static variable initializer
        return sharedGameKitHelperVar
    }
    
    override init(){
        
        _enableGameCenter = true
        _matchStarted = false
    }
    
    func authenticateLocalPlayer(){
        print("authenticateLocalPlayer activated")
        
        var localPlayer:GKLocalPlayer = GKLocalPlayer()
//        if (localPlayer.isAuthenticated){
        //vvv this line makes the MMVC reappear on restart
        if (GKLocalPlayer.local.isAuthenticated){
            print("localPlayer.isAuthenticated")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: self.LocalPlayerIsAuthenticated), object: nil)
            return
        }
        
        localPlayer.authenticateHandler = {(viewController, error) -> Void in
            //self.lastError = error as NSError?
            print("got into the authenticateHandler block")
            print("viewController = \(String(describing: viewController))")
            self.setLastError(error)

            if(viewController != nil){
                print("authenticateHandler viewController != nil")
                self.setAuthenticationViewController(authenticationViewController: viewController)
            }
            else if(GKLocalPlayer.local.isAuthenticated){
                print("player authenticated")
//                localPlayer.unregisterAllListeners()
//                localPlayer.register(self)
                GKLocalPlayer.local.unregisterAllListeners()
                GKLocalPlayer.local.register(self)
                self._enableGameCenter = true
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: self.LocalPlayerIsAuthenticated), object: nil)
            }
            else{
                print("viewController == nil and !localPlayer.isAuthenticated")
                print("error = \(String(describing: error))")
                self._enableGameCenter = false
            }
        }
        
        
    }
    
    func player(_ player: GKPlayer, didAccept invite: GKInvite) {
      print("Did accept invite")
        self.pendingInvite = invite
        GKMatchmaker.shared().match(for: invite, completionHandler: { match, error in

            if error != nil {
                if let description = error?.localizedDescription {
                    print("Error creating match from invitation: \(description)")
                }
                //Tell ViewController that match connect failed
            } else {
                self.update(with: match)
            }
        })
    }
    
    func update(with match: GKMatch?) {
        self.match = match
        self.match?.delegate = self
    }
    
    func player(player: GKPlayer!, didRequestMatchWithRecipients recipientPlayers: [AnyObject]!) {
      print("Did request matchmaking")
        self.pendingPlayersToInvite = recipientPlayers as NSArray?
        //add dismissViewController part here maybe
    }
    
    func lookupPlayers() {
        print("looking up players\(String(describing: self.match?.players.count))")
        for player in self.match!.players{
            print("player.gamePlayerID = \(player.gamePlayerID)")
            print("player.teamPlayerID = \(player.teamPlayerID)")
            print("player.displayName = \(player.displayName)")
            print("player.guestIdentifier = \(String(describing: player.guestIdentifier))")
//            self.playerAliasArray.append(player.gamePlayerID as String)
            self.playerAliasArray.append(player)
        }
        let playerIDs = match?.players.map { $0.playerID } ?? []
        GKPlayer.loadPlayers(forIdentifiers: playerIDs, withCompletionHandler: { players, error in
            print("inside loadPlayers block")
            if error != nil {
                print("Error retrieving player info: \(error?.localizedDescription ?? "")")
                self._matchStarted = false
                self._delegate?.matchEnded()
            } else {

                // Populate players dict
//                self.playersDict = [AnyHashable : Any](minimumCapacity: players?.count ?? 0) as? NSMutableDictionary
                self.playersDict = NSMutableDictionary()
                for player in players! {
//                    guard let player = player as? GKPlayer else {
//                        continue
//                    }
                    print("Found player: \(player.alias)")
                    
                    self.playersDict?.setObject(player, forKey: player.playerID as NSString)
                    print("playersDict in for loop = \(self.playersDict)")
                }
                self.playersDict?.setObject(GKLocalPlayer.local, forKey: GKLocalPlayer.local.playerID as NSString)
                print("playersDict outside of loop = \(self.playersDict)")

                // Notify delegate match can begin
                self._matchStarted = true
                self._delegate?.matchStarted()
            }
        })
    }
    
    func findMatch(
        minPlayers: Int,
        maxPlayers: Int,
        viewController: UIViewController?,
        delegate: GameKitHelperDelegate?
    ) {
        print("findMatchWithMinPlayers activated")
        if(!_enableGameCenter){
            return
        }
        
        self._matchStarted = false
        self.match = nil
        var viewController = viewController
        _delegate = delegate
        
        if(pendingInvite != nil){
            print("pendingInvite != nil")
            print("pendingInvite = \(String(describing: pendingInvite))")
            viewController?.dismiss(animated: false, completion: nil)
            _mmvc = GKMatchmakerViewController(invite: pendingInvite!)
            viewController?.present(_mmvc!, animated: true, completion: nil)
            self.pendingInvite = nil
        }
        else{
            print("pendingInvite == nil")
            viewController?.dismiss(animated: false, completion: nil)
            var request = GKMatchRequest()
            request.minPlayers = minPlayers
            request.maxPlayers = maxPlayers
            request.recipients = pendingPlayersToInvite as? [GKPlayer]
            print("request = \(request)")
            request.recipientResponseHandler = {(player,response) in
                print("response = \(response)")
                if (response == .inviteeResponseAccepted){
                    print("DEBUG: Player accepted:\(player)")
                    viewController?.dismiss(animated: true, completion: nil)
                }
            }
            _mmvc = GKMatchmakerViewController(matchRequest: request)
            _mmvc?.matchmakerDelegate = self
            
            viewController?.present(_mmvc!, animated: true, completion: nil)
            self.pendingPlayersToInvite = nil
        }
    }
    
    func setAuthenticationViewController(authenticationViewController:UIViewController?){
        if (authenticationViewController != nil){
            self.authenticationViewController = authenticationViewController
            NotificationCenter.default.post(
                name: NSNotification.Name(rawValue: PresentAuthenticationViewController),
            object: self)
        }
    }
    
    func removeAuthenticationViewController() {
        NotificationCenter.default.post(
            name: NSNotification.Name(rawValue: RemoveAuthenticationViewController),
            object: self)
    }
    
    func setLastError(_ error: Error?) {
        var lastError = error?.localizedDescription
        if (lastError != nil) {
            print(
                "GameKitHelper ERROR: \(lastError)")
        }
    }
    
    //GKMatchmakerViewControllerDelegate
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
        print("didFindMatch activated")
        viewController.dismiss(animated: true, completion: nil)
        self.match = match
        match.delegate = self
        if(!_matchStarted && match.expectedPlayerCount == 0){
            print("ready to start match! in didFindMatch")
            lookupPlayers()
        }
    }
    
    //GKMatchDelegate
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        if(self.match != match){
            return
        }
        
        _delegate?.match(match, didReceive: data, fromRemotePlayer: player)
    }
    
    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        if(self.match != match){
            return
        }
        
        OperationQueue.main.addOperation({
            self.matchmakerViewControllerWasCancelled(self._mmvc!)
        })
        
        switch state {
            case GKPlayerConnectionState.connected:
                // handle a new player connection.
                print("Player connected!")
                print(String(format: "expectedPlayerCount = %lu", UInt(match.expectedPlayerCount)))
                if !_matchStarted && match.expectedPlayerCount == 0 {
                    print("Ready to start match! in didChangeState")
                    lookupPlayers()
                }
            case GKPlayerConnectionState.disconnected:
                // a player just disconnected.
                print("Player disconnected!")
                _matchStarted = false
                _delegate?.matchEnded()
            default:
                break
        }

    }
    
    func match(_ match: GKMatch?, connectionWithPlayerFailed playerID: String?, withError error: Error?) {

        if self.match != match {
            return
        }

        print("Failed to connect to player with error: \(error?.localizedDescription ?? "")")
        _matchStarted = false
        _delegate?.matchEnded()
    }
    
    func match(_ match: GKMatch, didFailWithError error: Error?) {
        if(self.match != match){
            return
        }
        print("match failed with error: \(error?.localizedDescription)")
        _matchStarted = false
        _delegate?.matchEnded()
    }
}

//protocol GameKitHelperDelegate {
//    func matchStarted()
//    func matchEnded()
//    func match(_ match:GKMatch, didReceive data: Data, fromPlayer playerID:String)
//    func inviteReceived()
//}
