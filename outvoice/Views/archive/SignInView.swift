// LEGACY CODE
// NOT IN PRODUCTION

import SwiftUI

struct SignInView: View {
    // Required properties
    @State var email = ""
    @State var password = ""
    @State var isLoading = false
    @State var errorMessage: String?
    @State private var showingSignUp = false
    
    // Use AuthService directly from the environment
    @EnvironmentObject var authService: AuthService
    
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
                    
                    // NEW: Sign‑in with Google
                    Button(action: signInWithGoogle) {
                        HStack {
                            Image("google-icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 26)
                            Text("Sign In with Google")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)
                    
                    // NEW: Navigate to Sign‑up
                    Button {
                        showingSignUp = true
                    } label: {
                        Text("Don't have an account? Sign Up")
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                    }
                    .disabled(isLoading)
                    
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
            .navigationDestination(for: String.self) { value in
                if value == "signup" {
                    SignUpView(onClose: {
                        // Once sign‑up completes, pop back or close entire sheet
                        onClose()
                    })
                    .environmentObject(authService)
                }
            }
            .sheet(isPresented: $showingSignUp) {
                SignUpView(onClose: {
                    showingSignUp = false
                    onClose()
                })
                .environmentObject(authService)
            }
        }
    }
    
    private func signIn() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Use authService directly
                _ = try await authService.signIn(email: email, password: password)
                await MainActor.run {
                    isLoading = false
                    onClose()
                }
            } catch {
                // Inspect the error to decide if we should navigate to sign‑up
                let errorDesc = error.localizedDescription.lowercased()
                await MainActor.run {
                    isLoading = false
                    if errorDesc.contains("invalid login") || errorDesc.contains("user not found") {
                        // Automatically navigate to sign-up
                        showingSignUp = true
                    } else {
                        errorMessage = "Failed to sign in: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    private func signInWithGoogle() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                _ = try await authService.signInWithGoogle()
                await MainActor.run {
                    isLoading = false
                    onClose()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Google sign‑in failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - View Model
// Remove the entire AuthViewModel class

// MARK: - Previews
struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Default state
            SignInView(onClose: {})
                .previewDisplayName("Default")
                .environmentObject(AuthService(mockUser: nil)) // Provide a mock AuthService for preview
            
            // Loading state
            SignInView(
                email: "user@example.com", 
                password: "password123", 
                isLoading: true,
                onClose: {}
            )
            .previewDisplayName("Loading")
            .environmentObject(AuthService(mockUser: nil)) // Provide a mock AuthService for preview
            
            // Error state
            SignInView(
                email: "user@example.com",
                errorMessage: "Invalid credentials", 
                onClose: {}
            )
            .previewDisplayName("Error")
            .environmentObject(AuthService(mockUser: nil)) // Provide a mock AuthService for preview
        }
    }
} 
