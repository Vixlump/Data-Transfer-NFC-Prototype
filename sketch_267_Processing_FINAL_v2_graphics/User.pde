class User {
  String name; 
  int amount; 
  String pin; 
  int amount_old;
  
  User (String n, int a, String p) {
    name = n; 
    amount = a; 
    pin = p; 
    amount_old = 0;
  }
}

//account helper functions

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
  //println(randomNumbersStr);
  if (randomNumbersStr.equals(pin)) {
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
String loadAccountName(String name) {
  String[] load_account = loadStrings(name);
    return load_account[1];
   
}
String loadAccountPin(String name) {
  String[] load_account = loadStrings(name);
    return load_account[2];
}
String loadAccountBal(String name) {
  String[] load_account = loadStrings(name);
    return load_account[0];
}

String printAccountPublicInfo(String name) {

    String[] load_account = loadStrings(name);

    return "Account: [" + load_account[0] + "] [" + load_account[1] + "]";

}
