//
//  ScriptContext.swift
//  Executor
//
//  Created by Paweł Szot on 02/08/2019.
//  Copyright © 2019 Paweł Szot. All rights reserved.
//

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
    
    private(set) lazy var extensions = Set(items.map { $0.pathExtension })
    
    private(set) lazy var isDirectory: Bool? = {
        guard items.count == 1 else {
            return false
        }
        
        var result: ObjCBool = false
        let exists = fm.fileExists(atPath: items[0].path, isDirectory: &result)
        
        if exists {
            return result.boolValue
        } else {
            return nil
        }
    }()
}
