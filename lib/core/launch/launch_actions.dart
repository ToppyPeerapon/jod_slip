import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Something the app is asked to do as it opens, e.g. from the home-screen
/// widget. [id] is what the native side sends (the host of a `jodslip://` link
/// on iOS, the intent action suffix on Android).
enum LaunchAction {
  scanLibrary('scan-library');

  const LaunchAction(this.id);

  final String id;

  static LaunchAction? fromId(Object? id) => values.where((a) => a.id == id).firstOrNull;
}

/// Delivers [LaunchAction]s from the platform. Abstracted so widgets can be
/// tested without the native channel.
abstract interface class LaunchActionSource {
  /// Calls [onAction] with the action the app was opened with, if any, and
  /// with each later one while the app is running.
  void listen(void Function(LaunchAction action) onAction);
}

class NativeLaunchActionSource implements LaunchActionSource {
  const NativeLaunchActionSource();

  static const _channel = MethodChannel('jod_slip/launch_action');

  @override
  void listen(void Function(LaunchAction action) onAction) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onAction') {
        if (LaunchAction.fromId(call.arguments) case final action?) onAction(action);
      }
    });
    // "ready" tells the native side Dart is listening and returns the action
    // that launched the app, if any.
    _channel.invokeMethod<String>('ready').then((id) {
      if (LaunchAction.fromId(id) case final action?) onAction(action);
    }, onError: (Object error) => debugPrint('Launch action channel unavailable: $error'));
  }
}

final launchActionSourceProvider = Provider<LaunchActionSource>((ref) => const NativeLaunchActionSource());
