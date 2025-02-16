//
//  ContentView.swift
//  outvoice
//
//  Created by Riv Sal on 2/15/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    
    // main view
    var body: some View {
        TabView {
            Image(systemName: "house.fill")
                .imageScale(.large)
                .foregroundStyle(.green)
            
            Text("Home")
                .tabItem{
                    Text("Home")
                }
        }
        .padding()
    }
}
    
    
    #Preview {
        ContentView()
    }

