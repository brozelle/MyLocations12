//
//  Functions.swift
//  MyLocations12
//
//  Created by Buck Rozelle on 12/18/20.
//

import Foundation

//MARK:- Global Function for Handling Core Data Errors
let dataSaveFailedNotification = Notification.Name(
  rawValue: "DataSaveFailedNotification")

func fatalCoreDataError(_ error: Error) {
  print("*** Fatal error: \(error)")
  NotificationCenter.default.post(
    name: dataSaveFailedNotification,
    object: nil)
}

let applicationDocumentsDirectory: URL = {
    let paths = FileManager.default.urls(for: .documentDirectory,
                                         in: .userDomainMask)
    return paths [0]
}()

func afterDelay(_ seconds: Double,
                run: @escaping () -> Void) {
  DispatchQueue.main.asyncAfter(
    deadline: .now() + seconds,
    execute: run)

}
