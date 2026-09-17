import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medikiosk_ai/src/app/di.dart';
import 'package:medikiosk_ai/src/database/app_database.dart';
import 'package:medikiosk_ai/src/features/auth/presentation/providers/auth_provider.dart';
import 'package:medikiosk_ai/src/features/clinical_intake/presentation/providers/clinical_intake_provider.dart';
import 'package:medikiosk_ai/src/features/clinical_intake/presentation/screens/clinical_intake_screen.dart';
import 'package:medikiosk_ai/src/voice/services/stt_service.dart';
import 'package:medikiosk_ai/src/voice/services/tts_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugin.csd.speech_to_text'),
      (MethodCall methodCall) async => true,
    );
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await setupDependencyInjection();
    await AppDatabase.instance.initialize();
  });

  testWidgets('ClinicalIntakeScreen builds and renders AYUSH mode across languages', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Set language to Hindi
    await container.read(authProvider.notifier).setLanguage('hi');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ClinicalIntakeScreen(mode: 'ayush'),
        ),
      ),
    );

    await tester.pump();
    container.read(clinicalIntakeProvider.notifier).stopVoiceListening();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('आयुष (दशविध परीक्षा)'), findsOneWidget);
    expect(find.textContaining('प्रकृति'), findsWidgets);

    // Verify option chips are displayed in Hindi
    expect(find.text('वात प्रधान (दुबला, हल्का, सक्रिय)'), findsOneWidget);

    // Select an option
    await tester.tap(find.text('वात प्रधान (दुबला, हल्का, सक्रिय)'));
    await tester.pump();
    container.read(clinicalIntakeProvider.notifier).stopVoiceListening();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify advanced to next question
    expect(find.textContaining('विकृति'), findsWidgets);

    container.read(clinicalIntakeProvider.notifier).reset();
  });

  test('STTService.detectSpokenLanguage accurately detects Indic scripts and transliterations', () {
    // Devanagari script (Hindi)
    expect(STTService.detectSpokenLanguage('मुझे सीने में बहुत तेज़ दर्द हो रहा है'), 'hi');
    expect(STTService.detectSpokenLanguage('वात और पित्त'), 'hi');

    // Tamil script
    expect(STTService.detectSpokenLanguage('எனக்கு நெஞ்சு வலி அதிகம் உள்ளது'), 'ta');

    // Telugu script
    expect(STTService.detectSpokenLanguage('నాకు చాలా నొప్పిగా ఉంది'), 'te');

    // Bengali script
    expect(STTService.detectSpokenLanguage('আমার বুকে খুব ব্যথা করছে'), 'bn');

    // Transliterated Hindi in Latin script
    expect(STTService.detectSpokenLanguage('mujhe seene me bahut dard ho raha hai'), 'hi');
    expect(STTService.detectSpokenLanguage('pet me dard aur bukhar hai'), 'hi');

    // Transliterated Tamil in Latin script
    expect(STTService.detectSpokenLanguage('romba nenju vali irukku'), 'ta');

    // Transliterated Telugu in Latin script
    expect(STTService.detectSpokenLanguage('chala gunde noppi ga undi'), 'te');

    // Transliterated Bengali in Latin script
    expect(STTService.detectSpokenLanguage('buke khub byatha korche'), 'bn');

    // English text
    expect(STTService.detectSpokenLanguage('I have severe chest pain and nausea'), 'en');
  });

  test('TTSService has regular speaking rate', () {
    final tts = TTSService();
    expect(tts.currentRate, kIsWeb ? 1.0 : 0.5); // 1.0x on Web, 0.5x standard on native platforms
  });
}
