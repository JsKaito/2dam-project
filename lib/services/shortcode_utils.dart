class ShortcodeUtils {
  static const String _alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  static const int _base = 62;

  /// Convierte un ID numérico a un shortcode (ej: 123 -> 'b9')
  static String encode(int id) {
    if (id == 0) return _alphabet[0];
    String res = "";
    while (id > 0) {
      res = _alphabet[id % _base] + res;
      id = (id / _base).floor();
    }
    return res;
  }

  /// Convierte un shortcode a su ID numérico original (ej: 'b9' -> 123)
  static int decode(String code) {
    int res = 0;
    for (int i = 0; i < code.length; i++) {
      int charIndex = _alphabet.indexOf(code[i]);
      if (charIndex == -1) return -1;
      res = res * _base + charIndex;
    }
    return res;
  }

  /// Intenta obtener un ID de un string que puede ser shortcode o ID directo
  static dynamic parseId(String input) {
    // Si es un número puro, lo devolvemos como tal
    final int? numericId = int.tryParse(input);
    if (numericId != null) return numericId;
    
    // Si no, intentamos decodificarlo como shortcode
    final int decodedId = decode(input);
    return decodedId != -1 ? decodedId : input;
  }
}
