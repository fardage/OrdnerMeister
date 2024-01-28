//
//  Node.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 30.12.2023.
//

import Foundation

struct Node: Equatable {
    typealias Name = String
    var url: URL
    var children: [Name: Node]
}
