import 'package:flutter_test/flutter_test.dart';
import 'package:pashu_wani/main.dart';

void main() {
  testWidgets('PashuWaniApp smoke test builds splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PashuWaniApp());
    expect(find.byType(PashuWaniApp), findsOneWidget);
  });
}
