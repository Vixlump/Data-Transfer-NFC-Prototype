import processing.serial.*;

//Processing Components
Serial myPort;

//FRONT END
String status = "Welcome\nto the\nNFC Reader"; 
String currentInput = ""; 

int screenSelect = 1; 
int screen = -1; //9 = Menu, 1 = Make Account; 2 = Transfer; 3 = View Account; 4 = Error

int incorrectPinStartTime = -1; //Timer to initialize if user enter the wrong PIN. DO NOT TOUCH
int transferSuccessStartTime = -1; //Timer to initialize if a transaction is a success. DO NOT TOUCH 

String transferAmount = ""; //String of amount needed to be trasnferred. to be parsed into an int once all details of transaction is confirmed 
String pin = ""; // PIN string to be written into for displaying user profile 

String userSendPin = ""; //Sender's PIN
String userReceivePin = ""; // Receiver's PIN 

float distance = 9999; //Distance of sonar 

//Helper booleans 
boolean isCardScanned = false; //For creating new users and viewing user's profile 
boolean isPinConfirmed = false; //For confirming user's profile 
boolean isSenderCardScanned = false; 
boolean isReceiverCardScanned = false; 
boolean isSenderPinConfirmed = false; 
boolean isReceiverPinConfirmed = false; 
boolean isAmountConfirmed = false; 
boolean isPinIncorrect = false; 

int transferState = 0;
int signalState = 0;

User userCreate = new User("userMake", 100, "1234"); 
User userSend = new User("user1", 1000, "1234"); 
User userReceive = new User("user2", 500, "2345"); 
User userProfile = new User("userProfile", 0, "1234");

//Adding account stuff
int fileCounter = 0;
String fileName = "";
boolean isUserCreated = false;
boolean isReadyCreate = false;
boolean isCardWrittenTo = false;  // Marks if NFC write was successful and drawCreate should run

String typedName = "";
boolean isNameEntered = false;


String card_data = "";
String card_data_from = "";

String card_data_to = "";
String remote_code = "";

PFont fancyFont;
color gold = color(187, 155, 61);
color bgColor = color(240);
color primary = color(44, 62, 80);
color accent = color(52, 152, 219);
color softGreen = color(46, 204, 113);
color softRed = color(231, 76, 60);
float glowPulse = 0;
color highlight = color(52, 152, 219);

void setup() {
  fullScreen();
  //size(800, 600);
  smooth(8);
  fancyFont = createFont("Georgia", 24);
  textFont(fancyFont);
  
  println("Available serial ports:");
  println(Serial.list());  // List all available serial ports

  // Replace "COM3" with the port your Arduino is connected to
  String portName = Serial.list()[3];  // Change this to the correct port
  myPort = new Serial(this, portName, 9600);  // Initialize serial communication
  myPort.bufferUntil('\n');  // Buffer until a newline character is received
}

int draw_timer = 0;
boolean transferOnce = false;

void draw() {
  drawGradientBackground(); // fancy bg
  drawFloatingStatus();     // floating status text

  if (isPinIncorrect) {
    status = "Incorrect PIN :(";

    if (!transferOnce) {
      myPort.write("B");
      transferOnce = true;
    }

    if (millis() - incorrectPinStartTime > 3000) {
      reset();
    }
    return;
  }

  switch (screen) {
    case -1:
      if (draw_timer == 40) myPort.write("I");
      status = "Please approach the device.";
      drawDistanceIndicator();
      if (distance < 100) screen = 0;
      break;
    case 0:
      status = "Welcome to the\nNFC Transaction System";
      drawMenu();
      break;
    case 1:
      if (!isNameEntered) {
        status = "Enter your name:";
        drawNameInput();
        return;
      }

      if (!isCardWrittenTo && !isReadyCreate) {
        fileName = nf(int(random(1000)), 4);
        myPort.write("W " + fileName);
        fileName += ".txt";
        status = "Please Scan Your Card";
        isReadyCreate = true;
      }

      if (isCardWrittenTo) {
        status = "Account created\nsuccessfully!";
        drawCreate();
      }
      break;
    case 2:
      handleTransferFlow();
      break;
    case 3:
      handleProfileFlow();
      break;
  }

  draw_timer = (draw_timer + 1) % 100;
}

void drawGradientBackground() {
  for (int i = 0; i < height; i++) {
    stroke(lerpColor(color(230, 230, 255), color(255, 245, 230), i / float(height)));
    line(0, i, width, i);
  }
}

void drawFloatingStatus() {
  pushStyle();
  textAlign(LEFT);
  textSize(32);
  fill(50, 100, 200, 200);
  text(status, 50, 80 + sin(frameCount * 0.03) * 5);
  popStyle();
}


// Fancy glowing distance indicator
void drawDistanceIndicator() {
  pushStyle(); 
  noStroke();
  
  float glowAlpha = 100 + sin(frameCount * 0.1) * 50;
  color glowColor = distance < 50 ? softGreen : softRed;

  fill(glowColor, glowAlpha);
  ellipse(525, 125, 70, 70);

  fill(glowColor);
  ellipse(525, 125, 50, 50);

  popStyle(); 
}

void handleTransferFlow() {
  switch (transferState) {
    case 0:
      status = "Sender, please\nscan your card";
      if (signalState == 0) { myPort.write("R"); signalState = 1; }
      if (remote_code.contains("NFC:ReadPass")) {
        card_data_from = card_data;
        transferState = 1;
        isSenderCardScanned = true;
      }
      break;
    case 1:
      status = "Sender, please\nenter your PIN and press  ▶";
      drawConfirmPin();
      if (isSenderPinConfirmed) transferState = 2;
      break;
    case 2:
      status = "How much\ndo you\nwant to transfer? press  ▶  to confirm.";
      drawAmount();
      if (isAmountConfirmed) transferState = 3;
      break;
    case 3:
      status = "Receiver, please\nscan your card";
      if (signalState == 1) { myPort.write("R"); signalState = 2; }
      if (remote_code.contains("NFC:ReadPass")) {
        card_data_to = card_data;
        transferState = 4;
        isReceiverCardScanned = true;
      }
      break;
    case 4:
      status = "Receiver, please\nenter your PIN and press  ▶ ";
      drawConfirmPin();
      if (isReceiverPinConfirmed) transferState = 6;
      break;
    case 5:
      status = "Transaction Failed :(";
      break;
    case 6:
      if (!transferOnce) {
        userSend.amount_old = int(loadAccountBal(card_data_from));
        userReceive.amount_old = int(loadAccountBal(card_data_to));
        
        userReceive.name = loadAccountName(card_data_to);
        userSend.name = loadAccountName(card_data_from);
        userReceive.amount = int(loadAccountBal(card_data_to));
        userSend.amount = int(loadAccountBal(card_data_from));
        
        status = "Transaction Success!";
        status += "\n Account: " + userSend.name + "\nSent " + transferAmount;
        status += "\nTo: " + userReceive.name;
        status += "\nSender " + userSend.amount_old + " -> " + userSend.amount;
        status += "\nReceiver " + userReceive.amount_old + " -> " + userReceive.amount;
        status += "\n" + transferAmount(card_data_from, card_data_to, float(transferAmount));
        text("Press arrow button twice to return to the menu", 100, 550);
        myPort.write("A");
        transferOnce = true;
      }
      //if (millis() - transferSuccessStartTime > 3000) {reset();}
      break;
  }
}

void handleProfileFlow() {
  if (remote_code.contains("NFC:ReadPass")) {
    isCardScanned = true;
    status = "Please Enter your PIN and wait...";
  }

  if (isPinConfirmed) {
    status = "Your Profile";
    drawProfile();
  } else if (isCardScanned) {
    drawConfirmPin();
    if (draw_timer == 1 && comparePin(card_data, pin)) {
      isPinConfirmed = true;
      userProfile.name = loadAccountName(card_data);
      userProfile.amount = int(loadAccountBal(card_data));
      userProfile.pin = pin;
    }
  } else {
    myPort.write("R");
    isCardScanned = true;
    status = "Please Scan Your Card";
  }
}

// Draw a pretty button-like menu item
void drawMenuItem(String label, int y, int id) {
  pushStyle();
  rectMode(CENTER);
  textAlign(CENTER, CENTER);
  fill(screenSelect == id ? gold : primary);
  stroke(200);
  strokeWeight(1);
  rect(150, y, 200, 40, 12);

  fill(255);
  text(label, 150, y);
  popStyle();
}

// Helper for labeled fields with fancy underline
void drawLabeledText(String label, String value, int y) {
  fill(primary);
  textAlign(LEFT);
  text(label + ": " + value, 100, y);
  stroke(accent);
  strokeWeight(1);
  line(100, y + 5, 400, y + 5);
}

void drawMenu() {
  background(bgColor);
  drawDistanceIndicator();

  pushStyle();
  textSize(24);
  fill(primary);
  text("Main Menu", 100, 200);
  fill(3, 77, 148);
  text(status, 100, 100);
  fill(0);
  popStyle();

  drawMenuItem("Create", 300, 1);
  drawMenuItem("Transfer", 360, 2);
  drawMenuItem("Profile", 420, 3);

  // Explanation for each menu item
  String explanation = "";
  if (screenSelect == 1) {
    explanation = "Create - Creates an account on the NFC card.";
  } else if (screenSelect == 2) {
    explanation = "Transfer - Transfer money between two NFC cards.";
  } else if (screenSelect == 3) {
    explanation = "Profile - View your name, balance, and PIN.";
  }

  // Render explanation text
  pushStyle();
  fill(70);
  textSize(20);
  textAlign(LEFT);
  text(explanation, 100, 500);
  popStyle();

  // Navigation help
  pushStyle();
  fill(100);
  textSize(18);
  textAlign(LEFT);
  text("Use + and - on the number pad to navigate. Press  ▶ ︎to select.", 100, 550);
  popStyle();
}

void drawConfirmPin() {
  background(bgColor);
  pushStyle();
  textSize(24);
  text(status, 100, 100);

  String displayedPin = isReceiverCardScanned ? userReceivePin :
                        isSenderCardScanned ? userSendPin :
                        isCardScanned ? pin : "";

  if (!displayedPin.equals("")) {
    fill(primary);
    textAlign(LEFT);
    text("Your PIN is:", 100, 250);

    textSize(32);
    fill(highlight);
    text(displayedPin, 100, 300);
  }
  popStyle();
}

void drawCreate() {
  background(bgColor);
  textSize(24);
  text(status, 100, 100);
  fill(0, 200, 0);
  text("Press arrow button twice to return to the menu", 100, 250);
  fill(0);
  drawLabeledText("Name", userCreate.name, 300);
  drawLabeledText("Amount", str(userCreate.amount), 350);
  drawLabeledText("PIN", userCreate.pin, 400);

  if (!isUserCreated) {
    userCreate.name = typedName;
    userCreate.pin = makeAccount(fileName, userCreate.name, userCreate.amount);
    isUserCreated = true;
  }
}

void drawNameInput() {
  background(bgColor);
  textSize(24);
  fill(primary);
  text(status, 100, 100);
  text("Name: " + typedName + "_", 100, 300);
  fill(120);
  text("Press ENTER when done", 100, 350);
}

void drawAmount() {
  background(bgColor);
  textSize(24);
  text(status, 100, 100);
  drawLabeledText("Amount", transferAmount, 300);
}

void drawTransfer() {
  background(bgColor);
  textSize(24);
  text(status, 100, 100);
  fill(primary);
  text(userSend.name, 100, 350);
  drawArrow(190, 345, 50, 0);
  text(userReceive.name, 270, 350);
}

void drawProfile() {
  background(bgColor);
  textSize(20);
  text("Press arrow button to return to the menu", 100, 230);
  textSize(24);
  text(status, 100, 100);
  drawLabeledText("Name", userProfile.name, 300);
  drawLabeledText("Amount", str(userProfile.amount), 350);
  drawLabeledText("PIN", userProfile.pin, 400);
}


void reset() {
  status = "Welcome\nto the\nNFC Reader"; 
  currentInput = ""; 
  
  screenSelect = 1; 
  screen = -1;
  incorrectPinStartTime = -1; 
  transferSuccessStartTime = -1; 
  transferAmount = ""; 
  pin = ""; 
  userSendPin = ""; 
  userReceivePin = ""; 
  
  isCardScanned = false; 
  isPinConfirmed = false; 
  isSenderCardScanned = false; 
  isReceiverCardScanned = false; 
  isSenderPinConfirmed = false; 
  isReceiverPinConfirmed = false; 
  isAmountConfirmed = false; 
  isPinIncorrect = false; 
  
  //ADD ACCOUNT STUFF
  // Reset flags related to account creation
  isUserCreated = false;
  isReadyCreate = false;
  isCardWrittenTo = false;
  typedName = "";
  isNameEntered = false;
  
  transferState = 0;

  signalState = 0;

  transferOnce = false;

  card_data_from = "";

  card_data_to = "";
  
  distance = 9999;
}



float parseDistance(String input) {
  // Extract the numeric part of the string
  String distanceStr = input.substring(input.indexOf(":") + 1, input.indexOf("cm")).trim();
  return float(distanceStr);  // Convert to float and return
}

void serialEvent(Serial myPort) {
  myPort.write(" ");
  remote_code = myPort.readStringUntil('\n').trim();  //Read the serial input
  
  println(remote_code);  // Print the received input for debugging
  
  if (remote_code.contains("NFC: CARD WRITE SUCCESS")) {
    isCardScanned = true;          // still true if needed elsewhere
    isCardWrittenTo = true;        // new flag that now triggers drawCreate()
    myPort.write("A"); // success melody
    println("Card write confirmed. Ready to create user.");
  }
  
  if (remote_code.startsWith("Distance:")) {
    distance = parseDistance(remote_code);
  }
  
  if (remote_code.equals("+") && screenSelect > 1) {
    screenSelect--; 
    println(screenSelect); 
  } else if (remote_code.equals("-") && screenSelect < 3) {
    screenSelect++; 
    println(screenSelect); 
  }
  
  if (remote_code.equals("PLAY") && screen == 0) {
    screen = screenSelect; 
  }
  
  if (remote_code.equals("RETURN") && screen != 0) {
    reset(); 
  } 
  
  if (remote_code.equals("PLAY") && screen!=3) {
    if (userSendPin.length() > 0) {
      if (comparePin(card_data, userSendPin)) {
        isSenderPinConfirmed = true;
        userSend.pin = userSendPin; 
        userSendPin = ""; 
      } else {
        isPinIncorrect = true; 
        incorrectPinStartTime = millis(); 
      }
    }
    
    if (userReceivePin.length() > 0) {
       if (comparePin(card_data, userReceivePin)) {
        isReceiverPinConfirmed = true;
        userReceive.pin = userReceivePin; 
        userReceivePin = ""; 
      } else {
        isPinIncorrect = true; 
        incorrectPinStartTime = millis(); 
      }
    }
    
    if (isSenderPinConfirmed == true) {
      if (transferAmount.length() > 0 && int(transferAmount) > 0) {
        isAmountConfirmed = true; 
      }
    }
    
    if (pin.length() > 0) {
      if (pin.equals(userProfile.pin)) {
        isPinConfirmed = true; 
        println(isPinConfirmed); 
      } else {
        isPinIncorrect = true; 
        incorrectPinStartTime = millis(); 
      }
    }
  }
  
  if (remote_code.equals("0")
      || remote_code.equals("1")
      || remote_code.equals("2")
      || remote_code.equals("3")
      || remote_code.equals("4")
      || remote_code.equals("5")
      || remote_code.equals("6")
      || remote_code.equals("7")
      || remote_code.equals("8")
      || remote_code.equals("9")
  ) {
    if (isSenderCardScanned == true && isSenderPinConfirmed == false) {
      userSendPin += remote_code; 
      println("Pin entered: " + userSendPin); 
    }
    
    if (isSenderPinConfirmed == true && isAmountConfirmed == false) {
      transferAmount += remote_code; 
      println("Transfer amount entered: " + transferAmount); 
    }
    
    if (isReceiverCardScanned == true && isAmountConfirmed == true) {
      userReceivePin += remote_code; 
      println("Pin enetered: " + userReceivePin); 
    }
    
    if (isCardScanned == true) {
      pin += remote_code; 
      println("Pin enetered: " + pin); 
    }
  }
  
  //poll for NFC Data
  if (remote_code.contains("NFC: Data Read: ")) {
         card_data = remote_code.replace("NFC: Data Read: ", "")+".txt"; 
      }
}

void drawArrow(int cx, int cy, int len, float angle){
  pushMatrix();
  translate(cx, cy);
  rotate(radians(angle));
  line(0,0,len, 0);
  line(len, 0, len - 8, -8);
  line(len, 0, len - 8, 8);
  popMatrix();
}

void transfer(User userSend, User userReceive, int amount) {
  userSend.amount -= amount; 
  userReceive.amount += amount; 
  println("Sender's amount: " + userSend.amount); 
  println("Receiver's amount: " + userReceive.amount); 
}

void keyPressed() {
  if (screen == 1 && !isNameEntered) {
    if (key == BACKSPACE && typedName.length() > 0) {
      typedName = typedName.substring(0, typedName.length() - 1);
    } else if (key == ENTER || key == RETURN) {
      if (typedName.length() > 0) {
        isNameEntered = true;
      }
    } else if (key >= 32 && key <= 126) {  // Printable characters
      typedName += key;
    }
  }
}
