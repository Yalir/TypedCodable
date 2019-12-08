//
//  File.swift
//  
//
//  Created by Ceylo on 08/12/2019.
//

import Foundation

public protocol TypedEncodable: Encodable {
    func typedEncode(to encoder: Encoder) throws
}

private enum TypedEncodableCodingKeys: String, CodingKey {
    case type
}

public extension TypedEncodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: TypedEncodableCodingKeys.self)
        let typedesc = String(describing: type(of: self))
        try container.encode(typedesc, forKey: .type)
        try self.typedEncode(to: encoder)
    }
}

public protocol TypedCodable: TypedEncodable, Decodable {}
