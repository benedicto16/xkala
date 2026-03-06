//
//  Item.swift
//  Xkala
//
//  Created by Alejandro Laso Gómez on 6/3/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
