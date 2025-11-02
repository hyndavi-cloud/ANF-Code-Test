//
//  ANF_Code_TestTests.swift
//  ANF Code TestTests
//


import XCTest
@testable import ANF_Code_Test

class ANFExploreCardTableViewControllerTests: XCTestCase {

    var testInstance: ANFExploreCardTableViewController!
    
    @MainActor
    override func setUp() {
        super.setUp()
        // Instantiate controller from storyboard
        testInstance = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateInitialViewController() as? ANFExploreCardTableViewController
        // Load data from exploredata.json bundled with the app
        let jsonURL: URL = {
            guard let url = Bundle.main.url(forResource: "exploreData", withExtension: "json") else {
                XCTFail("Missing exploreData.json in main bundle")
                // Provide a temporary empty file URL to satisfy compiler; test will fail above
                return URL(fileURLWithPath: "/dev/null")
            }
            return url
        }()
        let jsonData: Data = {
            do { return try Data(contentsOf: jsonURL) } catch {
                XCTFail("Failed to read exploreData.json: \(error)")
                return Data()
            }
        }()
        let stubCards: [ExploreCard] = {
            do {
                let decoder = JSONDecoder()
                return try decoder.decode([ExploreCard].self, from: jsonData)
            } catch {
                XCTFail("Failed to decode exploreData.json into [ExploreCard]: \(error)")
                return []
            }
        }()
        // Stub repository matching protocol
        struct StubExploreCardRepository: ExploreCardRepository {
            let cards: [ExploreCard]
            func fetchCards() async throws -> [ExploreCard] { return cards }
        }
        // Inject stubbed view model (main-actor safe)
        let stubRepo = StubExploreCardRepository(cards: stubCards)
        testInstance.viewModel = ExploreViewModel(repository: stubRepo)
        // Force view to load and trigger table setup
        _ = testInstance.view
        // Load stub data and reload table synchronously on main actor
        let exp = expectation(description: "Load stub data")
        Task { @MainActor in
            await testInstance.viewModel?.load()
            testInstance.tableView.reloadData()
            exp.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func test_numberOfSections_ShouldBeOne() {
        let numberOfSections = testInstance.numberOfSections(in: testInstance.tableView)
        XCTAssert(numberOfSections == 1, "table view should have 1 section")
    }
    
    func test_numberOfRows_ShouldBeTen() {
        let numberOfRows = testInstance.tableView(testInstance.tableView, numberOfRowsInSection: 0)
        XCTAssert(numberOfRows == 10, "table view should have 10 cells")
    }
    
    func test_cellForRowAtIndexPath_titleText_shouldNotBeBlank() {
        let firstCell = testInstance.tableView(testInstance.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        let title = firstCell.viewWithTag(1) as? UILabel
        XCTAssert(title?.text?.count ?? 0 > 0, "title should not be blank")
    }
    
    func test_cellForRowAtIndexPath_ImageViewImage_shouldNotBeNil() {
        let firstCell = testInstance.tableView(testInstance.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        let imageView = firstCell.viewWithTag(2) as? UIImageView
        XCTAssert(imageView?.image != nil, "image view image should not be nil")
    }
}

