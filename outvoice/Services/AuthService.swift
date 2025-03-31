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
    
    init() {
        // Safe initialization with proper error handling
        if let supabaseURL = URL(string: "YOUR_SUPABASE_URL"),
           !supabaseURL.absoluteString.contains("YOUR_SUPABASE_URL") {
            self.supabase = SupabaseClient(
                supabaseURL: supabaseURL,
                supabaseKey: "YOUR_SUPABASE_KEY"
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
        
        let session = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        
        let user = try await fetchUserProfile(userId: session.user.id)
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
        
        if let session = try? await supabase.auth.session {
            // Session exists, we'll consider it valid
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
        
        // Fetch additional user data from your profiles table
        let response = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)  // Convert to string only for the database query
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        let userData = try decoder.decode(User.self, from: response.data)
        return userData
    }
} 
