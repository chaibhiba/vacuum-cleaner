#include <Arduino.h>
#include <WiFi.h>
#include <ESPAsyncWebServer.h>
#include <AsyncTCP.h>

// Wi-Fi credentials
const char* ssid     = "Test1234";
const char* password = "12345678";

// Motor pins
const int motor1Forward  = 25;
const int motor1Backward = 26;
const int motor2Forward  = 27;
const int motor2Backward = 14;
const int ENA = 32;
const int ENB = 33;

// Ultrasonic pins
const int trigPinFront = 5;
const int echoPinFront = 18;
const int trigPinRear  = 23;
const int echoPinRear  = 22;

// Relay pin for vacuum motor
const int relayPin = 4;

// Obstacle-avoidance threshold
const int OBSTACLE_THRESHOLD = 20; // cm

// Cleaning state
float cleaningArea = 0;
bool cleaningStatus = false;
bool cleaningJustFinished = false;
unsigned long lastAreaUpdate = 0;
int lastFrontDistance = -1;

// Variables to track the state of the movement
String currentMovement = "STOP";
float currentSpeedFactor = 0.0;

// Mode
enum Mode { IDLE, MANUAL, AUTOMATIC };
Mode currentMode = IDLE;
unsigned long autoEndTime = 0;
int autoPwm = 0;
String selectedPattern = "Square";
unsigned long patternStepStart = 0;


// Web server
AsyncWebServer server(80);


// Function declarations
void handleManualControl(String cmd, String speedStr);
void startAutomaticCleaning(int minutes, float speed, String pattern);
String getRobotStatus();
int measureDistance();
int measureRearDistance();
void stopMotors();
void backward(int pwm);
void right(int pwm);
void forward(int pwm);
void left(int pwm);
void runSquarePattern();
void runCirclePattern();
void runLinePattern();
void runRandomPattern();
void forwardLeft(int pwm);
void forwardRight(int pwm);
void backwardLeft(int pwm);
void backwardRight(int pwm);
void handleAutoNavigation();


/////////////////////////////SETUP///////////////////////////////////////////

void setup() {
  Serial.begin(115200);

  // Pin setup
  pinMode(motor1Forward, OUTPUT);
  pinMode(motor1Backward, OUTPUT);
  pinMode(motor2Forward, OUTPUT);
  pinMode(motor2Backward, OUTPUT);
  pinMode(ENA, OUTPUT);
  pinMode(ENB, OUTPUT);
  digitalWrite(ENA, LOW);
  digitalWrite(ENB, LOW);
  pinMode(trigPinFront, OUTPUT);
  pinMode(echoPinFront, INPUT);
  pinMode(trigPinRear, OUTPUT);
  pinMode(echoPinRear, INPUT);
  pinMode(relayPin, OUTPUT);
  digitalWrite(relayPin, LOW); 

  // Connect to Wi-Fi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.println("Connecting to WiFi...");
  }
  Serial.println("WiFi connected: " + WiFi.localIP().toString());

  // HTTP endpoints
  server.on("/control", HTTP_GET, [](AsyncWebServerRequest *req) {
    if (req->hasParam("cmd") && req->hasParam("speed")) {
      handleManualControl(req->getParam("cmd")->value(), req->getParam("speed")->value());
      req->send(200, "text/plain", "Command Received");
    } else {
      req->send(400, "text/plain", "Missing parameters");
    }
  });

  server.on("/automatic", HTTP_GET, [](AsyncWebServerRequest *req) {
    if (req->hasParam("duration") && req->hasParam("speed") && req->hasParam("pattern")) {
      startAutomaticCleaning(
        req->getParam("duration")->value().toInt(),
        req->getParam("speed")->value().toFloat(),
        req->getParam("pattern")->value()
      );
      req->send(200, "text/plain", "Automatic Cleaning Started");
    } else {
      req->send(400, "text/plain", "Missing parameters");
    }
  });

  server.on("/status", HTTP_GET, [](AsyncWebServerRequest *req) {
    cleaningJustFinished = false;
    req->send(200, "application/json", getRobotStatus());
  });

  server.begin();
}


////////////////////////////////////LOOP/////////////////////////

void loop() {
  if (currentMode == AUTOMATIC) {
    int front = measureDistance();
    int rear = measureRearDistance();


    // Always prioritize obstacle avoidance
    if ((front > 0 && front < OBSTACLE_THRESHOLD) || 
    (rear > 0 && rear < OBSTACLE_THRESHOLD)) {
      stopMotors();
      backward(autoPwm);
      delay(300);
      stopMotors();
      right(autoPwm);
      delay(400);
      stopMotors();
      patternStepStart = millis(); // Reset pattern timing
      return; // Skip pattern navigation this cycle
    }


    // Only proceed with pattern if no obstacle
    handleAutoNavigation();


    // area calculation 
    if (millis() - lastAreaUpdate >= 1000) {
      float robotWidth = 0.2; //20 cm
      float maxSpeed = 0.4; //0.4 m/s
      float actualSpeed = (autoPwm / 255.0) * maxSpeed * currentSpeedFactor;
      cleaningArea += robotWidth * actualSpeed;
      lastAreaUpdate = millis();
    }

    if (millis() >= autoEndTime) {
      stopMotors();
      digitalWrite(relayPin, HIGH); 
      currentMode = IDLE;
      cleaningStatus = false;
      cleaningJustFinished = true;
    }
  }
}


//////////////////////////////////////// FONCTION ////////////////////////////////////////////////////////////////////

void handleAutoNavigation() {
  if (selectedPattern == "Square") runSquarePattern();
  else if (selectedPattern == "Circle") runCirclePattern();
  else if (selectedPattern == "Line") runLinePattern();
  else if (selectedPattern == "Random") runRandomPattern();
  else forward(autoPwm);
}

void runSquarePattern() {
  unsigned long now = millis();
  if (now - patternStepStart < 2000) forward(autoPwm);
  else if (now - patternStepStart < 2500) right(autoPwm);
  else patternStepStart = now;
}

void runCirclePattern() {
  analogWrite(ENA, autoPwm);
  analogWrite(ENB, autoPwm);
  digitalWrite(motor1Forward, HIGH); digitalWrite(motor1Backward, LOW);
  digitalWrite(motor2Forward, HIGH); digitalWrite(motor2Backward, LOW);
}

void runLinePattern() {
  forward(autoPwm);
}

void runRandomPattern() {
  static unsigned long lastChange = 0;
  static int r = 0;
  if (millis() - lastChange > 3000) {
    r = random(0, 8);
    lastChange = lastChange = millis();
  }
  switch (r) {
    case 0: forward(autoPwm); break;
    case 1: backward(autoPwm); break;
    case 2: left(autoPwm); break;
    case 3: right(autoPwm); break;
    case 4: forwardLeft(autoPwm); break;
    case 5: forwardRight(autoPwm); break;
    case 6: backwardLeft(autoPwm); break;
    case 7: backwardRight(autoPwm); break;
  }
}

// ======================================
// motion functions to update the motion state
// ======================================

void forward(int pwm) {
  analogWrite(ENA, pwm); analogWrite(ENB, pwm);
  digitalWrite(motor1Forward, HIGH); digitalWrite(motor1Backward, LOW);
  digitalWrite(motor2Forward, HIGH); digitalWrite(motor2Backward, LOW);
  currentMovement = "FORWARD";
  currentSpeedFactor = 1.0; // عامل سرعة كامل
}

void backward(int pwm) {
  analogWrite(ENA, pwm); analogWrite(ENB, pwm);
  digitalWrite(motor1Forward, LOW); digitalWrite(motor1Backward, HIGH);
  digitalWrite(motor2Forward, LOW); digitalWrite(motor2Backward, HIGH);
  currentMovement = "BACKWARD";
  currentSpeedFactor = 0.0; // لا تحتسب مساحة للخلف
}

void left(int pwm) {
  analogWrite(ENA, pwm); analogWrite(ENB, pwm);
  digitalWrite(motor1Forward, LOW); digitalWrite(motor1Backward, HIGH);
  digitalWrite(motor2Forward, HIGH); digitalWrite(motor2Backward, LOW);
  currentMovement = "LEFT";
  currentSpeedFactor = 0.0; // حركة جانبية لا تحتسب
}

void right(int pwm) {
  analogWrite(ENA, pwm); analogWrite(ENB, pwm);
  digitalWrite(motor1Forward, HIGH); digitalWrite(motor1Backward, LOW);
  digitalWrite(motor2Forward, LOW); digitalWrite(motor2Backward, HIGH);
  currentMovement = "RIGHT";
  currentSpeedFactor = 0.0; // حركة جانبية لا تحتسب
}

void forwardLeft(int pwm) {
  analogWrite(ENA, pwm / 2); analogWrite(ENB, pwm);
  digitalWrite(motor1Forward, LOW); digitalWrite(motor1Backward, HIGH);
  digitalWrite(motor2Forward, LOW); digitalWrite(motor2Backward, HIGH);
  currentMovement = "FORWARD_LEFT";
  currentSpeedFactor = 0.75; // سرعة منخفضة بسبب الانعطاف
}

void forwardRight(int pwm) {
  analogWrite(ENA, pwm); analogWrite(ENB, pwm / 2);
  digitalWrite(motor1Forward, LOW); digitalWrite(motor1Backward, HIGH);
  digitalWrite(motor2Forward, LOW); digitalWrite(motor2Backward, HIGH);
  currentMovement = "FORWARD_RIGHT";
  currentSpeedFactor = 0.75; // سرعة منخفضة بسبب الانعطاف
}

void backwardLeft(int pwm) {
  analogWrite(ENA, pwm / 2); analogWrite(ENB, pwm);
  digitalWrite(motor1Forward, HIGH); digitalWrite(motor1Backward, LOW);
  digitalWrite(motor2Forward, HIGH); digitalWrite(motor2Backward, LOW);
  currentMovement = "BACKWARD_LEFT";
  currentSpeedFactor = 0.0; // لا تحتسب مساحة للخلف
}

void backwardRight(int pwm) {
  analogWrite(ENA, pwm);       // Left motor full speed backward
  analogWrite(ENB, pwm / 2);   // Right motor half speed backward (or 0 to pivot)
  
  // Set motors to BACKWARD direction:
  digitalWrite(motor1Forward, LOW);  digitalWrite(motor1Backward, HIGH);  // Left motor backward
  
  digitalWrite(motor2Forward, LOW);  digitalWrite(motor2Backward, HIGH);  // Right motor backward (or LOW to stop)
  
  currentMovement = "BACKWARD_RIGHT";
  currentSpeedFactor = 0.0;  // لا تحتسب مساحة للخلف
}


//////////// Motor STOP///////////////////////////////////////////////////////////////////

void stopMotors() {
  analogWrite(ENA, 0); analogWrite(ENB, 0);
  digitalWrite(motor1Forward, LOW); digitalWrite(motor1Backward, LOW);
  digitalWrite(motor2Forward, LOW); digitalWrite(motor2Backward, LOW);
  currentMovement = "STOP";
  currentSpeedFactor = 0.0; // توقف لا يحتسب
}

///////////////////////////////////////////Sensors/////////////////////////////////////////////////////

int getFilteredDistance(int trigPin, int echoPin) {
    const int NUM_READINGS = 5;
    static int readings[NUM_READINGS] = {0};
    static int index = 0;
    
    // Take new reading
    digitalWrite(trigPin, LOW);
    delayMicroseconds(2);
    digitalWrite(trigPin, HIGH);
    delayMicroseconds(10);
    digitalWrite(trigPin, LOW);
    long duration = pulseIn(echoPin, HIGH, 20000);
    int distance = duration * 0.034 / 2;
    
    ////////////////////////////////////// Store in array //////////////////////////////////////////////////////
    readings[index] = distance;
    index = (index + 1) % NUM_READINGS;
    
    // Calculate average
    int sum = 0;
    int validReadings = 0;
    for (int i = 0; i < NUM_READINGS; i++) {
        if (readings[i] > 0 && readings[i] < 400) { // Valid range
            sum += readings[i];
            validReadings++;
        }
    }
    
    return (validReadings > 0) ? sum / validReadings : -1;
}


int measureDistance() {
  return getFilteredDistance(trigPinFront, echoPinFront);
}

int measureRearDistance() {
  return getFilteredDistance(trigPinRear, echoPinRear);
}

void handleManualControl(String cmd, String speedStr) {
  currentMode = MANUAL;
  int pwm = (int)(speedStr.toFloat() * 255.0);
  if (cmd == "stop") {
    stopMotors();
    digitalWrite(relayPin, HIGH);
    return;
  }

 ////////////////////////////////////////////// Handle all movement commands//////////////////////////////////////////////////

  if (cmd == "forward") forward(pwm);
  else if (cmd == "backward") backward(pwm);
  else if (cmd == "left") left(pwm);
  else if (cmd == "right") right(pwm);
  else if (cmd == "forward_left") forwardLeft(pwm);
  else if (cmd == "forward_right") forwardRight(pwm);
  else if (cmd == "backward_left") backwardLeft(pwm);
  else if (cmd == "backward_right") backwardRight(pwm);

  digitalWrite(relayPin, LOW);
}

/////////////////////////////////// Automatic ////////////////////////////////////////////////

void startAutomaticCleaning(int minutes, float speed, String pattern) {
  currentMode = AUTOMATIC;
  cleaningStatus = true;
  cleaningJustFinished = false;
  cleaningArea = 0;
  autoPwm = (int)(speed * 255.0);
  autoEndTime = millis() + minutes * 60000UL;
  selectedPattern = pattern;
  patternStepStart = millis();
  digitalWrite(relayPin, LOW);
  
  // تهيئة حالة الحركة عند البدء
  currentMovement = "STOP";
  currentSpeedFactor = 0.0;
}

void avoidObstacle() {
    int frontDist = getFilteredDistance(trigPinFront, echoPinFront);
    int rearDist = getFilteredDistance(trigPinRear, echoPinRear);
    
    stopMotors();
    delay(200);
    
    // Front obstacle handling
    if (frontDist > 0 && frontDist < OBSTACLE_THRESHOLD) {
        if (rearDist == -1 || rearDist > OBSTACLE_THRESHOLD + 10) {
            backward(autoPwm);
            delay(calculateDelay(OBSTACLE_THRESHOLD + 10));
            stopMotors();
        }
        right(autoPwm);
        delay(500);
    }
    // Rear obstacle handling
    else if (rearDist > 0 && rearDist < OBSTACLE_THRESHOLD) {
        if (frontDist == -1 || frontDist > OBSTACLE_THRESHOLD + 10) {
            forward(autoPwm);
            delay(calculateDelay(OBSTACLE_THRESHOLD + 10));
            stopMotors();
        }
        left(autoPwm);
        delay(500);
    }
    // Complete blockage
    else if ((frontDist > 0 && frontDist < OBSTACLE_THRESHOLD) && 
             (rearDist > 0 && rearDist < OBSTACLE_THRESHOLD)) {
        right(autoPwm);
        delay(1000);
    }
    
    stopMotors();
    patternStepStart = millis();
}

// Status
String getRobotStatus() {
  lastFrontDistance = measureDistance();
  String json = "{";
  json += "\"status\":\"" + String(currentMode == IDLE ? "Idle" : currentMode == MANUAL ? "Manual" : "Automatic") + "\",";
  json += "\"cleaned_area\":" + String(cleaningArea * 10000, 2) + ",";
  json += "\"distance\":" + String(lastFrontDistance);
  json += "}";
  return json;
}