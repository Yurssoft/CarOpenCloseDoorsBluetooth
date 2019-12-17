#include <AltSoftSerial.h>
#include <Arduino.h>


void sendCommand(String command);

const unsigned char Open_Relay = 7;
const unsigned char Close_Relay = 6;

enum command {
  open,
  close
};

// Commands

#define COMMLISTLENGTH 18

String commList[COMMLISTLENGTH] = {
    "OPEN",
    "CLOSE"
};

// BT

AltSoftSerial BTserial;
bool commandReceived = true;
char btResponse[20];
const uint8_t BT_MAX = sizeof(btResponse);
uint8_t count;
uint8_t dividerPosition;

void setup() {
  Serial.begin(9600);
  BTserial.begin(9600);

  // Pins direction

  pinMode(Open_Relay, OUTPUT);
  pinMode(Close_Relay, OUTPUT);
  
  // Pins initial state

  digitalWrite(Open_Relay, LOW);
  digitalWrite(Close_Relay, LOW);
}

void closeRelays() {
  delay(555);
  digitalWrite(Open_Relay, LOW);
  digitalWrite(Close_Relay, LOW);
  delay(250);
}

void openDoors() {
  digitalWrite(Open_Relay, HIGH);
  digitalWrite(Close_Relay, LOW);
  closeRelays();
}

void closeDoors() {
  digitalWrite(Open_Relay, LOW);
  digitalWrite(Close_Relay, HIGH);
  closeRelays();
}


void execute(int command, int timing) {
  switch (command) {
    case open:
      openDoors();
      break;
    case close:
      closeDoors();
      break;
    default:
      break;
  }
}

void sendCommand(String command) {
  Serial.println("<- " + command);
  BTserial.print(command);
  delay(500);
  if (BTserial.available()) {
    String response = BTserial.readString();
    Serial.println("-> " + response);
  }
}

void bluetoothReset() {
  count = 0;
  dividerPosition = 0;
  memset(btResponse, 0, sizeof(btResponse));
  commandReceived = false;
}

void loop() {
  // Read from BLE buffer
  if (BTserial.available()) {
    char c = BTserial.read();

    if (c == ';') {
      commandReceived = true;
    } else if (count < BT_MAX - 1) {
      btResponse[count] = c;
      count++;

      if (c == '.') {
        dividerPosition = count-1;
      } 
    }

    if (strcmp(btResponse, "OK+CONN") == 0) {
      bluetoothReset();
    }

    if (strcmp(btResponse, "OK+LOST") == 0) {
      bluetoothReset();
    }
  }

  if (commandReceived) {
    Serial.println(btResponse);

    uint8_t commandLength = dividerPosition;
    uint8_t timingLength = (count-dividerPosition);
    char cmd[commandLength+1];
    char timingValue[timingLength+1];
    strncpy(cmd, btResponse, dividerPosition);
    strncpy(timingValue, &btResponse[dividerPosition+1], timingLength);

    cmd[commandLength] = '\0';
    timingValue[timingLength] = '\0';

    int timing = atoi(timingValue);
    
    Serial.print("Command: ");
    Serial.print(cmd);
    Serial.print(" timing: ");
    Serial.println(timing);

    for (int i = 0; i < COMMLISTLENGTH; i++) {
      if (strcmp(cmd, commList[i].c_str()) == 0) {
        execute(i, timing);
        break;
      }
    }

    bluetoothReset();
  }
}