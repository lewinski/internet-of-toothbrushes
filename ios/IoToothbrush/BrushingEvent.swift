//
//  BrushingEvent.swift
//  IoToothbrush
//
//  Created by Matthew Lewinski on 5/8/16.
//  Copyright © 2016 Matthew Lewinski. All rights reserved.
//

import Foundation

struct BrushingEvent {
    var start: NSDate
    var end: NSDate
    var duration: Int
    var device: NSUUID?
}
