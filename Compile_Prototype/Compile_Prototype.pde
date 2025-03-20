import processing.serial.*;

Serial myPort;  // Create object from Serial class
String state = "MENU";  // Variable to track the current state
String currentAction = "Waiting for input...";  // Variable to store the current action
float distance = 0;  // Variable to store the parsed distance
boolean showSuccessMessage = false;  // Flag to control the success message display
long successMessageStartTime = 0;  // Timer for the success message

void setup() {
  size(400, 300);  // Set the size of the window
  background(255);  // Set background to white
  textSize(20);  // Set text size for display
  fill(0);  // Set text color to black

  println("Available serial ports:");
  println(Serial.list());  // List all available serial ports

  // Replace "COM3" with the port your Arduino is connected to
  String portName = Serial.list()[0];  // Change this to the correct port
  myPort = new Serial(this, portName, 9600);  // Initialize serial communication
  myPort.bufferUntil('\n');  // Buffer until a newline character is received
}

void draw() {
  background(255);  // Clear the screen on each frame

  // Draw the success message if the flag is true
  if (showSuccessMessage) {
    drawSuccessMessage();
    // Check if 5 seconds have passed
    if (millis() - successMessageStartTime > 5000) {
      showSuccessMessage = false;  // Hide the message after 5 seconds
    }
  } else {
    // Draw the normal interface if the success message is not being shown
    drawIndicator();
    drawDistanceIndicator();
  }
}

void serialEvent(Serial myPort) {
  String input = myPort.readStringUntil('\n').trim();  // Read the serial input
  if (input != null) {
    println("Received: " + input);  // Print the received input for debugging

    // Parse the distance from the input
    if (input.startsWith("Distance:")) {
      distance = parseDistance(input);  // Extract the distance value
      println("Parsed Distance: " + distance + " cm");

      // Only proceed if the distance is under 50 cm
      if (distance < 50) {
        println("Distance is under 50 cm. Ready for commands.");
      } else {
        println("Distance is over 50 cm. Ignoring commands.");
      }
    } else if (input.equals("Write successful!")) {
      // Show the success message for 5 seconds
      showSuccessMessage = true;
      successMessageStartTime = millis();  // Record the start time
    } else if (distance < 50) {
      // Handle commands only if distance is under 50 cm
      handleMenuInput(input);
    }
  }
}

// Function to parse the distance from the input string
float parseDistance(String input) {
  // Extract the numeric part of the string
  String distanceStr = input.substring(input.indexOf(":") + 1, input.indexOf("cm")).trim();
  return float(distanceStr);  // Convert to float and return
}

// Function to handle input in the MENU state
void handleMenuInput(String input) {
  if (input.equals("+")) {
    state = "MAKE_ACCOUNT";
    currentAction = "Make Account";
    makeAccount();
  } else if (input.equals("TEST")) {
    state = "VIEW_ACCOUNT";
    currentAction = "View Account";
    viewAccount();
  } else if (input.equals("-")) {
    state = "TRANSFER";
    currentAction = "Transfer";
    transfer();
  } else if (input.equals("RETURN")) {
    state = "MENU";  // Return to the menu state
    currentAction = "Waiting for input...";
  } else {
    println("Invalid command: " + input);
  }
}

// Function to draw the current state indicator
void drawIndicator() {
  fill(0);  // Set text color to black
  text("Current State: " + state, 50, 50);  // Display the current state
  text("Current Action: " + currentAction, 50, 80);  // Display the current action
  text("Distance: " + distance + " cm", 50, 110);  // Display the parsed distance

  // Draw a colored rectangle based on the current state
  if (state.equals("MAKE_ACCOUNT")) {
    fill(0, 255, 0);  // Green for Make Account
    rect(50, 150, 300, 100);  // Draw a rectangle
  } else if (state.equals("VIEW_ACCOUNT")) {
    fill(0, 0, 255);  // Blue for View Account
    rect(50, 150, 300, 100);  // Draw a rectangle
  } else if (state.equals("TRANSFER")) {
    fill(255, 0, 0);  // Red for Transfer
    rect(50, 150, 300, 100);  // Draw a rectangle
  } else if (state.equals("MENU")) {
    fill(128);  // Gray for Menu
    rect(50, 150, 300, 100);  // Draw a rectangle
  }
}

// Function to draw the distance indicator (green/red circle)
void drawDistanceIndicator() {
  if (distance < 50) {
    fill(0, 255, 0);  // Green for under 50 cm
  } else {
    fill(255, 0, 0);  // Red for 50 cm or over
  }
  noStroke();  // Remove the outline of the circle
  ellipse(width - 50, 50, 50, 50);  // Draw a circle at the top-right corner
}

// Function to draw the success message
void drawSuccessMessage() {
  background(0, 255, 0);  // Set background to green
  fill(255);  // Set text color to white
  textSize(30);  // Increase text size for the message
  textAlign(CENTER, CENTER);  // Center the text
  text("Account Created", width / 2, height / 2);  // Display the message
}

// Placeholder function for making an account
void makeAccount() {
  println("Make Account selected");
  // Add your logic here to create a new account
}

// Placeholder function for viewing an account
void viewAccount() {
  println("View Account selected");
  // Add your logic here to view an account
}

// Placeholder function for transferring funds
void transfer() {
  println("Transfer selected");
  // Add your logic here to transfer funds
}
