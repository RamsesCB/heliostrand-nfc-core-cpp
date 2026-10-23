# Auditoría UML de Heliostrand — 22 de octubre de 2026

**Estado: entrega parcial verificada. Astah pendiente; no aceptar como auditoría completa.**

Rama local: `feature/desktop-ui-modernization`. Base: `3d86697`. No se ejecutó push, merge ni rebase. No se modificó código Java/Dart de la aplicación.

## Inventario y resultados

Se inspeccionaron los seis diagramas de cada maestro: **12 vistas, 189 relaciones representadas** (96 Draw.io y 93 Astah; no son 189 relaciones únicas). Las diferencias de alcance entre formatos ya existían y no se ocultaron eliminando relaciones.

| Diagrama | Draw.io | Astah |
|---|---:|---:|
| Clases Java | 15 | 15 |
| Clases Flutter | 20 | 25 |
| Casos de uso Java | 10 | 9 |
| Casos de uso Flutter | 11 | 11 |
| Procesos Java | 18 | 15 |
| Procesos Flutter | 22 | 18 |

La misma versión del verificador se aplicó a los originales y a la entrega. Los conteos representan incidencias geométricas, no necesariamente relaciones distintas. Las dimensiones de etiquetas se estiman; las cajas de casos de uso Astah son envolventes rectangulares conservadoras.

| Tipo | Draw.io antes | Draw.io después | Astah original | Astah entregado |
|---|---:|---:|---:|---:|
| `diagonal` | 26 | 0 | 35 | 35 |
| `label_label` | 2 | 0 | 0 | 0 |
| `label_line` | 19 | 0 | 0 | 0 |
| `label_node` | 16 | 0 | 0 | 0 |
| `line_crossing` | 53 | 0 | 23 | 23 |
| `line_node` | 19 | 0 | 0 | 0 |
| `line_overlap` | 23 | 0 | 12 | 12 |
| `node_overlap` | 0 | 0 | 2 | 2 |
| **Total** | **158** | **0** | **72** | **72** |

No quedan cruces detectados en Draw.io; no se ha declarado ningún cruce inevitable. Los 23 cruces Astah originales siguen pendientes, sin clasificarlos como inevitables. Las copias experimentales Astah llegaron a cero incidencias geométricas, pero fueron rechazadas por diferencias semánticas y no sustituyen al maestro.

## Correcciones entregadas

- Canales ortogonales separados y anclajes distribuidos, con etiquetas apartadas de otras conexiones y figuras.
- Coordenadas de conectores normalizadas al lienzo: las rutas dentro de límites de sistema o carriles tenían puntos interpretados respecto al contenedor. El verificador ahora aplica esa transformación y tiene una prueba de regresión.
- Cajas de clases con encabezados y separadores visibles, contenido dentro de sus límites y altura ajustada. Se corrigieron etiquetas HTML mostradas literalmente, preservando tipos genéricos como `List<int>`.
- Reubicación de `NfcDeviceException` cerca de su servicio y de actividades del flujo Java para evitar desvíos y cruces.
- Las seis vistas individuales canónicas Draw.io se extraen del maestro; los archivos históricos permanecen intactos.

## Integridad UML

Se compararon las 96 identidades de relación Draw.io, sus extremos, etiquetas y marcadores (`startArrow`, `endArrow`, rellenos y línea discontinua): no cambiaron. Los tres rombos de composición Flutter y las dos realizaciones se conservan. El código confirma `NfcService` y `SimulationService implements BaseTelemetryService`, la creación y disposición de ambos servicios por `_DashboardScreenState` y el parser propio de `NfcService`. Java confirma `NfcServiceManager extends AbstractNfcService` y `TrackerUiController implements NfcEventListener`.

El exportador Astah de solo lectura registra IDs de modelo y presentación, extremos de asociaciones y composición/agregación, supertipo/subtipo, cliente/proveedor y direcciones `include`/`extend`. Los archivos `.semantics` permiten comparar antes y después sin depender de la orientación del dibujo.

## Bloqueo Astah reproducido

Guardar una copia sin editar rutas preserva el inventario semántico. Aplicar rutas con la API instalada cambia siete relaciones `include`/`extend` aunque sus IDs y extremos de presentación sigan iguales. Se reprodujo también con `setPoints`; invertir el orden de puntos fue rechazado por la API. No se modificó directamente el modelo para compensarlo. Los originales permanecen byte a byte intactos.

Relaciones afectadas: `13f-e85f1fcbf713795ddf2de3303465c6e1`, `13t-e85f1fcbf713795ddf2de3303465c6e1`, `h60-20b9e3bff60ab7b3917f23f067051763`, `h6b-20b9e3bff60ab7b3917f23f067051763`, `iov-20b9e3bff60ab7b3917f23f067051763`, `ip6-20b9e3bff60ab7b3917f23f067051763`, `ut-e85f1fcbf713795ddf2de3303465c6e1`.

Hace falta resolver esa edición en una sesión de Astah con acceso gráfico y volver a comparar los extremos. La API `exportImage` de esta instalación requiere contexto de plugin; el acceso a aplicaciones nativas no está habilitado en esta sesión. **No se afirma que Astah haya superado inspección visual.**

## Validación y límites

- 15 pruebas unitarias del verificador: cruces, solapes, extremos compartidos, diagonales, anclajes, etiquetas, coordenadas relativas, estereotipos y entrada vacía.
- Draw.io: seis páginas y 96 relaciones, cero incidencias automáticas. Archivos XML válidos; individuales sincronizados con el maestro.
- Se abrieron gráficamente las seis vistas Draw.io. Esa revisión detectó y motivó las correcciones de texto y coordenadas. La revisión final detallada a todos los niveles de zoom sigue siendo necesaria; las cajas estimadas de etiquetas no son una medición tipográfica exacta.
- Astah: originales y copias se abren mediante API y pasan `validateProject`; eso no garantiza semántica inalterada ni apariencia. Se rechazaron las copias que fallaron la comparación.
- No se ejecutaron nuevas pruebas de hardware ni de la aplicación: esta entrega cambia diagramas, herramientas de auditoría y documentación.

## Reproducción

```bash
python3 tools/validate_uml_diagrams.py --json /tmp/uml-drawio.json
python3 -m unittest discover -s tools -p 'test_validate_uml_diagrams.py'
```

El resultado sin incidencias se llama `GEOMETRY_CLEAR_VISUAL_REVIEW_REQUIRED`. Cualquier incidencia produce salida distinta de cero; un archivo vacío no puede pasar. El maestro exige seis páginas y los conteos 15/20/10/11/18/22. `--expected-diagrams` sirve para otras exportaciones. Los TSV Astah se validan pasando su ruta como argumento.

## Archivos y respaldo

Repositorio: `/home/ramsescb/Projects/arduino_app_Fundamentos/`.

Cambios: `docs/diagrams/Heliostrand_Diagramas_Completos.drawio`, sus seis individuales canónicos, `tools/validate_uml_diagrams.py`, `tools/test_validate_uml_diagrams.py`, `tools/ExportAstahGraph.java`, `README.md`, `CONSTITUTION.md`, `RULES.md`, `CONTRIBUTING.md`, `DOCUMENTS.md`, `docs/diagrams/README.md` y los informes de auditoría.

Respaldo previo: `/home/ramsescb/Documents/Codex/2026-10-21/v/work/uml-audit/before/`.
Evidencia y entrega: `/home/ramsescb/Documents/Codex/2026-10-21/v/outputs/uml-audit-20261022/`.

Los `.asta` y las variantes no rastreadas del usuario no se sobrescriben. No se incluyen candidatos Astah rechazados en la entrega aceptada.
