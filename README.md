# ![](images/icon/Icon-83.5@2x.png)

# Internet of Toothbrushes

This repository contains my capstone project for the Spring 2016 session of the SEIS 785 Topics: Internet of Things class at the University of St. Thomas. This readme file helps explain the layout of the repository and how the pieces fit together.

More details on the project can be found in the presentation located in the `slides` directory.

## Motivation

A lot of recently published research suggests that poor dental health is a risk factor to a number of other health issues including kidney disease, heart disease, and Alzheimer's. The article "[Mind Your Mouth: How Oral Health Affects Overall Health](http://health.usnews.com/health-news/health-wellness/articles/2014/12/22/mind-your-mouth-how-oral-health-affects-overall-health)" is a good overview with more details. For some people, poor dental health may simply be caused by bad habits and forgetfulness.

The IoToothbrush is a technology-enabled toothbrush that helps people learn better dental health habits so that they can avoid periodontal disease and the related elevated risks of other health problems. People may just be interested in improving their own habits, but the IoToothbrush would also be a useful tool for keeping track of one's elderly parents or children. Because the toothbrush is designed so you don't have to do things differently, it is easily adopted into your life and usable by all ages.

## Overview

The Internet of Toothbrushes project consists of the following components:

* A tracking device that clips onto a toothbrush, based on PunchThrough Design's LightBlue Bean
* A companion iOS Application that can get data from the tracking device
* A scalable data service based on Amazon Web Services

## Tracking Device

The firmware for the Bean-based tracking device is compiled in Arduino and programmed using Bean Loader. The source code is in the `firmware` directory. There are photos of the tracking device hardware in various stages of construction in the `images/hardware` directory.

The tracking device is generally in a deep sleep mode to conserve battery power. When the [fast vibration sensor](https://www.adafruit.com/product/1766) is tripped, it will generate a pin change hardware interrupt which will wake the device up. Once it is on, it will note the start time from the [real time clock](https://www.adafruit.com/products/3013) and continuously query the accelerometer to see if the device is moving around. If it has not moved for a short period of time, then it considers toothbrushing to be done and will re-enter deep sleep.

The tracking device may also be waked by a bluetooth connection from the iOS application. The application and the firmware communicate over a serial connection with a simple line-oriented interface.

## Companion Application

The companion application runs on iOS 9, and was tested on an iPhone 6. The source code for the application is in the `ios` directory and there are screenshots of the application in the `images/screenshots` directory. This application uses the [Bean SDK](https://github.com/PunchThrough/Bean-iOS-OSX-SDK) to discover and connect to tracking devices running the firmware.

Once connected, the application will read data from the tracking device and then forward it to the data service using [Alamofire](https://github.com/Alamofire/Alamofire) to access a simple REST API.

The charts for the companion application are implemented by hosting an local HTML file in a UIWebView. This allows the data for the charts to be loaded from the data service using [jQuery](http://jquery.com)'s Ajax helper functions and passed to [Chart.js](http://www.chartjs.org) for data visualization.

## Data Service

The data service is built on top of Amazon Web Services to enable scalability. Requests are directed to the [Amazon API Gateway](https://aws.amazon.com/api-gateway/) service, which then routes to Javascript code running in [AWS Lambda](https://aws.amazon.com/lambda/). The Lambda services read and write to an [Amazon DynamoDB](https://aws.amazon.com/dynamodb/) table.

The only real code for the data service is the Lambda files, which are in the `web/lambda` directory. The other services were entirely configured through the AWS Console.

Because of how the data service is put together, it is theoretically quite scalable. These limits were obviously not tested with only a single device in service.
