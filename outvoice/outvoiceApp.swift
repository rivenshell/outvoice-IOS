//
//  outvoiceApp.swift
//  outvoice
//
//  Created by Riv Sal on 2/15/25.
//

import SwiftUI

@main
struct outvoiceApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var authService = AuthService()
    @StateObject private var invoiceService: InvoiceService

    init() {
        let authSvc = AuthService()
        _authService = StateObject(wrappedValue: authSvc)
        _invoiceService = StateObject(wrappedValue: InvoiceService(authService: authSvc))
    }


    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(authService)
                .environmentObject(invoiceService)
                .onOpenURL { url in
                    authService.handleDeepLink(url)
                }
        }
    }
}
