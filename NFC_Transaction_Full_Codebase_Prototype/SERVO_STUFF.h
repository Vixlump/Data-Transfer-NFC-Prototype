#include <Servo.h>


Servo myservo;  // create servo object to control a servo

// twelve servo objects can be created on most boards


int pos = 0;    // variable to store the servo position
int angle = 0;

bool moto_state = false;

void SERVO_setup() {

  myservo.attach(8);  // attaches the servo on pin 9 to the servo object
  myservo.write(angle);

}


void SERVO_loop() {
  if (moto_state && pos == 0) {
//    for (pos = 0; pos <= 180; pos += 1) { // goes from 0 degrees to 180 degrees
//
//      // in steps of 1 degree
//
//      myservo.write(pos);              // tell servo to go to position in variable 'pos'
//
//      delay(1);                       // waits 15ms for the servo to reach the position
//
//    }
//
//    for (pos = 180; pos >= 0; pos -= 1) { // goes from 180 degrees to 0 degrees
//
//      myservo.write(pos);              // tell servo to go to position in variable 'pos'
//
//      delay(1);                       // waits 15ms for the servo to reach the position
//
//    }

    // change angle of servo motor
    if(angle == 0)
      angle = 180;
    else if(angle == 180)
      angle = 0;

    // control servo motor arccoding to the angle
    myservo.write(angle);
    moto_state = false;
  }

}
