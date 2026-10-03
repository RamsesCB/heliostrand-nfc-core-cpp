# 📋 Reglas de Contribución y Estándares de Ingeniería (RULES.md)

> **Heliostrand NFC Core**  
> Directrices obligatorias para desarrolladores y colaboradores del proyecto.

---

## 1. Convenciones de Código y Estilo

### 1.1 Firmware C++ (PlatformIO / Arduino)
- **Estándar**: C++17.
- **Nombres de Clases y Structs**: `PascalCase` (ej. `TheoJansenTelemetry`, `SolarTracker`, `NfcTransceiver`).
- **Nombres de Métodos y Funciones**: `camelCase` (ej. `computeCrc8`, `updateSensors`, `writeNfcBlock`).
- **Constantes y Macros**: `SCREAMING_SNAKE_CASE` (ej. `PAYLOAD_SIZE`, `CRC8_POLYNOMIAL`, `NFC_BLOCK_START`).
- **Gestión de Memoria**: Prohibido el uso de memoria dinámica en el ciclo de ejecución `loop()`. Todos los buffers deben ser estáticos o en stack preasignado.
- **Formato**: Indentación de 2 o 4 espacios (consistente con `.clang-format`).

### 1.2 Aplicación de Escritorio Java 21 (Swing / FlatLaf)
- **Estándar**: Java SE 21 LTS con Maven.
- **Estructura de Paquetes**: Todo en minúsculas:
  - `com.theojansen.nfc.model`: Clases de dominio inmutables o POJOs.
  - `com.theojansen.nfc.core`: Servicios de conexión PC/SC, listeners de eventos.
  - `com.theojansen.nfc.parser`: Parser binario y cálculo de CRC-8.
  - `com.ramsescb.heliostrand.desktop`: Controladores y vistas de la interfaz Swing.
- **Concurrencia UI**: Toda mutación visual sobre componentes Swing **debe realizarse en el Event Dispatch Thread (EDT)**:
  ```java
  SwingUtilities.invokeLater(() -> {
      labelStatus.setText("Conectado");
  });
  ```
- **Pruebas**: Cada funcionalidad en `parser` o `model` debe contar con su correspondiente test JUnit 5 en `src/test/java/`.

### 1.3 Aplicación Móvil Flutter (Dart 3 / Material 3)
- **Estándar**: Dart 3.x con `flutter_lints`.
- **Nombres de Archivos**: `snake_case.dart` (ej. `nfc_service.dart`, `robot_telemetry.dart`).
- **Nombres de Clases y Widgets**: `PascalCase` (ej. `DashboardScreen`, `TheoJansenDataParser`).
- **Nombres de Variables y Métodos**: `camelCase` (ej. `batteryMillivolts`, `calculateCrc8`).
- **Gestión de Estados**: `ChangeNotifier` / `Provider` estructurado y reactivo.
- **Limpieza de Recursos**: Todo `StreamSubscription`, `Timer` o `TextEditingController` debe cerrarse en `dispose()`.

---

## 2. Invariantes del Protocolo de Telemetría (Protocolo V2 & CRC-8)

Cualquier propuesta que modifique la estructura binaria de la trama debe respetar estrictamente:

1. **Longitud Fija**: 12 bytes exactamente. Queda prohibida la aceptación de tramas de tamaño arbitrario.
2. **Endianness**: Big-Endian (Byte más significativo primero) para magnitudes multibyte (ej. voltaje en milivoltios en Bytes 8 y 9).
3. **Algoritmo CRC-8**:
   - Polinomio canónico: `0x07` ($x^8 + x^2 + x^1 + 1$).
   - Valor inicial: `0x00`.
   - Campo de verificación: Byte 11 (calculado sobre los primeros 11 bytes: 0 a 10).
4. **Protección de Desgaste EEPROM**: Primera escritura inmediata; las posteriores requieren al menos 5 minutos y un cambio significativo, o 15 minutos para refresh sin cambios. sequenceNumber y CRC quedan excluidos del detector de cambios. Toda escritura se verifica mediante read-back antes de actualizar el estado del writer.
5. **Mapeo Físico Invariante**: Ninguna modificación de firmware debe reintroducir conflictos de pines sobre el bus SPI (`D4 CS`, `D11 MOSI`, `D12 MISO`, `D13 SCK`) ni sobre los canales analógicos (`A0-A3 LDR`, `A4 Batería`).
6. **Sincronización Cuádruple**: Cualquier cambio de protocolo debe actualizarse y validarse simultáneamente en:
   - `include/TheoJansenTelemetry.h` y `src/TheoJansenTelemetry.cpp` (C++)
   - `TheoJansenDataParser.java` y `TheoJansenDataParserTest.java` (Java)
   - `theo_jansen_data_parser.dart` y `theo_jansen_data_parser_test.dart` (Dart)
   - `test/vectors/golden_telemetry_vectors.json` (Vectores Dorados de Referencia)

---

## 3. Flujo de Trabajo Git y Commits

### 3.1 Formato de Commits (Conventional Commits)
Los mensajes de confirmación deben seguir el formato:
```
<tipo>(<alcance opcional>): <descripción concisa en imperativo>
```
**Tipos válidos:**
- `feat`: Nueva funcionalidad (ej. `feat(nfc): add support for PN532 I2C fallback`).
- `fix`: Corrección de bug (ej. `fix(parser): correct byte order for battery reading`).
- `docs`: Documentación (ej. `docs: update telemetry frame mermaid diagram`).
- `refactor`: Refactorización de código sin cambio funcional.
- `test`: Incorporación o mejora de pruebas unitarias.
- `chore`: Tareas de mantenimiento o configuración de builds.

### 3.2 Estrategia de Ramas
1. Ramas de trabajo deben crearse a partir de `main` con prefijo:
   - `feature/<nombre-breve>`
   - `fix/<nombre-breve>`
2. No hacer commits directos sobre la rama `main`.
3. Antes de abrir un Pull Request, ejecutar un `rebase` sobre `main` para evitar commits de mezcla espurios.

---

## 4. Validación Pre-Pull Request (Local Checklist)

Antes de enviar un Pull Request, es obligatorio ejecutar y verificar localmente los siguientes comandos:

```bash
# 1. Verificar Firmware Arduino (Compilación y Análisis Estático)
pio run
pio check --skip-packages

# 2. Verificar y compilar Aplicación Java (Tests JUnit incluidos)
cd AplicacionJava
mvn clean test package
cd ..

# 3. Analizar y probar Aplicación Flutter
cd heliostrand_app
flutter analyze
flutter test
cd ..
```

Si alguno de estos comandos falla, el Pull Request será rechazado automáticamente.

---

## 5. Mantenimiento de Diagramas de Arquitectura

- Si se altera o amplía el modelo de dominio o las relaciones entre clases, debe actualizarse el diagrama nativo en [docs/diagrams/APPNFC.drawio](file:///home/ramsescb/Projects/arduino_app_Fundamentos/docs/diagrams/APPNFC.drawio) o los archivos de proyecto Astah [docs/diagrams/*.asta](file:///home/ramsescb/Projects/arduino_app_Fundamentos/docs/diagrams/).
