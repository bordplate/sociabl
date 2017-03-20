//
//  RegisterCollection.swift
//  sociabl
//
//  Created by Vetle Økland on 20/03/2017.
//
//

import Vapor
import Routing
import HTTP
import Auth

class RegisterCollection: RouteCollection {
    typealias Wrapped = HTTP.Responder
    func build<B: RouteBuilder>(_ builder: B) where B.Value == Wrapped {
        let register = builder.grouped("register")
        
        register.get(handler: self.present)
        register.post(handler: self.process)
    }
}

// Get requests
extension RegisterCollection {
    func present(request: Request) throws -> ResponseRepresentable {
        return try drop.view.make("register", for: request)
    }
}

// Post requests
extension RegisterCollection {
    func process(request: Request) throws -> ResponseRepresentable {
        // TODO: Fix up these error message and make them localizable.
        guard let username = request.data["username"]?.string else {
            return try drop.view.make("register",
                                      ["invalid": true, "message": "Invalid username, only alphanumeric please."],
                                      for: request)
        }
        
        guard let email = request.data["email"]?.string else {
            return try drop.view.make("register",
                                      ["invalid": true, "message": "Invalid email, don't be stupid."],
                                      for: request)
        }
        
        guard let password = request.data["password"]?.string else {
            return try drop.view.make("register",
                                      ["invalid": true, "message": "Invalid password or something."],
                                      for: request)
        }
        
        let registrationCredentials: RegistrationCredentials
        
        do {
            registrationCredentials = RegistrationCredentials(email: try email.validated(), username: try username.validated(), password: password)
        } catch let error as ValidationErrorProtocol {
            return try drop.view.make("register",
                                      ["invalid": true, "message": error.message],
                                      for: request)
        }
        
        do {
            _ = try User.register(credentials: registrationCredentials)
        } catch User.Error.emailUsed {
            return try drop.view.make("register",
                                      ["invalid": true, "message": "Email already used"],
                                      for: request)
        } catch User.Error.usernameTaken {
            return try drop.view.make("register",
                                      ["invalid": true, "message": "Username already used"],
                                      for: request)
        }
        
        // If we're here, then we probably made it through the process
        return try drop.view.make("register", for: request)
    }
}
