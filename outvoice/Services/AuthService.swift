import Foundation
import Supabase

// Protocol for testability and dependency injection
protocol AuthServiceProtocol {
    var currentUser: User? { get }
    var isAuthenticated: Bool { get }
    func signIn(email: String, password: String) async throws -> User
    func signUp(email: String, password: String, firstName: String) async throws -> User
    func signInWithGoogle() async throws -> User
    func signOut() async throws
    func getCurrentUser() async throws -> User?
}

class AuthService: AuthServiceProtocol, ObservableObject {
    @Published var currentUser: User?
    var isAuthenticated: Bool { currentUser != nil }
    
    // Use optional for Supabase client to avoid crashes in previews
    private let supabase: SupabaseClient?
    
    init() {
        // Replace the hard‑coded string with a value from configuration/Info.plist in production.
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3cXZzc2VodG5ldnhtYWxqZmtoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI5MDcxNjQsImV4cCI6MjA1ODQ4MzE2NH0.KXr7lKsLaWu82S5G39MOXIsqaSt-wcbqyCT8zhKDt2g"

        guard let supabaseURL = URL(string: "https://jwqvssehtnevxmaljfkh.supabase.co") else {
            // For previews or development, use a nil client
            print("[AuthService] Invalid Supabase URL – client not initialized.")
            self.supabase = nil
            return
        }

        // Provide a default redirect URL so that auth flows (sign‑up, magic links, OAuth, etc.)
        // always have a valid deep‑link to return to. This must correspond to a URL scheme that
        // is registered in Info.plist (see the `CFBundleURLSchemes` entry).
        let clientOptions = SupabaseClientOptions(
            auth: .init(
                redirectToURL: URL(string: "com.outvoiceios://login-callback")
            )
        )

        self.supabase = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey,
            options: clientOptions
        )

        // Kick‑off a background refresh of any existing session.
        Task {
            try? await refreshSession()
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
    
    func signUp(email: String, password: String, firstName: String) async throws -> User {
        // If Supabase client isn't configured (e.g. previews), return a mock user
        guard let supabase = supabase else {
            let mockUser = User(
                id: UUID(),
                email: email,
                firstName: firstName,
                lastName: "",
                createdAt: Date()
            )
            await MainActor.run {
                self.currentUser = mockUser
            }
            return mockUser
        }
        
        // Attempt to sign up the user with Supabase GoTrue
        // We attach the first name as user metadata so it can be stored in the `profiles` table with the edge function/trigger
        let metadata: [String: AnyJSON] = [
            "first_name": .string(firstName)
        ]
        let _ = try await supabase.auth.signUp(
            email: email,
            password: password,
            data: metadata
        )
        
        // After sign‑up, Supabase automatically authenticates the session. Fetch the user profile just like sign‑in.
        guard let session = try? await supabase.auth.session else {
            throw NSError(domain: "AuthService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve session after sign‑up."])
        }
        
        let user = try await fetchUserProfile(userId: session.user.id)
        await MainActor.run {
            self.currentUser = user
        }
        return user
    }
    
    func signInWithGoogle() async throws -> User {
        guard let supabase = supabase else {
            // Return a mock Google user in preview
            let mockUser = User(
                id: UUID(),
                email: "google_user@example.com",
                firstName: "Google",
                lastName: "User",
                createdAt: Date()
            )
            await MainActor.run {
                self.currentUser = mockUser
            }
            return mockUser
        }
        
        // Launch the OAuth sign‑in flow. The Supabase Swift SDK will handle the deep‑link back into the app automatically.
        let _ = try await supabase.auth.signInWithOAuth(provider: .google)
        
        // After the OAuth flow completes, attempt to get the current session/user.
        guard let session = try? await supabase.auth.session else {
            throw NSError(domain: "AuthService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Google sign‑in did not return a session."])
        }
        
        let user = try await fetchUserProfile(userId: session.user.id)
        await MainActor.run {
            self.currentUser = user
        }
        return user
    }
    
    // MARK: - Deep‑link handling
    /// Call this from the App's `onOpenURL` modifier so that Supabase can
    /// exchange the OAuth redirect code for a session.
    func handleDeepLink(_ url: URL) {
        guard let supabase = supabase else { return }
        Task { try? await supabase.auth.session(from: url) }
    }
} 
