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
    
    init() {
        // Configure the appearance of inactive tab items
        UITabBar.appearance().unselectedItemTintColor = UIColor.darkGray
    }
    
    // main view
    var body: some View {
        TabView(selection: $navigationState.selectedTab) {
            HomeView()
                .tabItem {
                    Label {
                        Text("Home")
                    } icon: {
                        Image(systemName: "house")
                    }
                }
                .tag(Tab.first)
            // disables home
                .opacity(0.1)   // Make it look disabled
                .onChange(of: navigationState.selectedTab) { oldValue, newValue in
                        if newValue == .first {
                            // Redirect to Invoice tab
                            navigationState.selectedTab = .second
                            }
                        }
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
        
        .tint(.green)
        .environmentObject(navigationState)
    }
}
    
    
    #Preview {
        ContentView()
    }

