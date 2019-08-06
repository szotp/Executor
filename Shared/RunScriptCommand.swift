//
//  RunScriptCommand.swift
//  Executor
//
//  Created by Paweł Szot on 02/08/2019.
//  Copyright © 2019 Paweł Szot. All rights reserved.
//

import Cocoa

let fm = FileManager.default

func dlog(_ x: Any?) {
    if let x = x {
        NSLog("\(x)")
    }
}

//public let launcherURL: URL = scriptsURL.appendingPathComponent("launcher")

public let scriptsURL: URL = {
    var url = try! fm.url(for: .applicationScriptsDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    url.deleteLastPathComponent()
    url.appendPathComponent("szotp.Executor.FinderExecutor")
    return url
}()

struct ScriptData: Codable {
    var timestamp: Date
    var script: [ScriptInfo]
    
    static func load() -> ScriptData{
        let dir = scriptsURL
        
        if !fm.fileExists(atPath: dir.path) {
            try! fm.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        }
        
        let contents = try! fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isExecutableKey], options: [])
        let scripts = contents.filter(ScriptInfo.isScript).map(ScriptInfo.fromURL)
        return ScriptData(timestamp: Date(), script: scripts)
    }
}

extension Encodable {
    var json: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode(self)
        let string = String(data: data, encoding: .utf8)!
        return string
    }
}

struct ScriptInfo: Codable {
    let url: URL
    let title: String
    let extensions: Set<String>?
    var launcher: String
    
    static let regex = try! NSRegularExpression(pattern: "#( [a-zA-Z0-9_]*):(.*)", options: [])
    
    static func parseDocumentation(url: URL) -> [String: String] {
        do {
            let content = try String(contentsOf: url) as NSString
            let regex = ScriptInfo.regex
            let matches = regex.matches(
                in: content as String,
                options: [],
                range: NSRange(location: 0, length: content.length)
            )
            
            var result: [String: String] = [:]
            
            for match in matches {
                func get(_ i: Int) -> String {
                    return content.substring(with: match.range(at: i)).trimmingCharacters(in: .whitespaces)
                }
                result[get(1)] = get(2)
            }
            
            return result
        } catch let error {
            dlog(error)
        }
        
        return [:]
    }
    
    static func fromURL(_ url: URL) -> ScriptInfo {
        let info = parseDocumentation(url: url)
        
        func getSet(value: String) -> Set<String> {
            let trimmed = value.split(separator: ",").map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            return Set(trimmed)
        }
        
        return ScriptInfo(
            url: url,
            title: info["title"] ?? url.lastPathComponent,
            extensions: info["extensions"].map(getSet),
            launcher: info["launcher"] ?? "launcher"
        )
    }
    
    static func isScript(url: URL) -> Bool {
        let name = url.lastPathComponent
        let ext = url.pathExtension
        
        
        if name.starts(with: ".") || name.starts(with: "launcher") {
            return false
        }
        
        return fm.isExecutableFile(atPath: url.path) || ext == "sh" || ext == ""
    }
}

struct RunScriptCommand: Codable {
    let currentDirectory: URL
    let script: ScriptInfo
    let items: [URL]
    
    var canRun: Bool {
        if let extensions = script.extensions {
            for item in items {
                if !extensions.contains(item.pathExtension) {
                    return false
                }
            }
        }
        
        return true
    }
}
