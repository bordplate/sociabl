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
        login.post(User.self, "unfollow", handler: self.unfollow)
        login.post(String.self, "post", handler: self.post)
    }
}

extension ProfileCollection {
    public func present(_ request: Request, username: String) throws -> ResponseRepresentable {
        guard let user = try User.query().filter("username", username).first() else {
            throw Abort.notFound
        }
        if let loggedUser = try? request.auth.user() as? User {
            let isFollowing = try? loggedUser?.isFollowing(user: user) ?? false
            
            return try drop.view.make("profile", ["user": try user.makeProfileNode(), "following": isFollowing ?? false], for: request)
        } else {
            return try drop.view.make("profile", ["user": try user.makeProfileNode()], for: request)
        }
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
        
        do {
            try user.follow(user: subject)
        } catch User.Error.alreadyFollowing {
            return try JSON(node: [
                "success": false,
                "message": "You are already following this person."
            ])
        }
        
        return try JSON(node: [
            "success": true
        ])
    }
    
    public func unfollow(_ request: Request, subject: User) throws -> ResponseRepresentable {
        guard let user = try request.auth.user() as? User else {
            return try JSON(node: [
                "success": false,
                "message": "You are not logged in."
            ])
        }
        
        do {
            try user.unfollow(user: subject)
        } catch User.Error.notFollowing {
            return try JSON(node: [
                "success": false,
                "message": "You can't unfollow someone you're not following."
                ])
        }
        
        return try JSON(node: [
            "success": true
        ])
    }
    
    /// Username doesn't really matter here, it's just for prettying up links and stuff
    ///     (and reserve less usernames.
    public func post(_ request: Request, username: String) throws -> ResponseRepresentable {
        guard let user = try request.auth.user() as? User else {
            return try JSON(node: [
                "success": false,
                "message": "An error occured."
            ])
        }
        
        guard let content = request.data["content"]?.string else {
            return try JSON(node: [
                "success": false,
                "message": "No content was received by the server."
            ])
        }
        
        do {
            try user.submit(post: content)
        } catch User.Error.postExceedsMaxLength {
            return try JSON(node: [
                "success": false,
                "message": "The post was too long."
            ])
        }
        
        return try JSON(node: [
            "success": true
        ])
    }
}
