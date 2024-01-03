//
//  NetworkRequestResponseListener.swift
//  NetworkRequestOperationQueue
//
//  Created by Bartosz on 07/12/2023.
//

import Foundation

@objc
public protocol NetworkRequestResponseListener: AnyObject {
    func requestDidReceive(response: Any?, error: Error?)
}
