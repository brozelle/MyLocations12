//
//  String+AddText.swift
//  MyLocations12
//
//  Created by Buck Rozelle on 12/20/20.
//

import Foundation

extension String {
    mutating func add(text: String?,
                      separatedBy separator: String = ""){
        if let text = text {
            if !isEmpty {
                self += separator
            }
            self += text
        }
    }
}
