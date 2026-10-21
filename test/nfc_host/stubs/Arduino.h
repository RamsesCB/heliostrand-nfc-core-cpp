#pragma once
#include <stddef.h>
#include <stdint.h>
extern unsigned long fakeMillis;
inline unsigned long millis() { return fakeMillis; }
