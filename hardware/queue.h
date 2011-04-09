#pragma once
#include "WProgram.h"

typedef struct {
  int   maxSize;
  char**  storage;
  int   frontPosition;
  int   currentSize;
} queue;

queue* newQueue(int size);
char* Qpos(queue* q, int pos);
char* Qfront(queue* q);
bool Qempty(queue* q);
bool Qfull(queue* q);
bool Qpush(queue* q, char* x);
bool Qpop(queue* q);
