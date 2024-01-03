//
//  NetworkRequestDummyMapper.swift
//  NetworkRequestOperationQueue
//
//  Created by Bartosz on 15/12/2023.
//

import Foundation

public class NetworkRequestDummyMapper: NetworkRequestContentMapper {

    public init() {
    }

    public func content(from data: Data, error: inout Error?) -> Any? {
        return data
    }
}
