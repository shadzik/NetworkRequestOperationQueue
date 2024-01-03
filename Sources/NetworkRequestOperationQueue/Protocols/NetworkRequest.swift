//
//  NetworkRequest.swift
//  Astate
//
//  Created by Bartosz on 05/12/2023.
//  Copyright © 2023 Automat Berlin GmbH. All rights reserved.
//

import UIKit

public typealias NetworkRequestCompletion = (any NetworkRequest, [AnyHashable: Any]?, Any?, Error?) -> Void
public typealias NetworkRequestProgressHandler = (any NetworkRequest, Float) -> Void

public enum NetworkRequestMethod: String {
    /// - head: HEAD request
    case head = "HEAD"
    /// - get: GET request
    case get = "GET"
    /// - post: POST request
    case post = "POST"
    /// - put: PUT request
    case put = "PUT"
    /// - delete: DELETE request
    case delete = "DELETE"
    /// - patch: PATCH request
    case patch = "PATCH"

    /// Create a URLRequest
    /// - Parameters:
    ///    - url: URL of the request
    ///    - headers: http headers
    ///    - body: data to send in the httpBody
    ///    - params: URL encoded parameters
    func request(url: URL, header: [String: String]? = nil, body: Data? = nil, params: [String: String]? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = self.rawValue
        request.httpBody = body
        request.timeoutInterval = 60
        request.allHTTPHeaderFields = header

        if let params = params {
            request.encodeParameters(parameters: params)
        }

        return request
    }
}

public enum NetworkRequestPriority: Int, Comparable {
    case low
    case `default`
    case high
    case highest

    static public func < (lhs: NetworkRequestPriority, rhs: NetworkRequestPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

public protocol NetworkRequest: Hashable {

    /// Select a retry strategy should the request fail
    var retryStrategy: NetworkRequestRetryStrategy? { get set }

    /// Array of ready strategies
    var readyStrategies: [NetworkRequestReadyStrategy]? { get set }

    /// Set the priority of the request
    /// Default: .default
    var priority: NetworkRequestPriority { get set }

    /// Selected error mapper
    var errorMapper: NetworkRequestErrorMapper? { get set }

    /// Selected content mapper
    var contentMapper: NetworkRequestContentMapper? { get set }

    /// Array of response listeners
    var responseListeners: [NetworkRequestResponseListener] { get }

    /// Indicates whether the request is ready to be executed
    var isReady: Bool { get }

    /// Request method:
    /// - Parameter va
    var method: NetworkRequestMethod { get }

    /// URL
    var url: URL { get }

    /// UUID of the request
    var id: String { get }

    /// Executed when the request hast finished
    var completion: NetworkRequestCompletion { get }

    /// Tracks progress of the data task
    var progressHandler: NetworkRequestProgressHandler? { get }

    /// Http headers
    /// ex. headers = ["Content-Type": "application/json"]
    var headers: [String: String]? { get set }

    /// URL parameters sent in httpBody
    var parameters: [String: AnyHashable]? { get set }

    /// Add a completion block to the request
    /// - Parameters:
    ///    - completion: The completion block, executed after request was fired
    func addCompletion(_ completion: @escaping NetworkRequestCompletion)

    /// Add a ready strategy  to the request
    /// - Parameters:
    ///    - strategy: The ready strategy of your choice
    func addReadyStrategy(_ strategy: NetworkRequestReadyStrategy)

    /// Add a ready strategy  to the request
    /// - Parameters:
    ///    - strategy: The ready strategy of your choice
    func addResponseListener(_ listener: NetworkRequestResponseListener)

    /// Checks the equality of two NetworkRequests.
    ///
    /// - Parameters:
    ///    - request: The request to compare to
    /// - Returns: true if both requests are equal, false otherwise
    func isEqualTo(_ request: any NetworkRequest) -> Bool
}
