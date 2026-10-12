import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

// These resources are opened once in main() before runApp and injected via
// ProviderScope overrides, so the rest of the app can read them synchronously.

final databaseProvider = Provider<Database>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden in main()'),
);

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden in main()'),
);

/// Directory where slip images are kept (inside the app's documents dir).
final slipDirectoryProvider = Provider<Directory>(
  (ref) => throw UnimplementedError('slipDirectoryProvider must be overridden in main()'),
);
