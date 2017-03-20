//
//  Localization.swift
//  sociabl
//
//  Created by Vetle Økland on 19/03/2017.
//
//

import Leaf
import Vapor

class LocalizationTag: Tag {
    public let name = "l"
    
    /// Only really takes 1 argument
    func run(stem: Stem, context: LeafContext, tagTemplate: TagTemplate, arguments: [Argument]) throws -> Node? {
        if arguments.count < 1 {
            return nil // We need at least one argument
        }
        
        var language: String?
        
        for node in context.queue.array {
            language = node["request", "storage", "localization-language"]?.string
        }
        
        // Turns out Chrome likes to put languages in user-preferred order by separating by `,`
        //TODO: Go through preferred languages and use the first one we actually have (maybe do in the Middleware?)
        guard let lang = language?.components(separatedBy: ",")[0] else {
            return arguments.last?.value
        }
        
        var localizationKeys = Array<String>()
    
        for argument in arguments {
            if let key = argument.value?.string {
                localizationKeys.append(key)
            }
        }
        
        return drop.localization[lang, localizationKeys].makeNode()
    }
}
