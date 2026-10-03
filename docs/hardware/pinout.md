# Especificación de hardware y pinout

> Objetivo: Arduino Uno R3 / ATmega328P, PN532 por SPI y batería Li-ion 1S.

## Pinout

| Pin | Conexión | Función |
|---|---|---|
| A0 | LDR Norte | ADC |
| A1 | LDR Sur | ADC |
| A2 | LDR Oeste | ADC |
| A3 | LDR Este | ADC |
| A4 | divisor batería 20 kOhm / 20 kOhm + 100 nF a GND | medición 1S |
| A5 | libre | expansión |
| D2 | PN532 IRQ | opcional |
| D3 | L298N ENA | PWM motor |
| D4 | PN532 CS | SPI chip select |
| D5 | L298N IN1 | dirección |
| D6 | L298N IN2 | dirección |
| D7 | LED de estado | salida |
| D9 | Servo Pitch | 15..165 grados |
| D10 | Servo Yaw | 10..170 grados |
| D11 | PN532 MOSI | SPI |
| D12 | PN532 MISO | SPI |
| D13 | PN532 SCK | SPI |

## Batería

El diseño actual es para un pack Li-ion 1S, nominalmente 3.0..4.2 V. No debe documentarse como pack de 8.4 V.

El divisor usa R1=20 kOhm y R2=20 kOhm; su impedancia de Thévenin es aproximadamente 10 kOhm. Se recomienda un capacitor de 100 nF desde A4 a GND. El firmware descarta la primera conversión, espera asentamiento, promedia 8 muestras y estima Vcc mediante la referencia interna del ATmega328P antes de convertir a milivoltios.

Valores fuera de 2500..5000 mV se tratan como lectura inválida y se transmiten como 0 (N/D).

## Bus NFC

SPI es la configuración normativa: CS=D4, MOSI=D11, MISO=D12, SCK=D13. D10 queda reservado al servo Yaw y D7 al LED.
