//
//  NetworkRequestReadyStrategy.swift
//  NetworkRequestOperationQueue
//
//  Created by Bartosz on 07/12/2023.
//

import Foundation

typealias NetworkRequestReadyBlockStrategyCompletion = (Bool) -> Void

protocol NetworkRequestReadyStrategyDelegate {
    func didUpdateReadyState(for strategy: NetworkRequestReadyStrategy)
}

protocol NetworkRequestReadyStrategy {
    var delegate: NetworkRequestReadyStrategyDelegate? { get set }
    var isReady: Bool { get }

    func start()
}
