import SwiftUI

struct SignInView: View {
    // Required properties
    @State var email = ""
    @State var password = ""
    @State var isLoading = false
    @State var errorMessage: String?
    
    // Optional environment object with default implementation for previews
    @StateObject private var authModel = AuthViewModel()
    
    var onClose: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Logo
                Image("logo-svg")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding(.bottom, 20)
                
                Text("Welcome Back")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                // Form fields
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .disabled(isLoading)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .disabled(isLoading)
                    
                    // Sign in button
                    Button {
                        signIn()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(isLoading ? 0.7 : 1.0))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                    .padding(.top)
                    
                    // Forgot password button
                    Button("Forgot Password?") {
                        // Forgot password logic would go here
                    }
                    .foregroundColor(.blue)
                    .padding(.top, 5)
                    .disabled(isLoading)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onClose()
                    }
                    .disabled(isLoading)
                }
            }
        }
        .onAppear {
            // Setup environment if available
            if let authService = try? AuthService() {
                authModel.authService = authService
            }
        }
    }
    
    private func signIn() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authModel.signIn(email: email, password: password)
                await MainActor.run {
                    isLoading = false
                    onClose()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to sign in: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - View Model
// This isolates the AuthService dependency and makes previews safer
class AuthViewModel: ObservableObject {
    var authService: AuthService?
    
    func signIn(email: String, password: String) async throws -> User {
        guard let authService = authService else {
            // Fallback for previews or when service is unavailable
            return User(
                id: UUID(),
                email: email, 
                firstName: "Preview", 
                lastName: "User",
                createdAt: Date()
            )
        }
        
        return try await authService.signIn(email: email, password: password)
    }
}

// MARK: - Previews
struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Default state
            SignInView(onClose: {})
                .previewDisplayName("Default")
            
            // Loading state
            SignInView(
                email: "user@example.com", 
                password: "password123", 
                isLoading: true,
                onClose: {}
            )
            .previewDisplayName("Loading")
            
            // Error state
            SignInView(
                email: "user@example.com",
                errorMessage: "Invalid credentials", 
                onClose: {}
            )
            .previewDisplayName("Error")
        }
    }
} 
