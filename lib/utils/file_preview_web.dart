import 'dart:html' as html;

Future<void> previewBase64File({
  required String fileName,
  required String base64Data,
  required String mimeType,
}) async {
  final safeMime = mimeType.trim().isEmpty ? 'application/octet-stream' : mimeType.trim();
  final url = 'data:$safeMime;base64,$base64Data';
  html.window.open(url, '_blank');
}
