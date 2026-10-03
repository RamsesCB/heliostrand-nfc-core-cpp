# 🏛️ Constitución del Proyecto: Heliostrand NFC Core

> **Ecosistema de Telemetría Solar y Robótica Bio-inspirada (Theo Jansen)**  
> Firmware Arduino C++ • Aplicación de Escritorio Java 21 (Swing/FlatLaf) • Aplicación Móvil Flutter (Dart/Material 3)

---

## Preámbulo

Nosotros, los desarrolladores, investigadores y colaboradores de **Heliostrand NFC Core**, establecemos esta **Constitución** para garantizar la excelencia técnica, la integridad de los datos de telemetría y una gobernanza abierta, ética y colaborativa.

Este proyecto fusiona la cinemática de los mecanismos de caminata de **Theo Jansen** con sistemas de seguimiento solar autónomo de dos ejes y transmisión inalámbrica de telemetría de campo cercano (**NFC NTAG213 / ISO 14443-A**). 

Toda contribución al repositorio debe alinearse con los principios inmutables descritos en los siguientes artículos.

---

## Artículo I: Invariantes Técnicos y Protocolo de Telemetría

### 1.1 Invariante de Integridad por CRC-8
1. La trama de telemetría de 12 bytes es el estándar universal e inmutable entre el hardware y todas las plataformas cliente.
2. La integridad de cada paquete recibido o transmitido **debe validarse obligatoriamente mediante CRC-8** con polinomio generador `0x07` ($x^8 + x^2 + x^1 + 1$) y valor inicial `0x00`:
   $$\text{CRC-8}(D_0, D_1, \dots, D_{10}) = D_{11}$$
3. Queda terminantemente prohibido procesar, graficar o almacenar en el modelo de dominio tramas cuyo checksum no coincida con el cálculo estricto.

### 1.2 Determinismo de Hardware
1. El firmware de Arduino (`src/`, `include/`) opera bajo control en tiempo real en lazo cerrado para los servomotores y sensores LDR.
2. La escritura NFC en los bloques de usuario de memoria (Bloques 4, 5 y 6 del NTAG213) y la transmisión Serial (115200 baud) no deben bloquear los ciclos de control cinemático.

### 1.3 Principio de Clean Architecture y Multiplataforma
1. El código de las aplicaciones clientes (Java y Flutter) debe respetar la separación en capas:
   - **Dominio / Modelo**: Entidades inmutables (`RobotTelemetry`, `LightDirection`, `MotorState`).
   - **Core / Servicios**: Parsers de bajo nivel, validadores CRC, gestores NFC y abstracciones de hardware.
   - **Presentación**: Vistas desacopladas, dashboards reactivos y renderizado gráfico.
2. La lógica de negocio y parseo debe ser funcionalmente idéntica en Java y Dart. Un paquete binario idéntico debe producir exactamente los mismos valores numéricos y estados en ambas aplicaciones.

### 1.4 Resiliencia y Modo Simulación Fallback
1. Ambas aplicaciones clientes deben mantener un generador de telemetría simulada autónomo para pruebas de UI y desarrollo sin lector físico conectado.

---

## Artículo II: Derechos y Deberes de los Contribuidores

### 2.1 Derechos del Contribuidor
- Todo colaborador tiene derecho a una revisión de código constructiva, objetiva y fundamentada en estándares técnicos.
- Toda contribución aceptada preservará el crédito y autoría del contribuidor en el historial de Git y archivos de contribución.

### 2.2 Deberes del Contribuidor
- **Cobertura de Pruebas**: Todo cambio en parsers, modelos o serialización debe incluir pruebas unitarias (JUnit 5 en Java, `test` en Flutter/Dart).
- **No Regresión**: No se aceptará ningún Pull Request que rompa la compilación de PlatformIO, el empaquetado Maven de Java o el análisis estático de Flutter.
- **Preservación Documental**: Si una contribución añade o modifica interfaces o contratos de datos, los diagramas de clase en `docs/diagrams/` (`.drawio` y `.asta`) deben actualizarse de manera síncrona.

---

## Artículo III: Estándares de Ingeniería y Calidad

### 3.1 C++ / Firmware
- Lenguaje: C++17 compatible con AVR-GCC para microcontroladores ATmega328P (Arduino Uno).
- Gestión de Memoria: Prohibida la asignación dinámica (`malloc`, `new`, `String` dinámico) en el bucle principal de ejecución (`loop()`) para evitar fragmentación de SRAM.

### 3.2 Java Desktop
- Lenguaje: Java 21 LTS con Maven.
- Concurrencia Swing: Todas las actualizaciones de UI deben ejecutarse obligatoriamente dentro del **Event Dispatch Thread (EDT)** usando `SwingUtilities.invokeLater`.
- Acceso a Hardware: Empleo del módulo estándar `java.smartcardio` para compatibilidad PC/SC sin dependencias nativas propietarias.

### 3.3 Flutter Mobile
- SDK: Flutter 3.x / Dart 3.x.
- UI/UX: Material Design 3 con tematización adaptativa (Dark/Light).
- Gestión de Recursos: Cancelación estricta de streams y temporizadores en `dispose()` para prevenir fugas de memoria.

---

## Artículo IV: Gobernanza y Flujo de Trabajo

### 4.1 Ramas de Trabajo
- `main`: Rama protegida de producción. Refleja código estable y probado en hardware.
- `feature/*`: Ramas individuales para nuevas características o componentes.
- `fix/*`: Ramas para corrección de anomalías o bugs de telemetría.

### 4.2 Proceso de Aprobación
1. Creación de Issue o discusión de propuesta.
2. Implementación siguiendo las directrices de `RULES.md`.
3. Verificación local de compilación triple (PlatformIO + Maven + Flutter).
4. Apertura de Pull Request con descripción técnica exhaustiva.
5. Aprobación y merge mediante Squash & Merge o Rebase limpio.

---

## Artículo V: Enmiendas

Cualquier modificación a esta Constitución requerirá consenso del equipo líder del proyecto y justificación arquitectónica documentada mediante un Architecture Decision Record (ADR).
