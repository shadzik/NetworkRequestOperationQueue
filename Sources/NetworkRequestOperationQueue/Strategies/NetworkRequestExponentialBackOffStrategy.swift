//
//  NetworkRequestExponentialBackOffStrategy.swift
//  NetworkRequestOperationQueue
//
//  Created by Bartosz on 07/12/2023.
//

import Foundation

public class NetworkRequestExponentialBackOffStrategy: NetworkRequestRetryStrategy {
    private let retryLimit: Int
    private var retryCount: Int = 0

    public init(retryLimit: Int) {
        self.retryLimit = retryLimit
    }

    /// Returns a logarithmically increasing time interval after which a request is to be retried
    public func retryRequest(with response: [String : AnyHashable]?, error: Error?) -> Float {
        guard let _ = error else {
            return 0
        }

        retryCount += 1
        if retryCount >= retryLimit {
            return 0
        }

        return log(Float(retryCount + 1))
    }
}
