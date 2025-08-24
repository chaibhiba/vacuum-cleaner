#ifndef ANALOGWRITE_ESP32
#define ANALOGWRITE_ESP32

#include <Arduino.h>

static int _analogWriteChannel[40];

void analogWrite(uint8_t pin, int value) {
  if (_analogWriteChannel[pin] == 0) {
    _analogWriteChannel[pin] = 1 + pin % 15; // Avoid channel 0 used by Servo
    ledcSetup(_analogWriteChannel[pin], 5000, 8);
    ledcAttachPin(pin, _analogWriteChannel[pin]);
  }
  ledcWrite(_analogWriteChannel[pin], value);
}

#endif
