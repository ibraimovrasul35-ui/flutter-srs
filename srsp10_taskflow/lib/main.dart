import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/database/app_database.dart';
import 'data/seed/demo_seeder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');

  final database = AppDatabase.open();
  // При первом запуске заполняем базу демонстрационными данными.
  await DemoSeeder(database).seedIfEmpty();

  runApp(TaskFlowApp(database: database));
}
