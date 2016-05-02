/*
 * Bean Firmware for SEIS 785 Project
 *
 * Pin Usage on the Bean:
 * - A0 : I2C connection to RTC
 * - A1 : I2C connection to RTC
 * - D0 : Wakeup when switch pulls pin to GND
 *
 * While connected over serial, commands to get/set data from the firmware are
 * available. Each command must be followed by a newline.
 *
 * - 'GetRTC'         : print the current unix timestamp from the RTC
 * - 'SetRTC <value>' : set the RTC's unix timestamp to value
 * - 'GetLastEvent'   : prints the start/stop/duration of the last brushing event
 */

#include <PinChangeInt.h>
#include <Wire.h>
#include "RTClib.h"

// The pin that the wake-up switch is attached to
#define PIN_WAKE 0

// Accelerometer range to configure during startup
#define ACCELERATION_RANGE 8

// How large a difference in accelerometer readings should we
// treat as being "equal". When the the accelerometer readings
// are equal for some length of time, we assume that the device
// is no longer being used. It feels like range * epsilon should
// be about 50, which corresponds to 5% of g.
#define ACCELERATION_EPSILON 6

// How many millis to sleep when we're in an "active" state in
// the state machine.
#define SLEEP_AMOUNT 1000

// After waking up, how many SLEEP_AMOUNTs of idle should indicate
// that the device has stopped moving.
#define MOVEMENT_TIMEOUT 10

// While the app is connected, after how many SLEEP_AMOUNTs will
// we disconnect if it hasn't sent any data.
#define IDLE_CONNECTION_TIMEOUT 15

#define SERIAL_BUFFER_LENGTH 200

// Firmware state machine
enum ToothbrushState {
  Idle,                 // Sleeping forever, waiting for an interrupt
  StartBrushing,        // Waking up because PIN_WAKE was triggered
  Brushing,             // Monitoring accelerometer for brushing
  DoneBrushing,         // Ready to return to Idle state
  AppConnected          // Connected to BLE central, waiting for serial commands
};

// Global variables for ultimate hubris
volatile ToothbrushState  currentState = Idle;
RTC_DS3231                rtc;
DateTime                  currentTime;
uint32_t                  brushingStartedTimestamp = 0;
uint32_t                  brushingStoppedTimestamp = 0;
uint32_t                  brushingSessionLength = 0;
AccelerationReading       lastAcceleration;
AccelerationReading       currentAcceleration;
AccelerationReading       deltaAcceleration;
uint8_t                   brushingStillLoops;
uint8_t                   idleConnectionLoops;
char                      commandBuffer[SERIAL_BUFFER_LENGTH];
char                      commandBufferLength = 0;

/**
 * Interrupt Service Routine (ISR) for waking up via switch
 *
 * This function can't do anything too expensive, because it
 * could potentially get interrupted by another interrupt.
 * So, if we are in the idle state, lets transition to the
 * waking up state. If we are not in the idle state, then that
 * is unexpected, but we shouldn't try to chane the state.
 */
void pinChanged() {
  if (currentState == Idle) {
    currentState = StartBrushing;
  }
}

/**
 * Read a command from the serial connection
 *
 * @todo This function should be more resilient to long inputs.
 *
 * @return bool true if serial data was read
 */
bool readSerialCommand() {
  char c;

  if (!Serial.available()) {
    return false;
  }

  // Read everything available, or until we have an entire line
  reading:
  c = 0;

  while (Serial.available() && c != '\n') {
    c = Serial.read();
    commandBuffer[commandBufferLength++] = c;
  }

  // If we got a whole command, then handle it and go back to accumulating the next one
  if (c == '\n') {
    commandBuffer[commandBufferLength] = 0;
    handleSerialCommand();
    commandBufferLength = 0;
    goto reading;
  }

  return true;
}

/**
 * Command handler for serial commands
 */
void handleSerialCommand() {
  if (strncmp("GetRTC", commandBuffer, 6) == 0) {
    currentTime = rtc.now();
    Serial.println(currentTime.unixtime());

  } else if (strncmp("SetRTC ", commandBuffer, 7) == 0) {
    uint32_t timestamp = strtoul(commandBuffer + 7, NULL, 10);
    RTC_DS3231::adjust(DateTime(timestamp));
    Serial.println("ok");

  } else if (strncmp("GetLastEvent", commandBuffer, 12) == 0) {
    Serial.println(brushingStartedTimestamp);
    Serial.println(brushingStoppedTimestamp);
    Serial.println(brushingSessionLength);

  } else {
    Serial.print("unknown command: ");
    Serial.println(commandBuffer);
  }
}

void setup() {
  // Bean Setup
  Bean.setBeanName("IoToothbrush");
  Bean.setAccelerationRange(ACCELERATION_RANGE);
  Bean.enableWakeOnConnect(true);

  // Communication with the iOS Application
  Serial.begin();

  // The wake-up pin should have pull-up resistors to avoid floating voltages
  pinMode(PIN_WAKE, INPUT_PULLUP);

  // Prototyping only: using D4 and D5 to provide power to other components
  #define PIN_VCC 4
  #define PIN_GND 5
  pinMode(PIN_VCC, OUTPUT);
  digitalWrite(PIN_VCC, HIGH);
  pinMode(PIN_GND, OUTPUT);
  digitalWrite(PIN_GND, LOW);
}

void loop() {
  // When the serial port is connected, then we'll be in the app connected state instead
  // of on the idle/brushing cycle.
  // @todo This could be improved so we wouldn't lose track of brushing if the app decided
  // to sync while the device was being used.
  if (Bean.getConnectionState()) {
    if (currentState != AppConnected) {
      Serial.println("Hello from IoToothbrush!");
      idleConnectionLoops = 0;
      currentState = AppConnected;
    }
  } else if (currentState == AppConnected) {
    currentState = Idle;
  }

  switch (currentState) {
    case Idle:
      // Attach ISR so we know when the wake up switch is triggered
      attachPinChangeInterrupt(PIN_WAKE, pinChanged, FALLING);

      // Enter permanent lower power sleep
      Bean.setLed(0, 0, 0);
      Bean.sleep(0xFFFFFFFF);

      // We woke up, so lets disable the ISR until we go into sleep again
      detachPinChangeInterrupt(PIN_WAKE);
      break;

    case AppConnected:
      // Set the LED blue while the app is connected.
      Bean.setLed(0, 0, 128);

      // If we read a serial command, then reset the idle counter to zero.
      // Otherwise, we had nothing to read, so this is an idle loop.
      if (readSerialCommand()) {
        idleConnectionLoops = 0;
      } else {
        idleConnectionLoops++;
      }

      // If we exceeded the idle timeout, then disconnect.
      if (idleConnectionLoops >= IDLE_CONNECTION_TIMEOUT) {
        Serial.println("Timed Out; Goodbye.");
        Bean.disconnect();
      } else {
        Bean.sleep(SLEEP_AMOUNT);
      }

      break;

    case StartBrushing:
      // Set the LED green while we are brushing
      Bean.setLed(0, 128, 0);

      // Start brushing
      currentTime = rtc.now();
      brushingStartedTimestamp = currentTime.unixtime();
      brushingStoppedTimestamp = 0;
      brushingSessionLength = 0;

      // Set up for the Brushing state
      currentAcceleration = Bean.getAcceleration();
      brushingStillLoops = 0;

      // Transition to Brushing state
      currentState = Brushing;

      // Wait a bit before entering next state
      Bean.sleep(SLEEP_AMOUNT);
      break;

    case Brushing:
      // Get new acceleration values
      lastAcceleration = currentAcceleration;
      currentAcceleration = Bean.getAcceleration();

      // Calculate absolute deviation from previous values
      deltaAcceleration.xAxis = abs(lastAcceleration.xAxis - currentAcceleration.xAxis);
      deltaAcceleration.yAxis = abs(lastAcceleration.yAxis - currentAcceleration.yAxis);
      deltaAcceleration.zAxis = abs(lastAcceleration.zAxis - currentAcceleration.zAxis);

      // If any deviation is greater than our error delta, then we're still moving
      if (deltaAcceleration.xAxis > ACCELERATION_EPSILON ||
          deltaAcceleration.yAxis > ACCELERATION_EPSILON ||
          deltaAcceleration.zAxis > ACCELERATION_EPSILON)
      {
        brushingStillLoops = 0;
      } else {
        brushingStillLoops++;
        if (brushingStillLoops >= MOVEMENT_TIMEOUT) {
          currentState = DoneBrushing;
        }
      }

      // Wait a bit before checking again
      Bean.sleep(SLEEP_AMOUNT);

      break;

    case DoneBrushing:
      // Get the end time of the brushing event
      currentTime = rtc.now();
      brushingStoppedTimestamp = currentTime.unixtime() - MOVEMENT_TIMEOUT;

      brushingSessionLength = brushingStoppedTimestamp - brushingStartedTimestamp;

      // Transition to the Idle state
      currentState = Idle;
      break;
  }
}


