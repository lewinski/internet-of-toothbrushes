//
//  BrushingEventUploader.swift
//  IoToothbrush
//
//  Created by Matthew Lewinski on 5/8/16.
//  Copyright © 2016 Matthew Lewinski. All rights reserved.
//

import Foundation
import Alamofire

class BrushingEventUploader {
    func uploadBrushingEvent(event: BrushingEvent) {
        let apiEndpoint = "https://3ccrvcnr22.execute-api.us-east-1.amazonaws.com/prod/logBrushingEvent"
        let params = jsonParamsForBrushingEvent(event)
        Alamofire.request(.POST, apiEndpoint, parameters: params, encoding: .JSON)
    }

    private func jsonParamsForBrushingEvent(event: BrushingEvent) -> [String:AnyObject] {
        var jsonEvent = [String:String]()

        jsonEvent["Device"] = event.device?.UUIDString
        jsonEvent["Start"] = String(Int(event.start.timeIntervalSince1970))
        jsonEvent["End"] = String(Int(event.end.timeIntervalSince1970))
        jsonEvent["Duration"] = String(event.duration)

        let timeFormatter = NSDateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        jsonEvent["StartTime"] = timeFormatter.stringFromDate(event.start)
        jsonEvent["EndTime"] = timeFormatter.stringFromDate(event.end)

        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        jsonEvent["StartDate"] = dateFormatter.stringFromDate(event.start)
        jsonEvent["EndDate"] = dateFormatter.stringFromDate(event.end)

        return jsonEvent
    }
}
