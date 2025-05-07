//
//  InvoiceView.swift
//  outvoice
//
//  Created by Riv Sal on 2/16/25.
//

//



import SwiftUI
import PDFKit

struct InvoiceView: View {
    @State private var showingAddInvoice = false
    @State private var searchText = ""
    @State private var showingSignIn = false
    
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var invoiceService: InvoiceService
    
    @State private var fetchError: String?
    @State private var operationError: String?
    
    var body: some View {
        NavigationStack {
            VStack {
                AuthHeaderView(showingSignIn: $showingSignIn)
                    .withAuthHeaderStyle()
                    .padding(.top, -120)
                
                if let fetchError = fetchError {
                    Text("Error loading invoices: \(fetchError)")
                        .foregroundColor(.red)
                        .padding()
                } else if invoiceService.invoices.isEmpty && fetchError == nil {
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
            }
            .sheet(isPresented: $showingAddInvoice) {
                AddInvoiceView(onSave: { newInvoice in
                    Task {
                        do {
                            try await invoiceService.addInvoice(newInvoice)
                            showingAddInvoice = false
                            operationError = nil
                        } catch {
                            print("Error adding invoice: \(error)")
                            operationError = "Failed to add invoice: \(error.localizedDescription)"
                        }
                    }
                })
            }
            .sheet(isPresented: $showingSignIn) {
                AuthView(onClose: { showingSignIn = false })
                    .environmentObject(authService)
            }
            .searchable(text: $searchText, prompt: "Search invoices")
        }
        .frame(width: UIScreen.main.bounds.width * 0.90)
        .padding()
        .task(id: authService.currentUser?.id) {
            await loadInvoices()
        }
        .alert("Operation Failed", isPresented: Binding(get: { operationError != nil }, set: { if !$0 { operationError = nil } }), actions: { 
            Button("OK") { operationError = nil }
        }, message: { 
            Text(operationError ?? "An unknown error occurred.")
        })
    }
    
    
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
        let sourceInvoices = invoiceService.invoices
        
        if searchText.isEmpty {
            return sourceInvoices
        } else {
            return sourceInvoices.filter { invoice in
                invoice.clientName.localizedCaseInsensitiveContains(searchText) ||
                invoice.invoiceNumber.localizedCaseInsensitiveContains(searchText) ||
                String(format: "%.2f", invoice.amount).contains(searchText)
            }
        }
    }
    
    private func deleteInvoice(at offsets: IndexSet) {
        Task {
            do {
                try await invoiceService.deleteInvoice(at: offsets)
                operationError = nil
            } catch {
                print("Error deleting invoice: \(error)")
                operationError = "Failed to delete invoice: \(error.localizedDescription)"
            }
        }
    }
    
    private func loadInvoices() async {
        fetchError = nil
        do {
            try await invoiceService.fetchInvoices()
        } catch {
            print("Error fetching invoices in view: \(error)")
            fetchError = error.localizedDescription
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
                DetailRow(label: "Client", value: invoice.clientName, icon: "person.fill")
                DetailRow(label: "Invoice #", value: invoice.invoiceNumber, icon: "number")
            }
            
            Section("Amount") {
                DetailRow(label: "Total", value: "$\(String(format: "%.2f", invoice.amount))", icon: "dollarsign.circle.fill")
                    .bold()
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Status")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(invoice.status.rawValue)
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(statusColor.opacity(0.5), lineWidth: 1)
                        )
                }
                .padding(.vertical, 8)
            } header: {
                Text("Status")
            }
            
            Section("Dates") {
                DetailRow(label: "Due Date", value: formattedDate(invoice.dueDate), icon: "calendar")
                DetailRow(label: "Created On", value: formattedDate(invoice.createdDate), icon: "clock")
            }
            
            Section {
                Button {
                    showingPDFPreview = true
                } label: {
                    HStack {
                        Image(systemName: "doc.text.viewfinder")
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                        Text("Preview PDF")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                
                Button {
                    // PDF download functionality would go here
                } label: {
                    HStack {
                        Image(systemName: "arrow.down.doc.fill")
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                        Text("Download PDF")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                
                Button {
                    // Email/sharing functionality would go here
                } label: {
                    HStack {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                        Text("Send Invoice")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.purple)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            } header: {
                Text("Actions")
            }
        }
        .navigationTitle("Invoice Details")
        .listStyle(InsetGroupedListStyle())
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
    let icon: String?
    
    init(label: String, value: String, icon: String? = nil) {
        self.label = label
        self.value = value
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
            }
            
            Text(label)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
    
    func bold() -> some View {
        return DetailRow(
            label: self.label,
            value: self.value,
            icon: self.icon
        )
        .font(.headline)
    }
}

struct PDFPreviewView: View {
    let invoice: Invoice
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with invoice details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Invoice #\(invoice.invoiceNumber)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(invoice.clientName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text("Amount: $\(String(format: "%.2f", invoice.amount))")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text(invoice.status.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(statusColor.opacity(0.2))
                            .foregroundColor(statusColor)
                            .cornerRadius(8)
                    }
                    .padding(.top, 4)
                }
                .padding()
                .background(Color(.systemGray6))
                
                // PDF Content - Placeholder with better mock display
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Company info
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("FROM")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Your Company Name")
                                    .font(.headline)
                                Text("123 Business Street")
                                Text("City, State 12345")
                                Text("contact@yourcompany.com")
                            }
                            
                            Spacer()
                            
                            Image(systemName: "doc.text.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .foregroundColor(.secondary.opacity(0.3))
                        }
                        .padding(.bottom, 8)
                        
                        Divider()
                        
                        // Client info
                        VStack(alignment: .leading, spacing: 4) {
                            Text("BILL TO")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(invoice.clientName)
                                .font(.headline)
                            Text("Client Address")
                            Text("client@example.com")
                        }
                        .padding(.vertical, 8)
                        
                        Divider()
                        
                        // Invoice details
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("INVOICE #")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(invoice.invoiceNumber)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("DATE")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formattedDate(invoice.createdDate))
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("DUE DATE")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formattedDate(invoice.dueDate))
                            }
                        }
                        .padding(.vertical, 8)
                        
                        Divider()
                        
                        // Invoice items (mocked)
                        VStack(spacing: 0) {
                            HStack {
                                Text("DESCRIPTION")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("QTY")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 50, alignment: .trailing)
                                
                                Text("RATE")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 80, alignment: .trailing)
                                
                                Text("AMOUNT")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 80, alignment: .trailing)
                            }
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            
                            // Example line items
                            ForEach(1...3, id: \.self) { index in
                                HStack {
                                    Text("Service \(index)")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Text("1")
                                        .frame(width: 50, alignment: .trailing)
                                    
                                    Text("$\(String(format: "%.2f", invoice.amount / 3.0))")
                                        .frame(width: 80, alignment: .trailing)
                                    
                                    Text("$\(String(format: "%.2f", invoice.amount / 3.0))")
                                        .frame(width: 80, alignment: .trailing)
                                }
                                .padding(.vertical, 12)
                                .background(index % 2 == 0 ? Color.white : Color(.systemGray6).opacity(0.3))
                            }
                            
                            // Total
                            HStack {
                                Spacer()
                                VStack(alignment: .trailing, spacing: 12) {
                                    HStack {
                                        Text("Subtotal")
                                            .frame(width: 100, alignment: .leading)
                                        Text("$\(String(format: "%.2f", invoice.amount))")
                                            .frame(width: 80, alignment: .trailing)
                                    }
                                    
                                    HStack {
                                        Text("Tax (0%)")
                                            .frame(width: 100, alignment: .leading)
                                        Text("$0.00")
                                            .frame(width: 80, alignment: .trailing)
                                    }
                                    
                                    HStack {
                                        Text("Total")
                                            .fontWeight(.bold)
                                            .frame(width: 100, alignment: .leading)
                                        Text("$\(String(format: "%.2f", invoice.amount))")
                                            .fontWeight(.bold)
                                            .frame(width: 80, alignment: .trailing)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6).opacity(0.5))
                                .cornerRadius(8)
                            }
                            .padding(.top, 20)
                        }
                        
                        Spacer(minLength: 40)
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOTES")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Thank you for your business!")
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationTitle("Invoice PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button {
                            // Share functionality
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        
                        Spacer()
                        
                        Button {
                            // Print functionality
                        } label: {
                            Image(systemName: "printer")
                        }
                        
                        Spacer()
                        
                        Button {
                            // Download functionality
                        } label: {
                            Image(systemName: "arrow.down.doc")
                        }
                    }
                    .padding(.horizontal)
                }
            }
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

// Model Definitions
struct Invoice: Identifiable, Codable {
    let id: UUID
    let clientName: String
    let invoiceNumber: String
    let amount: Double
    let status: InvoiceStatus
    let dueDate: Date
    let createdDate: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case clientName = "client_name"
        case invoiceNumber = "invoice_number"
        case amount
        case status
        case dueDate = "due_date"
        case createdDate = "created_date"
    }
}

enum InvoiceStatus: String, CaseIterable, Identifiable, Codable {
    case draft = "Draft"
    case sent = "Sent"
    case paid = "Paid"
    case overdue = "Overdue"
    
    var id: String { self.rawValue }
}

// Preview provider
#Preview {
    InvoiceView()
        .environmentObject(AuthService(mockUser: User(id: UUID(), email: "preview@example.com", firstName: "Preview", lastName: "User", createdAt: Date())))
        .environmentObject(InvoiceService(mockInvoices: [], authService: MockAuthService()))
}
