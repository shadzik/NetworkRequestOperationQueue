//
//  NetworkRequestOperationQueueTests.swift
//  NetworkRequestOperationQueueTests
//
//  Created by Bartosz on 05/12/2023.
//

import XCTest
@testable import NetworkRequestOperationQueue
@testable import OHHTTPStubsSwift
@testable import OHHTTPStubs

struct TestError: Error {
    let msg: String
    let code: HTTPCode
}

enum HTTPCode: Int32 {
    case success = 200
    case noContent = 204
    case unauthorized = 401
    case timeout = 408
}

class NetworkRequestTestErrorMapper: NetworkRequestErrorMapper {
    func map(error: Error) -> Error {
        let myError = TestError(msg: "", code: .timeout)
        return myError
    }
}

final class NetworkRequestOperationQueueTests: XCTestCase {

    var operationQueue: NetworkRequestOperationQueue?

    override func setUpWithError() throws {
        operationQueue = NetworkRequestOperationQueue()
        operationQueue?.maxConcurrentOperationCount = 1
    }

    override func tearDownWithError() throws {
        operationQueue = nil
    }

    func testAddOperationToQueue() {
        guard let url = URL(string: "/testAddOperationToQueue") else { return }

        let jsonObject: [String: String] = [
            "operation": url.absoluteString
        ]

        stub { request in
            return request.url?.relativePath == url.absoluteString
        } response: { request in
            return HTTPStubsResponse(jsonObject: jsonObject, statusCode: HTTPCode.success.rawValue, headers: nil)
        }

        let expectation = expectation(description: "testAddOperationToQueue")

        let request = DefaultNetworkRequest(url: url, method: .get) { request, headers, response, error in
            if let retVal = response as? [String: Any],
               let ret = retVal["operation"] as? String {
                if ret == url.absoluteString {
                    expectation.fulfill()
                }
            }
        }

        operationQueue?.addRequest(request)

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    // Test adding multiple requests to operation queue
    func testAddMultipleOperationsToQueue() {
        guard let url = URL(string: "/testAddOperationToQueue") else { return }

        let jsonObject: [String: String] = [
            "operation": url.absoluteString
        ]

        stub { request in
            return request.url?.relativePath == url.absoluteString
        } response: { request in
            return HTTPStubsResponse(jsonObject: jsonObject, statusCode: HTTPCode.success.rawValue, headers: nil)
        }

        operationQueue?.isSuspended = true

        var expectations: [XCTestExpectation] = []

        for int in 0..<4 {
            let expectationName = "testAddMultipleOperationsToQueue_\(int)"
            let expectation = expectation(description: expectationName)

            let request = DefaultNetworkRequest(url: url, method: .get, parameters: ["paramNumber": int]) { request, headers, response, error in
                if let retVal = response as? [String: Any],
                   let ret = retVal["operation"] as? String {
                    if ret == url.absoluteString {
                        expectation.fulfill()
                    }
                }
            }
            request.priority = .default

            expectations.append(expectation)
            operationQueue?.addRequest(request)
        }

        operationQueue?.isSuspended = false


        wait(for: expectations, timeout: 5, enforceOrder: true)
    }

    // Test adding multiple requests to operation queue
    // with sorting by priority (last one has highest priority and should be executed first)
    func testAddMultipleOperationsToQueueLastBeingFirst() {
        guard let url = URL(string: "/testAddMultipleOperationsToQueueLastBeingFirst") else { return }

        let jsonObject: [String: String] = [
            "operation": url.absoluteString
        ]

        stub { request in
            return request.url?.relativePath == url.absoluteString
        } response: { request in
            return HTTPStubsResponse(jsonObject: jsonObject, statusCode: HTTPCode.success.rawValue, headers: nil)
        }


        operationQueue?.isSuspended = true

        var expectations: [XCTestExpectation] = []

        for int in 0..<4 {
            let expectationName = "testAddMultipleOperationsToQueueLastBeingFirst_\(int)"
            let expectation = expectation(description: expectationName)

            let request = DefaultNetworkRequest(url: url, method: .get, parameters: ["paramNumber": int]) { request, headers, response, error in
                if let retVal = response as? [String: Any],
                   let ret = retVal["operation"] as? String {
                    if ret == url.absoluteString {
                        expectation.fulfill()
                    }
                }
            }
            if int == 3 {
                request.priority = .highest
                expectations.insert(expectation, at: 0)
            } else {
                expectations.append(expectation)
            }

            operationQueue?.addRequest(request)
        }

        operationQueue?.isSuspended = false


        wait(for: expectations, timeout: 5, enforceOrder: true)
    }

    // Test adding multiple requests to operation queue
    // the first one being delayed by 2 seconds so it should be executed last
    func testAddMultipleOperationsToQueueWithReadyStrategy() {
        guard let url = URL(string: "/testAddOperationToQueue") else { return }

        let jsonObject: [String: String] = [
            "operation": url.absoluteString
        ]

        stub { request in
            return request.url?.relativePath == url.absoluteString
        } response: { request in
            return HTTPStubsResponse(jsonObject: jsonObject, statusCode: HTTPCode.success.rawValue, headers: nil)
        }

        operationQueue?.isSuspended = true

        var expectations: [XCTestExpectation] = []

        for int in 0..<4 {
            let expectationName = "testAddMultipleOperationsToQueue_\(int)"
            let expectation = expectation(description: expectationName)

            let request = DefaultNetworkRequest(url: url, method: .get, parameters: ["paramNumber": int]) { request, headers, response, error in
                if let retVal = response as? [String: Any],
                   let ret = retVal["operation"] as? String {
                    if ret == url.absoluteString {
                        expectation.fulfill()
                    }
                }
            }
            if int == 0 {
                request.addReadyStrategy(NetworkRequestReadyAfterStrategy(readyAfter: 2))
            }

            expectations.append(expectation)
            operationQueue?.addRequest(request)
        }

        let firstExpectation = expectations.first!
        expectations.removeFirst()
        expectations.append(firstExpectation)

        operationQueue?.isSuspended = false


        wait(for: expectations, timeout: 10, enforceOrder: true)
    }

    // Test retrying request for 5 times without error
    func testRetryStrategyForSuccessfulAuthentication() {
        let expectedNumberOfIssuedRequests = 5
        var numberOfIssuedRequest = 0

        guard let url = URL(string: "/testAuthenticationSucceeds-testRefreshTokenReponse200") else { return }

        let jsonObject: [String: String] = [
            "operation": url.absoluteString
        ]

        stub { request in
            return request.url?.relativePath == url.absoluteString
        } response: { request in
            numberOfIssuedRequest += 1
            return HTTPStubsResponse(jsonObject: jsonObject, statusCode: HTTPCode.success.rawValue, headers: ["Content-Type": "application/json"])
        }

        let expectation = expectation(description: "testRetryStrategyForSuccessfulAuthentication")

        let request = DefaultNetworkRequest(url: url, method: .get) { request, headers, response, error in
            if let retVal = response as? [String: Any],
               let ret = retVal["operation"] as? String {
                if ret == url.absoluteString {
                    XCTAssertEqual(numberOfIssuedRequest, 1)
                    if error == nil {
                        expectation.fulfill()
                    }
                }
            }
        }
        request.priority = .highest
        request.retryStrategy = NetworkRequestExponentialBackOffStrategy(retryLimit: expectedNumberOfIssuedRequests)

        operationQueue?.addRequest(request)

        waitForExpectations(timeout: 20.0, handler: nil)
    }

    // Test retrying request for 5 times with error
    func testRetryStrategyForFailingAuthentication() {
        let expectedNumberOfIssuedRequests = 5
        var numberOfIssuedRequest = 0

        guard let url = URL(string: "/testRetryStrategyForFailingAuthentication-testRefreshTokenFailsDueToTimeout") else { return }

        stub { request in
            return request.url?.relativePath == url.absoluteString
        } response: { request in
            numberOfIssuedRequest += 1
            let error = TestError(msg: "Request: \(numberOfIssuedRequest)", code: .timeout)
            return HTTPStubsResponse(error: error)
        }

        let expectation = expectation(description: "testRetryStrategyForFailingAuthentication")

        let request = DefaultNetworkRequest(url: url, method: .get) { request, headers, response, error in
            XCTAssertEqual(numberOfIssuedRequest, expectedNumberOfIssuedRequests)
            if let _ = error {
                expectation.fulfill()
            }
        }
        request.priority = .highest
        request.retryStrategy = NetworkRequestExponentialBackOffStrategy(retryLimit: expectedNumberOfIssuedRequests)

        operationQueue?.addRequest(request)

        waitForExpectations(timeout: 20.0, handler: nil)
    }

    // Test retrying request for 5 times, but after the 3rd time the request is successful
    func testRetryStrategyForEventuallySucceedingAuthentication() {
        let failLimit = 3
        let maxRetries = 5
        var numberOfIssuedRequest = 0
        guard let url = URL(string: "/testRetryStrategyForFailingAuthentication") else { return }

        let jsonObject: [String: String] = [
            "operation": url.absoluteString
        ]

        stub { request in
            return request.url?.relativePath == url.absoluteString
        } response: { request in
            numberOfIssuedRequest += 1
            if numberOfIssuedRequest == failLimit {
                return HTTPStubsResponse(jsonObject: jsonObject, statusCode: HTTPCode.success.rawValue, headers: ["Content-Type": "application/json"])
            }
            let error = TestError(msg: "Request: \(numberOfIssuedRequest)", code: .timeout)
            return HTTPStubsResponse(error: error)
        }

        let expectation = expectation(description: "testRetryStrategyForEventuallySucceedingAuthentication")

        let request = DefaultNetworkRequest(url: url, method: .get) { request, headers, response, error in
            XCTAssertEqual(numberOfIssuedRequest, failLimit)
            if error == nil {
                expectation.fulfill()
            }
        }
        request.priority = .highest
        request.retryStrategy = NetworkRequestExponentialBackOffStrategy(retryLimit: maxRetries)

        operationQueue?.addRequest(request)

        waitForExpectations(timeout: 20.0, handler: nil)
    }

    // Test request execution by priority, adding request with lowest priority first
    // but expecting the highest priority requests to execute first.
    func testSortingMultipleOperationInQueueByPriority() {
        guard let url = URL(string: "/testSortingMultipleOperationInQueueByPriority") else { return }

        let jsonObject: [String: String] = [
            "operation": url.absoluteString
        ]

        stub { request in
            return request.url?.relativePath == url.absoluteString
        } response: { request in
            return HTTPStubsResponse(jsonObject: jsonObject, statusCode: HTTPCode.success.rawValue, headers: nil)
        }

        operationQueue?.isSuspended = true

        var expectations: [XCTestExpectation] = []

        for int in 0..<4 {
            let expectationName = "testSortingMultipleOperationInQueueByPriority_\(int)"
            let expectation = expectation(description: expectationName)

            let request = DefaultNetworkRequest(url: url, method: .get, parameters: ["paramNumber": int]) { request, headers, response, error in
                if let retVal = response as? [String: Any],
                   let ret = retVal["operation"] as? String {
                    if ret == url.absoluteString {
                        expectation.fulfill()
                    }
                }
            }

            expectations.append(expectation)
            request.priority = NetworkRequestPriority(rawValue: int) ?? .default

            operationQueue?.addRequest(request)
        }

        // reverse expectation order
        let newExpectations: [XCTestExpectation] = expectations.reversed()

        operationQueue?.isSuspended = false


        wait(for: newExpectations, timeout: 10, enforceOrder: true)
    }

    // Test request execution by priority, adding requests in proper priority order
    func testMultipleOperationsInQueueByPriority() {
        guard let url = URL(string: "/testMultipleOperationsInQueueByPriority") else { return }

        let jsonObject: [String: String] = [
            "operation": url.absoluteString
        ]

        stub { request in
            return request.url?.relativePath == url.absoluteString
        } response: { request in
            return HTTPStubsResponse(jsonObject: jsonObject, statusCode: HTTPCode.success.rawValue, headers: nil)
        }

        operationQueue?.isSuspended = true

        var expectations: [XCTestExpectation] = []

        for int in 0..<4 {
            let expectationName = "testMultipleOperationsInQueueByPriority_\(int)"
            let expectation = expectation(description: expectationName)

            let request = DefaultNetworkRequest(url: url, method: .get, parameters: ["paramNumber": int]) { request, headers, response, error in
                if let retVal = response as? [String: Any],
                   let ret = retVal["operation"] as? String {
                    if ret == url.absoluteString {
                        expectation.fulfill()
                    }
                }
            }

            expectations.append(expectation)
            let priorityValue = NetworkRequestPriority.highest.rawValue - int
            request.priority = NetworkRequestPriority(rawValue: priorityValue) ?? .default

            operationQueue?.addRequest(request)
        }

        operationQueue?.isSuspended = false

        wait(for: expectations, timeout: 10, enforceOrder: true)
    }

    // Test adding multiple same requests, which should fail
    // but when it differs, it should be added
    func testAddingIdenticalRequests() {
        guard let url = URL(string: "/testAddingIdenticalRequests") else { return }

        operationQueue?.isSuspended = true

        for _ in 0..<10 {
            let request = DefaultNetworkRequest(url: url, method: .get, completion: nil)

            operationQueue?.addRequest(request)
        }

        XCTAssertTrue(operationQueue?.operations.count == 1)

        for _ in 0..<10 {
            let request = DefaultNetworkRequest(url: url, method: .post, completion: nil)

            operationQueue?.addRequest(request)
        }

        XCTAssertTrue(operationQueue?.operations.count == 2)

        operationQueue?.isSuspended = false
    }

    func testAddingDifferentRequests() {
        guard let url = URL(string: "/testAddingDifferentRequests") else { return }

        operationQueue?.isSuspended = true

        for int in 0..<10 {
            let request = DefaultNetworkRequest(url: url, method: .get, parameters: ["paramNumber": int], completion: nil)

            operationQueue?.addRequest(request)
        }

        XCTAssertTrue(operationQueue?.operations.count == 10)

        for int in 0..<10 {
            let request = DefaultNetworkRequest(url: url, method: .post, parameters: ["paramNumber": int], completion: nil)

            operationQueue?.addRequest(request)
        }

        XCTAssertTrue(operationQueue?.operations.count == 20)

        operationQueue?.isSuspended = false
    }

    func testAddingSameRequestNotAfterEachOther() {
        guard let url = URL(string: "/testAddingSameRequestNotAfterEachOther") else { return }

        operationQueue?.isSuspended = true

        let request1 = DefaultNetworkRequest(url: url, method: .get, completion: nil)
        let request2 = DefaultNetworkRequest(url: url, method: .post, completion: nil)
        let request3 = DefaultNetworkRequest(url: url, method: .delete, completion: nil)

        operationQueue?.addRequest(request1)
        operationQueue?.addRequest(request2)
        operationQueue?.addRequest(request3)

        XCTAssertTrue(operationQueue?.operations.count == 3)

        operationQueue?.isSuspended = false
    }

    func testErrorMapping() {
        guard let url = URL(string: "/testErrorMapping") else { return }

        stub { request in
            return request.url?.relativePath == url.absoluteString
        } response: { request in
            let error = TestError(msg: "Unauthorized changed to timeout", code: .unauthorized)
            return HTTPStubsResponse(error: error)
        }

        let expectation = expectation(description: "testAddOperationToQueue")

        let request = DefaultNetworkRequest(url: url, method: .get) { request, headers, response, error in
            if let error = error as? TestError {
                XCTAssertEqual(error.code, .timeout)
            }
            expectation.fulfill()
        }

        request.errorMapper = NetworkRequestTestErrorMapper()

        operationQueue?.addRequest(request)

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    // Test retrying request with block for 5 times without error
    func testRetryWithBlockStrategyForSuccessfulAuthentication() {
        let expectedNumberOfIssuedRequests = 5
        var numberOfIssuedRequest = 0

        guard let url = URL(string: "/testRetryWithBlockStrategyForSuccessfulAuthentication") else { return }

        let jsonObject: [String: String] = [
            "operation": url.absoluteString
        ]

        stub { request in
            return request.url?.relativePath == url.absoluteString
        } response: { request in
            numberOfIssuedRequest += 1
            return HTTPStubsResponse(jsonObject: jsonObject, statusCode: HTTPCode.success.rawValue, headers: ["Content-Type": "application/json"])
        }

        let expectation = expectation(description: "testRetryWithBlockStrategyForSuccessfulAuthentication")

        let request = DefaultNetworkRequest(url: url, method: .get) { request, headers, response, error in
            if let retVal = response as? [String: Any],
               let ret = retVal["operation"] as? String {
                if ret == url.absoluteString {
                    XCTAssertEqual(numberOfIssuedRequest, 1)
                    if error == nil {
                        expectation.fulfill()
                    }
                }
            }
        }
        request.priority = .highest
        request.retryStrategy = NetworkRequestBlockRetryStrategy(retryLimit: expectedNumberOfIssuedRequests, retryBlock: { params, error in
            return numberOfIssuedRequest == expectedNumberOfIssuedRequests
        })

        operationQueue?.addRequest(request)

        waitForExpectations(timeout: 20.0, handler: nil)
    }

    // Test retrying request with block for 5 times with error
    func testRetryWithBlockStrategyWithError() {
        let expectedNumberOfIssuedRequests = 5
        var numberOfIssuedRequest = 0

        guard let url = URL(string: "/testRetryWithBlockStrategyWithError") else { return }

        stub { request in
            return request.url?.relativePath == url.absoluteString
        } response: { request in
            numberOfIssuedRequest += 1
            let error = TestError(msg: "", code: .unauthorized)
            return HTTPStubsResponse(error: error)
        }

        let expectation = expectation(description: "testRetryWithBlockStrategyWithError")

        let request = DefaultNetworkRequest(url: url, method: .get) { request, headers, response, error in
            XCTAssertEqual(numberOfIssuedRequest, expectedNumberOfIssuedRequests)
            if let _ = error {
                expectation.fulfill()
            }
        }

        request.priority = .highest
        request.retryStrategy = NetworkRequestBlockRetryStrategy(retryLimit: expectedNumberOfIssuedRequests, retryBlock: { params, error in
            return true
        })

        operationQueue?.addRequest(request)

        waitForExpectations(timeout: 20.0, handler: nil)
    }

    func testResponseListener() {
        guard let url = URL(string: "/testAddOperationToQueue") else { return }

        let jsonObject: [String: String] = [
            "operation": url.absoluteString
        ]

        stub { request in
            return request.url?.relativePath == url.absoluteString
        } response: { request in
            return HTTPStubsResponse(jsonObject: jsonObject, statusCode: HTTPCode.success.rawValue, headers: nil)
        }

        let expectation = expectation(description: "testAddOperationToQueue")

        let request = DefaultNetworkRequest(url: url, method: .get, completion: nil)

        let responseListener = NetworkRequestResponseFilteredListener { response, error in
            return true
        } callback: { response, error in
            if let retVal = response as? [String: Any],
               let ret = retVal["operation"] as? String {
                if ret == url.absoluteString {
                    expectation.fulfill()
                }
            }
        }

        request.addResponseListener(responseListener)

        operationQueue?.addRequest(request)

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testDefaultContentMapper() {
        guard let url = URL(string: "/testDefaultContentMapper") else { return }
        
        let jsonObject: [String: String] = [
            "operation": url.absoluteString
        ]
        let jsonObjectAsData = try! JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)

        stub { request in
            return request.url?.relativePath == url.absoluteString
        } response: { request in
            return HTTPStubsResponse(data: jsonObjectAsData, statusCode: HTTPCode.success.rawValue, headers: nil)
        }

        let expectation = expectation(description: "testDefaultContentMapper")

        let request = DefaultNetworkRequest(url: url, method: .get) { request, headers, response, error in
            if let error = error as? TestError {
                XCTAssertEqual(error.code, .timeout)
            }
            expectation.fulfill()
        }

        request.contentMapper = NetworkRequestDefaultMapper(acceptsEmptyResponse: false)

        operationQueue?.addRequest(request)

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testReadyBlockStrategy() {
        guard let url = URL(string: "/testReadyBlockStrategy") else { return }

        let jsonObject: [String: String] = [
            "operation": url.absoluteString
        ]
        let jsonObjectAsData = try! JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)

        stub { request in
            return request.url?.relativePath == url.absoluteString
        } response: { request in
            return HTTPStubsResponse(data: jsonObjectAsData, statusCode: HTTPCode.success.rawValue, headers: nil)
        }

        let expectation = expectation(description: "testReadyBlockStrategy")

        let request = DefaultNetworkRequest(url: url, method: .get) { request, headers, response, error in
            if let error = error as? TestError {
                XCTAssertEqual(error.code, .timeout)
            }
            expectation.fulfill()
        }

        let blockStrategy = NetworkRequestReadyBlockStrategy { readyBlock in
            readyBlock(true)
        }

        request.addReadyStrategy(blockStrategy)

        operationQueue?.addRequest(request)

        waitForExpectations(timeout: 5.0, handler: nil)
    }
}
