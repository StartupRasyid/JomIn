
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('JomIn welcome screen displays',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: JomInApp(),
      ),
    );

    expect(find.text('Welcome to JomIn!'), findsOneWidget);
  });
}
