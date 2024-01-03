//
//  NetworkRequestReadyAfterStrategy.swift
//  NetworkRequestOperationQueue
//
//  Created by Bartosz on 07/12/2023.
//

import Foundation

class NetworkRequestReadyAfterStrategy: NetworkRequestReadyStrategy {
    var delegate: NetworkRequestReadyStrategyDelegate?

    private let readyAfter: TimeInterval
    private var timer: Timer?
    var isReady: Bool

    init(readyAfter: TimeInterval) {
        self.readyAfter = readyAfter
        self.isReady = false
    }

    func start() {
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
