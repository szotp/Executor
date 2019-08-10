//
//  ScriptContext.swift
//  Executor
//
//  Created by Paweł Szot on 02/08/2019.
//  Copyright © 2019 Paweł Szot. All rights reserved.
//

import Cocoa

public let fm = FileManager.default

public func dlog(_ x: Any?) {
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

public struct ScriptData: Codable {
    var timestamp: Date
    public var script: [ScriptInfo]
    
    public static func load() -> ScriptData{
        let dir = scriptsURL

        if !fm.fileExists(atPath: dir.path) {
            try! fm.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        }
        
        let contents = try! fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isExecutableKey], options: [])
        let scripts = contents.filter(ScriptInfo.isScript).map(ScriptInfo.fromURL)
        let result = ScriptData(timestamp: Date(), script: scripts)

        return result
    }
}

public class ScriptDataLoader {
    private var cache: ScriptData?
    
    public init() {}
    
    public var value: ScriptData {
        if let timestamp = cache?.timestamp {
            let attributes = try! fm.attributesOfItem(atPath: scriptsURL.path)
            let date = attributes[.modificationDate] as! Date
            
            dlog("modification: \(date) timestamp: \(timestamp)")
            
            if date > timestamp {
                cache = nil
            }
        }
        
        if cache == nil {
            dlog("ScriptData.load")
            cache = ScriptData.load()
        }
        
        return cache!
    }
}

public extension Encodable {
    var json: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode(self)
        let string = String(data: data, encoding: .utf8)!
        return string
    }
}

public class ScriptInfo: Codable {
    public init(url: URL, title: String, triggers: Triggers, launcher: String) {
        self.url = url
        self.title = title
        self.triggers = triggers
        self.launcher = launcher
    }
    
    public let url: URL
    public let title: String
    public let triggers: Triggers
    public let launcher: String
    
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

/// Provides lazy loaded values used by triggers
public class ScriptContext: Codable {
    public init(currentDirectory: URL, items: [URL]) {
        self.currentDirectory = currentDirectory
        self.items = items
    }
    
    let currentDirectory: URL
    let items: [URL]
    
    private(set) lazy var pasteboardString: String = {
        let pasteboard = NSPasteboard.general
        let string = (pasteboard.string(forType: .string) ?? "")
        return string
    }()
    
    private(set) lazy var contents: [URL] = { () -> [URL] in
        let result = try? fm.contentsOfDirectory(at: currentDirectory, includingPropertiesForKeys: nil, options: [])
        return result ?? []
    }()
    
    private(set) lazy var children: Set<String> = Set(contents.map { $0.lastPathComponent })
    
    private(set) lazy var extensions: Set<String> = Set(self.contents.map { $0.pathExtension })
    
    private(set) lazy var isDirectory: Bool? = {
        var result: ObjCBool = false
        let exists = fm.fileExists(atPath: items[0].path, isDirectory: &result)
        
        if exists && items.count == 0 {
            return result.boolValue
        } else {
            return nil
        }
    }()
}
