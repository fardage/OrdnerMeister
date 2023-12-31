//
//  Node.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 30.12.2023.
//

import Foundation

struct Node {
    typealias Name = String
    var name: Name
    var children: [Name: Node]
}
