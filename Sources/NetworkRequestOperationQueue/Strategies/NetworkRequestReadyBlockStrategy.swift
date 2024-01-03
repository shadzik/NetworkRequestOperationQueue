//
//  NetworkRequestReadyBlockStrategy.swift
//  NetworkRequestOperationQueue
//
//  Created by Bartosz on 07/12/2023.
//

import Foundation

public class NetworkRequestReadyBlockStrategy: NetworkRequestReadyStrategy {
    public var delegate: NetworkRequestReadyStrategyDelegate?
    public var isReady: Bool
    public var readyBlock: (NetworkRequestReadyBlockStrategyCompletion) -> Void

    public init(readyBlock: @escaping (NetworkRequestReadyBlockStrategyCompletion) -> Void) {
        self.readyBlock = readyBlock
        self.isReady = false
    }

    public func start() {
        readyBlock({ [weak self] ready in
            guard let self = self else { return }
            self.isReady = ready
            self.delegate?.didUpdateReadyState(for: self)
        })
    }
}
