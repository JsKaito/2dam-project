// Stub for dart:html for non-web platforms
class Blob {
  Blob(List<dynamic> bytes);
}

class Url {
  static String createObjectUrlFromBlob(dynamic blob) => '';
  static void revokeObjectUrl(String url) {}
}

class AnchorElement {
  String href = '';
  AnchorElement({required String href});
  void setAttribute(String name, String value) {}
  void click() {}
}
