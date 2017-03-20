//
//  TimelineCollection.swift
//  sociabl
//
//  Created by Vetle Økland on 20/03/2017.
//
//

import Vapor
import Routing
import HTTP

class TimelineCollection: RouteCollection {
    typealias Wrapped = HTTP.Responder
    func build<B: RouteBuilder>(_ builder: B) where B.Value == Wrapped {
        let timeline = builder.grouped("") // We group for root
        
        timeline.get(handler: self.present)
    }
}

extension TimelineCollection {
    public func present(_ request: Request) throws -> ResponseRepresentable {
        if let user = try? request.auth.user() as? User {
            if let timeline = try user?.timeline() {
                return try drop.view.make("timeline", ["posts": timeline], for: request)
            }
        }
        
        return try drop.view.make("welcome", for: request)
    }
}
