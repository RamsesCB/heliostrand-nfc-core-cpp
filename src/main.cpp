#include <Arduino.h>

// Definición del pin del LED (la mayoría de placas Arduino/ESP usan LED_BUILTIN o pin 13 / 2)
#ifndef LED_BUILTIN
#define LED_BUILTIN 13
#endif

void setup() {
    // Configura el pin del LED como salida
    pinMode(LED_BUILTIN, OUTPUT);

    // Inicializa la comunicación serial para monitorear el estado
    Serial.begin(115200);
    delay(500);
    Serial.println("=================================");
    Serial.println("  Arduino App - Prueba de Blink  ");
    Serial.println("=================================");
}

void loop() {
    // Enciende el LED
    digitalWrite(LED_BUILTIN, HIGH);
    Serial.println("[ESTADO] LED Encendido (HIGH)");
    delay(1000); 

    // Apaga el LED
    digitalWrite(LED_BUILTIN, LOW);
    Serial.println("[ESTADO] LED Apagado (LOW)");
    delay(1000); 
}
