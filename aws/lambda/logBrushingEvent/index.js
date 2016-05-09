'use strict';
console.log('Loading function');

let doc = require('dynamodb-doc');
let dynamo = new doc.DynamoDB();

exports.handler = (event, context, callback) => {
    var item = {
        TableName: "ToothbrushEvents",
        Item: event
    }
    dynamo.putItem(item, callback);
};