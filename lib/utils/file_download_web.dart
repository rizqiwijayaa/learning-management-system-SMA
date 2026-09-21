import 'dart:html' as html;

Future<String> downloadBase64File({
  required String fileName,
  required String base64Data,
  required String mimeType,
}) async {
  final safeMime = mimeType.trim().isEmpty ? 'application/octet-stream' : mimeType.trim();
  final anchor = html.AnchorElement(
    href: 'data:$safeMime;base64,$base64Data',
  )
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  return fileName;
}
