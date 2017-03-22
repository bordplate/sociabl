import Vapor
import VaporMySQL
import Auth
import Foundation

// Prepare Droplet environment
let drop = Droplet()
try drop.addProvider(VaporMySQL.Provider.self)

// Database preparation
drop.preparations = [
    User.self,
    Post.self,
    Follower.self
]

// Prepare middleware
drop.middleware.append(LocalizationMiddleware())
drop.middleware.append(AuthMiddleware(user: User.self))
drop.middleware.append(AuthCheckMiddleware())

// Register our custom renderer
// The custom renderer will inject user-variables when relevant
let renderer = Renderer()
drop.view = renderer

// Register a custom leaf-tag so we can get config-values
//   from a leaf.
renderer.stem.register(ConfigurationTag())
renderer.stem.register(LocalizationTag())

// Register some globals from the configuration
// TODO: This is a dirty way to set globals, there is a more "Swifty" way to do it
struct Configuration {
    static var maxPostLength = 150
    
    static var useAPI = true
    static var APIHost = ""
}

Configuration.maxPostLength = drop.config["app", "post", "max-length"]?.int ?? Configuration.maxPostLength
Configuration.useAPI        = drop.config["app", "api", "activated"]?.bool ?? Configuration.useAPI
Configuration.APIHost       = drop.config["app", "api", "host"]?.string ?? Configuration.APIHost


// Set up all collections
drop.collection(LoginCollection())
drop.collection(RegisterCollection())
drop.collection(ProfileCollection())
drop.collection(TimelineCollection())

if Configuration.useAPI {
    let api = drop.grouped(host: Configuration.APIHost).grouped("v1")
    
    let userController = UserController()
    let postController = PostController()
    
    api.resource("post", postController)
    api.resource("user", userController)
    
    api.post("auth", handler: userController.authorize)
    
    api.get("timeline", handler: userController.timeline)
}

drop.run() // Wee
