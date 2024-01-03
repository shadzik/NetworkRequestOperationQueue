//
//  NetworkRequestErrorMapper.swift
//  NetworkRequestOperationQueue
//
//  Created by Bartosz on 07/12/2023.
//

import Foundation

public protocol NetworkRequestErrorMapper {
    func map(error: Error) -> Error
}
