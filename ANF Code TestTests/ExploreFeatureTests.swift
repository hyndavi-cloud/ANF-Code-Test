import XCTest
@testable import ANF_Code_Test

final class ExploreViewModelTests: XCTestCase {
    
    struct StubRepo: ExploreCardRepository {
        let result: Result<[ExploreCard], Error>
        
        func fetchCards() async throws -> [ExploreCard] {
            return try result.get()
        }
    }
    
    @MainActor
    func testLoadSuccess() async {
        let cards = [
            ExploreCard(
                title: "Title",
                backgroundImage: nil,
                content: nil,
                promoMessage: nil,
                topDescription: nil,
                bottomDescription: nil
            )
        ]
        let repo = StubRepo(result: .success(cards))
        let viewModel = ExploreViewModel(repository: repo)
        
        await viewModel.load()
        
        XCTAssertEqual(viewModel.cards, cards)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testLoadFailure() async {
        struct TestError: Error {}
        let repo = StubRepo(result: .failure(TestError()))
        let viewModel = ExploreViewModel(repository: repo)
        
        await viewModel.load()
        
        XCTAssertTrue(viewModel.cards.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }
}
