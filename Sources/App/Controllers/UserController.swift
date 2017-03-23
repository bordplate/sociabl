//
//  UsersController.swift
//  sociabl
//
//  Created by Vetle Økland on 22/03/2017.
//
//

import Vapor
import HTTP

class UserController: ResourceRepresentable {
    public func index(_ request: Request) throws -> ResponseRepresentable {
        guard let user = try? request.auth.user() as? User else { throw Abort.badRequest }
        
        if let user = user {
            return try user.makeProfileNode().converted(to: JSON.self)
        }
        
        throw Abort.badRequest
    }
    
    public func register(_ request: Request) throws -> ResponseRepresentable {
        guard let json = request.json else { throw Abort.badRequest }
    
        guard let email = json["email"],
            let username = json["username"],
            let password = json["password"]?.string else {
                throw Abort.badRequest
        }
        
        var user: User?
        do {
            user = try User.register(credentials: RegistrationCredentials(
                email: try email.validated(),
                username: try username.validated(),
                password: password)
            ) as? User
        } catch User.Error.usernameTaken {
            return JSON([
                "success": false,
                "error": true,
                "message": "User already taken."
                ])
        } catch User.Error.emailUsed {
            return JSON([
                "success": false,
                "error": true,
                "message": "Email already used."
                ])
        }
        
        try user?.save()
        
        if let user = user {
            return user
        }
        
        throw Abort.serverError
    }
    
    public func show(_ request: Request, user: User) throws -> ResponseRepresentable {
        if let user = user.id {
            if let user = try User.find(user) {
                return try user.makeProfileNode().converted(to: JSON.self)
            }
        }
        
        throw Abort.badRequest
    }
    
    public func makeResource() -> Resource<User> {
        return Resource(index: index,
                        store: register,
                        show: show
                        )
    }
}

extension UserController {
    public func authorize(_ request: Request) throws -> ResponseRepresentable {
        guard let json = request.json else { throw Abort.badRequest }
        
        guard let username = json["username"]?.string, let password = json["password"]?.string else {
            throw Abort.badRequest
        }
        
        do {
            try request.auth.login(UserPassword(username: username, password: password))
        }
        
        if let user = try request.auth.user() as? User {
            return JSON(["success": true, "user": try user.makeProfileNode()])
        }
        
        return JSON(["success": false, "error": true, "message": "An unknown error occured."])
    }
    
    public func timeline(_ request: Request) throws -> ResponseRepresentable {
        if let user = try? request.auth.user() as? User {
            if let timeline = try user?.timeline() {
                return JSON(["posts": timeline])
            }
        }
        
        throw Abort.badRequest
    }
}

extension Request {
    func user() throws -> User {
        guard let json = json else { throw Abort.badRequest }
        return try User(node: json)
    }
}
