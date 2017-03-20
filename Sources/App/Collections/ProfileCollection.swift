//
//  ProfileCollection.swift
//  sociabl
//
//  Created by Vetle Økland on 20/03/2017.
//
//

import Vapor
import Routing
import HTTP

class ProfileCollection: RouteCollection {
    typealias Wrapped = HTTP.Responder
    func build<B: RouteBuilder>(_ builder: B) where B.Value == Wrapped {
        let login = builder.grouped("") // We group for root
        
        login.get(String.self, handler: self.present)
        
        login.post(User.self, "follow", handler: self.follow)
    }
}

extension ProfileCollection {
    public func present(_ request: Request, username: String) throws -> ResponseRepresentable {
        if let user = try User.query().filter("username", username).first() {
            return try drop.view.make("profile", ["user": try user.makeProfileNode()], for: request)
        }
        
        throw Abort.notFound
    }
}

extension ProfileCollection {
    // TODO: Stuff like this needs some CSRF-mitigation
    public func follow(_ request: Request, subject: User) throws -> ResponseRepresentable {
        guard let user = try request.auth.user() as? User else {
            return try JSON(node: [
                "success": false,
                "message": "You are not logged in."
            ])
        }
        
        try user.followUser(subject: subject)
        
        return try JSON(node: [
            "success": true
        ])
    }
}
