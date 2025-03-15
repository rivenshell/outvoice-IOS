//
//  NavigationState.swift
//  outvoice
//
//  Created by Riv Sal on 2/16/25.
//

import SwiftUI

class NavigationState: ObservableObject {
    @Published var selectedTab: Tab = .second
    
    //add any addition navigation states
    // Explicitly define the navigationPath as a Binding
    @Published var firstViewPath: NavigationPath = NavigationPath()
    @Published var secondViewPath: NavigationPath = NavigationPath()
    @Published var thirdViewPath: NavigationPath = NavigationPath()
}

enum Tab {
    case first
    case second
    case third
}
