// LEGACY CODE
// NOT IN PRODUCTION

import SwiftUI

struct SignUpView: View {
    @State private var email = ""
    @State private var firstName = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Environment
    @EnvironmentObject var authService: AuthService
    
    // Callback when the sheet should be dismissed
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
                
                Text("Create Account")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Error message
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .disabled(isLoading)
                    
                    TextField("First Name", text: $firstName)
                        .autocapitalization(.words)
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
                    
                    // Sign‑up button
                    Button(action: signUp) {
                        HStack {
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Sign Up")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(isLoading ? 0.7 : 1.0))
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                    }
                    .disabled(email.isEmpty || firstName.isEmpty || password.isEmpty || isLoading)
                    .padding(.top)
                    
                    // Sign‑up with Google
                    Button(action: signUpWithGoogle) {
                        HStack {
                            Image("google-icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 26)
                            Text("Sign Up with Google")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.black))
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Sign Up")
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
    }
    
    private func signUp() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                _ = try await authService.signUp(email: email, password: password, firstName: firstName)
                await MainActor.run {
                    isLoading = false
                    onClose()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to sign up: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func signUpWithGoogle() {
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
                    errorMessage = "Google sign‑up failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    SignUpView(onClose: {})
        .environmentObject(AuthService(mockUser: nil))
} 