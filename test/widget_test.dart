import 'package:flutter_test/flutter_test.dart';
import 'package:snaptune/main.dart';

void main() {
  testWidgets('SnapTune app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SnapTuneApp());
    expect(find.byType(SnapTuneApp), findsOneWidget);
  });
}
