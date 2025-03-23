//
//  InvoiceView.swift
//  outvoice
//
//  Created by Riv Sal on 2/16/25.
//

import SwiftUI
import PDFKit

struct InvoiceView: View {
    @State private var invoices: [Invoice] = []
    @State private var showingAddInvoice = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                // Add greeting under logo
                Text("Hi, User")
                    .font(.system(size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, invoices.isEmpty ? 160 : 20)
                
                if invoices.isEmpty {
                    emptyStateView
                } else {
                    invoiceListView
                }
            }
            // .padding(.top)
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
                    invoices.append(newInvoice)
                    showingAddInvoice = false
                })
            }
            .searchable(text: $searchText, prompt: "Search invoices")
        }
        // Adjust width to be 75% of screen width
        .frame(width: UIScreen.main.bounds.width * 0.85)
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
            .background(Color.green)
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
    
    private func deleteInvoice(at offsets: IndexSet) {
        invoices.remove(atOffsets: offsets)
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

// Preview provider
#Preview {
    InvoiceView()
}
