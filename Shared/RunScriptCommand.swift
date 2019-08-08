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

struct CodablePredicate: Codable {
    var value: NSPredicate
    
    init(from decoder: Decoder) throws {
        value = try NSPredicate(format: decoder.singleValueContainer().decode(String.self))
    }
    
    init(_ value: NSPredicate) {
        self.value = value
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value.predicateFormat)
    }
}

protocol Trigger: Codable {
    static var identifier: String {get}
    
    init(rawValue: String) throws
    func matches(command: RunScriptCommand) -> Bool
}


struct IsDirectory: Trigger {
    static let identifier: String = "isDirectory"
    
    let value: Bool
    
    func matches(command: RunScriptCommand) -> Bool {
        return false
    }
    
    init(rawValue: String) throws {
        value = Bool(rawValue) ?? false
    }
}

struct HasExtension: Trigger {
    static let identifier: String = "extensions"
    
    func matches(command: RunScriptCommand) -> Bool {
        return false
    }
    
    var extensions: Set<String>
    
    init(rawValue: String) throws {
        let mapped = rawValue.split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespaces)
        }
        extensions = Set(mapped)
    }
}

struct HasChild: Trigger {
    static let identifier: String = "hasChild"
    
    func matches(command: RunScriptCommand) -> Bool {
        let dir = command.items[0]
        
        dlog(command.items)
        dlog("Checking \(dir)")
        
        do {
            let contents = try fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: [])
            
            for item in contents {
                if item.lastPathComponent == name {
                    return true
                }
            }
        } catch let error {
            dlog(error)
        }
        
        return false
    }
    
    var name: String
    
    init(rawValue: String) throws {
        name = rawValue
    }
}

struct Triggers {
    static let types: [Trigger.Type] = [HasExtension.self, HasChild.self, IsDirectory.self]
    static let typesByIdentifier: [String: Trigger.Type] = {
        var dict: [String: Trigger.Type] = [:]
        for item in Triggers.types {
            dict[item.identifier] = item
        }
        return dict
    }()

    var items: [Trigger] = []
    
    init(info: [ScriptInfo.Entry]) {
        for (key, value) in info {
            if let type = Triggers.typesByIdentifier[key] {
                if let trigger = try? type.init(rawValue: value) {
                    items.append(trigger)
                } else {
                    
                }
            }
        }
    }
    
    func matches(command: RunScriptCommand) -> Bool {
        for item in items {
            if item.matches(command: command) {
                return true
            }
        }
        
        return false
    }
}

extension Triggers: Codable {
    private struct AnyTrigger: Codable {
        static let types: [Codable.Type] = Triggers.types
        var value: Trigger
        
        init(value: Trigger) {
            self.value = value
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let identifier = try container.decode(String.self, forKey: .identifier)
            let type = Triggers.typesByIdentifier[identifier]!
            value = try type.init(from: decoder)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type(of: value).identifier, forKey: .identifier)
            try value.encode(to: encoder)
        }
    }
    
    init(from decoder: Decoder) throws {
        let boxed = try [AnyTrigger].init(from: decoder)
        items = boxed.map { $0.value }
    }
    
    func encode(to encoder: Encoder) throws {
        let boxed = items.map(AnyTrigger.init)
        try boxed.encode(to: encoder)
    }
    
    enum CodingKeys: CodingKey {
        case identifier
    }
}

struct ScriptInfo: Codable {
    let url: URL
    let title: String
    let triggers: Triggers
    var launcher: String
    
    typealias Entry = (key: String, value: String)
    
    static let regex = try! NSRegularExpression(pattern: "#( [a-zA-Z0-9_]*):(.*)", options: [])
    
    static func parseDocumentation(url: URL) -> [Entry] {
        do {
            let content = try String(contentsOf: url) as NSString
            let regex = ScriptInfo.regex
            let matches = regex.matches(
                in: content as String,
                options: [],
                range: NSRange(location: 0, length: content.length)
            )
            
            return matches.map { match in
                func get(_ i: Int) -> String {
                    return content.substring(with: match.range(at: i)).trimmingCharacters(in: .whitespaces)
                }
                
                return (get(1), get(2))
            }
        } catch let error {
            dlog(error)
        }
        
        return []
    }
    
    static func fromURL(_ url: URL) -> ScriptInfo {
        let info = parseDocumentation(url: url)
        
        func getSet(value: String) -> Set<String> {
            let trimmed = value.split(separator: ",").map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            return Set(trimmed)
        }
        
        func get(_ key: String) -> String? {
            return info.first { $0.key == key }?.value
        }
        
        return ScriptInfo(
            url: url,
            title: get("title") ?? url.lastPathComponent,
            triggers: Triggers(info: info),
            launcher: get("launcher") ?? "launcher"
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
        return script.triggers.matches(command: self)
    }
}
