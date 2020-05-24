//
//  GameKitHelperDelegate.swift
//  CatRaceSwift
//
//  Created by Aaron Hicks on 5/20/20.
//  Copyright © 2020 Aaron Hicks. All rights reserved.
//

import Foundation
import GameKit

protocol GameKitHelperDelegate {
    func matchStarted()
    func matchEnded()
    func match(_ match:GKMatch, didReceive data: Data, fromRemotePlayer player:GKPlayer)
    func inviteReceived()
}
