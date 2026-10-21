
# GUIA DE CAMBIOS RAPIDOS

Busca "TODO CAMBIAR" en main.dart:

1. FONDO Y COLORES:
   - scaffoldBackgroundColor -> cambia #F8F9FA por el que quieras
   - En _buildLdrCard, _buildServosCard cambia Colors.white si quieres dark

2. SENSORES LDR:
   - Lista ldrs inicial: si tienes 2 sensores en vez de 4, deja 2
   - En _buildLdrCard el Row con .map -> cambia color barra, altura
   - Borra driftTimer en initState cuando conectes sensores reales via Serial/Bluetooth

3. SERVOS:
   - pitch y yaw iniciales: double pitch = 90;
   - Slider min/max: si tu servo es 0-90 cambia max: 90
   - _servoItem accent: cambia Color(0xFFE9A000) por tu color de marca

4. NFC REAL:
   - En pubspec.yaml agrega nfc_manager: ^3.3.0
   - En handleScan() reemplaza Future.delayed por NfcManager.instance.startSession(...)
   - Ejemplo:
     NfcManager.instance.startSession(onDiscovered: (tag) async {
       // tu lectura
       setState(() { pitch = ...; yaw = ...; })
       NfcManager.instance.stopSession();
     });

5. POTENCIA:
   - En _buildMetricsGrid segundo Expanded, cambia Text("N/D") por Text("${voltaje}V")

6. HISTORIAL:
   - Si no lo necesitas, borra _buildHistoryCard() y su llamada en build

7. HEADER:
   - Cambia "Theo Jansen" por tu nombre, icono Icons.wb_sunny por otro

8. ANCHO:
   - ConstrainedBox maxWidth 390 -> pon 420 si tu movil es mas grande

TODOS LOS COMENTARIOS TODO CAMBIAR ESTAN EN EL CODIGO.
