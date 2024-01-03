//
//  NetworkRequestOperation.swift
//  Astate
//
//  Created by Bartosz on 05/12/2023.
//  Copyright © 2023 Automat Berlin GmbH. All rights reserved.
//

import UIKit

public typealias SuccessBlock = (URLSessionDataTask?, Any?) -> Void
public typealias FailureBlock = (URLSessionDataTask?, Error?) -> Void
public typealias ProgressBlock = (URLSessionDataTask?, Float) -> Void

public class NetworkRequestOperation: Operation, NetworkRequestReadyStrategyDelegate {
    let request: any NetworkRequest
    let contentMapper: NetworkRequestContentMapper
    var completion: NetworkRequestCompletion
    var progressHandler: NetworkRequestProgressHandler?
    private var mutableData: Data?
    private var expectedContentLength: Int64 = 0

    var runningTask: URLSessionTask?

    var requestPrepareBlock: ((any NetworkRequest) -> Void)?

    private var success: SuccessBlock?
    private var failure: FailureBlock?
    private var progress: ProgressBlock?

    init(request: any NetworkRequest, contentMapper: NetworkRequestContentMapper) {
        self.request = request
        self.contentMapper = contentMapper
        self.completion = request.completion
        self.mutableData = Data()

        super.init()

        if let strategies = request.readyStrategies {
            for var strategy in strategies {
                strategy.delegate = self
                strategy.start()
            }
        }
    }

    public override var isReady: Bool {
        return request.isReady && super.isReady
    }

    func poke() {
        if let strategies = request.readyStrategies {
            for strategy in strategies {
                strategy.start()
            }
        }
    }

    public override func main() {
        var response: Any?
        var headers: [AnyHashable: Any]?
        var responseError: Error?

        success = { task, myResponse in
            let httpResponse = task?.response as? HTTPURLResponse
            headers = httpResponse?.allHeaderFields
            let contentMapper = self.request.contentMapper != nil ? self.request.contentMapper! : self.contentMapper
            if let myResponse = myResponse,
                let dataResponse = myResponse as? Data {
                response = contentMapper.content(from: dataResponse, error: &responseError)
            } else {
                response = myResponse
            }

            if self.isCancelled {
                return
            }

            DispatchQueue.main.async {
                self.completion(self.request, headers, response, responseError)
                for listener in self.request.responseListeners {
                    listener.requestDidReceive(response: response, error: responseError)
                }
            }
        }

        failure = { task, error in
            if let error = error {
                responseError = (self.request.errorMapper != nil) ? self.request.errorMapper?.map(error: error) : error
            }
            headers?.removeAll()
            headers = nil

            DispatchQueue.main.async {
                self.completion(self.request, headers, response, responseError)
                for listener in self.request.responseListeners {
                    listener.requestDidReceive(response: response, error: responseError)
                }
            }
        }

        progress = { task, progress in
            DispatchQueue.main.async {
                self.progressHandler?(self.request, progress)
            }
        }

        DispatchQueue.main.async {
            self.requestPrepareBlock?(self.request)
        }

        runningTask = dataTask(with: request.method, url: request.url, success: success, failure: failure, progress: progress)
    }

    func dataTask(with method: NetworkRequestMethod, url: URL, parameters: [String: String]? = nil, success: SuccessBlock?, failure: FailureBlock?, progress: ProgressBlock? = nil) -> URLSessionDataTask? {

        self.success = success
        self.failure = failure
        self.progress = progress
        let request = method.request(url: url, params: parameters)
        let task = URLSession.shared.dataTask(with: request)

        task.delegate = self
        task.resume()

        return task
    }

    // KVO
    public func didUpdateReadyState(for strategy: NetworkRequestReadyStrategy) {
        willChangeValue(forKey: "isReady")
        didChangeValue(forKey: "isReady")
    }

    override public func cancel() {
        super.cancel()

        if runningTask?.state == .running {
            runningTask?.cancel()
            runningTask = nil
        }
    }
}

extension NetworkRequestOperation: URLSessionTaskDelegate, URLSessionDataDelegate {

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        expectedContentLength = response.expectedContentLength
        completionHandler(.allow)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // serialize task.response here, and fill responseObject
        let data = mutableData
        mutableData = nil

        if let error = error,
           let task = task as? URLSessionDataTask {
            failure?(task, error)
        } else if let task = task as? URLSessionDataTask,
            let data = data {
            success?(task, data)
        }
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        mutableData?.append(data)

        guard let mutableData = mutableData else { return }

        let percent = Float(mutableData.count) / Float(expectedContentLength)
        progress?(dataTask, percent)
    }
}
