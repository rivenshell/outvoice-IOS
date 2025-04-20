import Foundation
import Supabase

// Protocol for testability and dependency injection
protocol InvoiceServiceProtocol {
    var invoices: [Invoice] { get }
    func fetchInvoices() async throws
    func addInvoice(_ invoice: Invoice) async throws
    func deleteInvoice(at offsets: IndexSet) async throws
    // Potentially add updateInvoice later
}

// Define potential errors
enum InvoiceServiceError: Error {
    case supabaseClientNotInitialized
    case fetchFailed(Error)
    case addFailed(Error)
    case deleteFailed(Error)
    case decodeFailed(Error)
    case unexpectedResponse
}

class InvoiceService: InvoiceServiceProtocol, ObservableObject {
    @Published private(set) var invoices: [Invoice] = []
    
    // Use optional for Supabase client to avoid crashes in previews
    private let supabase: SupabaseClient?
    
    // Assume we need the AuthService to get the current user's ID for filtering invoices
    private let authService: AuthServiceProtocol

    // Initializer for the real service
    init(authService: AuthServiceProtocol) {
        self.authService = authService
        
        // Fix 1: Correct if-let structure
        // Check if URL is valid first.
        if let supabaseURL = URL(string: "https://jwqvssehtnevxmaljfkh.supabase.co") {
            // The key is a non-optional String, assign it directly.
            let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3cXZzc2VodG5ldnhtYWxqZmtoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI5MDcxNjQsImV4cCI6MjA1ODQ4MzE2NH0.KXr7lKsLaWu82S5G39MOXIsqaSt-wcbqyCT8zhKDt2g"
            self.supabase = SupabaseClient(
                supabaseURL: supabaseURL,
                supabaseKey: supabaseKey
            )
        } else {
            // If URL was invalid, supabase remains nil.
            print("Error: Invalid Supabase URL string.")
            self.supabase = nil
            // Load mock data if initialization failed
            loadMockData() // Fix 2: Call is now okay because loadMockData won't be @MainActor
        }
        
        // If supabase is still nil after the above check (e.g., URL was invalid)
        // ensure mock data is loaded if needed (this might be redundant now but safe)
        if self.supabase == nil && self.invoices.isEmpty { 
             print("Warning: Supabase client not initialized. Using mock InvoiceService.")
             loadMockData() // Call is okay here too
        }
    }
    
    // Convenience initializer for mocking and previews
    init(mockInvoices: [Invoice] = [], authService: AuthServiceProtocol = MockAuthService()) {
        self.invoices = mockInvoices
        self.supabase = nil
        self.authService = authService
        if mockInvoices.isEmpty { 
            loadMockData() // Fix 3: Call is okay because loadMockData won't be @MainActor
        }
    }
    
    // --- Protocol Methods ---

    @MainActor // Ensure updates to @Published var happen on the main thread
    func fetchInvoices() async throws {
        guard let supabase = supabase else {
            print("Using mock fetchInvoices.")
            // If using mock data, it's likely already loaded in init.
            // If you need to simulate async fetching for mocks, add a delay.
            // try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            return // No real fetching if client is nil
        }
        
        // Ensure we have a logged-in user to filter invoices
        guard let userId = authService.currentUser?.id else {
            print("No authenticated user found. Clearing invoices.")
            self.invoices = []
            return // Or throw an error if fetching requires authentication
        }

        do {
            // Fetch invoices associated with the current user
            // Assuming your 'invoices' table has a 'user_id' column matching the auth user ID
            let fetchedInvoices: [Invoice] = try await supabase
                .from("invoices") // Replace "invoices" with your actual table name
                .select() // Select all columns (*)
                .eq("user_id", value: userId.uuidString) // Filter by user ID
                .order("created_date", ascending: false) // Example: order by creation date
                .execute()
                .value
                
            self.invoices = fetchedInvoices
        } catch {
            print("Error fetching invoices: \(error)")
            throw InvoiceServiceError.fetchFailed(error)
        }
    }

    @MainActor
    func addInvoice(_ invoice: Invoice) async throws {
        guard let supabase = supabase else {
            print("Using mock addInvoice.")
            // Add to mock data locally
            invoices.insert(invoice, at: 0) // Add to beginning like fetch might
            return
        }
        
         // Ensure we have a logged-in user to associate the invoice
        guard let userId = authService.currentUser?.id else {
            print("No authenticated user found. Cannot add invoice.")
             throw InvoiceServiceError.addFailed(NSError(domain: "InvoiceService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
        }

        // You might need a separate Codable struct for insertion
        // if the `Invoice` struct contains read-only fields (like `id` if generated by DB)
        // or if you need to add the user_id.
        struct InsertableInvoice: Codable {
            var client_name: String
            var invoice_number: String
            var amount: Double
            var status: String // Assuming status is stored as rawValue String
            var due_date: Date
            var created_date: Date
            var user_id: UUID // Add user_id for association
        }
        
        let insertable = InsertableInvoice(
            client_name: invoice.clientName,
            invoice_number: invoice.invoiceNumber,
            amount: invoice.amount,
            status: invoice.status.rawValue,
            due_date: invoice.dueDate,
            created_date: invoice.createdDate,
            user_id: userId
        )

        do {
            // Insert and then fetch the newly created row to get the DB-generated ID, etc.
            let addedInvoice: Invoice = try await supabase
                .from("invoices")
                .insert(insertable, returning: .representation) // Use 'representation' to get the full row back
                .select() // Select all columns of the new row
                .single() // Expecting a single row back
                .execute()
                .value
            
            // Add to the local array
            invoices.insert(addedInvoice, at: 0) // Or re-fetch all
        } catch {
            print("Error adding invoice: \(error)")
            throw InvoiceServiceError.addFailed(error)
        }
    }

    @MainActor
    func deleteInvoice(at offsets: IndexSet) async throws {
         guard let supabase = supabase else {
            print("Using mock deleteInvoice.")
            // Delete from mock data locally
            invoices.remove(atOffsets: offsets)
            return
        }

        // Get the IDs of the invoices to delete
        let idsToDelete = offsets.map { invoices[$0].id }

        // Don't proceed if there's nothing to delete
        guard !idsToDelete.isEmpty else { return }

        do {
            try await supabase
                .from("invoices")
                .delete()
                .in("id", values: idsToDelete.map { $0.uuidString }) // Match based on UUID strings
                .execute()

            // Remove from the local array upon successful deletion
            invoices.remove(atOffsets: offsets)
        } catch {
            print("Error deleting invoice(s): \(error)")
            throw InvoiceServiceError.deleteFailed(error)
        }
    }
    
    // --- Mock Data ---
    
    // Fix 2 & 3: Remove @MainActor from loadMockData
    private func loadMockData() {
        // Populate with some sample data for previews/development
        self.invoices = [
            Invoice(id: UUID(), clientName: "Mock Client A", invoiceNumber: "MOCK-001", amount: 120.50, status: .paid, dueDate: Calendar.current.date(byAdding: .day, value: -10, to: Date())!, createdDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())!),
            Invoice(id: UUID(), clientName: "Mock Client B", invoiceNumber: "MOCK-002", amount: 350.00, status: .sent, dueDate: Calendar.current.date(byAdding: .day, value: 15, to: Date())!, createdDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!),
            Invoice(id: UUID(), clientName: "Mock Client C", invoiceNumber: "MOCK-003", amount: 99.99, status: .overdue, dueDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, createdDate: Calendar.current.date(byAdding: .day, value: -40, to: Date())!),
            Invoice(id: UUID(), clientName: "Another Company Inc.", invoiceNumber: "MOCK-004", amount: 1500.00, status: .draft, dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!, createdDate: Date()),
        ]
    }
}

// Mock AuthService for InvoiceService previews/tests if needed
class MockAuthService: AuthServiceProtocol {
    var currentUser: User? = User(id: UUID(), email: "mock@example.com", firstName: "Mock", lastName: "User", createdAt: Date()) // Provide a mock user
    var isAuthenticated: Bool { currentUser != nil }
    func signIn(email: String, password: String) async throws -> User { fatalError("Not implemented for mock") }
    func signUp(email: String, password: String, firstName: String) async throws -> User { fatalError("Not implemented for mock") }
    func signInWithGoogle() async throws -> User { fatalError("Not implemented for mock") }
    func signOut() async throws { fatalError("Not implemented for mock") }
    func getCurrentUser() async throws -> User? { currentUser }
}

// Helper to decode Supabase dates which might be in ISO8601 format with fractional seconds
extension JSONDecoder {
    static let supabaseDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try different ISO8601 formats Supabase might use
            let formatters = [
                ISO8601DateFormatter(), // Standard ISO8601
                { // ISO8601 with fractional seconds
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    return formatter
                }(),
            ]
            
            for formatter in formatters {
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
        return decoder
    }()
} 