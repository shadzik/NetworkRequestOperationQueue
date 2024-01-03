//
//  NetworkRequestContentMapper.swift
//  NetworkRequestOperationQueue
//
//  Created by Bartosz on 07/12/2023.
//

import Foundation

public protocol NetworkRequestContentMapper {
    func content(from data: Data, error: inout Error?) -> Any?
}
