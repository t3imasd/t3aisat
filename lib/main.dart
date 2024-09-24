import 'package:t3aisat/model/environment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'screens/take_photo_screen.dart';
import 'screens/parcel_map_screen.dart';

Future<void> main() async {
  // Set the logger
  _setupLogging();

  try {
    // Code from YouTube video https://www.youtube.com/watch?v=jMgrNw3_rZ0
    await dotenv.load(fileName: Environment.fileName);
    Logger.root.info('Loaded ${Environment.fileName} file successfully');
  } catch (e) {
    Logger.root
        .severe('Could not load ${Environment.fileName} file. ERROR: $e');
  }

  runApp(const MyApp());
}

void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'T3AISat',
      theme: ThemeData(
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
                const Color(0xFF388E3C)), // Verde Oscuro
            foregroundColor:
                WidgetStateProperty.all(const Color(0xFFFFFFFF)), // Blanco
            textStyle: WidgetStateProperty.all(
              const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            shadowColor: WidgetStateProperty.all(
                Colors.black54), // Sombra más pronunciada
            elevation: WidgetStateProperty.all(
                4), // Mayor elevación para un efecto de profundidad
          ),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0), // Gris Claro
      appBar: AppBar(
        title: const Text(
          'T3 AI Sat',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1976D2), // Azul Marino
          ),
        ),
        backgroundColor: const Color(0xFFE0E0E0), // Gris Claro
        elevation: 0, // Sin sombra en la barra de título
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment:
              CrossAxisAlignment.center, // Centra horizontalmente
          children: <Widget>[
            const SizedBox(
                height: 40), // Espaciado entre el título y el primer botón
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TakePhotoScreen()),
                );
              },
              child: const Text('Foto con Ubicación'),
            ),
            const SizedBox(height: 20), // Espaciado entre los botones
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ParcelMapScreen()),
                );
              },
              child: const Text('Mapa de Parcelas'),
            ),
            const SizedBox(
                height:
                    40), // Asegura que el contenido esté centrado verticalmente
          ],
        ),
      ),
    );
  }
}
