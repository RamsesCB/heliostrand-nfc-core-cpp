# Reglas técnicas

## Alcance y estilo

Preservar el tema, distribución visual, protocolo V2 y funciones existentes. Eliminar código y dependencias solo con evidencia de ausencia de consumidores. No introducir capas genéricas o librerías para resolver unas pocas líneas.

Código propio sin comentarios narrativos; contratos y explicación en Markdown y tests. Preservar shebangs, preprocesador, directivas necesarias y licencias. No editar paquetes descargados ni cachés. No regenerar formularios NetBeans sin revisar el diff, pues el generador puede reintroducir marcadores y sobrescribir lógica.

## Firmware

- Mantener compatibilidad con la configuración AVR-GCC/Arduino de `platformio.ini`; las pruebas de host usan C++17. No declarar un estándar de producción distinto del realmente configurado.
- Usar buffers fijos; ningún `new`, `malloc` ni `String` dinámico en `loop()`.
- Mantener el mapa de pines y límites de servos. UART permanece exclusivamente binario.
- Consultar comandos independientemente del límite de escrituras EEPROM. Un fallo de ACK no consume el comando como exitoso.
- Invalidar el commit destino antes de escribir payload, verificar lecturas y escribir commit al final.

## Java

- Java 21 y wrapper Maven con versión y hash fijados.
- `com.theojansen.nfc.model`: dominio; `.parser`: contrato binario; `.core`: lector PC/SC. `com.ramsescb.heliostrand.desktop`: presentación y controladores Swing.
- Lectores y archivos fuera del EDT; actualización de widgets dentro del EDT.
- Un lector ausente no inicia un bucle vacío. Fallos repetidos tienen espera de reintento y no acumulan diálogos modales.
- Interrumpir trabajadores al detener el escaneo; una sesión antigua no vuelve a publicar después de reiniciar.

## Flutter

- `snake_case.dart`, clases `PascalCase` y miembros `camelCase`; aplicar `dart format` y `flutter analyze`.
- La implementación actual usa streams, `StatefulWidget` y `setState`; no requiere Provider.
- Cancelar temporizadores/suscripciones en `dispose()`, comprobar `mounted` después de operaciones asíncronas.
- Una sesión NFC activa; validar CC y telemetría antes de escribir comandos. Confirmar ACK y conservar un comando nuevo si llega mientras otro está en curso.
- Detener simulación y NFC al cambiar de fuente. Los reportes usan una copia de la lista, conservan JSON/CSV y notifican fallos mediante la capa UI.
- Historial máximo de 500 muestras; cinco más recientes primero.
- El mínimo remoto es un `versionCode` entero positivo, nunca una cadena `1.2.0`. Respuesta HTTPS limitada a 4096 bytes y con timeout.

## Contratos y pruebas

Todo cambio de formato debe actualizar el serializador C++, parsers Java/Dart y vectores JSON de forma conjunta. Mantener CRC-8 `0x07`, Big-Endian para batería, códigos V2 y límites físicos. El checksum del comando de página 12 es XOR, no suma.

Ejecutar desde la raíz:

```bash
python3 tools/generate_golden_vectors_header.py
pio run -e uno
pio test -e native
pio check -e uno --skip-packages
c++ -std=c++17 -Wall -Wextra -Werror -Itest/nfc_host/stubs -Iinclude test/nfc_host/main.cpp src/NfcTransceiver.cpp src/TheoJansenTelemetry.cpp -o /tmp/nfc-host-tests
/tmp/nfc-host-tests
(cd AplicacionJava && ./mvnw --batch-mode clean test package)
(cd heliostrand_app && flutter analyze && flutter test)
```

Comprobar además el build Android cuando se alteran dependencias, código móvil o empaquetado. Validar manualmente hardware NFC y servos antes de publicar. Declarar plataformas y controles no ejecutados.

## Git, releases y secretos

Usar commits `fix`, `refactor`, `docs`, `test`, `chore` o `feat` con alcance y descripción concretos. Revisar el diff y los archivos ignorados antes de añadir cambios. No usar `git add -f` sobre firmas o `.env`.

Los tags `v*` deben coincidir exactamente con la versión Maven y el nombre de versión Flutter. El build number Android es independiente y creciente. Publicar SHA-256 de los artefactos; mantener el certificado de firma existente.

No confundir un DSN público con una credencial de administración. Si se confirma una clave privada expuesta, revocarla y coordinar la limpieza de todas las referencias afectadas sin prometer borrar copias ajenas.

## Documentación

README describe arquitectura, comandos y versiones verificadas; CONTRIBUTING describe el flujo de aporte; CONSTITUTION define invariantes. Los modelos activos de `docs/diagrams/` y `DOCUMENTS.md` se actualizan al cambiar código, requerimientos o semántica UML. Conservar respaldos de los originales y los diagramas históricos; nunca inventar releases.

Para modificar diagramas: leer el código fuente, documentar propiedades y ciclos de vida, conservar los seis modelos en Astah y Draw.io, aplicar rutas ortogonales que no entren en figuras ajenas, revisar dirección de `include`, `extend`, generalización y realización, y ejecutar `python3 tools/validate_uml_diagrams.py`. Revisar también `docs/diagrams/README.md` y el informe de auditoría. El maestro `.asta` se abre en Astah Professional, no en un navegador; `.drawio` es editable con diagrams.net o la extensión Draw.io de VS Code.


## Auditoría UML local — 22 de octubre de 2026

La revisión geométrica y su estado de aceptación se documentan en [el informe UML](docs/diagrams/AUDITORIA_HELIOSTRAND_MODELOS_20261022.md). Draw.io conserva seis páginas y 96 relaciones; el verificador ampliado distingue cruces, solapes, anclajes y límites de etiquetas. La actualización de Astah queda pendiente: las copias candidatas fallan la comparación semántica de siete relaciones `include`/`extend`, y no se ha podido inspeccionar su editor nativo. No considerar la auditoría completa ni publicar esas copias.

Una corrección de presentación debe preservar las identidades, los extremos UML y los marcadores de composición/herencia/realización. Una comparación semántica fallida impide sustituir el maestro aunque el control geométrico no encuentre colisiones.
