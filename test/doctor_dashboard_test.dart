import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medikiosk_ai/src/app/di.dart';
import 'package:medikiosk_ai/src/database/app_database.dart';
import 'package:medikiosk_ai/src/features/doctor_dashboard/presentation/screens/doctor_dashboard_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.';
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (MethodCall methodCall) async => 1,
    );
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await setupDependencyInjection();
    await AppDatabase.instance.initialize();
  });

  testWidgets('DoctorDashboardScreen builds and renders queue without layout crashes', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DoctorDashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Doctor Portal'), findsOneWidget);
    expect(find.text('Live Triage Queue'), findsOneWidget);
  });
}
