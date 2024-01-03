//
//  URLRequest+Extensions.swift
//  NetworkRequestOperationQueue
//
//  Created by Bartosz on 07/12/2023.
//

import Foundation

extension URLRequest {

  private func percentEscapeString(_ string: String) -> String {
    var characterSet = CharacterSet.alphanumerics
    characterSet.insert(charactersIn: "-._* ")

    return string.addingPercentEncoding(withAllowedCharacters: characterSet)!.replacingOccurrences(of: " ", with: "+")
  }

  mutating func encodeParameters(parameters: [String : String]) {
    let parameterArray = parameters.map { (arg) -> String in
      let (key, value) = arg
      return "\(key)=\(percentEscapeString(value))"
    }

    httpBody = parameterArray.joined(separator: "&").data(using: String.Encoding.utf8)
  }
}
