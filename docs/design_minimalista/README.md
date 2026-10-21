
# Theo Jansen Solar Tracker - Interfaz Minimalista

## QUE CONTIENE ESTE ZIP
- lib/main.dart -> Interfaz completa con comentarios TODO CAMBIAR
- pubspec.yaml -> Dependencias minimas
- PROMPT_MAESTRO.txt -> Prompt para IA
- GUIA_CAMBIOS.md -> Donde tocar que cosa

## COMO USAR
1. flutter create theo_tracker
2. Reemplaza lib/main.dart y pubspec.yaml con estos
3. flutter pub get
4. flutter run

## DONDE ESTAN LOS TODO CAMBIAR EN EL CODIGO
Busca en main.dart "TODO CAMBIAR" (Ctrl+F)
- Linea ~15: Color fondo
- Linea ~27: Nombres sensores
- Linea ~42: Valores iniciales pitch/yaw, NFC
- Linea ~55: Conectar sensores reales (borrar Timer de simulacion)
- Linea ~75: Umbral equilibrado
- Linea ~88: Logica real NFC con nfc_manager
- Header, LDR Card, Servos, Metrics, CTA -> todo marcado
