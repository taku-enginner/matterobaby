import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageStorageService {
  static const _uuid = Uuid();

  static Future<String> saveImage(File sourceFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final rewardsDir = Directory('${directory.path}/rewards');

    if (!await rewardsDir.exists()) {
      await rewardsDir.create(recursive: true);
    }

    final extension = sourceFile.path.split('.').last;
    final fileName = '${_uuid.v4()}.$extension';
    final targetPath = '${rewardsDir.path}/$fileName';

    await sourceFile.copy(targetPath);
    return targetPath;
  }

  static Future<void> deleteImage(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
