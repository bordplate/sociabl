import Vapor
import VaporMySQL
import Auth

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

// Set up all collections
drop.collection(LoginCollection())
drop.collection(RegisterCollection())
drop.collection(ProfileCollection())
drop.collection(TimelineCollection())

drop.run() // Wee
