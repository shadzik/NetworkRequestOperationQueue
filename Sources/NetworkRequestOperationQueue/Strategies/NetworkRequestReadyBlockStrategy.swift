//
//  NetworkRequestReadyBlockStrategy.swift
//  NetworkRequestOperationQueue
//
//  Created by Bartosz on 07/12/2023.
//

import Foundation

class NetworkRequestReadyBlockStrategy: NetworkRequestReadyStrategy {
    var delegate: NetworkRequestReadyStrategyDelegate?
    var isReady: Bool
    var readyBlock: (NetworkRequestReadyBlockStrategyCompletion) -> Void

    init(readyBlock: @escaping (NetworkRequestReadyBlockStrategyCompletion) -> Void) {
        self.readyBlock = readyBlock
        self.isReady = false
    }

    func start() {
        readyBlock({ [weak self] ready in
            guard let self = self else { return }
            self.isReady = ready
            self.delegate?.didUpdateReadyState(for: self)
        })
    }
}
