//
//  NetworkRequestReadyAfterStrategy.swift
//  NetworkRequestOperationQueue
//
//  Created by Bartosz on 07/12/2023.
//

import Foundation

public class NetworkRequestReadyAfterStrategy: NetworkRequestReadyStrategy {
    public var delegate: NetworkRequestReadyStrategyDelegate?

    private let readyAfter: TimeInterval
    private var timer: Timer?
    public var isReady: Bool

    public init(readyAfter: TimeInterval) {
        self.readyAfter = readyAfter
        self.isReady = false
    }

    public func start() {
        timer = Timer.scheduledTimer(timeInterval: readyAfter, target: self, selector: #selector(timerFired), userInfo: nil, repeats: false)
    }

    @objc
    private func timerFired(_ timer: Timer) {
        isReady = true
        delegate?.didUpdateReadyState(for: self)
        self.timer?.invalidate()
        self.timer = nil
    }

}
