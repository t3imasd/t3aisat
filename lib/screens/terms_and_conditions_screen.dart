import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/terms_helpers.dart';
import '../main.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  TermsAndConditionsScreenState createState() =>
      TermsAndConditionsScreenState();
}

class TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  late Future<String> termsContent;

  @override
  void initState() {
    super.initState();
    termsContent = loadTermsFromFile(context);
  }

  Future<void> _acceptTerms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('termsAccepted', true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MyHomePage()),
    );
  }

  void _declineTerms() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aviso'),
        content: const Text(
            'Debe aceptar los términos y condiciones para usar la aplicación.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Disable back navigation
      onPopInvokedWithResult: (didPop, result) {
        // Optionally handle pop attempts here
        // Since canPop is false, didPop should be false
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Términos y Condiciones'),
          automaticallyImplyLeading: false, // Remove back button from AppBar
        ),
        body: FutureBuilder<String>(
          future: termsContent,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(
                  child: Text('Error al cargar los términos y condiciones.'));
            } else {
              return Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Markdown(
                        data: snapshot.data ??
                            'No se pudieron cargar los términos.',
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _acceptTerms,
                        child: const Text('Aceptar'),
                      ),
                      ElevatedButton(
                        onPressed: _declineTerms,
                        child: const Text('Rechazar'),
                      ),
                    ],
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
