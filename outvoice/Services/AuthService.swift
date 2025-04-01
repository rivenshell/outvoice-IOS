import Foundation
import Supabase

// Protocol for testability and dependency injection
protocol AuthServiceProtocol {
    var currentUser: User? { get }
    var isAuthenticated: Bool { get }
    func signIn(email: String, password: String) async throws -> User
    func signOut() async throws
    func getCurrentUser() async throws -> User?
}

class AuthService: AuthServiceProtocol, ObservableObject {
    @Published var currentUser: User?
    var isAuthenticated: Bool { currentUser != nil }
    
    // Use optional for Supabase client to avoid crashes in previews
    private let supabase: SupabaseClient?
    
    // Add a method to access the Supabase client
    func getSupabaseClient() -> SupabaseClient? {
        return supabase
    }
    
    init() {
        // Load credentials from a configuration plist file
        if let supabaseConfig = loadSupabaseConfig(),
           let urlString = supabaseConfig["SUPABASE_URL"] as? String,
           let key = supabaseConfig["SUPABASE_KEY"] as? String,
           let url = URL(string: urlString),
           !key.isEmpty {
            
            self.supabase = SupabaseClient(
                supabaseURL: url,
                supabaseKey: key
            )
            
            // Only refresh session if we have a valid client
            Task {
                try? await refreshSession()
            }
        } else {
            // For previews or development, use nil client
            self.supabase = nil
        }
    }
    
    // Load Supabase configuration from plist
    private func loadSupabaseConfig() -> [String: Any]? {
        // Try to load from SupabaseConfig.plist first (not in version control)
        if let path = Bundle.main.path(forResource: "SupabaseConfig", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path) as? [String: Any] {
            return config
        }
        
        // Fallback to Info.plist for development/previews
        guard let infoDictionary = Bundle.main.infoDictionary else {
            return nil
        }
        
        let config: [String: Any] = [
            "SUPABASE_URL": infoDictionary["SUPABASE_URL"] as? String ?? "",
            "SUPABASE_KEY": infoDictionary["SUPABASE_KEY"] as? String ?? ""
        ]
        
        return config
    }
    
    // Convenience initializer for mocking and previews
    init(mockUser: User? = nil) {
        self.currentUser = mockUser
        self.supabase = nil
    }
    
    func signIn(email: String, password: String) async throws -> User {
        guard let supabase = supabase else {
            // For preview/testing, return mock user
            let mockUser = User(
                id: UUID(),
                email: email,
                firstName: "Preview",
                lastName: "User",
                createdAt: Date()
            )
            await MainActor.run {
                self.currentUser = mockUser
            }
            return mockUser
        }
        
        // Call Supabase Auth API to sign in
        let authResponse = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        
        // Fetch the user's profile from the profiles table
        let user = try await fetchUserProfile(userId: authResponse.user.id)
        
        // Update the current user on the main thread
        await MainActor.run {
            self.currentUser = user
        }
        
        return user
    }
    
    func signOut() async throws {
        guard let supabase = supabase else {
            // For preview/testing, just clear current user
            await MainActor.run {
                self.currentUser = nil
            }
            return
        }
        
        try await supabase.auth.signOut()
        await MainActor.run {
            self.currentUser = nil
        }
    }
    
    func getCurrentUser() async throws -> User? {
        guard let supabase = supabase else {
            // Just return the current mock user for previews
            return currentUser
        }
        
        // Check if there's an active session
        if let session = try? await supabase.auth.session {
            // Session exists, fetch the user profile
            let user = try await fetchUserProfile(userId: session.user.id)
            await MainActor.run {
                self.currentUser = user
            }
            return user
        }
        
        return nil
    }
    
    private func refreshSession() async throws {
        _ = try? await getCurrentUser()
    }
    
    private func fetchUserProfile(userId: UUID) async throws -> User {
        guard let supabase = supabase else {
            throw NSError(domain: "AuthService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Supabase client not initialized"])
        }
        
        // Fetch the user's profile from the profiles table
        let response = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
        
        // Decode the response into a User object
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        let userData = try decoder.decode(User.self, from: response.data)
        return userData
    }
    
    // Function to create a new user (sign up)
    func signUp(email: String, password: String, firstName: String, lastName: String) async throws -> User {
        guard let supabase = supabase else {
            // For preview/testing, return mock user
            let mockUser = User(
                id: UUID(),
                email: email,
                firstName: firstName,
                lastName: lastName,
                createdAt: Date()
            )
            await MainActor.run {
                self.currentUser = mockUser
            }
            return mockUser
        }
        
        // Create a new user in Supabase Auth
        let authResponse = try await supabase.auth.signUp(
            email: email,
            password: password
        )
        
        // Update the user's profile with first and last name
        try await supabase
            .from("profiles")
            .update([
                "first_name": firstName,
                "last_name": lastName
            ])
            .eq("id", value: authResponse.user.id.uuidString)
            .execute()
        
        // Fetch the complete user profile
        let user = try await fetchUserProfile(userId: authResponse.user.id)
        
        // Update the current user on the main thread
        await MainActor.run {
            self.currentUser = user
        }
        
        return user
    }
} 
