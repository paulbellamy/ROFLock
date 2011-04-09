/*
* Socket App
 *
 * A simple socket application example using the WiShield 1.0
 */

#include <WiShield.h>
//#include <string.h>
extern "C" {   
  #include <uip.h>
}

#define DEBUG 1

//Wireless configuration defines ----------------------------------------
#define WIRELESS_MODE_INFRA   1
#define WIRELESS_MODE_ADHOC   2

//Wireless configuration parameters ----------------------------------------
/*
unsigned char local_ip[] = {192,168,1,99};   // IP address of WiShield
 unsigned char gateway_ip[] = {192,168,1,1};   // router or gateway IP address
 unsigned char subnet_mask[] = {255,255,255,0};   // subnet mask for the local network
 const prog_char ssid[] PROGMEM = {"CEL-Mobile"};      // max 32 bytes
 unsigned char security_type = 0;   // 0 - open; 1 - WEP; 2 - WPA; 3 - WPA2
 
 // WPA/WPA2 passphrase
 const prog_char security_passphrase[] PROGMEM = {""};   // max 64 characters
*/

/**/
unsigned char local_ip[] = {192,168,3,95};   // IP address of WiShield
unsigned char gateway_ip[] = {192,168,3,1};   // router or gateway IP address
unsigned char subnet_mask[] = {255,255,255,0};   // subnet mask for the local network
const prog_char ssid[] PROGMEM = {"Pachube"};      // max 32 bytes
unsigned char security_type = 0;   // 0 - open; 1 - WEP; 2 - WPA; 3 - WPA2

// WPA/WPA2 passphrase
const prog_char security_passphrase[] PROGMEM = {""};   // max 64 characters
/**/


// WEP 128-bit keys
prog_uchar wep_keys[] PROGMEM = {
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // Key 0
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // Key 1
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // Key 2
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}; // Key 3
// setup the wireless mode
// infrastructure - connect to AP
// adhoc - connect to another WiFi device
unsigned char wireless_mode = WIRELESS_MODE_INFRA;
unsigned char ssid_len;
unsigned char security_passphrase_len;

// End of wireless configuration parameters ----------------------------------------

boolean connectToServer(void);

volatile static boolean connectingToServer = false;
volatile static boolean connectedToServer = false;
volatile static boolean subscribedToFeed = false;
volatile static boolean inited = false;
volatile static unsigned long nextXMitTime;

int ledPin = 6;
volatile int ledValue = -1;

int lockPin = 5;
volatile int lockValue = 0;

unsigned long toggleInterval = 500;
volatile unsigned long nextToggleTime;

volatile unsigned long offTime = 0;

#define MATCHING_KEY   0
#define MATCHING_VALUE 1
static char *matchString = "\"current_value\":\"";
static int matchStringLength = 16;
volatile int matchPtr = 0;
volatile int matchState = MATCHING_KEY;

#include "async_output.h"

void openLock() {
  #if DEBUG == 1
    Serial.println("Lock Open...");
  #endif
  lockValue = ledValue = 1;
  digitalWrite(ledPin, ledValue);
  digitalWrite(lockPin, lockValue);
  offTime = millis() + 15000; // 15 seconds
}

void closeLock() {
  #if DEBUG == 1
    Serial.println("Lock Locked...");
  #endif
  lockValue = ledValue = 0;
  digitalWrite(ledPin, ledValue);
  digitalWrite(lockPin, lockValue);
}

// Sliding-Window Buffered reading
void bufferedRead(const char* data, unsigned int data_len) {
  for (int i=0; i < data_len; i++) {
    switch (matchState) {
      case MATCHING_VALUE:
        if (data[i] != '"') {
          // Reading the value
          value_buffer[value_buffer_len] = data[i];
          value_buffer_len++;
        } else {
          // Done reading value
          matchPtr = 0;
          matchState = MATCHING_KEY;
          lockValue = atoi(value_buffer);
          if (lockValue == 1) {
            openLock();
          } else {
            closeLock();
          }
        }
        break;
      default:
      case MATCHING_KEY:
        if (data[i] == matchString[matchPtr]) {
          // Found the next char, look for the next one
          if (matchPtr >= matchStringLength) {
            // found the whole match parse the value
            matchState = MATCHING_VALUE;
            // Read the value into a buffer
            clearValueBuffer();
          } else {
            matchPtr++;
          }
        } else {
          matchPtr = 0;
          matchState = MATCHING_KEY;
        }
        break;
    }
  }
}

void setup() {
  #if DEBUG == 1
    Serial.begin(57600);   
    Serial.println("Starting Program...");
  #endif

  initializeOutput();

  // Blink 3 times then dim
  analogWrite(ledPin, 5);
  delay(150);
  analogWrite(ledPin, 0);
  delay(150);
  analogWrite(ledPin, 5);
  delay(150);
  analogWrite(ledPin, 0);
  delay(150);
  analogWrite(ledPin, 5);
  delay(150);
  analogWrite(ledPin, 0);
  delay(150);
  analogWrite(ledPin, 5);

  connectingToServer = false;
  connectedToServer = false; 
  WiFi.init();
  
  nextToggleTime = millis() + toggleInterval;
}

void loop() {
  WiFi.run();

  if (inited) {
    if (!connectedToServer) {
      // Connect to the server!
      if (!connectingToServer) {
        if (millis() > nextXMitTime) {
          #if DEBUG == 1
            Serial.print("Connecting to server...");
           #endif
          connectToServer();
        }
      }
      
      // Status Light
      if (nextToggleTime < millis()) {
        nextToggleTime += toggleInterval;
        ledValue = !ledValue;
      }
      int difference = map(nextToggleTime - millis(), 0, toggleInterval, 0, 255);
      //if (millis() % 10) Serial.println(difference);
      if (ledValue) {
        analogWrite(ledPin, 255 - difference);
      } else {
        analogWrite(ledPin, difference);
      }
    }
  }
}

// Connect to Socket server
boolean connectToServer(void) {
  connectingToServer = true; 
  struct uip_conn *conn;
  uip_ipaddr_t ipaddr;

  //uip_ipaddr(&ipaddr, 192,168,3,63); // Laptop IP
  //uip_ipaddr(&ipaddr, 209,85,146,106); // Google IP
  uip_ipaddr(&ipaddr, 173,203,109,233); // beta.pachube.com
  conn = uip_connect(&ipaddr, HTONS(8081));

  return (conn != NULL);
}

// socket_app.c
extern "C" {
  void socket_app_init() {
    #if DEBUG == 1
      Serial.println("In socket_app_init...");
    #endif
    inited = true;
    nextXMitTime = millis();
  }

  void socket_app_appcall() {
    //Serial.println("In socket_app_appcall...");
    if (uip_connected()) {
      connectedToServer = true;
      connectingToServer = false;
      digitalWrite(ledPin, LOW);
      #if DEBUG == 1
        Serial.println("{connected}");
      #endif
    }

    if (uip_aborted()) {
      #if DEBUG == 1
        Serial.println("{aborted}");
      #endif
      connectingToServer = false;
      connectedToServer = false;
    }

    if (uip_timedout()) {
      #if DEBUG == 1
        Serial.println("{timedout}");
      #endif
      connectingToServer = false;
      connectedToServer = false;
    }

    if(uip_closed() && !uip_newdata()) {
      #if DEBUG == 1
        Serial.println("{closed}");
      #endif
      if (connectedToServer) {
        nextXMitTime += 30000;// XMit again in 30 seconds
        connectingToServer = false;
        connectedToServer = false;
      }
    }

    if (uip_rexmit()) {
      #if DEBUG == 1
        Serial.println("{retransmit}");
      #endif
      if (!Qempty(outputQ)) {
        uip_send(Qfront(outputQ), strlen(Qfront(outputQ)));
      }
    }

    if (uip_acked()) {
      // Server has acknowledged it received our data
      if (!Qempty(outputQ)) {
        Qpop(outputQ);
      }
    }

    if (uip_poll()) {
      if (connectedToServer) {
        if (!Qempty(outputQ)) {
          uip_send(Qfront(outputQ), strlen(Qfront(outputQ)));
          #if DEBUG == 1
            Serial.print("=> ");
            Serial.println(Qfront(outputQ));
          #endif
          Qpop(outputQ); // This is the NO ACK HACK!
        } else {
          if (!subscribedToFeed) {
            subscribedToFeed = apiSubscribe();
          }
          
          if (offTime != 0 && offTime < millis()) {
            // Should shut the lock
            offTime = 0;
            closeLock();
            apiPut();
          }
        }
      }
    }

    if (uip_newdata()) {
      #if DEBUG == 1
        Serial.print("<= ");
        Serial.write((const uint8_t*)uip_appdata, uip_datalen());
        Serial.println("");
      #endif
      bufferedRead((const char*)uip_appdata, uip_datalen());
    }
  }
}

