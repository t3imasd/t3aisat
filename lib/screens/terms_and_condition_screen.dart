import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:t3aisat/helpers/terms_helpers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class TermsAndConditionScreen extends StatefulWidget {
  const TermsAndConditionScreen({super.key});

  @override
  State<TermsAndConditionScreen> createState() => _TermsAndConditionScreenState();
}

class _TermsAndConditionScreenState extends State<TermsAndConditionScreen> {
  bool agreedToTerms = false;
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  Future<void> _saveClickwrapConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();
    await prefs.setString('termsAcceptedTimestamp', now);
    await prefs.setString('termsVersion', '1.0');

    final consent = {
      'timestamp': now,
      'termsVersion': '1.0',
      'deviceInfo': await _getDeviceInfo(),
    };

    await prefs.setString('clickwrapConsent', jsonEncode(consent));
    await prefs.setBool('termsAccepted', true);
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      return {
        'platform': 'Android',
        'device': androidInfo.model,
        'version': androidInfo.version.release,
        'id': androidInfo.id,
      };
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      return {
        'platform': 'iOS',
        'device': iosInfo.model,
        'version': iosInfo.systemVersion,
        'id': iosInfo.identifierForVendor,
      };
    }
    return {
      'platform': 'unknown',
      'device': 'unknown',
      'version': 'unknown',
      'id': 'unknown',
    };
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, false); // Return false when backing out
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Términos y Condiciones'),
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Para continuar usando la app, debes aceptar nuestros términos y condiciones.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: FutureBuilder<String>(
                  future: loadTermsFromFile(context),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                        child: Text('No se encontró el contenido'),
                      );
                    }
                    return Markdown(
                      data: snapshot.data!,
                      styleSheet: MarkdownStyleSheet(
                        h1: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                        h2: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF424242),
                        ),
                        p: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                          height: 1.5,
                        ),
                      ),
                      onTapLink: (text, href, title) {
                        if (href != null) {
                          launchUrl(Uri.parse(href));
                        }
                      },
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: agreedToTerms,
                        onChanged: (value) {
                          setState(() {
                            agreedToTerms = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          'He leído y acepto los Términos y Condiciones y la Política de Privacidad',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context, false); // Return false when exiting
                          },
                          child: const Text('Salir'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: agreedToTerms
                              ? () async {
                                  await _saveClickwrapConsent();
                                  if (!mounted) return;
                                  Navigator.pop(context, true); // Return true when accepting
                                }
                              : null,
                          child: const Text('Aceptar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
