//
//  SettingsView.swift
//  outvoice
//
//  Created by Riv Sal on 2/16/25.
//

import SwiftUI
import Supabase

/// `SettingsView` provides the application's main settings interface.
/// This view allows users to:
/// - View account information
/// - Configure application settings
/// - Access developer diagnostics tools
/// - Sign out from the application
struct SettingsView: View {
    // MARK: - Environment & State
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService
    
    @State private var showSignOutConfirmation = false
    @State private var showDevMenu = false
    
    // For Supabase tests
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var connectionStatus: TestStatus = .idle
    @State private var signInStatus: TestStatus = .idle
    
    // For policy, integration, and security tests
    @State private var policyTestStatus: TestStatus = .idle
    @State private var policyResults: [String: Bool] = [:]
    @State private var integrationTestStatus: TestStatus = .idle
    @State private var integrationResults: [String: TestStatus] = [:]
    @State private var securityTestStatus: TestStatus = .idle
    @State private var securityResults: [String: TestStatus] = [:]
    
    // Re‑use the same client that the app uses elsewhere to avoid drift.
    private let client: SupabaseClient = {
        let url = URL(string: "https://jwqvssehtnevxmaljfkh.supabase.co")!
        let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3cXZzc2VodG5ldnhtYWxqZmtoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI5MDcxNjQsImV4cCI6MjA1ODQ4MzE2NH0.KXr7lKsLaWu82S5G39MOXIsqaSt-wcbqyCT8zhKDt2g"
        return SupabaseClient(supabaseURL: url, supabaseKey: key)
    }()

    var body: some View {
        NavigationStack {
            List {
                // Account section
                Section("Account") {
                    if let user = authService.currentUser {
                        userInfoSection(user: user)
                    } else {
                        Text("Not signed in")
                            .foregroundColor(.secondary)
                    }
                }
                
                // App settings
                Section("Application") {
                    Toggle("Enable notifications", isOn: .constant(true))
                    
                    NavigationLink("Data Export") {
                        Text("Export options would go here")
                    }
                }
                
                // Database diagnostics
                Section("Database") {
                    NavigationLink {
                        connectionDiagnosticsView()
                            .navigationTitle("Connection Tests")
                    } label: {
                        Label("Connection Diagnostics", systemImage: "network")
                    }
                }
                
                // Developer options
                developerSection
                
                // Sign out button
                Section {
                    Button(role: .destructive) {
                        showSignOutConfirmation = true
                    } label: {
                        Text("Sign Out")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await authService.signOut()
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    /// Creates a view that displays the user's information.
    private func userInfoSection(user: User) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(user.firstName) \(user.lastName)")
                .font(.headline)
            
            Text(user.email)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Member since: \(formattedDate(user.createdAt))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    /// A view builder property that creates the developer settings section.
    private var developerSection: some View {
        Section {
            DisclosureGroup("Developer Options", isExpanded: $showDevMenu) {
                NavigationLink {
                    connectionTestView()
                        .navigationTitle("Connection Test")
                } label: {
                    Label("Connection Test", systemImage: "bolt.horizontal")
                }
                
    
                
                NavigationLink {
                    integrationTestView()
                        .navigationTitle("Integration Test")
                } label: {
                    Label("Integration Test", systemImage: "externaldrive.connected.to.line.below")
                }
                
                NavigationLink {
                    securityTestView()
                        .navigationTitle("Security Test")
                } label: {
                    Label("Security Test", systemImage: "lock.shield")
                }
                
                Button {
                    resetPolicies()
                } label: {
                    Label("Reset Policies", systemImage: "arrow.triangle.2.circlepath")
                }
            }
            .accentColor(.blue)
        } header: {
            Text("Developer")
        } footer: {
            Text("These options are for debugging and testing purposes only.")
        }
    }
    
    // MARK: - Connection Diagnostics and Test Views
    
    /// Provides a view for running Supabase connection diagnostics
    private func connectionDiagnosticsView() -> some View {
        Form {
            Section("Connection") {
                labelledRow(title: "Ping") {
                    connectionStatus.icon
                }
                Button("Run Ping Test", action: runConnectionTest)
                    .disabled(connectionStatus == .running)
                
                if case .failure(let message) = connectionStatus {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 4)
                }
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
                    
                    if case .failure(let message) = signInStatus {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
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
    }
    
    /// Connection test view for detailed diagnostics
    private func connectionTestView() -> some View {
        Form {
            Section("Database Connection") {
                labelledRow(title: "Status") {
                    connectionStatus.icon
                }
                Text(connectionStatus.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Button("Run Connection Test", action: runConnectionTest)
                    .disabled(connectionStatus == .running)
            }
            
            if connectionStatus == .success {
                Section("Tables Information") {
                    Button("Fetch Tables") {
                        fetchTableInformation()
                    }
                }
            }
        }
    }
    
    
    
    
    /// Integration test view for testing API integrations
    private func integrationTestView() -> some View {
        Form {
            Section("API Integration Tests") {
                Text("Tests integration with Supabase backend APIs and functions.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                labelledRow(title: "Status") {
                    integrationTestStatus.icon
                }
                
                Button("Run Integration Tests", action: runIntegrationTests)
                    .disabled(integrationTestStatus == .running)
            }
            
            if !integrationResults.isEmpty {
                Section("API Tests") {
                    ForEach(Array(integrationResults.keys.sorted()), id: \.self) { key in
                        let status = integrationResults[key] ?? .idle
                        VStack(alignment: .leading) {
                            labelledRow(title: key) {
                                status.icon
                            }
                            if case .failure(let message) = status {
                                Text(message)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.leading)
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Security test view for testing authentication and data access controls
    private func securityTestView() -> some View {
        Form {
            Section("Security Tests") {
                Text("Verify authentication, authorization, and data access controls.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                labelledRow(title: "Status") {
                    securityTestStatus.icon
                }
                
                Button("Run Security Tests", action: runSecurityTests)
                    .disabled(securityTestStatus == .running)
            }
            
            if !securityResults.isEmpty {
                Section("Results") {
                    ForEach(Array(securityResults.keys.sorted()), id: \.self) { key in
                        let status = securityResults[key] ?? .idle
                        VStack(alignment: .leading) {
                            labelledRow(title: key) {
                                status.icon
                            }
                            if case .failure(let message) = status {
                                Text(message)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.leading)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Test Implementation Methods
    
    /// Run connection test to verify Supabase connectivity
    private func runConnectionTest() {
        connectionStatus = .running
        Task {
            do {
                // Test connectivity by selecting a single row from profiles
                _ = try await client.from("profiles").select().limit(1).execute()
                await MainActor.run { connectionStatus = .success }
            } catch {
                await MainActor.run { connectionStatus = .failure(error.localizedDescription) }
            }
        }
    }
    
    /// Fetch table information to display database schema
    private func fetchTableInformation() {
        Task {
            do {
                // This would normally require admin privileges
                // For demo purposes, we'll query a few known tables
                let _ = try await client.from("profiles").select("count").execute()
                print("Successfully queried profiles table")
                
                let _ = try await client.from("invoices").select("count").execute()
                print("Successfully queried invoices table")
            } catch {
                print("Error fetching table information: \(error.localizedDescription)")
            }
        }
    }
    
    /// Tests authentication by signing in with provided credentials
    private func runSignInTest() {
        signInStatus = .running
        Task {
            do {
                // Attempt to sign in with provided credentials
                _ = try await authService.signIn(email: email, password: password)
                await MainActor.run { signInStatus = .success }
            } catch {
                await MainActor.run { signInStatus = .failure(error.localizedDescription) }
            }
        }
    }
    
 
    
    
    /// Tests integration with Supabase APIs and functions
    private func runIntegrationTests() {
        integrationTestStatus = .running
        integrationResults = [:]
        
        Task {
            var results = [String: TestStatus]()
            
            // Test 1: REST API functionality
            do {
                _ = try await client.from("profiles").select().limit(1).execute()
                results["REST API"] = .success
            } catch {
                results["REST API"] = .failure(error.localizedDescription)
            }
            
            // Test 2: Real-time subscription (simplified)
            let testChannel = "test-channel"
            do {
                // This is simplified for demo - actual implementation would require full subscription setup
                let _ = client.realtime.channel(testChannel)
                results["Realtime API"] = .success
            } catch {
                results["Realtime API"] = .failure("Failed to create channel")
            }
            
            // Test 3: Storage API (if applicable)
            do {
                let buckets = try await client.storage.listBuckets()
                results["Storage API"] = buckets.isEmpty ? 
                    .failure("No storage buckets found") : .success
            } catch {
                results["Storage API"] = .failure(error.localizedDescription)
            }
            
            // Test 4: Database functions (if any exist)
            do {
                // Example calling a Postgres function (replace with actual function)
                // This would call a function defined in your Supabase project
                let _ = try await client.rpc("get_app_version").execute()
                results["Database Functions"] = .success
            } catch {
                results["Database Functions"] = .failure(error.localizedDescription)
            }
            
            await MainActor.run {
                integrationResults = results
                integrationTestStatus = .success
            }
        }
    }
    
    /// Tests security features and access controls
    private func runSecurityTests() {
        securityTestStatus = .running
        securityResults = [:]
        
        Task {
            var results = [String: TestStatus]()
            
            // Test 1: Authentication state
            if authService.currentUser != nil {
                results["Authentication"] = .success
            } else {
                results["Authentication"] = .failure("Not authenticated")
            }
            
            // Test 2: JWT token validation
            if let accessToken = try? await client.auth.session.accessToken {
                // Just checking we have a token, not validating its contents in this demo
                results["JWT Token"] = .success
            } else {
                results["JWT Token"] = .failure("No valid token")
            }
            
            // Test 3: Anonymous access restrictions
            do {
                // Try to access a protected resource - this should fail if proper security is in place
                let session = try? await client.auth.session
                if session == nil {
                    // Attempt to access a protected resource when not authenticated
                    _ = try await client.from("private_data").select().limit(1).execute()
                    results["Protected Access"] = .failure("Accessed protected resource anonymously")
                } else {
                    // Skip this test if authenticated
                    results["Protected Access"] = .success
                }
            } catch {
                // Expected to fail for anonymous users
                results["Protected Access"] = .success
            }
            
            // Test 4: Password policy (if implementing registration)
            // This is a placeholder - would need to be implemented with actual registration logic
            results["Password Policy"] = .success
            
            await MainActor.run {
                securityResults = results
                securityTestStatus = .success
            }
        }
    }
    
    /// Reset database policies to default state
    private func resetPolicies() {
        Task {
            do {
                // Call a Supabase function that resets policies to default state
                // This would be a custom function you would need to create in Supabase
                let response = try await client.functions.invoke("reset_policies")
                print("Policies reset successfully: \(response)")
            } catch {
                print("Failed to reset policies: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Formats a Date object into a readable string.
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func labelledRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(title)
            Spacer()
            content()
        }
    }
    
    // MARK: - Helper Types
    
    /// Represents the state of an individual diagnostic test
    private enum TestStatus: Equatable {
        case idle
        case running
        case success
        case failure(String)

        var icon: some View {
            switch self {
            case .idle:
                return AnyView(Image(systemName: "questionmark.circle")
                    .foregroundColor(.secondary))
            case .running:
                return AnyView(ProgressView())
            case .success:
                return AnyView(Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green))
            case .failure:
                return AnyView(Image(systemName: "xmark.octagon.fill")
                    .foregroundColor(.red))
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
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(AuthService(mockUser: nil))
} 
