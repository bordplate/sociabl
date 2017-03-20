//
//  LoginCollection.swift
//  sociabl
//
//  Created by Vetle Økland on 20/03/2017.
//
//

import Vapor
import Routing
import HTTP
import Auth

class LoginCollection: RouteCollection {
    typealias Wrapped = HTTP.Responder
    func build<B: RouteBuilder>(_ builder: B) where B.Value == Wrapped {
        let login = builder.grouped("login")
        
        login.get(handler: self.present)
        login.post(handler: self.process)
    }
    
    /*!
     * @discussion Just returns the login page, always.
     * @param request Incoming request
     * @return Login leaf
     */
    func present(request: Request) throws -> ResponseRepresentable {
        return try drop.view.make("login", for: request)
    }
    
    /*!
     * @discussion Processes post request from incoming login.
     * @param request Incoming request
     * @return Stuff
     */
    func process(request: Request) throws -> ResponseRepresentable {
        guard let username = request.data["username"]?.string, let password = request.data["password"]?.string else {
            return try drop.view.make("login", [
                "invalid": true
                ], for: request)
        }
        
        do {
            try request.auth.login(UserPassword(username: username, password: password))
        } catch User.Error.invalidCredentials {
            return try drop.view.make("login", ["invalid": true, "username": username], for: request)
        }
        
        return Response(redirect: "/")
    }
}
