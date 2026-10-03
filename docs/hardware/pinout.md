# 🔌 Especificación de Hardware & Pinout Unificado

> **Microcontrolador Objetivo**: Arduino Uno R3 (ATmega328P, 16 MHz, 5V)  
> **Transceptor NFC**: Módulo PN532 en bus SPI  
> **Actuadores**: 2 Servomotores SG90/MG996R + 1 Motor DC con Driver L298N  
> **Sensores**: 4 Fotorresistencias LDR (N, S, W, E) + 1 Divisor de Batería 1:2

---

## 1. Mapeo Definitivo de Pines (Sin Conflictos)

| Pin Arduino | Modo I/O | Conexión / Periférico | Función Operativa | Notas de Diseño |
| :---: | :---: | :--- | :--- | :--- |
| **`A0`** | INPUT | LDR Norte | Sensor fotométrico cuadrante Norte | Lectura analógica 10 bits ($0-5\text{V}$) |
| **`A1`** | INPUT | LDR Sur | Sensor fotométrico cuadrante Sur | Lectura analógica 10 bits ($0-5\text{V}$) |
| **`A2`** | INPUT | LDR Oeste | Sensor fotométrico cuadrante Oeste | Lectura analógica 10 bits ($0-5\text{V}$) |
| **`A3`** | INPUT | LDR Este | Sensor fotométrico cuadrante Este | Lectura analógica 10 bits ($0-5\text{V}$) |
| **`A4`** | INPUT | Divisor Batería ($100\text{k}\Omega : 100\text{k}\Omega$) | Medición de tensión de batería Li-ion | Rango $0 - 8.4\text{V}$ escalado a $0 - 4.2\text{V}$ |
| **`A5`** | INPUT | Libre / Expansión | Línea analógica de reserva | Disponible |
| **`D0 (RX)`**| INPUT | USB / Serial UART | Recepción Serial / Programación Bootloader | 115200 bps |
| **`D1 (TX)`**| OUTPUT| USB / Serial UART | Transmisión Serial Telemetría | 115200 bps |
| **`D2`** | INPUT | PN532 IRQ (Interrupción) | Señal de detección de campo/tag NFC | Opcional / Interrupción Externa INT0 |
| **`D3`** | OUTPUT| Driver L298N `ENA` | Habilitación PWM de velocidad motor | Timer 2 (OC2B) |
| **`D4`** | OUTPUT| **PN532 Chip Select (CS / SS)** | Habilitación de bus SPI del transceptor NFC | Control digital dedicado |
| **`D5`** | OUTPUT| Driver L298N `IN1` | Dirección de marcha tracción | Control H-Bridge |
| **`D6`** | OUTPUT| Driver L298N `IN2` | Dirección de marcha tracción | Control H-Bridge |
| **`D7`** | OUTPUT| LED Estado del Sistema | Indicador visual de ciclo y actividad | **Reasignado desde D13 para liberar SPI** |
| **`D8`** | OUTPUT| Libre / Auxiliar | Línea digital de reserva | Disponible |
| **`D9`** | OUTPUT| Servomotor Elevación (Pitch) | Control angular vertical ($15^\circ - 165^\circ$) | Timer 1 (PWM 50 Hz Servo) |
| **`D10`**| OUTPUT| Servomotor Azimut (Yaw) | Control angular horizontal ($10^\circ - 170^\circ$) | Timer 1 (PWM 50 Hz Servo) |
| **`D11`**| OUTPUT| **PN532 SPI MOSI** | Línea de datos Master-Out-Slave-In | Bus SPI Hardware ATmega328P |
| **`D12`**| INPUT | **PN532 SPI MISO** | Línea de datos Master-In-Slave-Out | Bus SPI Hardware ATmega328P |
| **`D13`**| OUTPUT| **PN532 SPI SCK** | Reloj del bus SPI | Bus SPI Hardware ATmega328P |

---

## 2. Resolución de Conflictos Eléctricos Resueltos

1. **Liberación del Pin `D10`**:
   - `D10` se reserva exclusivamente para la señal PWM del **Servo Yaw**.
   - La línea Chip Select (**CS / SS**) del PN532 se reasigna a **`D4`**, eliminando la colisión.

2. **Liberación del Pin `D13`**:
   - `D13` es el reloj hardware SPI (**SCK**) obligatorio para comunicarse con el módulo PN532 a alta velocidad.
   - El LED de estado de la aplicación se reubica en **`D7`**, permitiendo que el bus SPI funcione sin interferencias de carga resistiva del LED.

3. **Inviabilidad de I²C y Selección de SPI**:
   - Si se utilizara I²C para el PN532, los pines `A4` (SDA) y `A5` (SCL) quedarían ocupados, dejando únicamente 4 pines analógicos (`A0-A3`) para los LDRs, sin ningún pin analógico libre para medir la batería.
   - Al seleccionar **SPI** con CS en `D4`, los 5 pines analógicos (`A0` a `A4`) quedan completamente disponibles para los 4 sensores LDR y el divisor de batería.
