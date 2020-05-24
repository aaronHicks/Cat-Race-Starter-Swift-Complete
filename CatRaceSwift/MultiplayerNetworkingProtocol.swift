//
//  MultiplayerNetworkingProtocol.swift
//  CatRaceSwift
//
//  Created by Aaron Hicks on 5/20/20.
//  Copyright © 2020 Aaron Hicks. All rights reserved.
//

import Foundation


protocol MultiplayerNetworkingProtocol {
    func matchEnded()
    func setCurrentPlayerIndex(index:UInt)
    func movePlayerAtIndex(index:UInt)
    func gameOver(player1Won:Bool)
    func setPlayerAliases(playerAliases:NSArray)
}
