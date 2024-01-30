//
//  FileManager.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 06.01.2024.
//

import Foundation

protocol FileManaging {
    func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL]
    func fileExists(
        atPath path: String,
        isDirectory: UnsafeMutablePointer<ObjCBool>?
    ) -> Bool
    func copyItem(
        at srcURL: URL,
        to dstURL: URL
    ) throws
}

extension FileManager: FileManaging {}
