import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medikiosk_ai/src/app/app.dart';
import 'package:medikiosk_ai/src/app/di.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await setupDependencyInjection();
  });

  testWidgets('AyuDwarApp renders LanguageSelectionScreen initially', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AyuDwarApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('AyuDwar'), findsWidgets);
    expect(find.text('Select Your Language'), findsOneWidget);
    expect(find.text('English'), findsWidgets);
    expect(find.text('हिंदी'), findsOneWidget);
    expect(find.text('தமிழ்'), findsOneWidget);
    expect(find.text('తెలుగు'), findsOneWidget);
    expect(find.text('বাংলা'), findsOneWidget);
  });
}
