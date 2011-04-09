#include "queue.h"

queue* newQueue(int size) {
  queue* q = (queue*)malloc(sizeof(queue));
  q->maxSize = size;
  q->storage = (char**)malloc(q->maxSize * sizeof(char*));
  q->frontPosition = 0;
  q->currentSize = 0;
  return q;
}

char* Qpos(queue* q, int pos) {
  return q->storage[(q->frontPosition+pos) % q->maxSize];
}

char* Qfront(queue* q) {
  return q->storage[q->frontPosition];
}

bool Qempty(queue* q) {
  return (q->currentSize <= 0);
}

bool Qfull(queue* q) {
  return (q->currentSize >= q->maxSize);
}

bool Qpush(queue* q, char* x) {
  if (!Qfull(q)) {
    q->storage[(q->frontPosition+q->currentSize) % q->maxSize] = x; // insert the data at the tail
    q->currentSize++;
    return true;
  } else {
    return false;
  }
}

bool Qpop(queue* q) {
  if (!Qempty(q)) {
    free(q->storage[q->frontPosition]);
    q->storage[q->frontPosition] = 0; // clear the front
    q->frontPosition = (q->frontPosition + 1) % q->maxSize; // advance the queue pointer
    q->currentSize--;
    return true;
  } else {
    return false;
  }
}
