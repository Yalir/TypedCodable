
import Foundation

/// To support a new class family, create an enum that conforms to this protocol and contains the different types.
public protocol ClassFamily: Decodable {
    /// The discriminator key.
    static var discriminator: Discriminator { get }
    
    /// Returns the class type of the object coresponding to the value.
    var type: AnyObject.Type { get }
}

/// Discriminator key enum used to retrieve discriminator fields in JSON payloads.
public enum Discriminator: String, CodingKey {
    case type
}

