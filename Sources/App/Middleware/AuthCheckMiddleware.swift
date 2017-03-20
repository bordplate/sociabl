//
//  AuthCheckMiddleware.swift
//  sociabl
//
//  Created by Vetle Økland on 20/03/2017.
//
//

import Vapor
import HTTP

class AuthCheckMiddleware: Middleware {
    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        if let user = try? request.auth.user() as? User {
            request.storage["authorized"] = true
            request.storage["authorized_user"] = try user?.makeEmbedNode()
        }
        
        return try next.respond(to: request)
    }
}
