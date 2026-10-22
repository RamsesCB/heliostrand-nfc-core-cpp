# Modelos UML editables de Heliostrand

**Última revisión local:** 21 de octubre de 2026.
**Rama de trabajo:** `feature/desktop-ui-modernization`.
**Alcance:** Java Desktop (Swing, PC/SC) y Flutter Mobile (NTAG213), con clases, casos de uso y actividades/procesos.

## Modelos maestros

- **Astah Professional (nativo, no un sitio web):** [`Heliostrand_Modelos_Completos.asta`](Heliostrand_Modelos_Completos.asta).
- **Draw.io (diagrams.net o extensión de VS Code):** [`Heliostrand_Diagramas_Completos.drawio`](Heliostrand_Diagramas_Completos.drawio).

Los dos archivos maestros son las fuentes recomendadas. **Cada uno contiene exactamente seis diagramas**. Los archivos individuales permiten abrir solo una sección:

| Sección | Astah Professional | Draw.io |
|---|---|---|
| Java — clases | `JavaDesktop_ClassDiagram_Ordenado.asta` | `JavaDesktop_ClassDiagram_Ordenado.drawio` |
| Flutter — clases | `MobileApp_ClassDiagram_Ordenado.asta` | `MobileApp_ClassDiagram_Ordenado.drawio` |
| Java — casos de uso | `JavaDesktop_UseCases.asta` | `JavaDesktop_UseCases.drawio` |
| Flutter — casos de uso | `MobileApp_UseCases.asta` | `MobileApp_UseCases.drawio` |
| Java — procesos | `JavaDesktop_ProcessDiagram.asta` | `JavaDesktop_ProcessDiagram.drawio` |
| Flutter — procesos | `MobileApp_ProcessDiagram.asta` | `MobileApp_ProcessDiagram.drawio` |

## Convenciones UML comprobadas

- **Realización («implements»):** `NfcService` y `SimulationService` implementan el contrato `BaseTelemetryService`. El símbolo UML apunta al contrato; en Dart es una `abstract class` utilizada como interfaz.
- **Composición (rombo negro en el propietario):** `_DashboardScreenState`→`NfcService`; `_DashboardScreenState`→`SimulationService`; `NfcService`→`TheoJansenDataParser`. Se sustentan en construcción y administración del ciclo de vida.
- **Asociación:** `MainTrackerFrame` con servicios/controladores inyectados, historial de `RobotTelemetry` y el parser Java que puede aportarse externamente.
- **Dependencia:** relaciones de uso, decodificación o notificación. **Generalización:** herencia Java y excepciones. **Realización:** interfaz Java `NfcEventListener` y contrato Flutter.
- **Casos de uso:** «include» apunta al caso incluido; «extend» parte del caso opcional y apunta al extendido. El lector NFC y el servidor de políticas son actores secundarios físicos/externos, no clases internas.
- No representar **agregación** ni composición solo por conveniencia gráfica. No sustituir un constructor que admite inyección por una composición estricta.

Para los enlaces de casos de uso de Astah se ocultó el **nombre genérico redundante** `include` / `extend`, mostrando el estereotipo UML una sola vez. Si se observa una flecha visualmente invertida en una versión antigua de Astah, verificar la semántica con el modelo UML en lugar de invertir a ciegas sus extremos.

## Legibilidad y rutas

- Todas las conexiones Draw.io del maestro tienen anclajes explícitos a los bordes de las figuras, tramos ortogonales y puntos intermedios editables.
- La revisión geométrica ejecutada el 21 de octubre de 2026 cubre **96 conexiones** en las seis pestañas sin segmentos diagonales ni trayectos que entren en una figura que no sea origen o destino.
- Astah contiene **93 enlaces** en seis diagramas; se ajustaron **44 trayectorias** respecto al maestro previo y se verificó que ningún segmento cruce una figura no relacionada.
- La geometría de la flecha, sus etiquetas, el ancho del zoom y la colocación de leyendas se revisan también visualmente en el editor. El control automático no certifica ausencia absoluta de cruces entre **líneas** o etiquetas, ni calidad estética a todos los niveles de zoom.

### Prueba de rutas Draw.io (sin dependencias externas)

Desde la raíz del repositorio:

```bash
python3 tools/validate_uml_diagrams.py
```

El comando debe mostrar las seis páginas y terminar con `PASS — 96 orthogonal links`. Si actualizas el número de relaciones intencionalmente, ajusta las expectativas del script y revisa las relaciones nuevas.

### Abrir el proyecto

1. **Astah**: abre `Heliostrand_Modelos_Completos.asta` en **Astah Professional** y selecciona cualquiera de sus seis diagramas en la estructura. Un navegador no puede renderizar directamente el formato binario `.asta`.
2. **Draw.io**: abre `Heliostrand_Diagramas_Completos.drawio` con la extensión *Draw.io Integration* de VS Code o entra en <https://app.diagrams.net/> y selecciona *Open Existing Diagram* para importar el archivo local. No cambies nombres de relaciones ni direcciones sin revisar su semántica UML.
3. Si cambias clases/casos/procesos, sincroniza el maestro y el correspondiente archivo individual en **ambos** formatos; conserva sus seis páginas y el mismo contenido lógico.

## Revisión del código y límites

- Código Java: `AplicacionJava/src/main/java/`. `MainTrackerFrame` utiliza `initializeReader(null)` para elegir un lector PC/SC disponible. **RF-JD01** aún solicita selección manual, no implementada en la UI revisada; no declarar el requisito plenamente cumplido.
- Código Flutter: `heliostrand_app/lib/`. Polling NFC: 10 segundos de timeout; simulación: intervalo predeterminado de 1500 milisegundos.
- Contrato binario normativo: [`docs/protocol/telemetry-v2.md`](../protocol/telemetry-v2.md) y vectores compartidos.
- Documento de requisitos y trazabilidad: [`docs/REGLAS_DE_NEGOCIO_Y_REQUERIMIENTOS.md`](../REGLAS_DE_NEGOCIO_Y_REQUERIMIENTOS.md).
- Informe de auditoría: [`AUDITORIA_HELIOSTRAND_MODELOS_20261021.md`](AUDITORIA_HELIOSTRAND_MODELOS_20261021.md).

## Validación de software realizada (2026-10-21)

- **Java/Maven:** 9 pruebas, 0 fallos, `BUILD SUCCESS`.
- **Flutter SDK 3.47.2 / Dart 3.13.2:** `flutter analyze` sin observaciones, `flutter test` con 18 pruebas satisfactorias.
- La ruta `~/Tools/flutter` conserva Flutter 3.41.4 / Dart 3.11.1, que **no cumple** el `pubspec.yaml`; usar `~/flutter/bin/flutter` en el equipo revisado.
- No se realizó una prueba física del tag PN532/NTAG213 o hardware durante esta tarea de modelado. No se ejecutó un merge, push, ni lanzamiento de software a producción.

## Respaldo y política Git

El trabajo se efectúa exclusivamente en `feature/desktop-ui-modernization`, sin merge a `main`. Cada reemplazo conserva un respaldo anterior. No incorporar los respaldos a commits ordinarios, salvo que se acuerde conservarlos versionados.
