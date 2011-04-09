#pragma once

#include "WProgram.h"
#include "queue.h"

#define BUFFER_SIZE 256
//static char buffer[BUFFER_SIZE] = {'\0'};
//unsigned int buffer_len = 0;

#define VALUE_BUFFER_SIZE 12
char value_buffer[VALUE_BUFFER_SIZE] = {'\0'};
unsigned int value_buffer_len = 0;

char apiKey[] = "ZwY_-EBddMqXB4GMZy3ATGCMTv6Nq26U1ua864LB-E8";

queue* outputQ;

char* newBuffer() {
  char* b = (char*)malloc(BUFFER_SIZE * sizeof(char));
  memset(b, 0, BUFFER_SIZE);
  return b;
}

void clearValueBuffer() {
  value_buffer_len = 0;
  memset(value_buffer, 0, VALUE_BUFFER_SIZE);
}

void initializeOutput() {
  pinMode(ledPin, OUTPUT);
  digitalWrite(ledPin, ledValue);

  clearValueBuffer();
  
  outputQ = newQueue(1);
}

boolean socketSend(char* message) {
  if (!Qfull(outputQ)) {
    if (Qpush(outputQ, message)) {
      return true;
    }
  }
  free(message);
  return false;
}

boolean apiPut() {
  if (!Qfull(outputQ)) {
    char *buffer = newBuffer();
  
    // Build our message
    sprintf(buffer, "{\"method\":\"put\",\"resource\":\"/feeds/22380/datastreams/lock_state\",\"body\":{\"current_value\":\"%i\"},\"params\":{\"key\":\"%s\"}}\n", lockValue, apiKey);
    
    Serial.print("Built Message: ");
    Serial.print(buffer);
    
    // Send it
    return socketSend(buffer);
  }
  return false;
}

// Fetch/Subscribe to our feed
boolean apiSubscribe() {
  if (!Qfull(outputQ)) {
    char *buffer = newBuffer();
  
    // Build our message
    sprintf(buffer, "{\"method\":\"subscribe\",\"resource\":\"/feeds/22380/datastreams/lock_state\",\"params\":{\"key\":\"%s\"}}\n", apiKey);
    
    Serial.print("Built Message: ");
    Serial.print(buffer);
    
    // Send it
    return socketSend(buffer);
  }
  return false;
}
