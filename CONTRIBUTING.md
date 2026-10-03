# Guía de Contribución (CONTRIBUTING.md)

¡Gracias por tu interés en contribuir a **Heliostrand NFC Core**!

Para mantener la calidad, determinismo y arquitectura de este proyecto, todas las contribuciones se rigen por dos documentos fundamentales:

1. 🏛️ [**CONSTITUTION.md**](CONSTITUTION.md): Marco ético, gobernanza del proyecto, invariantes de arquitectura y derechos de autoría.
2. 📋 [**RULES.md**](RULES.md): Reglas técnicas de codificación (C++, Java, Dart), convenciones de commits convencionales, invariantes del protocolo CRC-8 y checklist de validación previa al Pull Request.

---

### Pasos rápidos para enviar un aporte:
1. Haz un **Fork** del repositorio.
2. Crea una rama descriptiva (`feature/nueva-mejora` o `fix/correccion-telemetria`).
3. Sigue las reglas de nombrado y pruebas descritas en [RULES.md](RULES.md).
4. Verifica que `pio run`, `mvn test` y `flutter test` pasen exitosamente.
5. Abre un **Pull Request** explicando el cambio y su impacto arquitectónico.
