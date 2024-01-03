//
//  NetworkRequestReachableReadyStrategy.swift
//  NetworkRequestOperationQueue
//
//  Created by Bartosz on 07/12/2023.
//

import Foundation
import Network

public enum ReachabilityStatus {
    case connected
    case disconnected
}

public protocol ReachabilityTesterDelegate {
    func didChangeReachability(_ status: ReachabilityStatus)
}

public class ReachabilityTester {
    private let pathMonitor = NWPathMonitor()
    private(set) var isReachable: Bool = false

    private var delegate: ReachabilityTesterDelegate?

    public init(delegate: ReachabilityTesterDelegate? = nil) {
        pathMonitor.pathUpdateHandler = { path in
            switch path.status {
            case .satisfied:
                self.isReachable = true
                self.delegate?.didChangeReachability(.connected)
            default:
                self.isReachable = false
                self.delegate?.didChangeReachability(.disconnected)
            }
        }
        pathMonitor.start(queue: .main)
    }
}

public class NetworkRequestReachableReadyStrategy: NetworkRequestReadyStrategy {
    private var reachabilityTester: ReachabilityTester!
    private var timer: Timer?
    private var didTimeOut: Bool = false
    private var timeout: TimeInterval
    public var delegate: NetworkRequestReadyStrategyDelegate?

    public init(timeout: TimeInterval) {
        self.timeout = timeout
    }

    public var isReady: Bool {
        return reachabilityTester.isReachable == true || didTimeOut
    }

    public func start() {
        reachabilityTester = ReachabilityTester(delegate: self)
        startTimer()
    }
    

    func startTimer() {
        disableTimer()

        if timeout > 0 {
            timer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false, block: { [unowned self] timer in
                self.didTimeOut = true
                self.delegate?.didUpdateReadyState(for: self)
            })
        }
    }

    func disableTimer() {
        timer?.invalidate()
        timer = nil
        didTimeOut = false
    }
}

extension NetworkRequestReachableReadyStrategy: ReachabilityTesterDelegate {
    public func didChangeReachability(_ status: ReachabilityStatus) {
        self.delegate?.didUpdateReadyState(for: self)

        if status == .connected {
            disableTimer()
        } else {
            startTimer()
        }
    }
}
