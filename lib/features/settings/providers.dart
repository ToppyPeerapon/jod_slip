import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

final ownerNamesProvider = NotifierProvider<OwnerNamesNotifier, List<String>>(OwnerNamesNotifier.new);

/// The user's own names, used to tell income from expense on a slip.
class OwnerNamesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => ref.watch(settingsRepositoryProvider).ownerNames();

  Future<void> add(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || state.contains(trimmed)) return;
    await _save([...state, trimmed]);
  }

  Future<void> remove(String name) => _save(state.where((n) => n != name).toList(growable: false));

  Future<void> _save(List<String> names) async {
    await ref.read(settingsRepositoryProvider).saveOwnerNames(names);
    state = List.unmodifiable(names);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => Locale(ref.watch(settingsRepositoryProvider).localeCode());

  Future<void> change(String code) async {
    await ref.read(settingsRepositoryProvider).saveLocaleCode(code);
    state = Locale(code);
  }
}
