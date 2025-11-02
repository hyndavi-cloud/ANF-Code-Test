import XCTest
import UIKit
@testable import ANF_Code_Test

final class UIImageViewAsyncExtensionTests: XCTestCase {
    // MARK: - URLProtocol stub
    final class URLProtocolStub: URLProtocol {
        struct Stub { let data: Data?; let response: URLResponse?; let error: Error? }
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
    
    override func setUp() {
        super.setUp()
        // Inject stub protocol globally for URLSession.shared by swizzling protocol classes
        let config = URLSessionConfiguration.default
        var classes = config.protocolClasses ?? []
        classes.insert(URLProtocolStub.self, at: 0)
        URLSessionConfiguration.default.protocolClasses = classes
        URLSessionConfiguration.ephemeral.protocolClasses = classes
        URLSessionConfiguration.background(withIdentifier: "ignored").protocolClasses = classes
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stub = nil
    }
    
    // MARK: - Tests
    func test_setImage_fromLocalAsset_setsImageSynchronously() {
        let imageView = UIImageView()
        imageView.setImage(from: "anf-20160527-app-m-shirts")
        XCTAssertNotNil(imageView.image, "Expected local asset to be set synchronously")
    }
    
    func test_setImage_fromEmptyString_doesNothing() {
        let imageView = UIImageView()
        imageView.image = UIImage() // preset
        imageView.setImage(from: "")
        XCTAssertNil(imageView.image, "Image should remain unchanged for empty input")
    }
    
    func test_setImage_fromInvalidURL_doesNotCrashOrSetImage() {
        let imageView = UIImageView()
        imageView.setImage(from: "ht!tp://bad url")
        // Invalid URL means treated as local name, which will fail to load and keep image nil
        XCTAssertNil(imageView.image)
    }
}
