import XCTest
@testable import TypedCodable

class Pet: TypedCodable {
    /// The name of the pet.
    let name: String
    
    init(name: String) {
        self.name = name
    }
    
    enum CodingKeys: String, CodingKey {
        case name
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
    }
    
    func typedEncode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
    }
}

extension Pet: Equatable {
    static func == (lhs: Pet, rhs: Pet) -> Bool {
        lhs.name == rhs.name
    }
}

class Cat: Pet {
    /// A cat can have a maximum of 9 lives.
    var lives: Int
    
    init(name: String, lives: Int) {
        self.lives = lives
        super.init(name: name)
    }
    
    enum CatCodingKeys: String, CodingKey {
        case lives
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CatCodingKeys.self)
        lives = try container.decode(Int.self, forKey: .lives)
        try super.init(from: container.superDecoder())
    }
    
    override func typedEncode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CatCodingKeys.self)
        try super.typedEncode(to: container.superEncoder())
        try container.encode(lives, forKey: .lives)
    }
}

extension Cat {
    static func == (lhs: Cat, rhs: Cat) -> Bool {
        lhs.lives == rhs.lives && lhs as Pet == rhs as Pet
    }
}

class Dog: Pet {
    override init(name: String) {
        super.init(name: name)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    func fetch() { /**/ }
}

/// The PetFamily enum describes the Pet family of objects.
enum PetFamily: String, ClassFamily {
    case pet = "Pet"
    case cat = "Cat"
    case dog = "Dog"
    
    static var discriminator: Discriminator = .type
    
    var type: AnyObject.Type {
        switch self {
        case .cat: return Cat.self
        case .dog: return Dog.self
        case .pet: return Pet.self
        }
    }
}

final class TypedCodableTests: XCTestCase {
    func testJSON() throws {
        let petsJson = """
        [
            { "type": "Cat", "super": { "name": "Garfield" }, "lives": 9 },
            { "type": "Dog", "name": "Pluto" }
        ]
        """

        if let petsData = petsJson.data(using: .utf8) {
            let decoder = JSONDecoder()
            
            // Wrongly decoded Pets
            let pets1 = try? decoder.decode([Pet].self, from: petsData)
            print("Wrongly decoded pets: \(pets1)") // Prints [Pet, Pet]
            
            // Correctly decoded Pets
            let pets2: [Pet] = try decoder.decode(family: PetFamily.self, from: petsData)
            print("Correctly decoded pets: \(pets2)") // Prints [Cat, Dog]
        }
    }
    
    func testNSArchive() throws {
        let pets = [
            Cat(name: "Garfield", lives: 9),
            Dog(name: "Pluto")
        ]
                
        let petsArchiver = NSKeyedArchiver(requiringSecureCoding: true)
        try petsArchiver.encodeEncodable(pets, forKey: "Pets")
        let petsData = petsArchiver.encodedData
                
        // Wrongly decoded Pets
        let petsDecoder1 = try NSKeyedUnarchiver(forReadingFrom: petsData)
        let pets1 = try? petsDecoder1.decodeDecodable([Pet].self, forKey: "Pets")
        XCTAssertNil(pets1)

        // Correctly decoded Pets
        let petsDecoder2 = try NSKeyedUnarchiver(forReadingFrom: petsData)
        let pets2: [Pet]? = petsDecoder2.decodeDecodable(family: PetFamily.self, forKey: "Pets")
        XCTAssertEqual(pets, pets2)
    }
}
