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

