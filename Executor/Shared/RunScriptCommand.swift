//
//  RunScriptCommand.swift
//  Executor
//
//  Created by Paweł Szot on 02/08/2019.
//  Copyright © 2019 Paweł Szot. All rights reserved.
//

import Foundation


func dlog(_ x: Any) {
    NSLog("\(x)")
}

struct ScriptInfo {
    let url: String
    let title: String
    
    static func load() -> [ScriptInfo] {
        return []
    }
}

struct RunScriptCommand: Codable {
    let currentDirectory: URL
    let script: URL
    let items: [URL]?
    
    func encode() -> URL {
        var components = URLComponents()
        components.scheme = "executor"
        components.path = "execute"
        components.queryItems = [
            URLQueryItem(name: "cd", value: currentDirectory.absoluteString),
            URLQueryItem(name: "script", value: script.absoluteString),
        ]
        
        return components.url!
    }
    
    static func decode(url: URL) -> RunScriptCommand {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        assert(components.scheme == "executor")
        
        func get(_ name: String) -> URL {
            for item in components.queryItems! {
                if item.name == name {
                    return URL(string: item.value!)!
                }
            }
            
            fatalError()
        }
        
        return RunScriptCommand(
            currentDirectory: get("cd"),
            script: get("script"),
            items: nil
        )
    }
}
