//
//  NetworkRequestReadyStrategy.swift
//  NetworkRequestOperationQueue
//
//  Created by Bartosz on 07/12/2023.
//

import Foundation

public typealias NetworkRequestReadyBlockStrategyCompletion = (Bool) -> Void

public protocol NetworkRequestReadyStrategyDelegate {
    func didUpdateReadyState(for strategy: NetworkRequestReadyStrategy)
}

public protocol NetworkRequestReadyStrategy {
    var delegate: NetworkRequestReadyStrategyDelegate? { get set }
    var isReady: Bool { get }

    func start()
}
