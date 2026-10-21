#pragma once
#include <stdint.h>
#include <string.h>
#include <vector>
#define PN532_MIFARE_ISO14443A 0
extern uint8_t pages[16][4];
extern int failedWritePage;
extern std::vector<int> writtenPages;
class Adafruit_PN532 {
public:
    explicit Adafruit_PN532(int) {}
    void begin() {}
    uint32_t getFirmwareVersion() { return 1; }
    void SAMConfig() {}
    bool readPassiveTargetID(int, uint8_t *uid, uint8_t *length, int) {
        memset(uid, 1, 7); *length = 7; return true;
    }
    bool ntag2xx_ReadPage(uint8_t page, uint8_t *out) {
        if (page >= 16) return false;
        memcpy(out, pages[page], 4); return true;
    }
    bool ntag2xx_WritePage(uint8_t page, uint8_t *data) {
        writtenPages.push_back(page);
        if (page >= 16 || page == failedWritePage) return false;
        memcpy(pages[page], data, 4); return true;
    }
};
