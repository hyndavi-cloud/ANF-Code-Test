//
//  ExploreViewModel.swift
//  ANF Code Test
//
//  Created by Hyndavi on 11/2/25.
//

import Foundation

@MainActor
class ExploreViewModel: ObservableObject {
    @Published private(set) var cards: [ExploreCard] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    private let repository: ExploreCardRepository
    
    init(repository: ExploreCardRepository) {
        self.repository = repository
    }
    
    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetchedCards = try await repository.fetchCards()
            cards = fetchedCards
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
