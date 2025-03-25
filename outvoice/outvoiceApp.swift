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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(authService)
        }
    }
}
