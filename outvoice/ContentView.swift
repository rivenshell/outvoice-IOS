//
//  ContentView.swift
//  outvoice
//
//  Created by Riv Sal on 2/15/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject private var navigationState = NavigationState()
    
    // main view
    var body: some View {
        TabView(selection: $navigationState.selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.first)
            InvoiceView()
                .tabItem {
                    Label("Invoice", systemImage: "text.page.fill")
                }
                .tag(Tab.second)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(Tab.third)
        }
//        .padding()
        // active color
        .tint(.green)
        
        .foregroundStyle(.black)
        .environmentObject(navigationState)
    }
}
    
    
    #Preview {
        ContentView()
    }

