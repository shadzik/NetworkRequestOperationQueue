//
//  NetworkRequestRetryStrategy.swift
//  NetworkRequestOperationQueue
//
//  Created by Bartosz on 07/12/2023.
//

import Foundation

public protocol NetworkRequestRetryStrategy {
    func retryRequest(with response: [String: AnyHashable]?, error: Error?) -> Float
}
