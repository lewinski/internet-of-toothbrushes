//
//  ToothbrushConnection.swift
//  IoToothbrush
//
//  Created by Matthew Lewinski on 5/7/16.
//  Copyright © 2016 Matthew Lewinski. All rights reserved.
//

import Foundation

protocol ToothbrushConnectionDelegate: class {
    func sendCommand(command: String)

    func timeReceived(date: NSDate)
    func brushingEventReceived(start: NSDate, end: NSDate, duration: Int)
}

class ToothbrushConnection {
    weak var delegate: ToothbrushConnectionDelegate?

    private var buffer = ""

    func sync() {
        let date = NSDate().timeIntervalSince1970
        delegate?.sendCommand("SetRTC " + String(Int(date)) + "\n")
        delegate?.sendCommand("GetRTC\n")
        delegate?.sendCommand("GetLastEvent\n")
    }

    func handleIncomingData(data: NSData) {
        if let string = String(data: data, encoding: NSASCIIStringEncoding) {
            buffer += string
        }
        
        if let lineEnd = buffer.rangeOfString("\n") {
            let firstLine = Range(buffer.startIndex..<lineEnd.endIndex.predecessor())

            let line = buffer.substringWithRange(firstLine)
            dispatchCommand(line)

            let remainder = buffer.substringWithRange(Range(lineEnd.endIndex..<buffer.endIndex))
            buffer = remainder
        }
    }

    func dispatchCommand(command: String) {
        let args = command.characters.split { $0 == ":" }.map(String.init)
        switch (args[0]) {

        case "GetRTC":
            print("GetRTC Response: \(args[1])")
            if let timestamp = NSTimeInterval(args[1]) {
                let date = NSDate(timeIntervalSince1970: timestamp)
                delegate?.timeReceived(date)
            }

        case "SetRTC":
            print("SetRTC Response: \(args[1])")

        case "GetLastEvent":
            print("GetLastEvent Response: \(args[1]) \(args[2]) \(args[3])")
            if let startTimestamp = NSTimeInterval(args[1]), stopTimestamp = NSTimeInterval(args[2]), duration = Int(args[3]) {
                if (duration < 10 || duration > 300) {
                    print("Ignoring spurious brushing event.")
                } else {
                    let startDate = NSDate(timeIntervalSince1970: startTimestamp)
                    let stopDate = NSDate(timeIntervalSince1970: stopTimestamp)
                    delegate?.brushingEventReceived(startDate, end: stopDate, duration: duration)
                }
                delegate?.sendCommand("ClearLastEvent\n")
            }
            break

        case "ClearLastEvent":
            print("ClearLastEvent Response: \(args[1])")

        default:
            print("Unknown Response: \(command)")
        }
    }
}
