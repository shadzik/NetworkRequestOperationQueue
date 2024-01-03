//
//  NetworkRequestBlockRetryStrategy.swift
//  NetworkRequestOperationQueue
//
//  Created by Bartosz on 07/12/2023.
//

import Foundation

class NetworkRequestBlockRetryStrategy: NetworkRequestRetryStrategy {

    typealias RetryBlock = ([String: AnyHashable]?, Error?) -> Bool

    private let retryLimit: Int
    private var retryCount: Int = 0
    private let shouldRetryBlock: RetryBlock

    init(retryLimit: Int, retryBlock: @escaping RetryBlock) {
        self.retryLimit = retryLimit
        self.shouldRetryBlock = retryBlock
    }

    func retryRequest(with response: [String : AnyHashable]?, error: Error?) -> Float {
        if !shouldRetryBlock(response, error) {
            return 0
        }

        retryCount += 1
        if retryCount >= retryLimit {
            return 0
        }

        return log(Float(retryCount + 1))
    }
}
