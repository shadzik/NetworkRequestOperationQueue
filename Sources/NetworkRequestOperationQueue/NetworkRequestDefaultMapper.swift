//
//  NetworkRequestDefaultMapper.swift
//  NetworkRequestOperationQueue
//
//  Created by Bartosz on 07/12/2023.
//

import Foundation

class NetworkRequestDefaultMapper: NetworkRequestContentMapper {
    let acceptsEmptyResponse: Bool

    init(acceptsEmptyResponse: Bool) {
        self.acceptsEmptyResponse = acceptsEmptyResponse
    }

    func content(from data: Data, error: inout Error?) -> Any? {
        if acceptsEmptyResponse && data.count == 0 {
            return nil
        }

        return try! JSONSerialization.jsonObject(with: data, options: [])
    }
}
