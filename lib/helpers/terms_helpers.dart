import 'package:flutter/services.dart' show rootBundle;

Future<String> loadTermsFromFile() async {
  try {
    final String content = await rootBundle.loadString(
      'assets/documents/privacy_policy_t3aisat.md',
      cache: true,
    );
    if (content.isEmpty) {
      throw Exception('El archivo de términos está vacío');
    }
    return content;
  } catch (e) {
    throw Exception('No se pudieron cargar los términos y condiciones: ${e.toString()}');
  }
}
