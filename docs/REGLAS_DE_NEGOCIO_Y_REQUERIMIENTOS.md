# Heliostrand — Especificación de Reglas de Negocio, Requerimientos y Procesos

> **Versión:** 2.0.0  
> **Estado:** Normativo / Aprobado  
> **Ámbito:** Java Desktop (Swing / PC-SC), Mobile App (Flutter / NFC), Firmware Arduino Uno R3 / NTAG213  
> **Rama de desarrollo:** `feature/desktop-ui-modernization`  

---

## 1. Introducción y Alcance del Sistema

El ecosistema **Heliostrand** es una plataforma ciberfísica de telemetría y control para robots cinemáticos *Strandbeest* guiados por luz solar. El sistema integra:
1. **Unidad Embebida (Robot):** Microcontrolador ATmega328P, servos de seguimiento solar (Pitch/Yaw), 4 sensores LDR cardinales, puente H para locomoción y transceptor NFC PN532 conectado por bus SPI a un tag EEPROM NTAG213.
2. **Estación Base de Monitoreo Desktop (Java Swing):** Aplicación de escritorio que adquiere telemetría mediante lectores USB compatibles con el estándar PC/SC (ISO/IEC 7816 / ISO/IEC 14443-A), procesa buffers FIFO históricos multinivel y renderiza paneles de control con temas profesionales (FlatLaf).
3. **Herramienta de Campo Móvil (Flutter Mobile):** Aplicación multiplataforma (Android / iOS) con comunicación bidireccional por NFC, capaz de validar políticas de versión (*Version Gate*), graficar radar cardinal en tiempo real, calibrar servomotores y persistir/exportar telemetría en JSON y CSV.

---

## 2. Catálogo Normativo de Reglas de Negocio (RN)

Las siguientes reglas gobiernan la lógica de dominio, la integridad de hardware y las restricciones criptográficas/binarias del sistema.

| ID | Regla de Negocio | Descripción y Criterio de Aceptación | Clases / Componentes Responsables | Severidad |
|---|---|---|---|---|
| **RN-01** | **Integridad Polinómica CRC-8** | Toda trama de telemetría transmitida o leída debe validar su integridad mediante CRC-8 con polinomio generador `0x07` e inicializador `0x00` sobre los primeros 11 bytes (offset 0..10). Si el CRC calculado no coincide exactamente con el byte 11, la trama se descarta inmediatamente. | `TheoJansenDataParser` (Java & Dart), `CorruptedPayloadException` | **Crítica (Bloqueante)** |
| **RN-02** | **Versionado Estricto de Protocolo V2** | Los bits 7-6 del primer byte (`headerFlags`) deben coincidir con `0b10` (versión 2). Cualquier trama con bits de versión distintos dispara una excepción de incompatibilidad. | `TheoJansenDataParser`, `UnsupportedProtocolVersionException` | **Crítica** |
| **RN-03** | **Estados Válidos del Puente H** | Los bits 5-4 de `headerFlags` codifican el estado de tracción: `00` = Detenido, `01` = Adelante, `10` = Atrás. El valor `11` está reservado y es considerado inválido, provocando el rechazo de la trama para prevenir cortocircuitos por conducción cruzada. | `MotorState`, `TheoJansenDataParser` | **Alta** |
| **RN-04** | **Cuadrantes de Orientación Cardinal** | Los bits 3-0 de `headerFlags` codifican la dirección de mayor irradiación solar: `0` = Equilibrado, `1` = Norte, `2` = Sur, `3` = Este, `4` = Oeste. Los códigos `5` a `15` son inválidos y deben ser rechazados. | `LightDirection`, `RobotTelemetry` | **Alta** |
| **RN-05** | **Restricción Cinemática de Servomotores** | El protocolo define un rango teórico de 0° a 180°. Sin embargo, el firmware impone límites mecánicos de seguridad: **Pitch (Elevación):** 15° a 165°; **Yaw (Azimut):** 10° a 170°. Todo comando fuera de estos rangos debe ser recortado (*clamped*) por la aplicación antes de transmitirlo al robot. | `ServosCard`, `NfcService` | **Crítica (Seguridad Mecánica)** |
| **RN-06** | **Rango Operativo de Batería Li-ion 1S** | La telemetría reporta milivoltios en un entero Big-Endian de 16 bits. El valor `0` indica medición no disponible. Si es distinto de cero, debe encontrarse en el rango de 2500 mV a 5000 mV (nominal 3000 a 4200 mV). Valores fuera de rango se marcan como inválidos. | `RobotTelemetry.getBatteryLevelPercent()`, `MotorBatteryCard` | **Alta** |
| **RN-07** | **Doble Buffer Ping-Pong y Wear Leveling** | Para maximizar la vida útil de la memoria EEPROM del tag NTAG213 (>100,000 ciclos de escritura), el almacenamiento se divide en Slot A (páginas 4 a 7) y Slot B (páginas 8 a 11). Cada slot reserva su última página como byte de confirmación (*commit*). El lector compara la generación modular de ambos slots y selecciona el más reciente no corrupto. | `AbstractNfcService`, `NfcServiceManager`, `NfcService` | **Crítica (Durabilidad EEPROM)** |
| **RN-08** | **Filtro Anti-Spam de Escritura NFC** | El robot debe esperar un intervalo mínimo de 5 minutos entre escrituras ordinarias en el tag NFC, y un refresco de 15 minutos en estados estacionarios sin cambios significativos. Esto previene la fatiga prematura del tag por fluctuaciones transitorias de luz. | Firmware C++, `NfcService` | **Media** |
| **RN-09** | **Trazabilidad Circular de Secuencia** | El campo `sequenceNumber` (0..255) es un contador incremental circular. Los clientes (Java y Móvil) mantienen la última secuencia procesada por cada UID de tag y no procesan lecturas redundantes con la misma secuencia. | `MainTrackerFrame`, `_DashboardScreenState` | **Media** |
| **RN-10** | **Monitor de Estrés Térmico del Motor** | El byte `polarityReversals` cuenta las transiciones directas `ADELANTE` ↔ `ATRÁS`. Si la tasa de inversiones supera el umbral crítico por minuto, la interfaz debe alertar posible sobrecalentamiento en el driver L298N. | `RobotTelemetry`, `MotorBatteryCard` | **Media** |
| **RN-11** | **Version Gate Obligatorio en Móvil** | Antes de habilitar cualquier interacción con el hardware, la app móvil debe consultar `UpdatePolicyService`. Si la versión instalada es obsoleta frente al esquema de telemetría activo, la pantalla se bloquea obligando a la actualización. | `VersionGate`, `UpdatePolicyService` | **Crítica (Compatibilidad)** |
| **RN-12** | **Aislamiento del Hilo Gráfico Swing EDT** | Ninguna operación de E/S bloqueante PC/SC debe ejecutarse en el Event Dispatch Thread (EDT). Todas las lecturas corren en hilos desacoplados y se despachan al EDT exclusivamente vía `SwingUtilities.invokeLater()`. | `TrackerUiController`, `NfcServiceManager` | **Crítica (Rendimiento UI)** |
| **RN-13** | **Buffer FIFO Histórico Multinivel** | La estación de monitoreo Java mantiene una ventana deslizante de exactamente 5 muestras para cada sensor LDR (Norte, Sur, Este, Oeste). Al llegar una nueva muestra, la más antigua se descarta y las barras se renderizan con opacidades decrecientes escalonadas (1.00, 0.80, 0.65, 0.50, 0.35). | `MainTrackerFrame`, `CustomBarRenderer` | **Media (Visualización)** |
| **RN-14** | **Transaccionalidad Exclusiva de Sesión NFC** | La sesión NFC móvil no debe permitir lecturas concurrentes simultáneas. Cada lectura debe abrir sesión, adquirir páginas de memoria, escribir comandos pendientes si existen, y ejecutar `FlutterNfcKit.finish()` de forma atómica en bloques `finally`. | `NfcService` | **Alta (Estabilidad Driver)** |
| **RN-15** | **Resiliencia de Transporte y Reconexión** | La desconexión accidental del lector USB o la retirada brusca de la tarjeta no debe abortar la aplicación ni causar fugas de memoria. El sistema debe capturar `CardException`, notificar al controlador e ingresar en modo espera automática. | `AbstractNfcService`, `NfcServiceManager` | **Alta (Tolerancia a Fallos)** |

---

## 3. Requerimientos del Sistema

### 3.1. Requerimientos Funcionales — Java Desktop (RF-JD)

- **RF-JD01 [Gestión de Terminales PC/SC]:** El sistema debe enumerar dinámicamente los lectores de tarjetas inteligentes USB conectados al equipo anfitrión y permitir al operador seleccionar el dispositivo activo.
- **RF-JD02 [Monitoreo Continuo Desacoplado]:** El sistema debe permitir iniciar y detener un hilo de escaneo en segundo plano que sondee la presencia de tags NTAG213 cada 1000 ms sin congelar la interfaz Swing.
- **RF-JD03 [Validación de Trama V2]:** El sistema debe validar la longitud (12 bytes), el CRC-8 polinómico `0x07` y los bits de versión antes de admitir cualquier lectura en el modelo de dominio.
- **RF-JD04 [Buffer FIFO y Renderizado Histórico]:** La aplicación debe actualizar un buffer de 5 muestras históricas por canal LDR y renderizar las barras con opacidades escalonadas y paleta profesional Slate/Cobalt.
- **RF-JD05 [Orientación y Brújula Solar]:** La UI debe mostrar la dirección solar dominante calculada por el robot (Norte, Sur, Este, Oeste o Equilibrado) mediante iconos y etiquetas destacadas.
- **RF-JD06 [Telemetría Eléctrica y Batería]:** El sistema debe presentar el voltaje operativo del robot en milivoltios y calcular el porcentaje de carga para celdas Li-ion 1S.
- **RF-JD07 [Modo Simulación Sintética]:** El operador debe poder alternar a un modo de simulación manual con temporizador interno para pruebas de escritorio sin hardware conectado.
- **RF-JD08 [Motor de Temas Visuales FlatLaf]:** El operador debe poder alternar entre temas modernos (Darcula, IntelliJ Light, macOS Light/Dark) en tiempo de ejecución sin reiniciar la aplicación.

### 3.2. Requerimientos Funcionales — Flutter Mobile (RF-MA)

- **RF-MA01 [Verificación de Versión en Arranque]:** La aplicación debe validar la compatibilidad de versión contra `UpdatePolicyService` antes de conceder acceso al panel de control.
- **RF-MA02 [Lectura Transaccional NFC]:** La app debe comunicarse con el tag NTAG213 mediante la API de proximidad de Android e iOS (ISO 14443-A), adquiriendo las páginas de datos en menos de 500 ms tras el contacto.
- **RF-MA03 [Resolución de Doble Buffer Ping-Pong]:** El parser debe comparar los encabezados de los slots A y B y deserializar el slot más reciente con integridad confirmada.
- **RF-MA04 [Brújula Radar y Tarjetas Reactivas]:** La UI debe mostrar tarjetas modulares desacopladas: Gráfico radar de 4 cuadrantes (`LdrChartCard`), Posición de servomotores (`ServosCard`), y Estado de motor/batería (`MotorBatteryCard`).
- **RF-MA05 [Transmisión de Comandos de Servos]:** El técnico debe poder calibrar ángulos de Pitch y Yaw mediante controles táctiles y transmitirlos al tag en la siguiente interacción RF.
- **RF-MA06 [Exportación de Historial]:** La aplicación debe permitir exportar las sesiones de telemetría a formatos abiertos estándar JSON y CSV para análisis en laboratorio.
- **RF-MA07 [Simulación Reactiva en Campo]:** La aplicación debe incorporar un `SimulationService` con generador periódico de muestras sintéticas controladas por sliders para demostraciones.
- **RF-MA08 [Bloqueo Obligatorio por Incompatibilidad]:** Si se detecta una versión deprecada, la aplicación debe mostrar una pantalla de bloqueo persistente impidiendo operaciones que comprometan la seguridad del robot.

### 3.3. Requerimientos No Funcionales (RNF)

- **RNF-01 [Rendimiento y Latencia]:**
  - El tiempo de deserialización y verificación CRC-8 debe ser inferior a 2 milisegundos en microprocesadores estándar de escritorio y dispositivos móviles.
  - La interfaz gráfica debe mantener una tasa de refresco fluida de 60 FPS sin bloqueos en el hilo principal.
- **RNF-02 [Robustez y Tolerancia a Fallos]:**
  - Cero caídas catastróficas (*zero unhandled crashes*): Todas las lecturas corrompidas, desconexiones o fallos en el bus RF deben aislarse con jerarquías de excepciones tipadas (`CorruptedPayloadException`, `NfcDeviceException`).
- **RNF-03 [Mantenibilidad y Arquitectura Limpia]:**
  - Separación estricta de capas: Dominio, Servicios, Controladores y Presentación.
  - Reutilización de contratos: Implementación de clases abstractas (`AbstractNfcService`, `BaseTelemetryService`) e interfaces públicas con métodos explícitos.
  - Inmutabilidad estricta en el modelo de datos (`RobotTelemetry`).
- **RNF-04 [Compatibilidad de Plataforma]:**
  - Java Desktop: Java Runtime Environment (JRE) versión 17 o superior en Linux, Windows y macOS.
  - Mobile App: Flutter 3.x con compatibilidad mínima para Android SDK 21 (Lollipop) e iOS 13+.
- **RNF-05 [Seguridad Operativa de Hardware]:**
  - Resguardo frente a sobreescrituras excesivas en la EEPROM mediante arquitectura ping-pong y límites de frecuencia de escritura.
  - Resguardo térmico de servomotores limitando los ángulos en software a las tolerancias mecánicas reales.

---

## 4. Especificación Detallada de Casos de Uso

### 4.1. Java Desktop Swing

#### CU-JD01: Seleccionar Terminal PC/SC
- **Actor Principal:** Operador de Estación.
- **Precondiciones:** Lector USB conectado y controladores PC/SC instalados.
- **Flujo Principal:**
  1. El operador abre la aplicación.
  2. El sistema enumera los lectores conectados en el combo desplegable.
  3. El operador selecciona el terminal deseado (ej. *ACS ACR122U*).
  4. El sistema vincula el terminal a `AbstractNfcService`.
- **Excepciones:** Si no se detectan terminales, el combo se inhabilita y se muestra el mensaje *"No se detectaron lectores PC/SC"*.

#### CU-JD02: Iniciar / Detener Monitoreo Continuo
- **Actor Principal:** Operador de Estación.
- **Actores Secundarios:** Lector NFC USB, Robot Strandbeest (Tag NTAG213).
- **Relaciones:** `<<include>>` CU-JD03 (Validar Integridad), `<<include>>` CU-JD04 (Visualizar Telemetría), `<<extend>>` CU-JD07 (Manejar Excepciones).
- **Flujo Principal:**
  1. El operador pulsa "Iniciar Monitoreo".
  2. `NfcServiceManager` lanza un hilo de ejecución en segundo plano.
  3. El hilo invoca cíclicamente `waitForCardPresent()`.
  4. Al detectar la tarjeta, lee las páginas del tag, valida la trama y actualiza la UI.
  5. El operador puede pulsar "Detener Monitoreo" en cualquier momento para liberar el lector.

#### CU-JD04: Visualizar Telemetría y Buffer FIFO LDR
- **Actor Principal:** Operador de Estación.
- **Flujo Principal:**
  1. Al recibir un nuevo objeto `RobotTelemetry`, `TrackerUiController` despacha los datos al EDT.
  2. `MainTrackerFrame` actualiza el buffer circular de 5 lecturas por sensor.
  3. `CustomBarRenderer` asigna colores y transparencias escalonadas a cada serie histórica.
  4. Se actualizan los indicadores de orientación cardinal, voltaje y estado del motor.

---

### 4.2. Flutter Mobile App

#### CU-MA01: Verificar Versión de App (Version Gate)
- **Actor Principal:** Técnico de Campo.
- **Actor Secundario:** Servidor de Políticas (`UpdatePolicyService`).
- **Relaciones:** `<<extend>>` CU-MA08 (Bloquear Interfaz).
- **Flujo Principal:**
  1. La aplicación se inicia en el dispositivo móvil.
  2. `VersionGate` consulta `requiresUpdate(versionActual)`.
  3. Si la versión es válida, carga directamente `DashboardScreen`.
  4. Si la versión es obsoleta, se desvía a `UpdateRequiredScreen` bloqueante.

#### CU-MA02: Escanear Telemetría NFC en Campo
- **Actor Principal:** Técnico de Campo.
- **Actor Secundario:** Sensor NFC del smartphone, Tag NTAG213.
- **Relaciones:** `<<include>>` CU-MA03 (Leer Slots y Verificar CRC), `<<include>>` CU-MA04 (Visualizar Brújula).
- **Flujo Principal:**
  1. El técnico presiona el botón de escaneo en `DashboardScreen`.
  2. `NfcService` activa `FlutterNfcKit.poll()`.
  3. El técnico aproxima el teléfono al tag del robot.
  4. Se leen las páginas 4 a 11 (Slots A y B).
  5. Se valida el CRC-8 y se emite la telemetría por Stream a la interfaz.
  6. Se reproduce una confirmación háptica/sonora de éxito.

#### CU-MA05: Programar y Transmitir Ángulos de Servos
- **Actor Principal:** Técnico de Campo.
- **Actor Secundario:** Tag NTAG213.
- **Flujo Principal:**
  1. El técnico ajusta los controles de Pitch y Yaw en `ServosCard`.
  2. La app valida que los ángulos estén dentro de los límites de seguridad (Pitch 15..165°, Yaw 10..170°).
  3. El comando queda encolado.
  4. En la siguiente aproximación NFC, la app ejecuta la escritura en el tag antes de cerrar la sesión.

---

## 5. Diagramas y Modelos Generados en el Repositorio

Todos los diagramas han sido generados y sincronizados en los formatos nativos **Astah Professional (`.asta`)** y **Draw.io (`.drawio`)** bajo la ruta:
[`docs/diagrams/`](diagrams/)

### 5.1. Catálogo de Archivos de Diagramas

| Componente | Tipo de Diagrama | Archivo Astah (`.asta`) | Archivo Draw.io (`.drawio`) |
|---|---|---|---|
| **Java Desktop** | Diagrama de Clases UML | [JavaDesktop_ClassDiagram_Ordenado.asta](diagrams/JavaDesktop_ClassDiagram_Ordenado.asta) | [JavaDesktop_ClassDiagram_Ordenado.drawio](diagrams/JavaDesktop_ClassDiagram_Ordenado.drawio) |
| **Java Desktop** | Casos de Uso | [JavaDesktop_UseCases.asta](diagrams/JavaDesktop_UseCases.asta) | [JavaDesktop_UseCases.drawio](diagrams/JavaDesktop_UseCases.drawio) |
| **Java Desktop** | Diagrama de Procesos / Actividades | [JavaDesktop_ProcessDiagram.asta](diagrams/JavaDesktop_ProcessDiagram.asta) | [JavaDesktop_ProcessDiagram.drawio](diagrams/JavaDesktop_ProcessDiagram.drawio) |
| **Flutter Mobile** | Diagrama de Clases UML | [MobileApp_ClassDiagram_Ordenado.asta](diagrams/MobileApp_ClassDiagram_Ordenado.asta) | [MobileApp_ClassDiagram_Ordenado.drawio](diagrams/MobileApp_ClassDiagram_Ordenado.drawio) |
| **Flutter Mobile** | Casos de Uso | [MobileApp_UseCases.asta](diagrams/MobileApp_UseCases.asta) | [MobileApp_UseCases.drawio](diagrams/MobileApp_UseCases.drawio) |
| **Flutter Mobile** | Diagrama de Procesos / Actividades | [MobileApp_ProcessDiagram.asta](diagrams/MobileApp_ProcessDiagram.asta) | [MobileApp_ProcessDiagram.drawio](diagrams/MobileApp_ProcessDiagram.drawio) |
| **MASTER UNIFICADO** | **Todas las Clases, Casos de Uso y Procesos Integrados** | [Heliostrand_Modelos_Completos.asta](diagrams/Heliostrand_Modelos_Completos.asta) | [Heliostrand_Diagramas_Completos.drawio](diagrams/Heliostrand_Diagramas_Completos.drawio) |

---

## 6. Matriz de Trazabilidad Cruzada

Esta matriz garantiza la correspondencia biunívoca entre los requerimientos del usuario, las reglas de negocio de ingeniería, los casos de uso modelados y las clases que componen el código fuente.

| Requerimiento | Regla de Negocio | Caso de Uso | Clases del Código Fuente | Cobertura en Diagramas |
|---|---|---|---|---|
| **RF-JD01** | RN-15 | CU-JD01 | `AbstractNfcService`, `NfcServiceManager`, `MainTrackerFrame` | Clases, Casos de Uso, Procesos |
| **RF-JD02** | RN-12, RN-15 | CU-JD02 | `NfcServiceManager`, `NfcEventListener`, `TrackerUiController` | Clases, Casos de Uso, Procesos |
| **RF-JD03** | RN-01, RN-02, RN-07 | CU-JD03 | `TheoJansenDataParser`, `CorruptedPayloadException`, `RobotTelemetry` | Clases, Casos de Uso, Procesos |
| **RF-JD04** | RN-13 | CU-JD04 | `MainTrackerFrame`, `CustomBarRenderer`, `RobotTelemetry` | Clases, Casos de Uso, Procesos |
| **RF-JD05** | RN-04 | CU-JD04 | `LightDirection`, `RobotTelemetry`, `MainTrackerFrame` | Clases, Casos de Uso |
| **RF-JD06** | RN-06 | CU-JD04 | `RobotTelemetry`, `MainTrackerFrame` | Clases, Casos de Uso |
| **RF-JD07** | — | CU-JD05 | `MainTrackerFrame` (simTimer, toggleSimulation) | Clases, Casos de Uso |
| **RF-JD08** | — | CU-JD06 | `MainTrackerFrame`, FlatLaf LookAndFeel | Clases, Casos de Uso |
| **RF-MA01** | RN-11 | CU-MA01 | `VersionGate`, `UpdatePolicyService`, `HeliostrandApp` | Clases, Casos de Uso, Procesos |
| **RF-MA02** | RN-07, RN-14 | CU-MA02 | `BaseTelemetryService`, `NfcService`, `FlutterNfcKit` | Clases, Casos de Uso, Procesos |
| **RF-MA03** | RN-01, RN-07 | CU-MA03 | `TheoJansenDataParser`, `NfcService` | Clases, Casos de Uso, Procesos |
| **RF-MA04** | RN-04, RN-06 | CU-MA04 | `DashboardScreen`, `LdrChartCard`, `ServosCard`, `MotorBatteryCard` | Clases, Casos de Uso, Procesos |
| **RF-MA05** | RN-05, RN-14 | CU-MA05 | `ServosCard`, `NfcService` | Clases, Casos de Uso, Procesos |
| **RF-MA06** | — | CU-MA06 | `ReportService`, `HistoryCard`, `RobotTelemetry` | Clases, Casos de Uso |
| **RF-MA07** | — | CU-MA07 | `SimulationService`, `BaseTelemetryService`, `DashboardScreen` | Clases, Casos de Uso, Procesos |
| **RF-MA08** | RN-11 | CU-MA08 | `VersionGate`, `UpdateRequiredScreen` | Clases, Casos de Uso, Procesos |


---

## 7. Seguimiento de correspondencia entre requisitos, implementación y UML (2026-10-21)

Esta sección no cambia los requisitos aprobados; registra diferencias entre **lo solicitado** y **lo implementado**:

- **RF-JD01 / CU-JD01 — pendiente parcial:** el requisito exige selección manual de lectores PC/SC; el código `MainTrackerFrame` llama actualmente `NfcServiceManager.initializeReader(null)` para elegir un lector disponible sin selector desplegable. El diagrama operativo vigente refleja esa implementación. Mantener RF-JD01 abierto hasta implementar y probar selección o aprobar formalmente un cambio del requisito.
- **Flutter — implementación verificada en código:** polling `Duration(seconds: 10)` y emisión de simulación con período de 1500 ms. Son valores de implementación, no garantías de latencia RF ni de FPS.
- **UML:** tres composiciones Flutter sustentadas por propiedad y `dispose()`; dos realizaciones hacia el contrato `BaseTelemetryService`; sin agregaciones inferidas arbitrariamente. Conservar relaciones de asociación Java para objetos potencialmente inyectados.
- **Fuentes editables:** `Heliostrand_Modelos_Completos.asta` y `Heliostrand_Diagramas_Completos.drawio` (seis diagramas cada uno). Validación de rutas: `python3 tools/validate_uml_diagrams.py`.

- **CU-MA05 — límites de servos pendientes de alineación:** el caso de uso prescribe Pitch 15–165° y Yaw 10–170°, pero `NfcService` admite comandos entre 0 y 180°. Esos límites mecánicos específicos no están implementados en el servicio; no asumir esa protección hasta alinear firmware, interfaz y validación con pruebas de hardware.
