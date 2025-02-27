//
//  OnboardingItem.swift
//  outvoice
//
//  Created by Riv Sal on 2/24/25.
//

import Foundation

//data model (for each pageg)
struct OnboardingItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
}

//extension
extension OnboardingItem {
    // defualt onboarding content
    static let defaultItems = [
        OnboardingItem(
            title: "Welcome, founder",
            description: "This is a new world, where you can manage anything",
            imageName: "null"
            ),
        OnboardingItem(
                    title: "Stay Organized",
                    description: "Keep all your tasks in one place",
                    imageName: "onboarding2"
                ),
                OnboardingItem(
                    title: "Get Started",
                    description: "Join us today and boost your productivity",
                    imageName: "onboarding3"
                )
    ]
}
