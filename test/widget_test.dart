
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khatabook/main.dart';

void main() {
  testWidgets('KhataBook dashboard test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: KhataBookApp(),
      ),
    );

    expect(find.text('KhataBook'), findsOneWidget);
    expect(find.text('Welcome Back!'), findsOneWidget);
  });
}
