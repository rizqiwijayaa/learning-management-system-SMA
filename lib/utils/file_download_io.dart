import 'dart:convert';
import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

Future<String> downloadBase64File({
  required String fileName,
  required String base64Data,
  required String mimeType,
}) async {
  final bytes = base64Decode(base64Data);
  final safeName = fileName.trim().isEmpty ? 'download.bin' : fileName.trim();

  Directory? baseDirectory;
  if (Platform.isAndroid) {
    final downloadDirectories = await getExternalStorageDirectories(
      type: StorageDirectory.downloads,
    );
    if (downloadDirectories != null && downloadDirectories.isNotEmpty) {
      baseDirectory = downloadDirectories.first;
    }
  }

  baseDirectory ??=
      (Platform.isAndroid
          ? await getExternalStorageDirectory()
          : await getApplicationDocumentsDirectory());
  baseDirectory ??= await getApplicationDocumentsDirectory();

  final file = File('${baseDirectory.path}${Platform.pathSeparator}$safeName');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);

  final openResult = await OpenFilex.open(file.path, type: mimeType.trim());
  if (openResult.type == ResultType.error && openResult.message.trim().isNotEmpty) {
    throw Exception('${openResult.message} (${file.path})');
  }

  return file.path;
}
