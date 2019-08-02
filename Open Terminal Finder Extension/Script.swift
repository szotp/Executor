//
//  Script.swift
//  OpenTerminal
//
//  Created by Paweł Szot on 02/08/2019.
//  Copyright © 2019 QP. All rights reserved.
//

import Foundation
import Cocoa

struct Script {
    let title: String
    let url: URL
    
    init(url: URL) {
        self.url = url
        title = url.lastPathComponent
    }
    
    func execute(target: URL) {
        print("LOL")
        let task = try! NSUserScriptTask(url: target)
        task.execute { (_) in
            
        }
    }
    
    static func fetch(url: URL) -> [Script] {
        let fm = FileManager.default
        let contents = try! FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isExecutableKey], options: [])
        
        func isScript(url: URL) -> Bool {
            return fm.isExecutableFile(atPath: url.path) || url.pathExtension == "command"
        }
        
        return contents.filter(isScript).map(Script.init)
    }
}
