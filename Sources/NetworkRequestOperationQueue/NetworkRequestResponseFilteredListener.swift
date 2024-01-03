//
//  NetworkRequestResponseFilteredListener.swift
//  NetworkRequestOperationQueue
//
//  Created by Bartosz on 13/12/2023.
//

import Foundation

public class NetworkRequestResponseFilteredListener: NetworkRequestResponseListener {
    let filter: (Any?, Error?) -> Bool
    let callback: (Any?, Error?) -> Void

    init(filter: @escaping (Any?, Error?) -> Bool, callback: @escaping (Any?, Error?) -> Void) {
        self.filter = filter
        self.callback = callback
    }

    public func requestDidReceive(response: Any?, error: Error?) {
        if filter(response, error) {
            callback(response, error)
        }
    }
}
