//
//  NetworkRequestOperationQueue.swift
//  Astate
//
//  Created by Bartosz on 05/12/2023.
//  Copyright © 2023 Automat Berlin GmbH. All rights reserved.
//

import UIKit

public class NetworkRequestOperationQueue: OperationQueue {

    var requestPrepareBlock: ((any NetworkRequest) -> Void)? = nil
    let contentMapper: NetworkRequestContentMapper

    init(contentMapper: NetworkRequestContentMapper = NetworkRequestDefaultMapper(acceptsEmptyResponse: true)) {
        self.contentMapper = contentMapper
    }

    func addRequest(_ request: any NetworkRequest) {
        addRequest(request, forced: false)
    }

    func retryRequest(_ request: any NetworkRequest) {
        addRequest(request, forced: true)
    }

    func addRequest(_ request: any NetworkRequest, forced: Bool) {
        if let lastOperation = operations.last as? NetworkRequestOperation {
            if lastOperation.request.isEqualTo(request) && !forced {
                lastOperation.request.addCompletion(request.completion)
                if !lastOperation.isReady {
                    lastOperation.poke()
                }

                return
            }
        }

        let newOperation = NetworkRequestOperation(request: request, contentMapper: contentMapper)

        // Wrap the completion to add handling retries
        newOperation.completion = { [weak self] request, headers, response, error in
            var retryAfter: Float = 0
            if let retryStrategy = request.retryStrategy {
                let res = response as? [String: AnyHashable]
                retryAfter = retryStrategy.retryRequest(with: res, error: error)
            }

            if retryAfter != 0 {
                request.addReadyStrategy(NetworkRequestReadyAfterStrategy(readyAfter: TimeInterval(retryAfter)))
                self?.retryRequest(request)
                return
            }

            request.completion(request, headers, response, error)
        }

        newOperation.progressHandler = { request, progress in
            request.progressHandler?(request, progress)
        }

        newOperation.requestPrepareBlock = self.requestPrepareBlock
        updateDependenciesWithOperation(newOperation)
        addOperation(newOperation)
    }

    func updateDependenciesWithOperation(_ operation: NetworkRequestOperation) {
        for currentOperation in operations {
            guard let currentOperation = currentOperation as? NetworkRequestOperation else { return }
            if !currentOperation.isKind(of: NetworkRequestOperation.self) {
                continue
            }

            if currentOperation.isExecuting || currentOperation.isCancelled {
                continue
            }

            // If the already enqueued operations priority is higher than the new operation, add the existing as dependency.
            if currentOperation.request.priority > operation.request.priority {
                operation.addDependency(currentOperation)
                continue
            }

            // if the new operation priority is higher than the already enqueued ones, then add it as dependency of the existing one
            if operation.request.priority > currentOperation.request.priority {
                currentOperation.addDependency(operation)
            }
        }
    }

    override public func addOperation(_ op: Operation) {
        if let operation = op as? NetworkRequestOperation {
            super.addOperation(operation)
        }
    }
}
