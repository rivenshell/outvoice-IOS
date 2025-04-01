import Foundation
import Supabase

protocol InvoiceServiceProtocol {
    func fetchInvoices() async throws -> [Invoice]
    func createInvoice(_ invoice: Invoice) async throws -> Invoice
    func updateInvoice(_ invoice: Invoice) async throws -> Invoice
    func deleteInvoice(id: UUID) async throws
}

class InvoiceService: InvoiceServiceProtocol {
    private let supabase: SupabaseClient?
    
    init(supabase: SupabaseClient?) {
        self.supabase = supabase
    }
    
    func fetchInvoices() async throws -> [Invoice] {
        guard let supabase = supabase else {
            // For previews or when no client is available, return sample data
            return sampleInvoices
        }
        
        // Fetch invoices from Supabase for the authenticated user
        let response = try await supabase
            .from("invoices")
            .select()
            .order("created_at", ascending: false)
            .execute()
        
        // Decode the response
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        // Map the response data to Invoice objects
        return try decoder.decode([SupabaseInvoice].self, from: response.data).map { supabaseInvoice in
            Invoice(
                id: supabaseInvoice.id,
                clientName: supabaseInvoice.clientName,
                invoiceNumber: supabaseInvoice.invoiceNumber,
                amount: supabaseInvoice.amount,
                status: InvoiceStatus(rawValue: supabaseInvoice.status) ?? .draft,
                dueDate: supabaseInvoice.dueDate,
                createdDate: supabaseInvoice.createdAt
            )
        }
    }
    
    func createInvoice(_ invoice: Invoice) async throws -> Invoice {
        guard let supabase = supabase, let userId = supabase.auth.session?.user.id else {
            // For previews or when no client is available, just return the invoice
            return invoice
        }
        
        // Create a new invoice in Supabase
        let invoiceData: [String: Any] = [
            "user_id": userId.uuidString,
            "client_name": invoice.clientName,
            "invoice_number": invoice.invoiceNumber,
            "amount": invoice.amount,
            "status": invoice.status.rawValue,
            "due_date": ISO8601DateFormatter().string(from: invoice.dueDate),
            "created_at": ISO8601DateFormatter().string(from: invoice.createdDate)
        ]
        
        let response = try await supabase
            .from("invoices")
            .insert(invoiceData)
            .single()
            .execute()
        
        // Decode the response
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        // Map the response data to an Invoice object
        let supabaseInvoice = try decoder.decode(SupabaseInvoice.self, from: response.data)
        return Invoice(
            id: supabaseInvoice.id,
            clientName: supabaseInvoice.clientName,
            invoiceNumber: supabaseInvoice.invoiceNumber,
            amount: supabaseInvoice.amount,
            status: InvoiceStatus(rawValue: supabaseInvoice.status) ?? .draft,
            dueDate: supabaseInvoice.dueDate,
            createdDate: supabaseInvoice.createdAt
        )
    }
    
    func updateInvoice(_ invoice: Invoice) async throws -> Invoice {
        guard let supabase = supabase else {
            // For previews or when no client is available, just return the invoice
            return invoice
        }
        
        // Update an existing invoice in Supabase
        let invoiceData: [String: Any] = [
            "client_name": invoice.clientName,
            "invoice_number": invoice.invoiceNumber,
            "amount": invoice.amount,
            "status": invoice.status.rawValue,
            "due_date": ISO8601DateFormatter().string(from: invoice.dueDate)
        ]
        
        let response = try await supabase
            .from("invoices")
            .update(invoiceData)
            .eq("id", value: invoice.id.uuidString)
            .single()
            .execute()
        
        // Decode the response
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        // Map the response data to an Invoice object
        let supabaseInvoice = try decoder.decode(SupabaseInvoice.self, from: response.data)
        return Invoice(
            id: supabaseInvoice.id,
            clientName: supabaseInvoice.clientName,
            invoiceNumber: supabaseInvoice.invoiceNumber,
            amount: supabaseInvoice.amount,
            status: InvoiceStatus(rawValue: supabaseInvoice.status) ?? .draft,
            dueDate: supabaseInvoice.dueDate,
            createdDate: supabaseInvoice.createdAt
        )
    }
    
    func deleteInvoice(id: UUID) async throws {
        guard let supabase = supabase else {
            // For previews or when no client is available, do nothing
            return
        }
        
        // Delete an invoice from Supabase
        try await supabase
            .from("invoices")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    // Sample invoices for previews and development
    private var sampleInvoices: [Invoice] {
        [
            Invoice(id: UUID(), clientName: "Acme Corp", invoiceNumber: "INV-001", amount: 1500.0, status: .paid, dueDate: Date().addingTimeInterval(86400 * 30), createdDate: Date()),
            Invoice(id: UUID(), clientName: "Wayne Industries", invoiceNumber: "INV-002", amount: 3200.0, status: .sent, dueDate: Date().addingTimeInterval(86400 * 15), createdDate: Date()),
            Invoice(id: UUID(), clientName: "Stark Tech", invoiceNumber: "INV-003", amount: 800.0, status: .draft, dueDate: Date().addingTimeInterval(86400 * 7), createdDate: Date())
        ]
    }
}

// Supabase data model for decoding JSON responses
private struct SupabaseInvoice: Codable {
    let id: UUID
    let userId: UUID
    let clientName: String
    let invoiceNumber: String
    let amount: Double
    let status: String
    let dueDate: Date
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case clientName = "client_name"
        case invoiceNumber = "invoice_number"
        case amount
        case status
        case dueDate = "due_date"
        case createdAt = "created_at"
    }
} 