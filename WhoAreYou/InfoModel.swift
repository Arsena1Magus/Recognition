//
//  InfoModel.swift
//  WhoAreYou
//
//  Created by Никита Петров on 13.11.2021.
//  Copyright © 2021 M'haimdat omar. All rights reserved.
//

import UIKit

struct InfoModel {
    var id: String = ""
    var name: String = ""
    var age: String = ""
    var position: String = ""
    var level: String = ""
    var time: String = ""
    
    init(json: [String: Any]) {
        if let id = json["id"] as? String {
            self.id = id
        }
        if let name = json["name"] as? String {
            self.name = name
        }
        if let age = json["age"] as? String {
            self.age = age
        }
        if let position = json["position"] as? String {
            self.position = position
        }
        if let level = json["level"] as? String {
            self.level = level
        }
        if let time = json["time"] as? String {
            self.time = time
        }
    }
}
