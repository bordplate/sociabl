//
//  Renderer.swift
//  sociabl
//
//  Created by Vetle Økland on 20/03/2017.
//
//

import Vapor
import Leaf
import HTTP
import Auth

/// A custom renderer that injects authentication details if any
public final class Renderer: ViewRenderer {
    public let stem: Stem
    
    public init(viewsDir: String = drop.workDir + "Resources/Views") {
        stem = Stem(workingDirectory: viewsDir)
    }
    
    public func make(_ path: String, _ context: Node) throws -> View {
        var appendingContext = context
        appendingContext["authorized"] = false
        
        if let storage = context["request"]?["storage"] {
            if storage["authorized"] == true {
                appendingContext["authorized"] = true
                appendingContext["logged_user"] = storage["authorized_user"]
            }
        }
        
        let leaf = try stem.spawnLeaf(named: path)
        let context = Context(appendingContext.makeNode())
        let bytes = try stem.render(leaf, with: context)
        return View(data: bytes)
    }
}
