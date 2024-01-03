//
//  DefaultNetworkRequest.swift
//  NetworkRequestOperationQueue
//
//  Created by Bartosz on 07/12/2023.
//

import Foundation

public class DefaultNetworkRequest: NetworkRequest {
    public var retryStrategy: NetworkRequestRetryStrategy?
    public var readyStrategies: [NetworkRequestReadyStrategy]?
    public var priority: NetworkRequestPriority = .default
    public var errorMapper: NetworkRequestErrorMapper?
    public var contentMapper: NetworkRequestContentMapper?
    public var responseListeners: [NetworkRequestResponseListener] {
        return responseListenerTable.allObjects
    }
    public var isReady: Bool {
        var _isReady = true
        if let readyStrategies = readyStrategies {
            for strategy in readyStrategies {
                _isReady = _isReady && strategy.isReady
            }

            return _isReady
        }

        return _isReady
    }
    public var method: NetworkRequestMethod
    public var url: URL
    public var completion: NetworkRequestCompletion {
        return { request, headers, response, error in
            for completion in self.completions {
                completion(request, headers, response, error)
            }
        }
    }
    public var progressHandler: NetworkRequestProgressHandler?
    var completions: [NetworkRequestCompletion] = []
    var responseListenerTable = NSHashTable<NetworkRequestResponseListener>.weakObjects()
    public var headers: [String : String]?
    public var parameters: [String : AnyHashable]?
    public var id: String = UUID().uuidString

    public init(url: URL, method: NetworkRequestMethod, headers: [String : String]? = nil, parameters: [String : AnyHashable]? = nil, completion: NetworkRequestCompletion?, progressHandler: NetworkRequestProgressHandler? = nil) {
        self.retryStrategy = nil
        self.readyStrategies = []
        self.errorMapper = nil
        self.contentMapper = nil
        self.method = method
        self.url = url
        self.headers = headers
        self.progressHandler = progressHandler
        if headers == nil {
            self.headers = ["content-type": "application/json"]

        }
        self.parameters = parameters


        if let completion = completion {
            addCompletion(completion)
        }
    }

    public func addCompletion(_ completion: @escaping NetworkRequestCompletion) {
        completions.append(completion)
    }

    public func addReadyStrategy(_ strategy: NetworkRequestReadyStrategy) {
        readyStrategies?.append(strategy)
    }
    
    public func addResponseListener(_ listener: NetworkRequestResponseListener) {
        responseListenerTable.add(listener)
    }
    
    /// We consider a request to be equal when the URL, method and parameters are the same
    /// hashValue combines the url and request method in one hash
    public func isEqualTo(_ request: any NetworkRequest) -> Bool {
        return hashValue == request.hashValue
        && parameters == request.parameters
    }
}

extension DefaultNetworkRequest: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(method)
    }

    public static func == (lhs: DefaultNetworkRequest, rhs: DefaultNetworkRequest) -> Bool {
        return lhs.hashValue == rhs.hashValue
        && lhs.parameters == rhs.parameters
    }
}
