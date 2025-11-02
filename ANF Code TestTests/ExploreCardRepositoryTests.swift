import XCTest
@testable import ANF_Code_Test

final class ExploreCardRepositoryTests: XCTestCase {
    // MARK: - Helpers
    struct Sample: Codable, Equatable {
        let id: Int
    }
    
    // URLProtocol stub to intercept network calls
    final class URLProtocolStub: URLProtocol {
        struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        static var stub: Stub?
        
        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
        override func startLoading() {
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            } else {
                if let response = URLProtocolStub.stub?.response {
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                }
                if let data = URLProtocolStub.stub?.data {
                    client?.urlProtocol(self, didLoad: data)
                }
                client?.urlProtocolDidFinishLoading(self)
            }
        }
        override func stopLoading() {}
    }
    
    // Create a URLSession that uses our URLProtocolStub
    private func makeStubbedSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: config)
    }
    
    // MARK: - LocalExploreCardRepository
    func test_LocalExploreCardRepository_success_decodesCards() async throws {
        // Arrange: create a temporary json file in a temp bundle-like folder
        let cards: [ExploreCard] = [
            ExploreCard(title: "A", backgroundImage: nil, content: nil, promoMessage: nil, topDescription: nil, bottomDescription: nil),
            ExploreCard(title: "B", backgroundImage: nil, content: nil, promoMessage: nil, topDescription: nil, bottomDescription: nil)
        ]
        let data = try JSONEncoder().encode(cards)
        let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let fileName = "cards_test"
        let fileURL = tmpDir.appendingPathComponent("\(fileName).json")
        try data.write(to: fileURL)
        
        // Create a custom bundle that resolves our temp resource URL
        class TempBundle: Bundle {
            let base: URL
            init(base: URL) { self.base = base; super.init() }
            required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
            override func url(forResource name: String?, withExtension ext: String?) -> URL? {
                guard let name, let ext else { return nil }
                return base.appendingPathComponent("\(name).\(ext)")
            }
        }
        let bundle = TempBundle(base: tmpDir)
        let sut = LocalExploreCardRepository(bundle: bundle, fileName: fileName)
        
        // Act
        let result = try await sut.fetchCards()
        
        // Assert
        XCTAssertEqual(result.map { $0.title }, ["A", "B"]) // minimal verification
    }
    
    func test_LocalExploreCardRepository_missingFile_throws() async {
        let sut = LocalExploreCardRepository(bundle: .main, fileName: "does_not_exist")
        await XCTAssertThrowsErrorAsync(try await sut.fetchCards())
    }
    
    // MARK: - RemoteExploreCardRepository
    func test_RemoteExploreCardRepository_success_decodesCards() async throws {
        let cards: [ExploreCard] = [
            ExploreCard(title: "Remote", backgroundImage: nil, content: nil, promoMessage: nil, topDescription: nil, bottomDescription: nil)
        ]
        let data = try JSONEncoder().encode(cards)
        let url = URL(string: "https://example.com/cards")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        URLProtocolStub.stub = .init(data: data, response: response, error: nil)
        
        let session = makeStubbedSession()
        let sut = RemoteExploreCardRepository(url: url, session: session)
        
        let result = try await sut.fetchCards()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Remote")
    }
    
    func test_RemoteExploreCardRepository_non200_throws() async {
        let url = URL(string: "https://example.com/cards")!
        let response = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!
        URLProtocolStub.stub = .init(data: Data(), response: response, error: nil)
        
        let session = makeStubbedSession()
        let sut = RemoteExploreCardRepository(url: url, session: session)
        
        await XCTAssertThrowsErrorAsync(try await sut.fetchCards())
    }
    
    func test_RemoteExploreCardRepository_networkError_throws() async {
        let url = URL(string: "https://example.com/cards")!
        let err = NSError(domain: "test", code: -1)
        URLProtocolStub.stub = .init(data: nil, response: nil, error: err)
        
        let session = makeStubbedSession()
        let sut = RemoteExploreCardRepository(url: url, session: session)
        
        await XCTAssertThrowsErrorAsync(try await sut.fetchCards())
    }
    
    // MARK: - CompositeExploreCardRepository
    func test_CompositeExploreCardRepository_usesPrimaryOnSuccess() async throws {
        struct Stub: ExploreCardRepository {
            let result: Result<[ExploreCard], Error>
            func fetchCards() async throws -> [ExploreCard] { try result.get() }
        }
        let primary = Stub(result: .success([ExploreCard(title: "P", backgroundImage: nil, content: nil, promoMessage: nil, topDescription: nil, bottomDescription: nil)]))
        let fallback = Stub(result: .success([ExploreCard(title: "F", backgroundImage: nil, content: nil, promoMessage: nil, topDescription: nil, bottomDescription: nil)]))
        let sut = CompositeExploreCardRepository(primary: primary, fallback: fallback)
        
        let result = try await sut.fetchCards()
        XCTAssertEqual(result.first?.title, "P")
    }
    
    func test_CompositeExploreCardRepository_fallsBackOnPrimaryFailure() async throws {
        struct Stub: ExploreCardRepository {
            let result: Result<[ExploreCard], Error>
            func fetchCards() async throws -> [ExploreCard] { try result.get() }
        }
        enum E: Error { case fail }
        let primary = Stub(result: .failure(E.fail))
        let fallback = Stub(result: .success([ExploreCard(title: "F", backgroundImage: nil, content: nil, promoMessage: nil, topDescription: nil, bottomDescription: nil)]))
        let sut = CompositeExploreCardRepository(primary: primary, fallback: fallback)
        
        let result = try await sut.fetchCards()
        XCTAssertEqual(result.first?.title, "F")
    }
}

// MARK: - Async Throws helper
@inline(__always)
func XCTAssertThrowsErrorAsync<T>(_ expression: @autoclosure @escaping () async throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) async {
    do {
        _ = try await expression()
        XCTFail(message(), file: file, line: line)
    } catch {
        // Success
    }
}
