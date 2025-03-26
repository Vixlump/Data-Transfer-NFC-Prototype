#include <DIYables_IRcontroller.h>
#include "pitches.h"
#include "NFC_STUFF.h"
#include "SERVO_STUFF.h"

// ULTRASONIC SENSOR
int trigPin = 7;    // TRIG pin
int echoPin = A0;    // ECHO pin
float duration_us, distance_cm;

// IR SENSOR
DIYables_IRcontroller_21 irController(6, 200); // Pin 6, debounce time is 200ms

Key21 key;


// PIEZO BUZZER
  int BUZZER_PIN = 5; // Arduino pin connected to Buzzer's pin

  // Notes in the melody:
  int successMelody[] = {
    NOTE_E6, NOTE_G6, NOTE_E7, NOTE_C7, NOTE_D7, NOTE_G7
  };
  
  int failMelody[] = {
    NOTE_E3, NOTE_E3
  };
  
  // Note durations: 4 = quarter note, 8 = eighth note, etc:
  int successNoteDurations[] = {
    8, 8, 8, 8, 8, 8
  };
  
  int failNoteDurations[] = {
    8, 4
  };



void setup() {
  Serial.begin(9600);

  // ULTRASONIC SENSOR
  // Configure the trigger pin to output mode
  pinMode(trigPin, OUTPUT);
  // Configure the echo pin to input mode
  pinMode(echoPin, INPUT);

  // IR SENSOR
  irController.begin();

  // PIEZO BUZZER
  pinMode(BUZZER_PIN, OUTPUT); // Set the buzzer pin as an output
  
  NFC_setup();
  SERVO_setup();
}

void loop() {

  

  if (Serial.available()) {
        irSensorReading();
        char choice = Serial.read();
        if (choice == 'I') {
            ultrasonicSensorReading();
        } else if (choice == 'R') {
            Serial.println("Read mode selected. Scan an NFC card...");
            readCard();
        } else if (choice == 'W') {
            Serial.println("Write mode selected. Enter text:");
            writeCard();
        } else if (choice == 'A') {
            Serial.println("Received '1'. Playing success melody...");
            makeNoise(successMelody, successNoteDurations, sizeof(successNoteDurations) / sizeof(int)); // Call the function to make noise
            irController.begin();
        } else if (choice == 'B') {
            Serial.println("Received '2'. Playing fail melody...");
            makeNoise(failMelody, failNoteDurations, sizeof(failNoteDurations) / sizeof(int));
            irController.begin();
        } else if (choice == 'M') {
            moto_state = true;
        }
        
    }
  if (!Serial.available()) {
    irSensorReading();
  }

  SERVO_loop();
  
  delay(10);
}

float ultrasonicSensorReading() {
  // Generate 10-microsecond pulse to TRIG pin
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  // Measure duration of pulse from ECHO pin
  duration_us = pulseIn(echoPin, HIGH);

  // Calculate the distance
  distance_cm = 0.017 * duration_us;

  // Print the value to Serial Monitor
  Serial.print("Distance: ");
  Serial.print(distance_cm);
  Serial.println(" cm"); // Send distance to Processing
  delay(500);
  return distance_cm;
}

void irSensorReading(){
  key = irController.getKey();
  if (key != Key21::NONE) {
    //Serial.println("IR_HIT");
    moto_state = true;
    switch (key) {
      case Key21::KEY_CH_MINUS:
        Serial.println("POWER");
        // TODO: YOUR CONTROL
        break;

      case Key21::KEY_CH:
        Serial.println("NONE");
        // TODO: YOUR CONTROL
        break;

      case Key21::KEY_CH_PLUS:
        Serial.println("MENU");
        // TODO: YOUR CONTROL
        break;

      case Key21::KEY_PREV:
        Serial.println("TEST");
        // TODO: YOUR CONTROL
        break;

      case Key21::KEY_NEXT:
        Serial.println("+");
        // TODO: YOUR CONTROL
        break;

      case Key21::KEY_PLAY_PAUSE:
        Serial.println("RETURN");
        // TODO: YOUR CONTROL
        break;

      case Key21::KEY_VOL_MINUS:
        Serial.println("BACK");
        // TODO: YOUR CONTROL
        break;

      case Key21::KEY_VOL_PLUS:
        Serial.println("PLAY");
        // TODO: YOUR CONTROL
        break;

      case Key21::KEY_EQ:
        Serial.println("SKIP");
        // TODO: YOUR CONTROL
        break;

      case Key21::KEY_100_PLUS:
        Serial.println("-");
        // TODO: YOUR CONTROL
        break;

      case Key21::KEY_200_PLUS:
        Serial.println("C");
        // TODO: YOUR CONTROL
        break;

      case Key21::KEY_0:
        Serial.println("0");
        // TODO: YOUR CONTROL
        break;

      case Key21::KEY_1:
        Serial.println("1");
        // TODO: YOUR CONTROL
        break;

      case Key21::KEY_2:
        Serial.println("2");
        // TODO: YOUR CONTROL
        break;

      case Key21::KEY_3:
        Serial.println("3");
        // TODO: YOUR CONTROL
        break;

      case Key21::KEY_4:
        Serial.println("4");
        // TODO: YOUR CONTROL
        break;

      case Key21::KEY_5:
        Serial.println("5");
        // TODO: YOUR CONTROL
        break;

      case Key21::KEY_6:
        Serial.println("6");
        // TODO: YOUR CONTROL
        break;

      case Key21::KEY_7:
        Serial.println("7");
        // TODO: YOUR CONTROL
        break;

      case Key21::KEY_8:
        Serial.println("8");
        // TODO: YOUR CONTROL
        break;

      case Key21::KEY_9:
        Serial.println("9");
        // TODO: YOUR CONTROL
        break;

      default:
        Serial.println("WARNING: undefined key:");
        break;
    }
    //Serial.println("IR_END");
  }
}

void makeNoise(int melody[], int noteDurations[], int size) {
  Serial.println("NOISE_HIT");
  // Iterate over the notes of the melody:
  for (int thisNote = 0; thisNote < size; thisNote++) {
    // To calculate the note duration, take one second divided by the note type.
    // e.g., quarter note = 1000 / 4, eighth note = 1000 / 8, etc.
    int noteDuration = 1000 / noteDurations[thisNote];
    tone(BUZZER_PIN, melody[thisNote], noteDuration);

    // To distinguish the notes, set a minimum time between them.
    // The note's duration + 30% seems to work well:
    int pauseBetweenNotes = noteDuration * 1.30;
    delay(pauseBetweenNotes);
    // Stop the tone playing:
    noTone(BUZZER_PIN);
  }
  Serial.print("NOISE_END");
}
