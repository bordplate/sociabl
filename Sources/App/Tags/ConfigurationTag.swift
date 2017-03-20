//
//  ConfigurationTag.swift
//  sociabl
//
//  Created by Vetle Økland on 19/03/2017.
//
//

import Leaf

/// A `#config`-tag that takes the value of `app.json`s `public`-tree
class ConfigurationTag: BasicTag {
    public let name = "config"
    
    /// Only really takes 1 argument
    func run(arguments: [Argument]) throws -> Node? {
        if(arguments.count > 0) {
            if let argument = arguments[0].value?.string {
                return drop.config["app", "public", argument]?.node
            }
        }
        
        return nil
    }
}
