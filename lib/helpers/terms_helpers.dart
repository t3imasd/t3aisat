import 'package:flutter/services.dart' show rootBundle;

Future<String> loadTermsFromFile() async {
  try {
    return await rootBundle.loadString('documentation/privacy_policy/privacy_policy_t3aisat.md');
  } catch (e) {
    return 'Error al cargar los términos y condiciones. Por favor, inténtelo más tarde.';
  }
}
