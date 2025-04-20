import SwiftUI

/// A single, unified authentication sheet that lets users toggle between
/// “Sign In” and “Sign Up” without spawning additional sheets.
struct AuthView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case signIn = "Sign In"
        case signUp = "Sign Up"
        var id: Self { self }
    }

    // MARK: – State
    @State private var mode: Mode = .signIn

    @State private var email       = ""
    @State private var firstName   = ""   // Only used during sign‑up
    @State private var password    = ""
    @State private var isLoading   = false
    @State private var errorMessage: String?

    // MARK: – Environment
    @EnvironmentObject private var authService: AuthService
    @Environment(\.dismiss)       private var dismiss

    // Callback after successful auth or when user taps “Cancel”.
    var onClose: () -> Void = {}

    // Custom init so callers (e.g. previews) can set the initial mode.
    init(mode: Mode = .signIn, onClose: @escaping () -> Void = {}) {
        _mode = State(initialValue: mode)
        self.onClose = onClose
    }

    // MARK: – Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Logo
                Image("logo-svg")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding(.bottom, 8)

                // Mode picker (Sign In / Sign Up)
                Picker("Authentication Mode", selection: $mode) {
                    ForEach(Mode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Error message
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Form
                Group {
                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .disableAutocorrection(true)

                    if mode == .signUp {
                        TextField("First Name", text: $firstName)
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                    }

                    SecureField("Password", text: $password)
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
                .disabled(isLoading)
                .textInputAutocapitalization(.never)

                // Primary button (Sign In / Sign Up)
                Button(action: handlePrimaryAction) {
                    HStack {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text(mode == .signIn ? "Sign In" : "Sign Up")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(isLoading ? 0.7 : 1))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(disablePrimaryButton)
                .padding(.top)

                // Google auth (works for both modes)
                Button(action: signInWithGoogle) {
                    HStack {
                        Image("google-icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                        Text("Continue with Google")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(10)
                }
                .disabled(isLoading)

                // Forgot password (only in sign‑in mode)
                if mode == .signIn {
                    Button("Forgot Password?") {
                        // Placeholder for future implementation
                    }
                    .foregroundColor(.blue)
                    .disabled(isLoading)
                    .padding(.top, 4)
                }

                Spacer()
            }
            .padding()
            .navigationTitle(mode.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { close() }
                        .disabled(isLoading)
                }
            }
        }
    }

    // MARK: – Helpers
    private var disablePrimaryButton: Bool {
        switch mode {
        case .signIn:
            return email.isEmpty || password.isEmpty || isLoading
        case .signUp:
            return email.isEmpty || firstName.isEmpty || password.isEmpty || isLoading
        }
    }

    private func handlePrimaryAction() {
        switch mode {
        case .signIn: signIn()
        case .signUp: signUp()
        }
    }

    private func signIn() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                _ = try await authService.signIn(email: email, password: password)
                await MainActor.run { finish() }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to sign in: \(error.localizedDescription)"
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
                await MainActor.run { finish() }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to sign up: \(error.localizedDescription)"
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
                await MainActor.run { finish() }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Google authentication failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func finish() {
        isLoading = false
        close()
    }

    private func close() {
        // If the view was presented via sheet we should call dismiss();
        // otherwise the parent can choose to listen via `onClose`.
        dismiss()
        onClose()
    }
}

// MARK: – Previews
struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AuthView()
                .environmentObject(AuthService(mockUser: nil))
                .previewDisplayName("Sign In")

            AuthView(mode: .signUp)
                .environmentObject(AuthService(mockUser: nil))
                .previewDisplayName("Sign Up")
        }
    }
} 