# 📚 Documentación Técnica & Manual de Usuario (DOCUMENTS.md)

> **Proyecto**: Heliostrand NFC Core  
> **Versión**: 1.0.0 (Protocolo V2 Estandarizado)  
> **Autor Principal**: RamsesCB  
> **Repositorio Oficial**: [https://github.com/RamsesCB/heliostrand-nfc-core-cpp](https://github.com/RamsesCB/heliostrand-nfc-core-cpp)  
> **Especificaciones Normativas**: [docs/protocol/telemetry-v2.md](docs/protocol/telemetry-v2.md) | [docs/hardware/pinout.md](docs/hardware/pinout.md)

---

## 📑 Índice General

1. [Especificación Técnica de Ingeniería](#1-especificación-técnica-de-ingeniería)
   - [Cinemática Bio-inspirada (Theo Jansen)](#11-cinemática-bio-inspirada-theo-jansen)
   - [Seguimiento Solar Biaxial Diferencial](#12-seguimiento-solar-biaxial-diferencial)
   - [Capa de Hardware y Mapeo de Pines (Arduino Uno)](#13-capa-de-hardware-y-mapeo-de-pines-arduino-uno)
   - [Mapeo de Memoria NFC NTAG213 y Protocolo V2](#14-mapeo-de-memoria-nfc-ntag213-y-protocolo-v2)
   - [Matemática de Verificación CRC-8](#15-matemática-de-verificación-crc-8)
2. [Manual de Usuario: Aplicación Desktop (Java 21)](#2-manual-de-usuario-aplicación-desktop-java-21)
   - [Requisitos Previos de Sistema](#21-requisitos-previos-de-sistema)
   - [Instalación y Ejecución](#22-instalación-y-ejecución)
   - [Uso de la Interfaz Gráfica](#23-uso-de-la-interfaz-gráfica)
   - [Solución de Problemas (Troubleshooting Desktop)](#24-solución-de-problemas-troubleshooting-desktop)
3. [Manual de Usuario: Aplicación Móvil (Flutter / Android)](#3-manual-de-usuario-aplicación-móvil-flutter--android)
   - [Requisitos e Instalación del APK](#31-requisitos-e-instalación-del-apk)
   - [Procedimiento de Lectura NFC en Campo](#32-procedimiento-de-lectura-nfc-en-campo)
   - [Navegación en el Dashboard Móvil](#33-navegación-en-el-dashboard-móvil)
   - [Exportación y Reportes de Telemetría (CSV y JSON)](#34-exportación-y-reportes-de-telemetría-csv-y-json)
   - [Modo Simulación Móvil](#35-modo-simulación-móvil)
4. [Certificación de Calidad y Pruebas del Sistema](#4-certificación-de-calidad-y-pruebas-del-sistema)

---

## 1. Especificación Técnica de Ingeniería

### 1.1 Cinemática Bio-inspirada (Theo Jansen)
El sistema motriz implementa el mecanismo planar de 11 barras de **Theo Jansen**, el cual convierte la rotación continua de un cigüeñal impulsado por un motor DC reductor en una trayectoria de paso casi plana con levantamiento suave. Esto maximiza la tracción sobre superficies irregulares minimizando las oscilaciones mecánicas del chasis, permitiendo que la plataforma superior de sensores y paneles solares mantenga estabilidad angular durante el desplazamiento.

### 1.2 Seguimiento Solar Biaxial Diferencial
El subsistema de orientación lumínica emplea cuatro fotorresistencias (LDR) organizadas en cuadrantes cardinales (Norte, Sur, Oeste, Este) separadas por una cruceta de sombra:
- **Eje de Azimut / Yaw (Horizontal)**: Controlado por el Servomotor en pin `D10` (Rango seguro restringido por software: $0^\circ - 180^\circ$, neutral en $90^\circ$).
- **Eje de Elevación / Pitch (Vertical)**: Controlado por el Servomotor en pin `D9` (Rango seguro restringido por software: $0^\circ - 180^\circ$, elevación solar nominal entre $30^\circ$ y $150^\circ$).
- **Banda Muerta (Deadband)**: Se implementa un umbral de histéresis $\Delta_{\text{umbral}} = 50$ en lecturas ADC para prevenir trepidaciones (*jitter*) de los servomotores cuando los niveles de irradiancia incidente se encuentran balanceados.

### 1.3 Capa de Hardware y Mapeo de Pines (Arduino Uno)

El conexionado físico resuelve la contención de buses periféricos y la disponibilidad de canales analógicos:

| Pin Arduino | Tipo | Conexión Hardware | Función en el Sistema |
| :---: | :---: | :--- | :--- |
| `A0` | Analógico In | LDR Norte + $10\text{ k}\Omega$ | Sensor de luminosidad Norte / Superior |
| `A1` | Analógico In | LDR Sur + $10\text{ k}\Omega$ | Sensor de luminosidad Sur / Inferior |
| `A2` | Analógico In | LDR Oeste + $10\text{ k}\Omega$ | Sensor de luminosidad Oeste / Izquierda |
| `A3` | Analógico In | LDR Este + $10\text{ k}\Omega$ | Sensor de luminosidad Este / Derecha |
| `A4` | Analógico In | Divisor resistivo ($100\text{ k}\Omega / 100\text{ k}\Omega$) | Sensor de voltaje de batería Li-Ion |
| `A5` | - | Sin conexión | Reservado |
| `D3` | Salida PWM | L298N ENA | Regulación de velocidad PWM del motor de tracción |
| `D4` | Salida Digital | PN532 SS / Chip Select | Habilitación de esclavo SPI para transceptor NFC |
| `D5` | Salida Digital | L298N IN1 | Sentido de tracción motor |
| `D6` | Salida Digital | L298N IN2 | Sentido de tracción motor |
| `D7` | Salida Digital | Resistencia $220\Omega$ + LED | LED de estado del sistema (movido desde D13 para liberar SPI SCK) |
| `D9` | Salida PWM | Servomotor Pitch (Elevación) | Control de ángulo vertical ($0^\circ - 180^\circ$) |
| `D10` | Salida PWM | Servomotor Yaw (Azimut) | Control de ángulo horizontal ($0^\circ - 180^\circ$) |
| `D11` | SPI MOSI | PN532 MOSI | Transmisión serie sincrónica hacia transceptor NFC |
| `D12` | SPI MISO | PN532 MISO | Recepción serie sincrónica desde transceptor NFC |
| `D13` | SPI SCK | PN532 SCK | Reloj de bus SPI hardware |

### 1.4 Mapeo de Memoria NFC NTAG213 y Protocolo V2

Las etiquetas NTAG213 organizan la memoria de usuario en bloques de 4 bytes (denominados *páginas*). La trama normativa de **12 bytes** se distribuye exactamente en las páginas 4, 5 y 6:

```
+------------+-------------------------------------------------------+
| Página 0-3 | Datos de Fábrica, UID (7 bytes), Lock Bytes, CC OTP   |
+------------+-------------------------------------------------------+
| Página 4   | [B0: Header] [B1: SeqNum] [B2: LDR_N] [B3: LDR_S]    |
+------------+-------------------------------------------------------+
| Página 5   | [B4: LDR_W]  [B5: LDR_E]  [B6: Pitch] [B7: Yaw]      |
+------------+-------------------------------------------------------+
| Página 6   | [B8: Bat_MSB][B9: Bat_LSB][B10: RevCount][B11: CRC-8] |
+------------+-------------------------------------------------------+
| Página 7+  | Configuración NTAG, Dynamic Lock, Contador de Lectura |
+------------+-------------------------------------------------------+
```

#### Estructura Detallada de Campos

| Byte Offset | Campo | Tipo | Rango / Valores | Descripción |
| :---: | :--- | :---: | :---: | :--- |
| `0` | `header` | `uint8_t` | Bitfield | Bit 7: Versión de protocolo (`1` = Protocolo V2).<br>Bits 4-6: `motorState` (`0`=DETENIDO, `1`=ADELANTE, `2`=ATRAS, `3`=GIRO_IZQ, `4`=GIRO_DER).<br>Bits 0-3: `lightDirection` (`0`=EQUILIBRADO, `1`=NORTE, `2`=SUR, `3`=ESTE, `4`=OESTE). |
| `1` | `sequenceNumber` | `uint8_t` | $0 - 255$ | Contador monotónico modular de paquetes emitidos. |
| `2` | `ldrNorth` | `uint8_t` | $0 - 255$ | Sensor Norte escalado ($ADC / 4$). |
| `3` | `ldrSouth` | `uint8_t` | $0 - 255$ | Sensor Sur escalado ($ADC / 4$). |
| `4` | `ldrWest` | `uint8_t` | $0 - 255$ | Sensor Oeste escalado ($ADC / 4$). |
| `5` | `ldrEast` | `uint8_t` | $0 - 255$ | Sensor Este escalado ($ADC / 4$). |
| `6` | `servoPitchAngle` | `uint8_t` | $0 - 180^\circ$ | Ángulo de elevación solar actual. |
| `7` | `servoYawAngle` | `uint8_t` | $0 - 180^\circ$ | Ángulo de acimut solar actual. |
| `8` - `9` | `operatingVoltageMv` | `uint16_t` | $0 \lor 3000 - 4200\text{ mV}$ | Voltaje en milivoltios medido en divisor resistivo (formato **Big-Endian**: B8 es MSB, B9 es LSB). $0\text{ mV}$ denota sensor desconectado. |
| `10` | `polarityReversals` | `uint8_t` | $0 - 255$ | Conteo de transiciones `ADELANTE` $\leftrightarrow$ `ATRAS`. |
| `11` | `checksum` | `uint8_t` | `0x00 - 0xFF` | **CRC-8** ($0x07$) calculado sobre los primeros 11 bytes (`0` a `10`). |

#### Consideraciones de Resistencia y Escritura No Atómica
1. **Detección de tramas incompletas**: La escritura sobre un tag NFC NTAG213 se realiza mediante 3 comandos `ntag2xx_WritePage` separados (páginas 4, 5 y 6). Debido a que el protocolo ISO 14443-A no ofrece una transacción atómica para múltiples páginas, una retirada abrupta del dispositivo NFC causaría una trama partida. Dado que el CRC-8 se ubica en el último byte de la página 6, cualquier lectura con páginas desincronizadas fallará inmediatamente la verificación de redundancia cíclica y será descartada.
2. **Mitigación de desgaste de EEPROM**: La memoria EEPROM del transpondedor NTAG213 soporta típicamente $100{,}000$ ciclos de escritura por celda. Escribir continuamente a 1 Hz agotaría la memoria en 27.8 horas. El firmware implementa un estrangulamiento temporal (`NFC_WRITE_THROTTLE_MS = 30000UL`) y chequeo de delta de CRC, escribiendo únicamente ante cambios físicos comprobados o transcurridos al menos 30 segundos.

### 1.5 Matemática de Verificación CRC-8
El algoritmo de redundancia cíclica opera sobre los primeros 11 bytes:
$$P(x) = x^8 + x^2 + x^1 + 1 \quad (\text{Hexadecimal: } 0x07)$$
En cada byte entrante, los bits se desplazan hacia la izquierda; si el bit más significativo (MSB) es `1`, se efectúa una operación XOR con `0x07`:
$$\text{CRC}_{k} = (\text{CRC}_{k-1} \ll 1) \oplus 0x07 \quad \text{si MSB}=1$$
Este cálculo previene falsos positivos ocasionados por acoplamientos inductivos degradados o ruido térmico en las transmisiones de campo cercano.

---

## 2. Manual de Usuario: Aplicación Desktop (Java 21)

La aplicación de escritorio proporciona una estación de telemetría completa para laboratorios y estaciones base de monitoreo.

### 2.1 Requisitos Previos de Sistema
- **Java Runtime Environment (JRE) / JDK**: Versión **21 LTS** o superior de 64 bits.
- **Sistema Operativo**: GNU/Linux, Windows 10/11, macOS.
- **Hardware Opcional**: Lector NFC de escritorio USB compatible con PC/SC (ej. Identiv uTrust, ACR122U, SCM SCL3711).
- **En GNU/Linux**: Asegurar que el servicio `pcscd` se encuentre activo:
  ```bash
  sudo systemctl enable --now pcscd
  ```

### 2.2 Instalación y Ejecución
1. Descargue el archivo ejecutable [AplicacionJava-1.0.0-jar-with-dependencies.jar](https://github.com/RamsesCB/heliostrand-nfc-core-cpp/releases/download/v1.0.0/AplicacionJava-1.0.0-jar-with-dependencies.jar).
2. Ejecute la aplicación abriendo una terminal en la carpeta donde descargó el archivo:
   ```bash
   java --add-modules java.smartcardio -jar AplicacionJava-1.0.0-jar-with-dependencies.jar
   ```
3. O en entornos de desarrollo: Abra la carpeta `AplicacionJava/` en NetBeans, IntelliJ IDEA o VSCode y compile con Maven:
   ```bash
   mvn clean test package
   ```

### 2.3 Uso de la Interfaz Gráfica
Al iniciar, la aplicación presenta una interfaz estilizada con el tema moderno **FlatLaf**:

```
+-------------------------------------------------------------------------+
| [Heliostrand Tracker Desktop v1.0]            [ Estado: CONECTADO ]     |
+------------------------------------+------------------------------------+
|  PANEL DE CONTROL DE SERVOS        |  LECTURAS FOTOMÉTRICAS (LDR)       |
|  - Azimut / Yaw (Servo 2): [ 92° ] |  - LDR Norte: 100 ADC / 25         |
|  - Elevación / Pitch (Servo 1): 90°|  - LDR Sur:   120 ADC / 30         |
|  - Estado Tracción: ADELANTE       |  - Balance Solar: HACIA EL ESTE    |
+------------------------------------+------------------------------------+
|  MEDICIÓN DE ENERGÍA Y BATERÍA     |  GRÁFICO TEMPORAL EN VIVO          |
|  [||||||||||||||||||......] 3850 mV|  (Curvas dinámicas JFreeChart de   |
|  Estado: Nominal (Li-Ion 71%)      |   Intensidad Lumínica vs Tiempo)   |
+------------------------------------+------------------------------------+
|  [ Iniciar Lectura NFC PC/SC ]  [ Activar Simulación ]  [ Exportar CSV ]|
+-------------------------------------------------------------------------+
```

1. **Botón 'Iniciar Lectura NFC'**: Busca lectores PC/SC USB conectados y queda a la espera de aproximar la etiqueta NTAG213 del robot. La consulta de UID utiliza la APDU estándar ISO 7816-4 `FF CA 00 00 00` y libera la tarjeta de manera segura en bloques `finally`.
2. **Botón 'Activar Simulación'**: Si no dispone de hardware físico, genera un ciclo armónico de telemetría para comprobar el rendimiento de los gráficos y medidores en tiempo real.
3. **Pestaña 'Historial de Eventos'**: Muestra una tabla con cada paquete de telemetría decodificado, fecha/hora y validación de integridad CRC.

### 2.4 Solución de Problemas (Troubleshooting Desktop)
- **Error: "No se encontró ningún terminal PC/SC"**: Verifique que el lector USB esté conectado firmemente y que el daemon del sistema esté ejecutándose (`sudo systemctl status pcscd`).
- **Error: "java.lang.NoClassDefFoundError: javax/smartcardio"**: Debe incluir el flag `--add-modules java.smartcardio` en el comando `java` si utiliza OpenJDK modular.
- **Trama Descartada / Error CRC**: Ocurre cuando la etiqueta se retira del lector antes de completar la transferencia de los 12 bytes. Mantenga la tarjeta estática durante al menos 100 ms.

---

## 3. Manual de Usuario: Aplicación Móvil (Flutter / Android)

La aplicación móvil permite a operadores de campo monitorear y diagnosticar el robot directamente mediante un smartphone Android con antena NFC integrada.

### 3.1 Requisitos e Instalación del APK
- **Dispositivo**: Teléfono o tableta con Android 7.0 (API nivel 24) o superior y chip NFC habilitado.
- **Instalación**:
  1. Descargue el paquete [heliostrand-app.apk](https://github.com/RamsesCB/heliostrand-nfc-core-cpp/releases/download/v1.0.0/heliostrand-app.apk).
  2. En su dispositivo Android, abra el archivo descargado. Si el sistema lo solicita, active la casilla *"Permitir la instalación de fuentes desconocidas"*.
  3. Presione **Instalar** y otorgue los permisos normales de NFC.

### 3.2 Procedimiento de Lectura NFC en Campo
1. Inicie la aplicación **Heliostrand Tracker**.
2. Verifique en los ajustes rápidos de Android que el **NFC** esté encendido.
3. Presione el botón flotante circular con el icono de antena: **"Escanear Robot NFC"**.
4. Aproxime la parte posterior de su teléfono a la antena del transceptor PN532 del robot (a una distancia menor a 2 cm).
5. El teléfono emitirá una vibración breve y la pantalla se actualizará instantáneamente con la última muestra telemétrica.

### 3.3 Navegación en el Dashboard Móvil
- **Indicadores Circulares de Servomotores**: Ilustran gráficamente la rotación de acimut ($0^\circ - 180^\circ$) y elevación ($0^\circ - 180^\circ$).
- **Widget de Nivel de Batería**: Barra con gradiente dinámico (Verde $>3700\text{ mV}$, Amarillo $3400-3700\text{ mV}$, Rojo $<3400\text{ mV}$). Si el sensor está desconectado ($0\text{ mV}$), muestra estado de advertencia claro.
- **Monitor de Iluminación**: Tarjetas visuales que indican el valor de cada fotorresistencia y el cuadrante hacia donde orienta el robot su marcha.
- **Historial Acotado**: Gestión circular de memoria limitada a las últimas 50 muestras telemétricas para prevenir fugas de memoria o degradación de rendimiento.

### 3.4 Exportación y Reportes de Telemetría (CSV y JSON)
1. Toque el menú de opciones (tres puntos verticales) en la barra superior del Dashboard.
2. Seleccione **"Exportar CSV"** o **"Exportar JSON"**.
3. El formato CSV cumple rigurosamente con la norma RFC 4180 con encabezados estandarizados (`timestamp,version,sequence,voltage_mv,battery_pct,battery_valid,pitch_deg,yaw_deg,motor_state,light_dir,reversals,ldr_north,ldr_south,ldr_west,ldr_east,tag_uid`).
4. El sistema invocará el menú de compartición nativo de Android (`share_plus`) permitiéndole enviar el registro por correo, mensajería o guardarlo localmente.

### 3.5 Modo Simulación Móvil
Para demostraciones en interiores o entornos sin luz solar directa:
1. Toque el botón de **Simulación** en el panel superior.
2. La aplicación simulará una fuente solar móvil en rotación y un ciclo de batería gradual, permitiendo evaluar el comportamiento de la interfaz y la estabilidad de las gráficas.

---

## 4. Certificación de Calidad y Pruebas del Sistema

El ecosistema cuenta con un régimen integral de verificación continua automatizado en GitHub Actions:

| Módulo | Tipo de Verificación | Herramienta | Resultado |
| :--- | :--- | :--- | :---: |
| **Firmware Arduino C++** | Compilación ATmega328P | PlatformIO CLI (`pio run`) | **APROBADO** (RAM: 28.8%, Flash: 38.6%) |
| **Firmware Arduino C++** | Análisis Estático de Código | PlatformIO Check (`pio check`) | **APROBADO** (0 errores, 0 leaks) |
| **Java Desktop Parser** | Verificación Protocolo V2 & Vectores Dorados | JUnit 5 (`mvn test`) | **APROBADO** (7/7 pruebas pasadas) |
| **Java Desktop App** | Empaquetado Standalone Fat JAR | Maven Assembly Plugin | **APROBADO** (`AplicacionJava-1.0.0`) |
| **Flutter Mobile App** | Análisis Estático de Código | `flutter analyze` | **APROBADO** (0 issues / 0 warnings) |
| **Flutter Mobile Parser** | Verificación Protocolo V2 & Vectores Dorados | `flutter test` | **APROBADO** (8/8 pruebas pasadas) |
| **CI/CD Automatizado** | Pipeline Multiplataforma Integrado | GitHub Actions (`ci.yml`) | **APROBADO** (3/3 jobs exitosos) |
| **Diagramas UML** | Consistencia de Arquitectura | Draw.io XML y Astah UML | **VALIDADO** en `docs/diagrams/` |
