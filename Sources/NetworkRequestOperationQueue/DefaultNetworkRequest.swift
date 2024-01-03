//
//  DefaultNetworkRequest.swift
//  NetworkRequestOperationQueue
//
//  Created by Bartosz on 07/12/2023.
//

import Foundation

class DefaultNetworkRequest: NetworkRequest {
    var retryStrategy: NetworkRequestRetryStrategy?
    var readyStrategies: [NetworkRequestReadyStrategy]?
    var priority: NetworkRequestPriority = .default
    var errorMapper: NetworkRequestErrorMapper?
    var contentMapper: NetworkRequestContentMapper?
    var responseListeners: [NetworkRequestResponseListener] {
        return responseListenerTable.allObjects
    }
    var isReady: Bool {
        var _isReady = true
        if let readyStrategies = readyStrategies {
            for strategy in readyStrategies {
                _isReady = _isReady && strategy.isReady
            }

            return _isReady
        }

        return _isReady
    }
    var method: NetworkRequestMethod
    var url: URL
    var completion: NetworkRequestCompletion {
        return { request, headers, response, error in
            for completion in self.completions {
                completion(request, headers, response, error)
            }
        }
    }
    var progressHandler: NetworkRequestProgressHandler?
    var completions: [NetworkRequestCompletion] = []
    var responseListenerTable = NSHashTable<NetworkRequestResponseListener>.weakObjects()
    var headers: [String : String]?
    var parameters: [String : AnyHashable]?
    var id: String = UUID().uuidString

    init(url: URL, method: NetworkRequestMethod, headers: [String : String]? = nil, parameters: [String : AnyHashable]? = nil, completion: NetworkRequestCompletion?, progressHandler: NetworkRequestProgressHandler? = nil) {
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

    func addCompletion(_ completion: @escaping NetworkRequestCompletion) {
        completions.append(completion)
    }

    func addReadyStrategy(_ strategy: NetworkRequestReadyStrategy) {
        readyStrategies?.append(strategy)
    }
    
    func addResponseListener(_ listener: NetworkRequestResponseListener) {
        responseListenerTable.add(listener)
    }
    
    /// We consider a request to be equal when the URL, method and parameters are the same
    /// hashValue combines the url and request method in one hash
    func isEqualTo(_ request: any NetworkRequest) -> Bool {
        return hashValue == request.hashValue
        && parameters == request.parameters
    }
}

extension DefaultNetworkRequest: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(method)
    }

    static func == (lhs: DefaultNetworkRequest, rhs: DefaultNetworkRequest) -> Bool {
        return lhs.hashValue == rhs.hashValue
        && lhs.parameters == rhs.parameters
    }
}
