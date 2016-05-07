//
//  ToothbrushConnection.swift
//  IoToothbrush
//
//  Created by Matthew Lewinski on 5/7/16.
//  Copyright © 2016 Matthew Lewinski. All rights reserved.
//

import Foundation

protocol ToothbrushConnectionDelegate: class {
    func timeRecieved(date: NSDate);
}

class ToothbrushConnection {
    weak var delegate: ToothbrushConnectionDelegate?

    private var buffer = ""

    func handleIncomingData(data: NSData) {
        if let string = String(data: data, encoding: NSASCIIStringEncoding) {
            buffer += string
            print(buffer)
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
        case "GetLastEvent":
            print("start = \(args[1])")
        case "GetRTC":
            if let timestamp = Double(args[1]) {
                let date = NSDate(timeIntervalSince1970: timestamp)
                delegate?.timeRecieved(date)
            }
        default:
            print("Unknown Response: \(command)")
        }
    }
}
