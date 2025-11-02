//
//  ExploreCard.swift
//  ANF Code Test
//
//  Created by Hyndavi on 11/2/25.
//

import Foundation

struct ExploreCard: Codable, Equatable {
    let title: String
    let backgroundImage: String?
    let content: [ExploreContent]?
    let promoMessage: String?
    let topDescription: String?
    let bottomDescription: String?
}

struct ExploreContent: Codable, Equatable {
    let target: String
    let title: String
}
