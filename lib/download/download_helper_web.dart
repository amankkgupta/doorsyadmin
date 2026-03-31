// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

Future<bool> downloadFileFromUrl(String url, String fileName) async {
  final request = await html.HttpRequest.request(
    url,
    method: 'GET',
    responseType: 'blob',
  );

  final blob = request.response;
  if (blob is! html.Blob) {
    return false;
  }

  final objectUrl = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: objectUrl)
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(objectUrl);
  return true;
}
