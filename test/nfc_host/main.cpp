#include <assert.h>
#include <string.h>
#include <vector>
#include "NfcTransceiver.h"

unsigned long fakeMillis = 1000;
uint8_t pages[16][4] = {};
int failedWritePage = -1;
std::vector<int> writtenPages;

int main() {
    pages[3][0] = 0xE1;
    pages[3][1] = 0x10;
    pages[3][2] = 0x12;
    NfcTransceiver nfc;
    assert(nfc.begin());
    TelemetryPacket packet{};
    packet.version = 2;
    uint8_t payload[12];
    packTelemetry(packet, payload);
    assert(nfc.publish(payload, 12));
    assert(writtenPages.front() == 7);
    assert(writtenPages.back() == 7);
    writtenPages.clear();

    fakeMillis += 1000;
    const uint8_t command[] = {0x53, 90, 100, 0x53 ^ 90 ^ 100};
    memcpy(pages[12], command, 4);
    nfc.pollServoCommand();
    uint8_t pitch = 0, yaw = 0;
    assert(nfc.fetchServoCommand(pitch, yaw));
    assert(pitch == 90 && yaw == 100);
    assert(!nfc.fetchServoCommand(pitch, yaw));
    assert(writtenPages.size() == 1 && writtenPages[0] == 12);
    assert(nfc.publish(payload, 12));
    assert(writtenPages.size() == 1);

    memcpy(pages[12], command, 4);
    failedWritePage = 12;
    nfc.pollServoCommand();
    assert(!nfc.fetchServoCommand(pitch, yaw));
    failedWritePage = -1;
    nfc.pollServoCommand();
    assert(nfc.fetchServoCommand(pitch, yaw));
    memcpy(pages[12], command, 4);
    pages[12][3] ^= 1;
    nfc.pollServoCommand();
    assert(!nfc.fetchServoCommand(pitch, yaw));

    fakeMillis += 900000;
    memcpy(pages[11], pages[7], 4);
    pages[11][2] = 255;
    pages[11][3] = 0;
    failedWritePage = 9;
    assert(!nfc.publish(payload, 12));
    assert(pages[11][0] == 0 && pages[11][1] == 0);
    assert(pages[7][0] == 0x48 && pages[7][1] == 0x53);
}
