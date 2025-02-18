//
//  HomeView.swift
//  outvoice
//
//  Created by Riv Sal on 2/16/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var navigationState: NavigationState
    
    var body: some View {
        NavigationStack(path: $navigationState.firstViewPath) {
            VStack {
                Text("I will add my content here")
                Text("Find a way")
                
                //more content here
            }
//            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeView()
        .environmentObject({
            let state = NavigationState()
            state.selectedTab = .first
            return state
        }())
}
