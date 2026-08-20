import 'package:flutter_test/flutter_test.dart';
import 'package:istakipmobil/main.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const IsTakipApp());

    // Verify that login screen or app header rendered.
    expect(find.text('İş Takip Sistemi'), findsOneWidget);
  });
}
