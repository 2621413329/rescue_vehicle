import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rescue_mobile/main.dart';

void main() {
  testWidgets('App smoke test', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RescueApp()));
    expect(find.text('救备通'), findsOneWidget);
  });
}
