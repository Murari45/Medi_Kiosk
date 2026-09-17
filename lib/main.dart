import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app/app.dart';
import 'src/app/di.dart';
import 'src/database/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup Dependency Injection (GetIt)
  await setupDependencyInjection();

  // Initialize Database (handles Native SQLite & Web in-memory)
  await AppDatabase.instance.initialize();

  runApp(
    const ProviderScope(
      child: AyuDwarApp(),
    ),
  );
}
