//
//  Triggers.swift
//  ExecutorKit
//
//  Created by pszot on 10/08/2019.
//  Copyright © 2019 Paweł Szot. All rights reserved.
//

import Cocoa

public struct IsDirectory: Trigger {
    public static let identifier: String = "isDirectory"
    
    let value: Bool
    
    public func matches(command: ScriptContext) -> Bool {
        return command.isDirectory == value
    }
    
    public init?(rawValue: String) {
        value = Bool(rawValue) ?? false
    }
    
    public var rawValue: String {
        return value.description
    }
}

public struct HasExtension: Trigger {
    public static let identifier: String = "extensions"
    
    public func matches(command: ScriptContext) -> Bool {
        return extensions.intersection(command.extensions).count > 0
    }
    
    var extensions: Set<String>
    
    public init?(rawValue: String) {
        let mapped = rawValue.split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespaces)
        }
        extensions = Set(mapped)
    }
    
    public var rawValue: String {
        return extensions.joined(separator: ", ")
    }
}

public struct HasChild: Trigger {
    public static let identifier: String = "hasChild"
    
    public func matches(command: ScriptContext) -> Bool {
        return command.children.contains(name)
    }
    
    var name: String
    
    public init?(rawValue: String) {
        name = rawValue
    }
    
    public var rawValue: String {
        return name
    }
}

public struct PasteboardContains: Trigger {
    public static let identifier: String = "ifPasteboard"
    let text: String
    
    public func matches(command: ScriptContext) -> Bool {
        let string = command.pasteboardString
        return string.contains(text)
    }
    
    public init?(rawValue: String) {
        self.text = rawValue
    }
    
    public var rawValue: String {
        return text
    }
}

public struct Triggers {
    static let types: [Trigger.Type] = [
        HasExtension.self,
        HasChild.self,
        IsDirectory.self,
        PasteboardContains.self
    ]
    
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
                if let trigger = type.init(rawValue: value) {
                    items.append(trigger)
                } else {
                    assertionFailure()
                }
            }
        }
    }
    
    public func canRun(command: ScriptContext) -> Bool {
        if items.isEmpty {
            return true
        }
        
        for item in items {
            if item.matches(command: command) {
                return true
            }
        }
        
        return false
    }
    
    public static func printHelp() {
        print("Supported triggers:")
        
        for type in types {
            print(type.identifier)
        }
    }
}

extension Triggers: Codable {
    private struct AnyTrigger: Codable {
        var value: Trigger
        
        init(value: Trigger) {
            self.value = value
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            
            let range = string.range(of: ": ")!
            let key = string[string.startIndex ..< range.lowerBound]
            let rawValue = string[range.upperBound ..< string.endIndex]
            
            let type = Triggers.typesByIdentifier[String(key)]!
            value = type.init(rawValue: String(rawValue))!
        }
        
        func encode(to encoder: Encoder) throws {
            let identifier = type(of: value).identifier
            let string = identifier + ": " + value.rawValue
            var container = encoder.singleValueContainer()
            try container.encode(string)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let boxed = try [AnyTrigger].init(from: decoder)
        items = boxed.map { $0.value }
    }
    
    public func encode(to encoder: Encoder) throws {
        let boxed = items.map(AnyTrigger.init)
        try boxed.encode(to: encoder)
    }
}

public protocol Trigger {
    static var identifier: String {get}
    
    func matches(command: ScriptContext) -> Bool
    
    init?(rawValue: String)
    var rawValue: String {get}
}
