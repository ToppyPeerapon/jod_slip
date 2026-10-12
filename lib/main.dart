import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'core/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final (db, prefs, documents) = await (
    AppDatabase.open(),
    SharedPreferences.getInstance(),
    getApplicationDocumentsDirectory(),
  ).wait;
  await Future.wait([initializeDateFormatting('th'), initializeDateFormatting('en')]);

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        slipDirectoryProvider.overrideWithValue(Directory(p.join(documents.path, 'slips'))),
      ],
      child: const JodSlipApp(),
    ),
  );
}
