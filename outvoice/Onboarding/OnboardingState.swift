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
        // update
    }
    
    var isLastPage: Bool {
        currentPage == items.count - 1
    }
    // navigating to pages
    func advance() {
        guard currentPage < items.count - 1 else { return }
        currentPage += 1
    }
    
    func goTO(_ page: Int) {
        guard page >= 0 && page < items.count else { return }
        currentPage = page
    }
    
}
