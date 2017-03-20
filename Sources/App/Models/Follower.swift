//
//  Follower.swift
//  sociabl
//
//  Created by Vetle Økland on 20/03/2017.
//
//

import Vapor
import Fluent

final class Follower: Model {
    var id: Node?
    
    var owner: Node? // The person who follows
    var subject: Node? // The person who is being followed
    
    var exists: Bool = false
    
    init(owner: Node?, subject: Node?) {
        self.owner = owner
        self.subject = subject
    }
    
    init(node: Node, in context: Context) throws {
        self.id = try node.extract("id")
        self.owner = try node.extract("owner")
        self.subject = try node.extract("subject")
    }
    
    public func makeNode(context: Context) throws -> Node {
        if let context = context as? Dictionary<String, Bool> {
            if context["subjects_only"] == true {
                return subject ?? 0
            }
        }
        
        return try Node(node: [
            "id": id,
            "owner": owner,
            "subject": subject
        ])
    }
}

extension Follower {
    public static func subjects(for owner: Node) throws -> Node? {
        return try Follower.query().filter("owner", owner).all().makeNode(context: ["subjects_only": true])
    }
}

extension Follower: Preparation {
    public static func prepare(_ database: Database) throws {
        try database.create("followers") { follower in
            follower.id()
            follower.parent(idKey: "owner")
            follower.parent(idKey: "subject")
        }
    }
    
    public static func revert(_ database: Database) throws {
        try database.delete("followers")
    }
}
