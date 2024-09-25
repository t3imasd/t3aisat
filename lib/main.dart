import 'package:t3aisat/model/environment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:image_picker/image_picker.dart'; // Import para abrir la cámara
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
                const Color(0xFF388E3C)), // Dark green
            foregroundColor:
                WidgetStateProperty.all(const Color(0xFFFFFFFF)), // blanco
            textStyle: WidgetStateProperty.all(
              const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            shadowColor: WidgetStateProperty.all(
                Colors.black54), // More pronounced shadow
            elevation: WidgetStateProperty.all(
                4), // Greater elevation for a depth effect
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
      backgroundColor: const Color(0xFFE0E0E0), // Light gray
      appBar: AppBar(
        title: const Text(
          'T3 AI Sat',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1976D2), // Navy blue
          ),
        ),
        backgroundColor: const Color(0xFFE0E0E0), // Light gray
        elevation: 0, // Without shadow in the title bar
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment:
              CrossAxisAlignment.center, // Focuses horizontally
          children: <Widget>[
            const SizedBox(
                height: 40), // Spacing between the title and the first button
            ElevatedButton(
              onPressed: () async {
                final ImagePicker picker = ImagePicker();
                final XFile? photo = await picker.pickImage(source: ImageSource.camera);
                if (photo != null && context.mounted) {
                  // Navigate to the TakePhotosScreen screen with the captured photo route
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TakePhotoScreen(imagePath: photo.path),
                    ),
                  );
                }
              },
              child: const Text('Foto con Ubicación'),
            ),
            const SizedBox(height: 20), // Spacing between the buttons
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
                    40), // Center the content vertically
          ],
        ),
      ),
    );
  }
}
