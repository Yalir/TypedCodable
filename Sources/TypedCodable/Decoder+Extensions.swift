//
//  File.swift
//  
//
//  Created by Ceylo on 08/12/2019.
//

import Foundation

private class ClassWrapper<T: ClassFamily, U: Decodable>: Decodable {
    /// The family enum containing the class information.
    let family: T
    /// The decoded object. Can be any subclass of U.
    let object: U?
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Discriminator.self)
        // Decode the family with the discriminator.
        family = try container.decode(T.self, forKey: T.discriminator)
        // Decode the object by initialising the corresponding type.
        if let type = family.type as? U.Type {
            object = try type.init(from: decoder)
        } else {
            object = nil
        }
    }
}

public extension JSONDecoder {
    /// Decode a heterogeneous list of objects.
    /// - Parameters:
    ///     - family: The ClassFamily enum type to decode with.
    ///     - data: The data to decode.
    /// - Returns: The list of decoded objects.
    func decode<T: ClassFamily, U: Decodable>(family: T.Type, from data: Data) throws -> [U] {
        return try self.decode([ClassWrapper<T, U>].self, from: data).compactMap { $0.object }
    }
}

public extension NSKeyedUnarchiver {
    func decodeDecodableArray<T: ClassFamily, U: Decodable>(family: T.Type, forKey key: String) -> [U]? {
        return self.decodeDecodable([ClassWrapper<T, U>].self, forKey: key)?.compactMap { $0.object }
    }
    
    func decodeDecodable<T: ClassFamily, U: Decodable>(family: T.Type, forKey key: String) -> U? {
        return self.decodeDecodable(ClassWrapper<T, U>.self, forKey: key)?.object
    }
}
