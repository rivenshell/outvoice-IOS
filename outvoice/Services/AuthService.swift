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
    
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "YOUR_SUPABASE_URL")!,
        supabaseKey: "YOUR_SUPABASE_KEY"
    )
    
    init() {
        Task {
            try? await refreshSession()
        }
    }
    
    func signIn(email: String, password: String) async throws -> User {
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
        try await supabase.auth.signOut()
        await MainActor.run {
            self.currentUser = nil
        }
    }
    
    func getCurrentUser() async throws -> User? {
        if let session = try? await supabase.auth.session, session.isValid {
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
    
    private func fetchUserProfile(userId: String) async throws -> User {
        // Fetch additional user data from your profiles table
        let response = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        let userData = try decoder.decode(User.self, from: response.data)
        return userData
    }
} 