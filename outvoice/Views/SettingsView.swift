//
//  SettingsView.swift
//  outvoice
//
//  Created by Riv Sal on 2/16/25.
//

import SwiftUI
import Supabase

/// A small dashboard for running basic Supabase diagnostics at runtime.
/// The goal is to help developers (and curious beta‑testers) verify that
/// networking, authentication and basic database access work as expected
/// without opening Xcode's console.
struct SettingsView: View {
    // MARK: – Nested Types
    /// Represents the state of an individual diagnostic test
    private enum TestStatus: Equatable {
        case idle
        case running
        case success
        case failure(String)

        var icon: some View {
            switch self {
            case .idle:
                return Image(systemName: "questionmark.circle")
                    .foregroundColor(.secondary)
            case .running:
                return ProgressView()
            case .success:
                return Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .failure:
                return Image(systemName: "xmark.octagon.fill")
                    .foregroundColor(.red)
            }
        }

        var description: String {
            switch self {
            case .idle: return "Idle"
            case .running: return "Running…"
            case .success: return "Success"
            case .failure(let message): return "Failed – \(message)"
            }
        }
    }

    // MARK: – Environment & State
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService

    // Developer‑supplied credentials for sign‑in test
    @State private var email: String = ""
    @State private var password: String = ""

    @State private var connectionStatus: TestStatus = .idle
    @State private var signInStatus:     TestStatus = .idle

    // Re‑use the same client that the app uses elsewhere to avoid drift.
    // In production you would centralise this in a proper dependency, but
    // for the sake of an isolated testing view we recreate it here.
    private let client: SupabaseClient = {
        let url = URL(string: "https://jwqvssehtnevxmaljfkh.supabase.co")!
        let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3cXZzc2VodG5ldnhtYWxqZmtoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI5MDcxNjQsImV4cCI6MjA1ODQ4MzE2NH0.KXr7lKsLaWu82S5G39MOXIsqaSt-wcbqyCT8zhKDt2g"
        return SupabaseClient(supabaseURL: url, supabaseKey: key)
    }()

    // MARK: – View
    var body: some View {
        Form {
            Section("Connection") {
                labelledRow(title: "Ping") {
                    connectionStatus.icon
                }
                Button("Run Ping Test", action: runConnectionTest)
                    .disabled(connectionStatus == .running)
            }

            Section("Authentication") {
                if authService.currentUser == nil {
                    // Show sign‑in fields when not authenticated
                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $password)
                    labelledRow(title: "Sign‑in Test") {
                        signInStatus.icon
                    }
                    Button("Run Sign‑In Test", action: runSignInTest)
                        .disabled(signInStatus == .running || email.isEmpty || password.isEmpty)
                } else {
                    labelledRow(title: "Current user") {
                        VStack(alignment: .trailing) {
                            Text(authService.currentUser?.email ?? "")
                            Text("Authenticated")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Button("Sign Out") {
                        Task { try? await authService.signOut() }
                    }
                }
            }
        }
        .navigationTitle("Supabase Tests")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    // MARK: – Helpers
    private func labelledRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(title)
            Spacer()
            content()
        }
    }

    private func runConnectionTest() {
        connectionStatus = .running
        Task {
            do {
                _ = try await client.from("profiles").select().limit(1).execute()
                await MainActor.run { connectionStatus = .success }
            } catch {
                await MainActor.run { connectionStatus = .failure(error.localizedDescription) }
            }
        }
    }

    private func runSignInTest() {
        signInStatus = .running
        Task {
            do {
                _ = try await authService.signIn(email: email, password: password)
                await MainActor.run { signInStatus = .success }
            } catch {
                await MainActor.run { signInStatus = .failure(error.localizedDescription) }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(AuthService(mockUser: nil))
} 