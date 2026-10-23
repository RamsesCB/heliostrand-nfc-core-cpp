# Constitución de Heliostrand NFC Core

Marco técnico y de contribución para firmware Arduino, cliente Java y aplicación Flutter. Esta revisión acompaña al código 1.2.0 y conserva la apariencia, el protocolo V2 y las funciones existentes.

## I. Contratos invariables

- La telemetría tiene exactamente 12 bytes. CRC-8 usa polinomio `0x07` e inicial `0x00`; se calcula sobre bytes 0–10 y se guarda en el byte 11.
- Java y Dart rechazan longitud, CRC, versiones, códigos reservados y rangos inválidos antes de presentar datos.
- Los vectores de `test/vectors/golden_telemetry_vectors.json` son compartidos por C++, Java y Dart.
- NTAG213 reserva páginas 4–7 para slot A, 8–11 para slot B y 12 para comandos de servos. El comando es `[0x53, pitch, yaw, 0x53 ^ pitch ^ yaw]`; admite 0–180 antes de aplicar límites mecánicos.
- UART transmite `AA 55 + payload + CR LF`, sin texto diagnóstico mezclado.

## II. Arquitectura y responsabilidades

- El firmware separa seguimiento solar, serialización y transportes. Consultar comandos no depende de los intervalos de escritura de telemetría.
- Los modelos y parsers no dependen de la presentación. Servicios NFC y simulación entregan datos validados; la UI conserva su diseño y controles.
- Swing solo se modifica en el EDT. Inicializar lectores y escribir archivos se hace fuera de él.
- Flutter cancela suscripciones, temporizadores y sesiones al terminar. Cambiar de fuente detiene la anterior.
- Las operaciones externas fallidas generan mensajes recuperables; no se ocultan errores convirtiéndolos en lecturas válidas.

## III. Hardware y persistencia

- No se introduce memoria dinámica en el `loop()` del ATmega328P ni se cambian pines o calibración para optimizar tamaño.
- Primera escritura NFC inmediata; siguientes con cambio significativo y cinco minutos mínimos, o refresco a los quince minutos. CRC y secuencia no participan en la detección de cambios.
- El slot destino se invalida antes de sobrescribirlo, el payload se verifica y el commit se escribe al final. El otro slot permanece disponible.
- El comando se entrega al controlador después de confirmar su borrado. La lectura se consulta cada ciclo de telemetría de un segundo.
- CRC y filtrado UID protegen frente a errores o selección accidental; no autentican al emisor.

## IV. Calidad y tamaño

- Se elimina código muerto tras revisar referencias, configuración, pruebas y puntos de entrada.
- El código propio se mantiene sin comentarios narrativos; nombres, pruebas y Markdown expresan el contrato. Las directivas de compilador y avisos legales necesarios se preservan.
- No se retiran validaciones, accesibilidad, recursos visuales utilizados ni plataformas por una reducción de tamaño sin evidencia.
- Las métricas comparan artefactos del mismo modo y arquitectura; un APK por ABI no se presenta como reducción equivalente del APK universal.
- Cambios de lógica requieren regresiones concretas. Pruebas simuladas no certifican hardware real.

## V. Seguridad y gobernanza

- `.env`, credenciales de firma y claves privadas permanecen fuera de Git. Los ejemplos solo contienen placeholders.
- Ante una clave privada expuesta: revocar/rotar, identificar referencias afectadas y sanearlas coordinadamente. Borrar un commit no revoca la credencial ni borra copias externas.
- Los contribuyentes conservan atribución y autoría. Los tags publicados son inmutables.
- Las ramas `feature/*` y `fix/*` se integran mediante revisión y CI. No se publica una release solo por cambiar las versiones del fuente.
- La documentación se mantiene sincronizada con el código y con los diagramas UML maestros. Los históricos conservan su condición de históricos; los artefactos de diseño vigentes están en `docs/diagrams/`.


## VI. Constitución de los diagramas UML

- Existen seis diagramas por formato: clases Java, clases Flutter, casos de uso Java, casos de uso Flutter, procesos Java y procesos Flutter.
- Fuentes maestras editables: `docs/diagrams/Heliostrand_Modelos_Completos.asta` y `docs/diagrams/Heliostrand_Diagramas_Completos.drawio`. Las versiones individuales deben mantener sus relaciones y contenido equivalentes.
- Las realizaciones `implements` de `NfcService` y `SimulationService` apuntan a la interfaz contractual `BaseTelemetryService`; en Dart el contrato se declara `abstract class`.
- La composición (rombo negro en el **propietario**) se emplea únicamente en `_DashboardScreenState`→`NfcService`, `_DashboardScreenState`→`SimulationService` y `NfcService`→`TheoJansenDataParser`. No se añaden diamantes vacíos/negros por motivos decorativos.
- La asociación simple refleja el historial de telemetría, controladores inyectados y el parser Java que puede recibirse desde fuera. Las flechas de herencia, realización, dependencias, «include» y «extend» deben conservar su dirección UML correcta.
- Los conectores deben entrar/salir por límites de los objetos y esquivar toda figura no participante. Preferir tramos horizontales/verticales con canales libres y etiquetas que no oculten nodos.
- Toda edición UML significativa requiere revisar código y requisitos, actualizar ambos maestros y sus diagramas individuales, validar `python3 tools/validate_uml_diagrams.py` y dejar constancia del alcance en `docs/diagrams/README.md` y el informe de auditoría.
- Una diferencia entre requisito deseado y función implementada no puede declararse resuelta únicamente cambiando el diagrama: se registra explícitamente como brecha (por ejemplo, RF-JD01 selector manual PC/SC).
- No mezclar ramas ni modificar `main` por una actualización local de documentación y diagramas. Los cambios se revisan en su rama de trabajo.


## Auditoría UML local — 22 de octubre de 2026

La revisión geométrica y su estado de aceptación se documentan en [el informe UML](docs/diagrams/AUDITORIA_HELIOSTRAND_MODELOS_20261022.md). Draw.io conserva seis páginas y 96 relaciones; el verificador ampliado distingue cruces, solapes, anclajes y límites de etiquetas. La actualización de Astah queda pendiente: las copias candidatas fallan la comparación semántica de siete relaciones `include`/`extend`, y no se ha podido inspeccionar su editor nativo. No considerar la auditoría completa ni publicar esas copias.

Una corrección de presentación debe preservar las identidades, los extremos UML y los marcadores de composición/herencia/realización. Una comparación semántica fallida impide sustituir el maestro aunque el control geométrico no encuentre colisiones.
