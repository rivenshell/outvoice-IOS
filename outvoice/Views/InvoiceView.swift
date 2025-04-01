//
//  InvoiceView.swift
//  outvoice
//
//  Created by Riv Sal on 2/16/25.
//

//
/*
    Out of dade.
    Current
    V0.1 Q1 2025
    
    New
    V0.2 Q2 2025
    - Add Supabase Auth
    - Add Supabase Database
    - Add Supabase Storage
    - Add Supabase Functions
    - Add Supabase Realtime
    - Add Supabase Edge Functions
    - Add Supabase Notifications
    - Add Supabase Email
    - Add Supabase SMS


 
 */







import SwiftUI
import PDFKit

struct InvoiceView: View {
    @State private var invoices: [Invoice] = []
    @State private var showingAddInvoice = false
    @State private var searchText = ""
    @State private var showingSignIn = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @EnvironmentObject var authService: AuthService
    @StateObject private var invoiceService = InvoiceService(supabase: nil) // Will be initialized in onAppear
    
    var body: some View {
        NavigationStack {
            VStack {
                // Use the reusable component
                AuthHeaderView(showingSignIn: $showingSignIn)
                    .withAuthHeaderStyle()
                    .padding(.top, -120)
                
                if isLoading {
                    ProgressView("Loading invoices...")
                        .padding()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else if invoices.isEmpty {
                    emptyStateView
                } else {
                    invoiceListView
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image("logo-svg")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 200)
                        .foregroundColor(Color(UIColor.label))
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                        .padding(.leading)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if authService.isAuthenticated {
                        Button(action: {
                            showingAddInvoice = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddInvoice) {
                AddInvoiceView(onSave: { newInvoice in
                    addInvoice(newInvoice)
                })
            }
            .sheet(isPresented: $showingSignIn) {
                InvoiceSignInView(onClose: {
                    showingSignIn = false
                    // Refresh invoices after signing in
                    if authService.isAuthenticated {
                        loadInvoices()
                    }
                })
            }
            .searchable(text: $searchText, prompt: "Search invoices")
            .onAppear {
                // Initialize the InvoiceService with the Supabase client from AuthService
                if let supabase = authService.getSupabaseClient() {
                    invoiceService = InvoiceService(supabase: supabase)
                }
                
                // Load invoices when the view appears
                if authService.isAuthenticated {
                    loadInvoices()
                }
            }
        }
        // Adjust width to be 75% of screen width
        .frame(width: UIScreen.main.bounds.width * 0.90)
        .padding()
    }
    
    
    // att "+" button to enable users to add new invoices
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 54))
                .foregroundColor(.gray)
            
            Text("Bummer.. No Invoices")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Create your first invoice by tapping the + button above")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            Button("Create Invoice") {
                showingAddInvoice = true
            }
            .padding()
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.top)
            .bold()
        }
        .padding()
    }
    
    private var invoiceListView: some View {
        List {
            ForEach(filteredInvoices) { invoice in
                NavigationLink(destination: InvoiceDetailView(invoice: invoice)) {
                    InvoiceRowView(invoice: invoice)
                }
            }
            .onDelete(perform: deleteInvoice)
        }
    }
    
    private var filteredInvoices: [Invoice] {
        if searchText.isEmpty {
            return invoices
        } else {
            return invoices.filter { invoice in
                invoice.clientName.localizedCaseInsensitiveContains(searchText) ||
                invoice.invoiceNumber.localizedCaseInsensitiveContains(searchText) ||
                String(format: "%.2f", invoice.amount).contains(searchText)
            }
        }
    }
    
    // MARK: - Data Operations
    
    private func loadInvoices() {
        guard authService.isAuthenticated else {
            invoices = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedInvoices = try await invoiceService.fetchInvoices()
                await MainActor.run {
                    invoices = fetchedInvoices
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load invoices: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func addInvoice(_ invoice: Invoice) {
        // Add the invoice to the local array first for immediate UI feedback
        invoices.append(invoice)
        showingAddInvoice = false
        
        // Save to Supabase
        Task {
            do {
                let savedInvoice = try await invoiceService.createInvoice(invoice)
                await MainActor.run {
                    // Update the local array with the saved invoice (which has the correct ID from Supabase)
                    if let index = invoices.firstIndex(where: { $0.id == invoice.id }) {
                        invoices[index] = savedInvoice
                    }
                }
            } catch {
                print("Error saving invoice: \(error.localizedDescription)")
                // You could show an error message here if desired
            }
        }
    }
    
    private func deleteInvoice(at offsets: IndexSet) {
        // Remove from local array first for immediate UI feedback
        let idsToDelete = offsets.map { invoices[$0].id }
        invoices.remove(atOffsets: offsets)
        
        // Delete from Supabase
        Task {
            for id in idsToDelete {
                do {
                    try await invoiceService.deleteInvoice(id: id)
                } catch {
                    print("Error deleting invoice: \(error.localizedDescription)")
                    // You could show an error message here if desired
                }
            }
        }
    }
}

struct InvoiceRowView: View {
    let invoice: Invoice
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(invoice.clientName)
                    .font(.headline)
                Text("Invoice #\(invoice.invoiceNumber)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(String(format: "%.2f", invoice.amount))")
                    .font(.headline)
                
                HStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    
                    Text(invoice.status.rawValue)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        switch invoice.status {
        case .draft:
            return .gray
        case .sent:
            return .blue
        case .paid:
            return .green
        case .overdue:
            return .red
        }
    }
}

struct AddInvoiceView: View {
    @State private var clientName = ""
    @State private var invoiceNumber = ""
    @State private var amount = ""
    @State private var status = InvoiceStatus.draft
    @State private var dueDate = Date()
    
    @Environment(\.dismiss) private var dismiss
    
    var onSave: (Invoice) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Client Information") {
                    TextField("Client Name", text: $clientName)
                    TextField("Invoice Number", text: $invoiceNumber)
                }
                
                Section("Amount") {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                }
                
                Section("Details") {
                    Picker("Status", selection: $status) {
                        ForEach(InvoiceStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }
            }
            .navigationTitle("New Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newInvoice = Invoice(
                            id: UUID(),
                            clientName: clientName,
                            invoiceNumber: invoiceNumber,
                            amount: Double(amount) ?? 0.0,
                            status: status,
                            dueDate: dueDate,
                            createdDate: Date()
                        )
                        onSave(newInvoice)
                    }
                    .disabled(clientName.isEmpty || invoiceNumber.isEmpty || amount.isEmpty)
                }
            }
        }
    }
}

struct InvoiceDetailView: View {
    let invoice: Invoice
    @State private var showingPDFPreview = false
    
    var body: some View {
        List {
            Section("Client Information") {
                DetailRow(label: "Client", value: invoice.clientName)
                DetailRow(label: "Invoice #", value: invoice.invoiceNumber)
            }
            
            Section("Amount") {
                DetailRow(label: "Total", value: "$\(String(format: "%.2f", invoice.amount))")
            }
            
            Section("Status") {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(invoice.status.rawValue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(8)
                }
            }
            
            Section("Dates") {
                DetailRow(label: "Due Date", value: formattedDate(invoice.dueDate))
                DetailRow(label: "Created On", value: formattedDate(invoice.createdDate))
            }
            
            Section {
                Button("Preview PDF") {
                    showingPDFPreview = true
                }
                
                Button("Download PDF") {
                    // PDF download functionality would go here
                }
                
                Button("Send Invoice") {
                    // Email/sharing functionality would go here
                }
            }
        }
        .navigationTitle("Invoice Details")
        .sheet(isPresented: $showingPDFPreview) {
            PDFPreviewView(invoice: invoice)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private var statusColor: Color {
        switch invoice.status {
        case .draft:
            return .gray
        case .sent:
            return .blue
        case .paid:
            return .green
        case .overdue:
            return .red
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
    }
}

struct PDFPreviewView: View {
    let invoice: Invoice
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("PDF Preview Placeholder")
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Invoice PDF")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Model Definitions
struct Invoice: Identifiable {
    let id: UUID
    let clientName: String
    let invoiceNumber: String
    let amount: Double
    let status: InvoiceStatus
    let dueDate: Date
    let createdDate: Date
}

enum InvoiceStatus: String, CaseIterable, Identifiable {
    case draft = "Draft"
    case sent = "Sent"
    case paid = "Paid"
    case overdue = "Overdue"
    
    var id: String { self.rawValue }
}

// Add the InvoiceSignInView
struct InvoiceSignInView: View {
    @State private var email = ""
    @State private var password = ""
    var onClose: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image("logo-svg")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding(.bottom, 20)
                
                Text("Welcome Back")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Button(action: {
                        // Sign in logic would go here
                        // For now, just close the sheet
                        onClose()
                    }) {
                        Text("Sign In")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                    
                    Button("Forgot Password?") {
                        // Forgot password logic would go here
                    }
                    .foregroundColor(.blue)
                    .padding(.top, 5)
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
                }
            }
        }
    }
}

// Preview provider
#Preview {
    InvoiceView()
        .environmentObject(AuthService(mockUser: nil))
}
