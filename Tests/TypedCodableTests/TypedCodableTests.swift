import XCTest
@testable import TypedCodable

class Pet: TypedCodable {
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
    func testJSONDecoder_decodeHeterogeneousArrayWithoutFamily_Fails() throws {
        let petsJson = """
        [
            { "type": "Cat", "super": { "name": "Garfield" }, "lives": 9 },
            { "type": "Dog", "name": "Pluto" }
        ]
        """

        let petsData = petsJson.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        // Wrongly decoded Pets
        XCTAssertNil(try? decoder.decode([Pet].self, from: petsData))
    }
    
    func testJSONDecoder_decodeHeterogeneousArrayWithFamily_Succeeds() throws {
        let petsJson = """
        [
            { "type": "Cat", "super": { "name": "Garfield" }, "lives": 9 },
            { "type": "Dog", "name": "Pluto" }
        ]
        """
        
        let petsData = petsJson.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let expectedPets = [
            Cat(name: "Garfield", lives: 9),
            Dog(name: "Pluto")
        ]
        
        let actualPets: [Pet] = try decoder.decode(family: PetFamily.self, from: petsData)
        XCTAssertEqual(expectedPets, actualPets)
    }
    
    func testNSArchive_decodeSubclassWithoutFamily_Fails() throws {
        let pet = Cat(name: "Garfield", lives: 9)
                
        let petsArchiver = NSKeyedArchiver(requiringSecureCoding: true)
        try petsArchiver.encodeEncodable(pet, forKey: "Pets")
                
        let petsDecoder = try NSKeyedUnarchiver(forReadingFrom: petsArchiver.encodedData)
        XCTAssertNil(try? petsDecoder.decodeDecodable(Pet.self, forKey: "Pets"))
    }
    
    func testNSArchive_decodeSubclassWithFamily_Succeeds() throws {
        let encodedPet = Cat(name: "Garfield", lives: 9)
        let someOtherCat = Cat(name: "Pluto", lives: 5)
        
        let petsArchiver = NSKeyedArchiver(requiringSecureCoding: true)
        try petsArchiver.encodeEncodable(encodedPet, forKey: "Pets")
        let petsData = petsArchiver.encodedData

        let petsDecoder = try NSKeyedUnarchiver(forReadingFrom: petsData)
        let decodedPet: Pet? = petsDecoder.decodeDecodable(family: PetFamily.self, forKey: "Pets")
        XCTAssertEqual(encodedPet, decodedPet)
        XCTAssertNotEqual(someOtherCat, decodedPet)
    }
    
    func testNSArchive_decodeHeterogeneousArrayWithoutFamily_Fails() throws {
        let pets = [
            Cat(name: "Garfield", lives: 9),
            Dog(name: "Pluto")
        ]
                
        let petsArchiver = NSKeyedArchiver(requiringSecureCoding: true)
        try petsArchiver.encodeEncodable(pets, forKey: "Pets")
                
        let petsDecoder = try NSKeyedUnarchiver(forReadingFrom: petsArchiver.encodedData)
        XCTAssertNil(try? petsDecoder.decodeDecodable([Pet].self, forKey: "Pets"))
    }
    
    func testNSArchive_decodeHeterogeneousArrayWithFamily_Succeeds() throws {
        let encodedPets = [
            Cat(name: "Garfield", lives: 9),
            Dog(name: "Pluto")
        ]
                
        let petsArchiver = NSKeyedArchiver(requiringSecureCoding: true)
        try petsArchiver.encodeEncodable(encodedPets, forKey: "Pets")
        let petsData = petsArchiver.encodedData

        let petsDecoder = try NSKeyedUnarchiver(forReadingFrom: petsData)
        let decodedPets: [Pet]? = petsDecoder.decodeDecodableArray(family: PetFamily.self, forKey: "Pets")
        XCTAssertEqual(encodedPets, decodedPets)
    }
}
