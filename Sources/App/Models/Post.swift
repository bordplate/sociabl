import Vapor
import Fluent
import Foundation

final class Post: Model {
    var id: Node?
    var content: String
    var date: Date
    var userId: Node?
    
    var exists: Bool = false
    
    init(content: String, date: Date, userId: Node?) {
        self.id = UUID().uuidString.makeNode()
        self.content = content
        self.date = date
        self.userId = userId
    }

    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        content = try node.extract("content")
        userId = try node.extract("user_id")
        
        date = try node.extract("date") { (timestamp: Int) -> Date in
            return Date(timeIntervalSince1970: TimeInterval(timestamp))
        }
    }

    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "content": content,
            "date": date.timeIntervalSince1970,
            "user_id": userId
        ])
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
