//
//  ViewController.swift
//  NetworkRequestOperationQueueDemo
//
//  Created by Bartosz on 03/01/2024.
//

import UIKit
import NetworkRequestOperationQueue

class ViewController: UIViewController {

    @IBOutlet private weak var sendButton: UIButton!
    @IBOutlet private weak var responseView: UITextView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var progressView: UIProgressView!

    private let requestQueue = NetworkRequestOperationQueue()

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    @IBAction private func sendRequest() {
        requestQueue.isSuspended = false
        sendButton.setTitle("Reset", for: .normal)

        if !responseView.text.isEmpty {
            setup()
        }

        if imageView.image != nil {
            setup()
        }
    }

    private func setup() {
        responseView.text = nil
        sendButton.setTitle("Send request", for: .normal)
        requestQueue.isSuspended = true
        requestQueue.maxConcurrentOperationCount = 1
        progressView.progress = 0.0
        imageView.image = nil

        guard let url1 = URL(string: "https://images.unsplash.com/photo-1702559558083-b2e3193ddc07?q=80&w=3775&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"),
              let url2 = URL(string: "https://jsonplaceholder.typicode.com/todos/1"),
              let url3 = URL(string: "https://images.unsplash.com/photo-1565010505218-b3d8d0fb75e4?q=80&w=2943&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"),
              let url4 = URL(string: "https://jsonplaceholder.typicode.com/posts/1"),
              let url5 = URL(string: "https://plus.unsplash.com/premium_photo-1673264933051-3206029946b3?q=80&w=4000&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"),
              let url = [url1, url2, url3, url4, url5].randomElement() else { return }

        let request = DefaultNetworkRequest(url: url, method: .get, completion: { request, headers, response, error in
            // JSON
            if let response = response as? [String: Any] {
                var dump = ""

                // dump response to text
                for (key, value) in response {
                    dump += "\(key): \(value)\n"
                }

                self.responseView.text = dump
            }

            // Data/Image
            if let responseData = response as? Data {
                let image = UIImage(data: responseData)
                DispatchQueue.main.async {
                    self.imageView.image = image
                }
            }
        }) { request, progress in
            DispatchQueue.main.async {
                self.progressView.progress = progress
            }
        }

        let reachabilityStrategy = NetworkRequestReachableReadyStrategy(timeout: 2)
        let retryStrategy = NetworkRequestExponentialBackOffStrategy(retryLimit: .max)
        request.addReadyStrategy(reachabilityStrategy)
        request.retryStrategy = retryStrategy
        if url == url1 || url == url3 || url == url5 {
            request.contentMapper = NetworkRequestPassThroughMapper()
        }

        requestQueue.addRequest(request)
    }

}
