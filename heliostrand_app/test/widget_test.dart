import 'package:flutter_test/flutter_test.dart';
import 'package:heliostrand_app/main.dart';

void main() {
  testWidgets('Carga el dashboard de Theo Jansen Solar Tracker', (WidgetTester tester) async {
    await tester.pumpWidget(const HeliostrandApp());

    // Verificar que el título de la app se renderiza
    expect(find.text('Theo Jansen Solar Tracker'), findsOneWidget);
    // Verificar que los paneles principales están presentes
    expect(find.text('Sensores LDR (Luz)'), findsOneWidget);
    expect(find.text('Servomotores (Seguimiento)'), findsOneWidget);
  });
}
