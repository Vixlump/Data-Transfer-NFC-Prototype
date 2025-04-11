#include <SPI.h>
#include <MFRC522.h>

#define SS_PIN 10
#define RST_PIN 9
#define START_BLOCK 4   //First user-writable block on NTAG213
#define END_BLOCK 39    //Last writable block on NTAG213 (adjust as needed)
#define BLOCK_SIZE 16   //Each block holds 16 bytes

MFRC522 mfrc522(SS_PIN, RST_PIN); //Create MFRC522 instance

bool nfc_status = false;
bool nfc_mode = false; //false = read, true = write
String write_data = "0000";

String readNFCData() {
    String result = "";
    byte buffer[18]; //16 bytes + 2 CRC
    byte size = sizeof(buffer);

    for (byte block = START_BLOCK; block <= END_BLOCK; block++) {
        MFRC522::StatusCode status = mfrc522.MIFARE_Read(block, buffer, &size);

        if (status != MFRC522::STATUS_OK) {
            Serial.print("NFC: Read failed at block ");
            Serial.print(block);
            Serial.print(": ");
            Serial.println(mfrc522.GetStatusCodeName(status));
            break;
        }

        //stop reading if the block contains all 0x00 or 0xFF (assumed empty)
        bool empty = true;
        for (byte i = 0; i < BLOCK_SIZE; i++) {
            if (buffer[i] != 0x00 && buffer[i] != 0xFF) {
                empty = false;
                break;
            }
        }
        if (empty) break;

        //append valid characters only
        for (byte i = 0; i < BLOCK_SIZE; i++) {
            if (isPrintable(buffer[i])) {
                result += (char)buffer[i];
            }
        }
    }

    return result;
}

void writeNFCData(String data) {
    int totalLength = data.length();
    int requiredBlocks = (totalLength + BLOCK_SIZE - 1) / BLOCK_SIZE;

    if (START_BLOCK + requiredBlocks - 1 > END_BLOCK) {
        Serial.println("NFC: ERROR: Text is too long for NTAG213 storage.");
        return;
    }

    for (int i = 0; i < requiredBlocks; i++) {
        byte buffer[BLOCK_SIZE] = {0}; //fill with 0 to avoid junk data
        int startIdx = i * BLOCK_SIZE;
        int endIdx = min(startIdx + BLOCK_SIZE, totalLength);

        for (int j = startIdx; j < endIdx; j++) {
            buffer[j - startIdx] = data[j];
        }

        byte block = START_BLOCK + i;
        MFRC522::StatusCode status = mfrc522.MIFARE_Write(block, buffer, BLOCK_SIZE);

        if (status != MFRC522::STATUS_OK) {
            Serial.print("NFC: WRITE FAILED AT BLOCK ");
            Serial.print(block);
            Serial.print(": ");
            Serial.println(mfrc522.GetStatusCodeName(status));
            return;
        }
    }

    Serial.println("NFC: CARD WRITE SUCCESS");
}

void readCard() {
  String data_from_card = "";
    while (true) {
        if (!mfrc522.PICC_IsNewCardPresent() || !mfrc522.PICC_ReadCardSerial()) {
            continue;
        }

        Serial.println("NFC: CARD DETECTED READING DATA");
        
        data_from_card = readNFCData();

        Serial.print("NFC: Data Read: ");
        Serial.println(data_from_card);
        
        mfrc522.PICC_HaltA();
        mfrc522.PCD_StopCrypto1();
        Serial.println("NFC:ReadPass");
        break;
    }
}

void writeCard() {
    while (true) {
        if (Serial.available()) {
            String inputData = Serial.readStringUntil('\n');
            inputData.trim();

            if (inputData.length() == 0) {
                Serial.println("NFC: ERROR: No input provided.");
                return;
            }

            Serial.println("NFC: SCAN AN NFC CARD");

            while (true) {
                if (!mfrc522.PICC_IsNewCardPresent() || !mfrc522.PICC_ReadCardSerial()) {
                    continue;
                }
                

                Serial.println("NFC: CARD DETECTED WRITING DATA");
                writeNFCData(inputData);

                mfrc522.PICC_HaltA();
                mfrc522.PCD_StopCrypto1();
                return;
            }
        }
    }
}

void NFC_setup() {

    SPI.begin();
    mfrc522.PCD_Init();

    Serial.println("NFC: Select mode:");
    Serial.println("NFC: R - Read Data");
    Serial.println("NFC: W - Write Data");

}
