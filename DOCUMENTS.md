# 📚 Documentación Técnica & Manual de Usuario (DOCUMENTS.md)

> **Proyecto**: Heliostrand NFC Core  
> **Versión**: 1.0.0 (Release Certificada)  
> **Autor Principal**: RamsesCB  
> **Repositorio Oficial**: [https://github.com/RamsesCB/heliostrand-nfc-core-cpp](https://github.com/RamsesCB/heliostrand-nfc-core-cpp)

---

## 📑 Índice General

1. [Especificación Técnica de Ingeniería](#1-especificación-técnica-de-ingeniería)
   - [Cinemática Bio-inspirada (Theo Jansen)](#11-cinemática-bio-inspirada-theo-jansen)
   - [Seguimiento Solar Biaxial](#12-seguimiento-solar-biaxial)
   - [Capa de Hardware y Mapeo de Pines (Arduino Uno)](#13-capa-de-hardware-y-mapeo-de-pines-arduino-uno)
   - [Mapeo de Memoria NFC NTAG213](#14-mapeo-de-memoria-nfc-ntag213)
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
   - [Exportación y Reportes de Telemetría](#34-exportación-y-reportes-de-telemetría)
   - [Modo Simulación Móvil](#35-modo-simulación-móvil)
4. [Certificación de Calidad y Pruebas del Sistema](#4-certificación-de-calidad-y-pruebas-del-sistema)

---

## 1. Especificación Técnica de Ingeniería

### 1.1 Cinemática Bio-inspirada (Theo Jansen)
El sistema motriz implementa el mecanismo planar de 11 barras de **Theo Jansen**, el cual convierte la rotación continua de un cigüeñal impulsado por un motor DC reductor en una trayectoria de paso casi plana con levantamiento suave. Esto maximiza la tracción sobre superficies irregulares sin balanceo vertical excesivo, permitiendo que la plataforma de paneles solares mantenga estabilidad angular.

### 1.2 Seguimiento Solar Biaxial
El control de orientación utiliza dos fotorresistencias (LDR) montadas con un tabique separador de sombra central:
- **Eje de Azimut (Horizontal)**: Controlado por el Servomotor 1 (Rango: $0^\circ - 180^\circ$, neutral en $90^\circ$).
- **Eje de Elevación (Vertical)**: Controlado por el Servomotor 2 (Rango: $0^\circ - 180^\circ$, elevación solar óptima entre $30^\circ$ y $150^\circ$).
- **Banda Muerta (Deadband)**: Se implementa un umbral de histéresis $\Delta_{\text{umbral}} = 50$ en lecturas ADC para prevenir vibraciones servomotoras cuando la iluminación es homogénea.

### 1.3 Capa de Hardware y Mapeo de Pines (Arduino Uno)

| Componente | Pin Arduino | Tipo de Señal | Función Operativa |
| :--- | :---: | :---: | :--- |
| **LDR Izquierda** | `A0` | Entrada Analógica | Sensor de intensidad lumínica izquierda (0 - 5V) |
| **LDR Derecha** | `A1` | Entrada Analógica | Sensor de intensidad lumínica derecha (0 - 5V) |
| **Divisor Tensión Batería** | `A2` | Entrada Analógica | Medición de batería Li-Ion mediante divisor resistivo |
| **Servo Azimut (H)** | `D9` | Salida PWM (Timer 1) | Posicionamiento angular horizontal ($0^\circ - 180^\circ$) |
| **Servo Elevación (V)**| `D10` | Salida PWM (Timer 1) | Posicionamiento angular vertical ($0^\circ - 180^\circ$) |
| **Driver Motor Tracción** | `D5, D6` | Salidas Digitales | Habilitación y sentido de marcha del puente H |
| **NFC PN532 SS / CS** | `D10` (o D4) | SPI Chip Select | Selección de bus para comunicación con transceptor |
| **NFC PN532 SCK/MOSI/MISO** | `D13, D11, D12`| Bus SPI Hardware | Transferencia de datos de alta velocidad con el chip NFC |

### 1.4 Mapeo de Memoria NFC NTAG213

El transceptor graba atómicamente la estructura de telemetría en el área accesible de usuario (User Memory):

```
+------------+-------------------------------------------------------+
| Bloque 0-3 | Datos de Fábrica, UID (7 bytes), Lock Bytes, CC OTP   |
+------------+-------------------------------------------------------+
| Bloque 4   | [B0: Servo1 LSB] [B1: Servo1 MSB] [B2: Servo2 LSB] [B3: Servo2 MSB] |
+------------+-------------------------------------------------------+
| Bloque 5   | [B4: LDR_L LSB]  [B5: LDR_L MSB]  [B6: LDR_R LSB]  [B7: LDR_R MSB]  |
+------------+-------------------------------------------------------+
| Bloque 6   | [B8: Bat_mV LSB] [B9: Bat_mV MSB] [B10: StatusFlags] [B11: CRC-8]   |
+------------+-------------------------------------------------------+
| Bloque 7+  | Configuración NTAG, Dynamic Lock, Contador de Lectura |
+------------+-------------------------------------------------------+
```

### 1.5 Matemática de Verificación CRC-8
El algoritmo de redundancia cíclica opera sobre los primeros 11 bytes:
$$P(x) = x^8 + x^2 + x^1 + 1 \quad (\text{Hexadecimal: } 0x07)$$
En cada byte entrante, los bits se desplazan hacia la izquierda; si el bit más significativo (MSB) es `1`, se efectúa una operación XOR con `0x07`:
$$\text{CRC}_{k} = (\text{CRC}_{k-1} \ll 1) \oplus 0x07 \quad \text{si MSB}=1$$
Este cálculo previene falsos positivos ocasionados por lecturas electromagnéticas degradadas en campo.

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
1. Descargue el archivo ejecutable [AplicacionJava-1.0-SNAPSHOT-jar-with-dependencies.jar](https://github.com/RamsesCB/heliostrand-nfc-core-cpp/releases/download/v1.0.0/AplicacionJava-1.0-SNAPSHOT-jar-with-dependencies.jar).
2. Ejecute la aplicación abriendo una terminal en la carpeta donde descargó el archivo:
   ```bash
   java --add-modules java.smartcardio -jar AplicacionJava-1.0-SNAPSHOT-jar-with-dependencies.jar
   ```
3. O en entornos de desarrollo: Abra la carpeta `AplicacionJava/` en **Apache NetBeans** o IntelliJ IDEA y presione **Run Project (F6)**.

### 2.3 Uso de la Interfaz Gráfica
Al iniciar, la aplicación presenta una interfaz estilizada con el tema moderno **FlatLaf**:

```
+-------------------------------------------------------------------------+
| [Heliostrand Tracker Desktop v1.0]            [ Estado: CONECTADO ]     |
+------------------------------------+------------------------------------+
|  PANEL DE CONTROL DE SERVOS        |  LECTURAS FOTOMÉTRICAS (LDR)       |
|  - Azimut (Servo 1): [  92° ]       |  - Sensor Izquierdo: 645 ADC       |
|  - Elevación (Servo 2): [ 115° ]   |  - Sensor Derecho:   712 ADC       |
|  - Estado Tracción: ACTIVO         |  - Balance Solar:    HACIA EL ESTE |
+------------------------------------+------------------------------------+
|  MEDICIÓN DE ENERGÍA Y BATERÍA     |  GRÁFICO TEMPORAL EN VIVO          |
|  [||||||||||||||||||......] 3840 mV|  (Curvas dinámicas JFreeChart de   |
|  Estado: Saludable (Li-Ion 82%)    |   Intensidad Lumínica vs Tiempo)   |
+------------------------------------+------------------------------------+
|  [ Iniciar Lectura NFC PC/SC ]  [ Activar Simulación ]  [ Exportar CSV ]|
+-------------------------------------------------------------------------+
```

1. **Botón 'Iniciar Lectura NFC'**: Busca lectores PC/SC USB conectados y queda a la espera de aproximar la etiqueta NTAG213 del robot.
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
4. Aproxime la parte superior o posterior de su teléfono (donde se ubica la bobina NFC) a la placa NTAG213 del robot Theo Jansen (a una distancia menor a 2 cm).
5. El teléfono emitirá una vibración héctica breve y la pantalla se actualizará instantáneamente con la última muestra telemétrica.

### 3.3 Navegación en el Dashboard Móvil
- **Indicadores Circulares de Servomotores**: Ilustran gráficamente la rotación de acimut ($0^\circ - 180^\circ$) y elevación ($0^\circ - 180^\circ$).
- **Widget de Nivel de Batería**: Barra con gradiente dinámico (Verde $>3700\text{ mV}$, Amarillo $3400-3700\text{ mV}$, Rojo $<3400\text{ mV}$).
- **Monitor de Iluminación**: Tarjetas visuales que indican el valor ADC de cada fotorresistencia y una flecha direccional que indica hacia dónde orienta el robot su marcha.
- **Gráfica Reactiva**: Gráfica de líneas suave impulsada por `fl_chart` con histórico de las últimas 50 muestras.

### 3.4 Exportación y Reportes de Telemetría
1. Toque el botón de opciones en la esquina superior derecha del Dashboard.
2. Seleccione **"Exportar Telemetría"**.
3. Elija el formato deseado (**CSV** tabular o **JSON** estructurado).
4. El sistema invocará el menú nativo de Android (`share_plus`) permitiéndole enviar el registro por WhatsApp, correo electrónico, Google Drive o guardarlo localmente.

### 3.5 Modo Simulación Móvil
Para demostraciones en interiores o entornos sin luz solar directa:
1. Active el selector **"Modo Simulación"** en el panel superior.
2. La aplicación simulará una fuente solar móvil en órbita y un consumo de batería gradual, permitiendo evaluar el comportamiento de la interfaz y la estabilidad de las gráficas.

---

## 4. Certificación de Calidad y Pruebas del Sistema

El ecosistema cuenta con un régimen integral de verificación continua:

| Módulo | Tipo de Prueba | Framework / Herramienta | Estado de Certificación |
| :--- | :--- | :--- | :---: |
| **Firmware Arduino C++** | Integridad de tipos y memoria SRAM | PlatformIO Static Analysis (`pio check`) | **APROBADO** (0 memory leaks) |
| **Java Desktop Parser** | Verificación de tramas y CRC-8 ($0x07$) | JUnit 5 (`TheoJansenDataParserTest`) | **APROBADO** (3/3 Tests Pasados) |
| **Flutter Mobile Parser** | Verificación de tramas binarias Little-Endian | Dart Test Runner (`flutter test`) | **APROBADO** (100% Cobertura Parser) |
| **Diagramas UML** | Consistencia de Arquitectura | Draw.io XML y Astah UML | **VALIDADO** en `docs/diagrams/` |
