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
- La documentación se actualiza dentro del alcance autorizado. En esta revisión, `DOCUMENTS.md` y `docs/` permanecen intactos; el README documenta la arquitectura actual.
