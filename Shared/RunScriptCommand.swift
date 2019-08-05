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

public let launcherURL: URL = scriptsURL.appendingPathComponent("launcher")

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
    
    static let regex = try! NSRegularExpression(pattern: "([a-zA-Z0-9_]*)='(.*)'", options: [])
    
    static func fromURL(_ url: URL) -> ScriptInfo {
        var title = url.lastPathComponent
        var extensions: Set<String>?
        
        do {
            let content = try String(contentsOf: url) as NSString
            let regex = ScriptInfo.regex
            let matches = regex.matches(
                in: content as String,
                options: [],
                range: NSRange(location: 0, length: content.length)
            )
            
            for x in matches {
                let name = content.substring(with: x.range(at: 1))
                let value = content.substring(with: x.range(at: 2))
                
                if name == "SCRIPT_NAME" {
                    title = value
                }
                
                if name == "SCRIPT_EXTENSIONS" {
                    extensions = Set(value.split(separator: ",").map { String($0) })
                }
            }
        } catch let error {
            dlog(error)
        }
        
        return ScriptInfo(url: url, title: title, extensions: extensions)
    }
    
    static func isScript(url: URL) -> Bool {
        if url == launcherURL {
            return false
        }
        
        let name = url.lastPathComponent
        let ext = url.pathExtension
        
        if name.starts(with: ".") {
            return false
        }
        
        return fm.isExecutableFile(atPath: url.path) || ext == "sh" || ext == ""
    }
}

struct RunScriptCommand: Codable {
    let currentDirectory: URL
    let script: ScriptInfo
    let items: [URL]?
    
    static func decode(url: URL) -> RunScriptCommand {
        var string = url.absoluteString
        let range = string.range(of: "executor://")!
        string.replaceSubrange(range, with: "")
        

        let data = Data(base64Encoded: string)!
        let decoder = JSONDecoder()
        return try! decoder.decode(self, from: data)
    }
    
    func encode() -> URL {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        return URL(string: "executor://" + data.base64EncodedString())!
    }
}
