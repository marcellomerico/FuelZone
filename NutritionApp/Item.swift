//
//  Item.swift
//  NutritionApp
//
//  Created by Marcello Merico on 20.05.26.
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
