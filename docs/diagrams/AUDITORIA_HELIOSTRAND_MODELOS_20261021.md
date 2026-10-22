# Informe de auditoría UML y coherencia de código — Heliostrand

**Fecha:** 21 de octubre de 2026 (hora de Perú)
**Rama local:** `feature/desktop-ui-modernization`
**Raíz del proyecto:** `/home/ramsescb/Projects/arduino_app_Fundamentos/`
**Objetivo:** eliminar las superposiciones de flechas sobre las figuras en los seis modelos UML, alinear ambos formatos y revisar el código y sus documentos de referencia.

## Cambios efectuados

### Astah Professional — seis diagramas

Modelo maestro: `docs/diagrams/Heliostrand_Modelos_Completos.asta`.

- 44 trayectorias de enlace corregidas en la copia de trabajo, respetando los modelos y los enlaces existentes.
- Se ajustaron los retornos en procesos PC/SC, el caso de trama corrupta, la rama `Solo Lectura` y los enlaces entre actores y casos de uso que atravesaban cuadros.
- Revisión geométrica posterior sobre 93 enlaces: **0 intersecciones con cuadros no participantes**. Las asociaciones de propiedades y el resto de relaciones UML permanecen editables.
- Persisten las seis secciones y se conservan las **3 composiciones** propietarias de Flutter y **2 realizaciones** hacia `BaseTelemetryService` sin reemplazarlas por herencia errónea.
- No se añadieron composiciones/agregaciones que no se desprenden del código.
- Las copias Astah individuales se sincronizan con los recorridos del maestro.

### Draw.io — seis pestañas

Modelo maestro: `docs/diagrams/Heliostrand_Diagramas_Completos.drawio`.

- Se calcularon nuevas rutas con anclajes explícitos sobre los límites de las figuras, tramos horizontales y verticales y puntos de desvío para cada enlace.
- **96 conexiones corregidas**: 15 clases Java, 20 clases Flutter, 10 casos de uso Java, 11 casos de uso Flutter, 18 flujos Java y 22 flujos Flutter.
- Validación geométrica: **0 líneas diagonales, 0 cruces sobre figuras no relacionadas** y referencias de origen/destino válidas.
- Cada pestaña del maestro se sincronizó con el correspondiente Draw.io independiente sin modificar la semántica ni suprimir clases o actores.
- Ejecución reproducible: `python3 tools/validate_uml_diagrams.py` (sin dependencias de terceros).
- El control no implica que dos líneas no se crucen nunca entre ellas o que todas las etiquetas sean perfectas a cualquier zoom; la inspección visual en ambos editores es complementaria.

## Concordancia UML ↔ código

| Elementos | Semántica justificada |
|---|---|
| `_DashboardScreenState` ◆— `NfcService` | Composición: el estado posee y libera el servicio |
| `_DashboardScreenState` ◆— `SimulationService` | Composición: el estado posee y detiene el servicio |
| `NfcService` ◆— `TheoJansenDataParser` (Flutter) | Composición: parser interno creado por NFC |
| `NfcService` + `SimulationService` ···▷ `BaseTelemetryService` | Realización: contrato de interfaz `implements` de Dart |
| `MainTrackerFrame` → manager, controller, `RobotTelemetry` | Asociaciones ordinarias (inyección y registros) |
| `AbstractNfcService` → `TheoJansenDataParser` (Java) | Asociación simple: admite parser externo |

Las orientaciones de «include» / «extend», las flechas de herencia de excepciones y las dependencias fueron conservadas. Las relaciones de asociación no se confundieron con composición ni se dibujaron rombos en su extremo incorrecto.

## Código verificado

Se contrastaron las clases Java y Flutter con las relaciones del modelo, en particular `MainTrackerFrame`, `NfcServiceManager`, `AbstractNfcService`, `DashboardScreen`, `NfcService`, `SimulationService` y `BaseTelemetryService`.

- Java 21 / Maven 3.9.9: **9 tests superados, 0 fallos**.
- Flutter 3.47.2 / Dart 3.13.2, ruta `/home/ramsescb/flutter/bin/flutter`: **`flutter analyze` limpio y 18 tests aprobados**.
- Flutter ubicado en `/home/ramsescb/Tools/flutter` es 3.41.4 / Dart 3.11.1, incompatible con el requisito `^3.13.2` del proyecto; se utilizó el SDK ya instalado que sí es compatible.
- No se realizaron cambios de lógica de Java, Dart, firmware ni protocolo V2 en esta tarea. No se probó hardware NFC físico.

### Brecha de requerimientos

**RF-JD01** pide selección manual del lector PC/SC. El código ejecuta `initializeReader(null)` y selecciona un lector automáticamente. La documentación UML y de procesos refleja el comportamiento **implementado**, mientras el requisito queda identificado como **pendiente parcial**, no resuelto por la edición de los diagramas.

## Actualización documental

Revisados: `README.md`, `CONSTITUTION.md`, `RULES.md`, `CONTRIBUTING.md`, `DOCUMENTS.md`, `heliostrand_app/README.md`, `docs/REGLAS_DE_NEGOCIO_Y_REQUERIMIENTOS.md`, `docs/diagrams/README.md` y este informe.

## Copias, verificación y Git

Los 14 originales se respaldaron en `docs/diagrams/backup_antes_ajuste_flechas_20261021_212351/` antes del reemplazo. Los formatos editables son `.asta` (Astah Professional) y `.drawio` (diagrams.net / extensión VS Code). Un navegador no puede mostrar `.asta` nativamente.

Los cambios se limitan a la **rama local** `feature/desktop-ui-modernization`; no se realizó merge a `main`, ni push ni publicación de versiones.
