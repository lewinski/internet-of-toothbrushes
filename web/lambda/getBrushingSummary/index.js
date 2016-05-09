'use strict';
console.log('Loading function');

let doc = require('dynamodb-doc');
let dynamo = new doc.DynamoDB();

exports.handler = (event, context, callback) => {
    dynamo.scan({"TableName": "ToothbrushEvents"}, function(err, data) {
        var summary = {};
        data.Items.forEach(function(brushingEvent) {
            if (!(brushingEvent.StartDate in summary)) {
                summary[brushingEvent.StartDate] = {
                    date: brushingEvent.StartDate,
                    count: 0,
                    duration: 0
                }
            }
            summary[brushingEvent.StartDate].count++;
            summary[brushingEvent.StartDate].duration += +brushingEvent.Duration;
        });
        var results = [];
        Object.keys(summary).sort().forEach(function (date) {
            summary[date].average = summary[date].duration / summary[date].count
            results.push(summary[date])
        });
        callback(null, results);
    });
};