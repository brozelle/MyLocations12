//
//  Functions.swift
//  MyLocations12
//
//  Created by Buck Rozelle on 12/18/20.
//

import Foundation


func afterDelay(_ seconds: Double,
                run: @escaping () -> Void) {
  DispatchQueue.main.asyncAfter(
    deadline: .now() + seconds,
    execute: run)
}
