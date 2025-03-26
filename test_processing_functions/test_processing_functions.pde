void setup() {
  //example usage of the functions
  String fileName1 = "user1.txt";
  String fileName2 = "user2.txt";
  String userName = "Alice";
  float initialBalance = 100.0;

  //create a file and get the random numbers
  String randomNumbers = makeAccount(fileName1, userName, initialBalance);
  String randomNumbers_2 = makeAccount(fileName2, userName+"_2", initialBalance);

  //compare the pin
  String pinToCheck = "1234"; // Example pin to check
  boolean isPinCorrect = comparePin(fileName1, pinToCheck);
  boolean testret = comparePin(fileName2, randomNumbers_2);
  println("Pin match: " + isPinCorrect);
  println("Pin match 2: " + testret);

  //transfer amount
  float amountToTransfer = 50.0;
  String transactionMessage = transferAmount(fileName1, fileName2, amountToTransfer);
  println(transactionMessage);
  println(printAccountInfo(fileName1));
  println(printAccountInfo(fileName2));
}

String makeAccount(String fileName, String name, float value) {
  //create a file and write the data
  String line;
  line = str(int(random(0, 10))) + str(int(random(0, 10))) + str(int(random(0, 10))) + str(int(random(0, 10))); // Write the random numbers to the next line

  //save the file
  String[] lines = {str(value), name, line};
    
  saveStrings(fileName, lines);

  return line;
}

boolean comparePin(String fileName, String pin) {
  //read the file
  String[] lines = loadStrings(fileName);
  if (lines == null || lines.length < 3) {
    return false; // File doesn't exist or is invalid
  }

  //get the random numbers from the file
  String randomNumbersStr = lines[2];
  if (randomNumbersStr==pin) {
     return true; 
  }
   return false;
}

String transferAmount(String fromFileName, String toFileName, float amount) {
  //read the from file
  String[] fromLines = loadStrings(fromFileName);
  if (fromLines == null || fromLines.length < 3) {
    return "Transaction failed: Invalid from file.";
  }

  //read the to file
  String[] toLines = loadStrings(toFileName);
  if (toLines == null || toLines.length < 3) {
    return "Transaction failed: Invalid to file.";
  }

  //get the balances
  float fromBalance = float(fromLines[0]);
  float toBalance = float(toLines[0]);

  //check if the transfer is possible
  if (fromBalance - amount < 0) {
    return "Transaction failed: Insufficient funds.";
  }

  // Update the balances
  fromBalance -= amount;
  toBalance += amount;

  //update the files
  fromLines[0] = str(fromBalance);
  toLines[0] = str(toBalance);

  //save the updated files
  saveStrings(fromFileName, fromLines);
  saveStrings(toFileName, toLines);

  return "Transaction complete.";
}

String printAccountInfo(String name) {
    String[] load_account = loadStrings(name);
    return "Account: [" + load_account[0] + "] [" + load_account[1] + "] [" + load_account[2]+"]";
}
