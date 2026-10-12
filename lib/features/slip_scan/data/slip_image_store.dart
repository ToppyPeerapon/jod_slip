import 'dart:io';

import 'package:path/path.dart' as p;

/// Keeps copies of slip images inside the app's own storage.
///
/// Only the file name is stored in the database: iOS changes the absolute
/// app container path between installs/updates, so absolute paths go stale.
class SlipImageStore {
  const SlipImageStore(this._directory);

  final Directory _directory;

  /// Copies [sourcePath] into the slip directory and returns the new file name.
  Future<String> save(String sourcePath) async {
    await _directory.create(recursive: true);
    final extension = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final fileName = 'slip_${DateTime.now().microsecondsSinceEpoch}$extension';
    await File(sourcePath).copy(p.join(_directory.path, fileName));
    return fileName;
  }

  File resolve(String fileName) => File(p.join(_directory.path, p.basename(fileName)));

  Future<void> delete(String fileName) async {
    final file = resolve(fileName);
    if (await file.exists()) await file.delete();
  }
}
