//
//  ExploreCardRepository.swift
//  ANF Code Test
//
//  Created by Hyndavi on 11/2/25.
//

import Foundation

protocol ExploreCardRepository {
    func fetchCards() async throws -> [ExploreCard]
}

struct LocalExploreCardRepository: ExploreCardRepository {
    let bundle: Bundle
    let fileName: String
    private let decoder = JSONDecoder()
    
    func fetchCards() async throws -> [ExploreCard] {
        let url = bundle.url(forResource: fileName, withExtension: "json")
        guard let url = url else {
            throw NSError(domain: "LocalExploreCardRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Local file not found"])
        }
        let data = try Data(contentsOf: url)
        let cards = try decoder.decode([ExploreCard].self, from: data)
        return cards
    }
}

struct RemoteExploreCardRepository: ExploreCardRepository {
    let url: URL
    let session: URLSession
    private let decoder = JSONDecoder()
    
    func fetchCards() async throws -> [ExploreCard] {
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "RemoteExploreCardRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
        }
        let cards = try decoder.decode([ExploreCard].self, from: data)
        return cards
    }
}

struct CompositeExploreCardRepository: ExploreCardRepository {
    let primary: ExploreCardRepository
    let fallback: ExploreCardRepository
    
    func fetchCards() async throws -> [ExploreCard] {
        do {
            return try await primary.fetchCards()
        } catch {
            return try await fallback.fetchCards()
        }
    }
}

protocol ImageLoader {
    func imageData(from url: URL) async throws -> Data
}

actor DefaultImageLoader: ImageLoader {
    private var cache: [URL: Data] = [:]
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func imageData(from url: URL) async throws -> Data {
        if let cached = cache[url] {
            return cached
        }
        
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "DefaultImageLoader", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
        }
        cache[url] = data
        return data
    }
}
