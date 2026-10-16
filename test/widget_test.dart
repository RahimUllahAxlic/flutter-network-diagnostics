import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_network_diagnostics/main.dart';

void main() {
  testWidgets('FlutterNetworkDiagnosticsApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FlutterNetworkDiagnosticsApp());
    expect(find.text('Network & DNS Observability Suite'), findsOneWidget);
    expect(find.text('Run Diagnostic Suite'), findsOneWidget);
  });
}
