//
//  User.swift
//  sociabl
//
//  Created by Vetle Økland on 16/03/2017.
//
//

import Foundation
import Vapor
import Fluent
import Auth
import Random

/// Social network user.
final class User: Model {
    enum Error: Swift.Error {
        case invalidCredentials
        case usernameTaken
        case emailUsed
        
        case postExceedsMaxLength
        
        case alreadyFollowing
        case notFollowing
    }
    
    var id: Node?
    var email: String
    var username: String
    var password: String
    var salt: String
    var displayName: String
    var profileDescription: String
    var profileImgUrl: String
    var joinDate: Date
    
    var exists: Bool = false
    
    init(email: String, username: String, password: String, salt: String, displayName: String, profileDescription: String, profileImgUrl: String, joinDate: Date) {
        self.id = UUID().uuidString.makeNode()
        self.email = email
        self.username = username
        self.password = password
        self.salt = salt
        self.displayName = displayName
        self.profileDescription = profileDescription
        self.profileImgUrl = profileImgUrl
        self.joinDate = joinDate
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        email = try node.extract("email")
        username = try node.extract("username")
        password = try node.extract("password")
        salt = try node.extract("salt")
        displayName = try node.extract("display_name")
        profileDescription = try node.extract("profile_description")
        profileImgUrl = try node.extract("profile_img_url")
        
        // Database stores the date as Unix-style timestamp, so we convert that to a `Date`
        joinDate = try node.extract("join_date") { (timestamp: Int) throws -> Date in
            return Date(timeIntervalSince1970: TimeInterval(timestamp))
        }
    }
    
    /**
     ## Discussion
     It feels dangerous to return the password here,
     even though it's hashed.
     */
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "email": email,
            "username": username,
            "password": password,
            "salt": salt,
            "display_name": displayName,
            "profile_description": profileDescription,
            "profile_img_url": profileImgUrl,
            "join_date": joinDate.timeIntervalSince1970 // Convert Date to Unix timestamp
        ])
    }
    
    /// Use this for when making a Node that should be displayed as a profile.
    func makeProfileNode() throws -> Node {
        return try Node(node: [
            "id": id,
            "username": username,
            "display_name": displayName,
            "profile_description": profileDescription,
            "profile_img_url": profileImgUrl,
            "join_date": joinDate.timeIntervalSince1970,
            "post_count": try self.postCount(),
            "like_count": try self.likeCount(),
            "following_count": try self.followingCount(),
            "follower_count": try self.followerCount(),
            "posts": try self.posts().makeNode(context: ["public": true])
        ])
    }
    
    /// For when a user should be embedded in e.g. a post.
    func makeEmbedNode() throws -> Node {
        return try Node(node: [
            "id": id,
            "username": username,
            "display_name": displayName,
            "profile_img_url": profileImgUrl
        ])
    }
    
    /// Returns the timeline for the user.
    func timeline() throws -> Node? {
        if let id = self.id {
            if var subjects = try Follower.subjects(for: id)?.nodeArray {
                if let id = self.id { subjects += id } // To see your own posts in the timeline as well.
                return try Post.posts(for: subjects).makeNode(context: ["public": true])
            }
        }
        
        return nil
    }
}

// - Interactions with other users
extension User {
    /**
     Follows provided subject given valid credentials.
     
     ## Discusion
     This probably should have some sort of check to see that the subject
        does not have a private profile, if that ever becomes a thing.
     
     - parameters:
        - subject: The user of the user to follow.
     */
    public func follow(user subject: User) throws {
        if try self.isFollowing(user: subject) {
            throw Error.alreadyFollowing
        }
        
        var followerRelationship = Follower(owner: self.id, subject: subject.id)
        try followerRelationship.save()
    }
    
    public func unfollow(user subject: User) throws {
        guard let subjectId = subject.id else {
            throw Abort.badRequest
        }
        
        if let relation = try self.children("owner", Follower.self).filter("subject", subjectId).first() {
            try relation.delete()
        } else {
            throw Error.notFollowing
        }
    }
    
    public func submit(post content: String) throws {
        if content.count > Configuration.maxPostLength {
            throw Error.postExceedsMaxLength
        }
        
        var post = Post(content: content, date: Date(), user: self)
        try post.save()
    }
    
    public func isFollowing(user subject: User) throws -> Bool {
        guard let subjectId = subject.id else {
            throw Abort.badRequest
        }
        
        if try self.children("owner", Follower.self).filter("subject", subjectId).count() > 0 {
            return true
        }
        
        return false
    }
}

extension User {
    public func postCount() throws -> Int {
        return try self.children(nil, Post.self).count()
    }
    
    public func likeCount() throws -> Int {
        return 0
    }
    
    public func followingCount() throws -> Int {
        return try self.children("owner", Follower.self).count()
    }
    
    public func followerCount() throws -> Int {
        return try self.children("subject", Follower.self).count()
    }
    
    public func posts() throws -> [Post] {
        return try self.children(nil, Post.self).all()
    }
}

extension User: Preparation {
    /// Mostly useful when setting up app on new system
    public static func prepare(_ database: Database) throws {
        try database.create("users") { user in
            user.id()
            user.string("email")
            user.string("username")
            user.string("password")
            user.string("salt")
            user.string("display_name")
            user.string("profile_description")
            user.string("profile_img_url")
            user.int("join_date")
        }
    }

    /// Called when you do a `vapor <something> revert` from a terminal.
    public static func revert(_ database: Database) throws {
        try database.delete("users");
    }
}

extension User: Auth.User {
    // TODO: Erh... Should salt and pepper passwords...
    static func authenticate(credentials: Credentials) throws -> Auth.User {
        var user: User?
        
        switch credentials {
        case let creds as UserPassword:
            let passwordHash = try drop.hash.make(creds.password)
            user = try User.query().filter("username", creds.username).filter("password", passwordHash).first()
        case let id as Identifier:
            user = try User.find(id.id)
        default:
            throw Abort.custom(status: .badRequest, message: "Malformed request")
        }
        
        guard let u = user else {
            throw Error.invalidCredentials
        }
        
        return u
    }
    
    static func register(credentials: Credentials) throws -> Auth.User {
        guard let registration = credentials as? RegistrationCredentials else {
            throw Error.invalidCredentials
        }

        if try User.query().filter("username", registration.username.value).count() > 0 {
            throw Error.usernameTaken
        }
        
        if try User.query().filter("email", registration.email.value).count() > 0 {
            throw Error.emailUsed
        }
        
        let password = try drop.hash.make(registration.password)
        let salt = "Totally random salt" //try URandom.bytes(count: 24).string()
        
        var user = User(email: registration.email.value,
                        username: registration.username.value,
                        password: password,
                        salt: salt,
                        displayName: registration.username.value,
                        profileDescription: "",
                        profileImgUrl: "",
                        joinDate: Date())
        
        try user.save()
        
        return user
    }
}

class UserPassword: Credentials {
    public let username: String
    public let password: String
    
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

// TODO: Validation for password as well.  
class RegistrationCredentials: Credentials {
    public let email: Valid<Email>
    public let username: Valid<OnlyAlphanumeric>
    public let password: String
    
    public init(email: Valid<Email>, username: Valid<OnlyAlphanumeric>, password: String) {
        self.email = email
        self.username = username
        self.password = password
    }
}
