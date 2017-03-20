//
//  LocalizationMiddleware.swift
//  sociabl
//
//  Created by Vetle Økland on 19/03/2017.
//
//

import Vapor
import HTTP


/// Inserts the current user's localization settings into the request for later usage.
class LocalizationMiddleware: Middleware {
    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        // TODO: Actually make this into user-specified setting
        request.storage["localization-language"] = request.lang
    
        return try next.respond(to: request)
    }
}
