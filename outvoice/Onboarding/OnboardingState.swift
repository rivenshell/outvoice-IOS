//
//  OnboardingState.swift
//  outvoice
//
//  Created by Riv Sal on 2/24/25.
//

import Foundation

@MainActor
final class OnboardingState: ObservableObject {
    // thy elexr of truth for our onboarding flow
    @Published private(set) var currentPage = 0
    let items: [OnboardingItem]
    
    // fix this
    init(items: [OnboardingItem] = OnboardingItem.defaultItems) {
        self.items = items
    }
    
}
