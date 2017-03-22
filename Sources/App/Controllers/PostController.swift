import Vapor
import HTTP

final class PostController: ResourceRepresentable {
    func index(request: Request) throws -> ResponseRepresentable {
        return try Post.all().makeNode().converted(to: JSON.self)
    }

    func create(request: Request) throws -> ResponseRepresentable {
        guard
            let user = try request.auth.user() as? User,
            let json = request.json else {
            return try JSON(node: [
                "success": false,
                "message": "An error occured."
                ])
        }
        
        guard let content = json["content"]?.string else {
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

    func show(request: Request, post: Post) throws -> ResponseRepresentable {
        return post
    }

    func delete(request: Request, post: Post) throws -> ResponseRepresentable {
        try post.delete()
        return JSON([:])
    }

    func clear(request: Request) throws -> ResponseRepresentable {
        try Post.query().delete()
        return JSON([])
    }

    func update(request: Request, post: Post) throws -> ResponseRepresentable {
        let new = try request.post()
        var post = post
        post.content = new.content
        try post.save()
        return post
    }

    func replace(request: Request, post: Post) throws -> ResponseRepresentable {
        try post.delete()
        return try create(request: request)
    }

    func makeResource() -> Resource<Post> {
        return Resource(
            index: index,
            store: create,
            show: show,
            replace: replace,
            modify: update,
            destroy: delete,
            clear: clear
        )
    }
}

extension Request {
    func post() throws -> Post {
        guard let json = json else { throw Abort.badRequest }
        return try Post(node: json)
    }
}
