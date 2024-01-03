//
//  NetworkRequestAuthorizationProtocol.swift
//  NetworkRequestOperationQueue
//
//  Created by Bartosz on 07/12/2023.
//

import Foundation

protocol NetworkRequestAuthorizationProtocol {
    var headers: [String: String]? { get set }
    var parameters: [String: Any]? { get set }
}
