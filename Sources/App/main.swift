import Vapor
import VaporMySQL
import Auth

// Prepare Droplet environment
let drop = Droplet()
try drop.addProvider(VaporMySQL.Provider.self)

// Database preparation
drop.preparations = [
    User.self,
    Post.self
]

// Prepare middleware
drop.middleware.append(LocalizationMiddleware())
drop.middleware.append(AuthMiddleware(user: User.self))

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

// Static routes
drop.get() { request in
    return try drop.view.make("welcome", for: request)
}

drop.run() // Wee
