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
}

if let maxPostLength = drop.config["post", "max-length"]?.int {
    Configuration.maxPostLength = maxPostLength
}

// Set up all collections
drop.collection(LoginCollection())
drop.collection(RegisterCollection())
drop.collection(ProfileCollection())
drop.collection(TimelineCollection())

drop.run() // Wee
