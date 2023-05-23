//
//  Logger.swift
//  PatMe
//
//  Created by Jan on 19.02.22.
//

enum LogType: String{
    case error
    case warning
    case success
    case action
    case canceled
}


class Logger{

 static func log(_ logType: LogType, _ message: String){
        switch logType {
        case LogType.error:
            print("\n📕 Error: \(message)\n")
        case LogType.warning:
            print("\n📙 Warning: \(message)\n")
        case LogType.success:
            print("\n📗 Success: \(message)\n")
        case LogType.action:
            print("\n📘 Action: \(message)\n")
        case LogType.canceled:
            print("\n📓 Cancelled: \(message)\n")
        }
    }

}
