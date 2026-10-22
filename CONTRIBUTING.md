# Contribuir a Heliostrand

Antes de empezar, consulta [README](README.md), [CONSTITUTION](CONSTITUTION.md) y [RULES](RULES.md).

## Preparar el cambio

1. Parte de una rama actualizada y crea `fix/<tema>` o `feature/<tema>`.
2. Describe el problema y los componentes afectados: firmware, Java, Flutter o contrato compartido.
3. Conserva interfaz visual, calibración, firma Android y compatibilidad del protocolo salvo cambio explícitamente aprobado.
4. Revisa consumidores antes de retirar código. Usa nombres claros y documentación Markdown, sin comentarios narrativos dentro del código propio.

## Verificar

Ejecuta los comandos de [validación](README.md#desarrollo-y-validación). Una corrección de lógica debe incluir una prueba que reproduzca el fallo. Los cambios NFC requieren comprobar errores, cancelación, reintentos, integridad y slots alternos.

Para cambios visuales, compara capturas con el mismo tamaño, fuentes y datos. Para tamaño, mide el mismo tipo de artefacto y ABI antes/después; conserva los recursos que se muestran al usuario.

Antes de añadir archivos, revisa `git status --short`, `git diff --check` y `.gitignore`. No publiques `.env`, `key.properties`, keystores ni valores de secretos en logs, capturas o reportes.

## Abrir el pull request

Incluye problema y comportamiento resultante, pruebas ejecutadas con resultados, impacto en protocolo/tamaño y límites de validación. Indica claramente si faltan pruebas con dispositivo físico o en otra plataforma. Los commits siguen Conventional Commits.

Los cambios se revisan y pasan CI antes de integrarse. No muevas tags publicados ni cambies el certificado Android. Una versión del fuente no equivale a una release publicada.

## Documentación y seguridad

Actualiza los documentos dentro del alcance del cambio, incluido `DOCUMENTS.md`, `CONSTITUTION.md`, `RULES.md` y los modelos de `docs/diagrams/` cuando sean relevantes. Para diagramas comprueba las seis pestañas del Draw.io maestro y el proyecto Astah, ejecuta `python3 tools/validate_uml_diagrams.py`, conserva copia de seguridad y verifica la correspondencia entre relación UML y código antes de guardar.

Si descubres una credencial privada expuesta, informa sin reproducir su valor. Primero se revoca o rota; después se coordina el saneamiento de Git. La historia técnica y la atribución se preservan salvo el contenido sensible que deba retirarse.
