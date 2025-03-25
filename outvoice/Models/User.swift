import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let firstName: String
    let lastName: String
    let createdAt: Date
    
    init(id: UUID, email: String, firstName: String, lastName: String, createdAt: Date) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.createdAt = createdAt
    }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var displayName: String {
        firstName
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case createdAt = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle id as either UUID or String
        if let idString = try? container.decode(String.self, forKey: .id) {
            if let uuid = UUID(uuidString: idString) {
                self.id = uuid
            } else {
                throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Invalid UUID string")
            }
        } else {
            self.id = try container.decode(UUID.self, forKey: .id)
        }
        
        email = try container.decode(String.self, forKey: .email)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
} 