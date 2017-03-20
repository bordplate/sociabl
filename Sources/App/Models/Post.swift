import Vapor
import Fluent
import Foundation

final class Post: Model {
    var id: Node?
    var content: String
    var date: Date
    var user: User?
    
    var exists: Bool = false
    
    init(content: String, date: Date, user: User?) {
        self.id = UUID().uuidString.makeNode()
        self.content = content
        self.date = date
        self.user = user
    }

    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        content = try node.extract("content")
        
        user = try node.extract("user_id") { (userId: Node) throws -> User? in
            return try User.find(userId)
        }
        
        date = try node.extract("date") { (timestamp: Int) -> Date in
            return Date(timeIntervalSince1970: TimeInterval(timestamp))
        }
    }

    func makeNode(context: Context) throws -> Node {
        if let context = context as? Dictionary<String, Bool> {
            if context["public"] == true {
                return try self.makePublicNode()
            }
        }
        
        return try Node(node: [
            "id": id,
            "content": content,
            "date": date.timeIntervalSince1970,
            "user_id": user?.id
        ])
    }
    
    public func makePublicNode() throws -> Node {
        return try Node(node: [
            "id": id,
            "content": content,
            "date": "Nicely formatted date",
            "user": try user?.makeEmbedNode()
        ])
    }
}

extension Post {
    public static func posts(for users: [Node]) throws -> [Post] {
        return try Post.query().filter("user_id", .in, users).sort("date", .descending).all()
    }
}

extension Post: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create("posts") { post in
            post.id()
            post.string("content")
            post.int("date")
            post.parent(User.self, optional: false, unique: false)
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete("posts")
    }
}
