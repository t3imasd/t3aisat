# o1-preview image_picker package

## USER MESSAGE

En mi aplicación creada con Flutter usando Dart titulada T3AI-SAT tengo una pantalla principal (lib/main.dart) con dos botones: "Captura con Ubicación" y "Mapa de Parcelas".

Cuando pulsas en el botón "Captura con Ubicación" te abre la cámara de fotos mediante un image_picker y una vez que se toma la foto. Una vez pulsado en la cámara el botón "Aceptar", te lleva a una nueva pantalla MediaLocationScreen (lib/screens/media_location_screen.dart) donde escribe en la foto las coordenadas (latitud y longitud) y la dirección en texto donde se ha hecho la foto, además le añade metadatos EXIF y guarda la foto con esos metadatos en la Galería de fotos de Android o en la App Fotos del iPhone.

Entonces, ahora quiero que haga lo mismo en los vídeos. ¿Es posible?

Entonces, quiero que cambies para usar una cámara que sea válida tanto para fotos como para vídeos. Me gusta el paquete [image_picker: ^1.1.2](https://pub.dev/packages/image_picker) que está preparado para los metadatos EXIF y además te muestra una cámara o visualizar para elegir entre Foto o Vídeo. Además, para guardar la fotos quiero que uses el paquete [saver_gallery: ^3.0.6](https://pub.dev/packages/saver_gallery/example) ya que está actualizado hace 42 días (mientras que gallery_saver lleva 2 años sin actualizar).

El flujo que quiero que haga el usuario, si es posible hacerlo así es el siguiente, tanto para la foto como para el vídeo:

1. El usuario pulsa en la pantalla principal en "Captura con Ubicación".
2. Se abre la Cámara de image_picker para que el usuario pueda tomar una foto o grabar un vídeo.
3. El usuario pulsa el botón Aceptar o similar para aceptar la foto o vídeo que ha hecho en la Cámara de image_picker.
4. En la pantalla MediaLocationScreen se muestra la imagen como hasta ahora en el archivo media_location_screen.dart o si es un vídeo tendrá un visualizador de vídeos.
5. Añadirá los metadatos EXIT tal cual lo hace ahora a la imagen, y al vídeo también los añadirá.
6. La foto será guardada en la Galería de fotos de Android o en la App Fotos de iOS tal cual lo hace ahora, y el vídeo se guardará en la Galería de Android o Fotos de iOS con el paquete saver_gallery.

Entonces, lo que te pido es que me crees el flujo que quiero para el usuario tanto para las fotos como para los vídeos, si es posible de forma sencilla añadirle a los vídeos el texto de las coordenadas y la dirección en letra como en las fotos y además añadirle los metadatos EXIF. Entonces, en las fotos mantienes igual el código implementado en media_location_screen.dart, pues con total seguridad añade muy bien los metadatos EXIF a las fotos y la fotos las guarda perfectamente en la Galería de Android o en la App Fotos del iPhone, solamente cambiaría que en lugar de abrir la cámara nativa mediante image_picker, pues ahora la abriría con image_picker. Y sí tienes que añadir todas las funcionalidades que quiero para los vídeos (escribir texto en vídeo con coordanadas y dirección -si es posible-, añadir metadatos EXIF al mp4 -si es posible- y guardar el vídeo en la Galería de Android y en la App Fotos del iPhone)

Ahora, te iré escribiendo los README de los paquetes para que así tenga la información actualizada, también el contenido de los archivo `lib/main.dart` y `lib/screens/media_location_screen.dart` que tengo en mi proyecto. También, te escribo el contenido que tengo los archivos `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/kotlin/com/t3aisat/t3aisat/MainActivity.kt`, `ios/Runner/Info.plist`, `ios/Runner/AppDelegate.swift` y `pubspec.yml` para que así veas como están todos los permisos dados.

Empezamos con los archivos

`lib/main.dart`

```dart
import 'package:t3aisat/model/environment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:image_picker/image_picker.dart'; // Import to open the camera
import 'screens/media_location_screen.dart';
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
            backgroundColor:
                WidgetStateProperty.all(const Color(0xFF388E3C)), // Dark green
            foregroundColor:
                WidgetStateProperty.all(const Color(0xFFFFFFFF)), // White
            textStyle: WidgetStateProperty.all(
              const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.all(16), // Increased padding to 16px
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    12), // Rounded corners with 12px radius
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
      backgroundColor: const Color(0xFFE6E6E6), // Light gray
      appBar: AppBar(
        title: Text(
          'T3 AI Sat',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1976D2), // Navy blue
            shadows: [
              Shadow(
                blurRadius: 3.0,
                color: Colors.black
                    .withOpacity(0.25), // Light shadow behind the title
                offset: const Offset(0, 2.0),
              ),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFE6E6E6), // Light gray
        elevation: 0, // Without shadow in the title bar
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center, // Focuses horizontally
          children: <Widget>[
            const SizedBox(
                height: 60), // Spacing between the title and the first button
            ElevatedButton(
              onPressed: () async {
                final ImagePicker picker = ImagePicker();
                final XFile? photo =
                    await picker.pickImage(source: ImageSource.camera);
                if (photo != null && context.mounted) {
                  // Navigate to the PhotoLocationScreen screen with the captured photo route
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PhotoLocationScreen(imagePath: photo.path),
                    ),
                  );
                }
              },
              child: const Text('Captura con Ubicación'),
            ),
            const SizedBox(height: 40), // Spacing between the buttons
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
                height: 60), // Spacing to center the content vertically
          ],
        ),
      ),
    );
  }
}

```

`lib/screens/media_location_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart'; // Add this import for MethodChannel
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:native_exif/native_exif.dart'; // Import for EXIF data

class PhotoLocationScreen extends StatefulWidget {
  final String imagePath;

  const PhotoLocationScreen({super.key, required this.imagePath});

  @override
  MediaLocationScreenState createState() => MediaLocationScreenState();
}

class MediaLocationScreenState extends State<PhotoLocationScreen> {
  Position? _currentPosition;
  String? _address;
  final Logger log = Logger('MediaLocationScreen');
  String? _updatedImagePath; // Variable to store the updated image path
  bool _isLoading = true; // Variable to manage the loading spinner

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Function to obtain the current location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      log.severe('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        log.severe('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      log.severe('Location permissions are permanently denied');
      return;
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      log.info('Current position: $_currentPosition');

      // Obtain address from coordinates
      await _getAddressFromCoordinates(
          _currentPosition!.latitude, _currentPosition!.longitude);

      // Write the text on the image and save it in the gallery
      await _writeTextOnImageAndSaveToGallery(widget.imagePath);
    } catch (e) {
      log.severe('Failed to obtain location or process image: $e');
    } finally {
      // Ensure the loading spinner is hidden
      setState(() {
        _isLoading = false; // Hide the loading spinner when processing is done
      });
    }
  }

  // Function to get the address from the coordinates
  Future<void> _getAddressFromCoordinates(double lat, double lon) async {
    final accessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'];
    final url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$lon,$lat.json?access_token=$accessToken';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'].isNotEmpty) {
          setState(() {
            // Adjust the address to be split into three lines
            final addressParts = data['features'][0]['place_name'].split(',');
            _address =
                "${addressParts[0].trim()}\n${addressParts[1].trim()}\n${addressParts[2].trim()}";
          });
          log.info('Address: $_address');
        }
      } else {
        log.severe('Failed to get address from coordinates');
      }
    } catch (e) {
      log.severe('Error fetching address: $e');
    }
  }

  // Function to convert decimal coordinates to DMS format
  String _convertToDMS(double decimal) {
    final degrees = decimal.truncate();
    final minutes = ((decimal - degrees) * 60).truncate();
    final seconds = (((decimal - degrees) * 60) - minutes) * 60;

    return '${degrees.abs()}°${minutes.abs()}\'${seconds.abs().toStringAsFixed(2)}" ${decimal >= 0 ? 'N' : 'S'}';
  }

  // TODO: To add ICC Profile data (e.g., RedMatrixColumn, GreenMatrixColumn, BlueMatrixColumn, MediaWhitePoint),
  // consider integrating an image processing library that supports full ICC profile handling, such as
  // ImageMagick or GraphicsMagick. You may need to extract the ICC profile from the image file, modify it,
  // and then re-embed it using a tool that provides robust support for ICC profiles.
  // This step would involve:
  // 1. Extracting the existing ICC profile from the image if present.
  // 2. Modifying or appending the necessary color profile metadata.
  //    - Profile Description
  //    - Red Matrix Column
  //    - Green Matrix Column
  //    - Blue Matrix Column
  //    - Media White Point
  //    - Red Tone Reproduction Curve
  //    - Green Tone Reproduction Curve
  //    - Blue Tone Reproduction Curve
  // 3. Re-embedding the updated ICC profile back into the image.
  // Note: Flutter does not natively support ICC profile editing, and this may need an external tool or plugin
  // to be implemented efficiently for both Android and iOS.
  // IMPORTANT: ICC Profile data is not essential to verify the integrity of the image, but it can be useful for color management.

  // Function to add EXIF data to the image
  Future<void> _addExifData(String imagePath) async {
    try {
      final exif = await Exif.fromPath(imagePath);

      if (_currentPosition != null) {
        // Add GPS coordinates
        await exif.writeAttributes({
          'GPSLatitude': _currentPosition!.latitude.toString(),
          'GPSLongitude': _currentPosition!.longitude.toString(),
        });
      }

      // Add GPS Date/Time in UTC
      final now = DateTime.now().toUtc();
      await exif.writeAttributes({
        'GPSDateStamp': DateFormat('yyyy:MM:dd').format(now),
        'GPSTimeStamp': DateFormat('HH:mm:ss').format(now),
      });

      // Add other EXIF data with ASCII encoding (as required by Android EXIF specification)
      await exif.writeAttributes({
        'DateTimeOriginal':
            DateFormat('yyyy:MM:dd HH:mm:ss').format(DateTime.now()),
        'UserComment':
            't3AI-SAT App. Direccion en la que fue tomada la foto: ${_address ?? 'Sin direccion'}',
        'ProfileDescription': 'sRGB', // Add color profile description
        'ColorSpace': '1', // Add color space as sRGB (value 1 means sRGB)
      });

      await exif.close();
    } catch (e) {
      log.severe('Error writing EXIF data: $e');
    }
  }

  // Function to get the directory path for saving on Android in the DCIM/Camera folder
  Future<String> _getExternalStoragePath() async {
    // Android DCIM directory
    Directory? externalDir = Directory('/storage/emulated/0/DCIM/Camera');
    if (await externalDir.exists()) {
      return externalDir.path;
    } else {
      // If the directory doesn't exist, create it
      externalDir.create(recursive: true);
      return externalDir.path;
    }
  }

  // Function to save the photo with the location on the device and the gallery
  Future<void> _writeTextOnImageAndSaveToGallery(String imagePath) async {
    try {
      // Read the original image file as bytes
      final bytes = await File(imagePath).readAsBytes();
      final img.Image originalImage = img.decodeImage(bytes)!;

      // Load the font from the assets to draw text on the image
      final fontData = await rootBundle.load(
          'assets/fonts/roboto_black/Roboto-Black_100_size_white_color.ttf.zip');
      final font = img.BitmapFont.fromZip(fontData.buffer.asUint8List());

      // Convert coordinates to Degrees, Minutes, Seconds (DMS) format
      final latitudeDMS = _convertToDMS(_currentPosition!.latitude);
      final longitudeDMS = _convertToDMS(_currentPosition!.longitude);

      // Get the current date and time
      final now = DateTime.now();
      final timeZoneName =
          now.timeZoneName; // Detects the time zone name (e.g., CEST, CET)

      // Add 1 second to the network time to simulate network synchronization
      final networkTime = now.add(const Duration(seconds: 1));

      // Format the network and local times
      final formattedNetworkTime =
          '${DateFormat('dd MMM yyyy HH:mm:ss').format(networkTime)} $timeZoneName';
      final formattedLocalTime =
          '${DateFormat('dd MMM yyyy HH:mm:ss').format(now)} $timeZoneName';

      final formattedLocation = 'Lat: $latitudeDMS\nLon: $longitudeDMS';
      log.info('Formatted location: $formattedLocation');

      // Format the address and location for displaying on the image
      final formattedAddress = _address?.split(',').join('\n');

      // Build the text that will be drawn on the image
      final formattedText = '''
Network: $formattedNetworkTime
Local: $formattedLocalTime
$latitudeDMS $longitudeDMS
$formattedAddress
''';

      // Draw the address and coordinates on the image
      final updatedImage = img.drawString(
        originalImage,
        formattedText,
        font: font,
        x: 60, // Ensure the left margin is consistent
        y: originalImage.height - 850, // Position the text towards the bottom
        color: img.ColorRgba8(255, 255, 255, 255), // White color for text
      );

      // Generate the filename with the format t3aisat_yyyymmdd_hhmmss.jpg
      final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(now);

      String updatedImagePath;

      if (Platform.isAndroid) {
        // Use custom path for Android DCIM/Camera folder
        final externalStoragePath = await _getExternalStoragePath();
        updatedImagePath = path.join(
          externalStoragePath,
          't3aisat_$formattedDate.jpg', // Filename with the desired format
        );
      } else if (Platform.isIOS) {
        // Use application documents directory for initial save on iOS
        final directory = await getApplicationDocumentsDirectory();
        updatedImagePath = path.join(
          directory.path,
          't3aisat_$formattedDate.jpg', // Filename with the desired format
        );
      } else {
        log.severe('Unsupported platform');
        return;
      }

      // Save the updated image to the specified path
      final updatedImageFile = File(updatedImagePath);
      log.info('Updated image path: $updatedImagePath');
      log.info('Updated image file path: ${updatedImageFile.path}');

      // Write the updated image bytes to the file
      await updatedImageFile.writeAsBytes(img.encodeJpg(updatedImage));

      // Verify if the file exists after saving
      if (await updatedImageFile.exists()) {
        log.info('File created successfully: ${updatedImageFile.path}');
      } else {
        log.severe('File not created: ${updatedImageFile.path}');
        return;
      }

      // Add EXIF data (e.g., GPS coordinates, description) to the image
      await _addExifData(updatedImageFile.path);

      // Request permission to save in the gallery
      var status = await Permission.photos.status;
      if (!status.isGranted) {
        status = await Permission.photos.request();
      }

      if (status.isGranted) {
        if (Platform.isAndroid) {
          // Save to gallery using ImageGallerySaver for Android
          final result =
              await ImageGallerySaver.saveFile(updatedImageFile.path);
          if (result != null &&
              result['isSuccess'] != null &&
              result['isSuccess']) {
            log.info(
                'Updated image saved to gallery on Android: ${result['filePath']}');
          } else {
            log.severe('Failed to save image to gallery');
          }
        } else if (Platform.isIOS) {
          // Use platform channel to save the image with EXIF metadata on iOS
          await _saveImageToGalleryWithExifIOS(updatedImagePath);
          log.info('Updated image saved to gallery on iOS');
        }
      } else {
        log.severe('Permission denied to access photos');
      }

      // Update the state to reflect the new image path in the UI
      setState(() {
        _updatedImagePath = updatedImagePath;
      });
    } catch (e) {
      // Log any errors that occur during the image processing
      log.severe('Failed to process image: $e');
    }
  }

  // Function to save the image to the gallery with EXIF metadata on iOS
  Future<void> _saveImageToGalleryWithExifIOS(String imagePath) async {
    try {
      // Create a method channel to interact with native iOS code
      const platform = MethodChannel('com.t3aisat/save_to_gallery');
      await platform
          .invokeMethod('saveImageWithExif', {'imagePath': imagePath});
      log.info('Updated image saved to gallery on iOS');
    } catch (e) {
      log.severe(
          'Failed to save image to gallery on iOS with EXIF metadata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoPosición',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1976D2), // Navy blue
            )),
        backgroundColor: const Color(0xFFE6E6E6), // Light gray
        foregroundColor: const Color(0xFF1976D2), // Navy blue for text
        elevation: 0, // No shadow in the AppBar
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(
                color: Color(0xFF1976D2), // Navy blue spinner
              )
            : Column(
                children: [
                  if (_updatedImagePath != null)
                    Expanded(
                      child: Image.file(
                        File(_updatedImagePath!),
                        fit: BoxFit.cover, // Ensures the image fills the space
                        width: double.infinity,
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (_currentPosition != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment
                            .start, // Align content to the start of the row
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFF388E3C), // Dark green
                            size: 30, // Increased icon size
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            // Ensures text wraps and aligns properly
                            child: Text(
                              'Latitud: ${_currentPosition?.latitude}\nLongitud: ${_currentPosition?.longitude}',
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 16,
                                  color: Color(0xFF424242)), // Dark gray
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_address != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment
                            .start, // Align content to the start of the row
                        children: [
                          const Icon(
                            Icons.home,
                            color: Color(0xFF388E3C), // Dark green
                            size: 30, // Increased icon size
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            // Ensures text wraps and aligns properly
                            child: Text(
                              '$_address',
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 16,
                                  color: Color(0xFF424242)), // Dark gray
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }
}

```

`android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
        <!-- Definición de permisos necesarios para la aplicación -->
        <uses-permission android:name="android.permission.INTERNET" />
        <uses-permission android:name="android.permission.CAMERA" />
        <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
        <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
        <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
        <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
        <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
        <uses-permission android:name="android.permission.ACCESS_MEDIA_LOCATION"/>
        <!-- Permisos específicos para Android 13 o superior -->
        <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
        <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
        <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
    <application
        android:label="t3aisat"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:requestLegacyExternalStorage="true"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <!-- Specifies an Android theme to apply to this Activity as soon as
                 the Android process has started. This theme is visible to the user
                 while the Flutter UI initializes. After that, this theme continues
                 to determine the Window background behind the Flutter UI. -->
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <!-- Don't delete the meta-data below.
             This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    <!-- Required to query activities that can process text, see:
         https://developer.android.com/training/package-visibility and
         https://developer.android.com/reference/android/content/Intent#ACTION_PROCESS_TEXT.

         In particular, this is used by the Flutter engine in io.flutter.plugin.text.ProcessTextPlugin. -->
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>

```

`android/app/src/main/kotlin/com/t3aisat/t3aisat/MainActivity.kt`

```kotlin
package com.t3aisat.t3aisat

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity()

```

`ios/Runner/Info.plist`

```plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>$(DEVELOPMENT_LANGUAGE)</string>
  <key>CFBundleDisplayName</key>
  <string>t3 AI Sat</string>
  <key>CFBundleExecutable</key>
  <string>$(EXECUTABLE_NAME)</string>
  <key>CFBundleIdentifier</key>
  <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>t3aisat</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$(FLUTTER_BUILD_NAME)</string>
  <key>CFBundleSignature</key>
  <string>????</string>
  <key>CFBundleVersion</key>
  <string>$(FLUTTER_BUILD_NUMBER)</string>
  <key>LSRequiresIPhoneOS</key>
  <true/>
  <key>UIApplicationSupportsIndirectInputEvents</key>
  <true/>
  <key>UILaunchStoryboardName</key>
  <string>LaunchScreen</string>
  <key>UIMainStoryboardFile</key>
  <string>Main</string>
  <key>UISupportedInterfaceOrientations</key>
  <array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
  </array>
  <key>UISupportedInterfaceOrientations~ipad</key>
  <array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationPortraitUpsideDown</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
  </array>
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>La App necesita tener acceso a tu ubicación mientras la aplicación está en uso.</string>
  <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
  <string>La App necesita tener acceso a tu ubicación mientras la aplicación está en uso y en segundo plano.</string>
  <key>NSLocationUsageDescription</key>
  <string>Los dispositivos más antiguos necesitan la ubicación.</string>
  <key>NSLocationAlwaysUsageDescription</key>
  <string>La App necesita tener acceso a tu ubicación incluso cuando la aplicación está en segundo plano.</string>
  <key>NSCameraUsageDescription</key>
  <string>La App necesita tener permiso a tu cámara para hacer fotos.</string>
  <key>NSPhotoLibraryUsageDescription</key>
  <string>La App necesita permiso de acceso a tu librería de fotos.</string>
  <key>CADisableMinimumFrameDurationOnPhone</key>
  <true/>
  <key>NSPhotoLibraryAddUsageDescription</key>
  <string>Necesitamos añadir fotos a tu libería de Fotos.</string>
</dict>
</plist>

```

`ios/Runner/AppDelegate.swift`

```swift
import Flutter
import UIKit
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let saveImageChannel = FlutterMethodChannel(name: "com.t3aisat/save_to_gallery",
                                                binaryMessenger: controller.binaryMessenger)
    saveImageChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "saveImageWithExif" {
        guard let args = call.arguments as? [String: Any],
              let imagePath = args["imagePath"] as? String else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Image path not provided", details: nil))
          return
        }
        self.saveImageWithExif(imagePath: imagePath, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func saveImageWithExif(imagePath: String, result: @escaping FlutterResult) {
    let imageUrl = URL(fileURLWithPath: imagePath)
    do {
      let imageData = try Data(contentsOf: imageUrl)

      PHPhotoLibrary.requestAuthorization { status in
        if status == .authorized {
          PHPhotoLibrary.shared().performChanges({
            let creationRequest = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            options.originalFilename = (imageUrl.lastPathComponent) // Use the original filename for saving
            creationRequest.addResource(with: .photo, data: imageData, options: options)
          }) { success, error in
            if success {
              result(true)
            } else {
              result(FlutterError(code: "SAVE_FAILED", message: "Failed to save image to gallery", details: error?.localizedDescription))
            }
          }
        } else {
          result(FlutterError(code: "PERMISSION_DENIED", message: "Photo library access denied", details: nil))
        }
      }
    } catch {
      result(FlutterError(code: "FILE_READ_ERROR", message: "Could not read image file", details: error.localizedDescription))
    }
  }
}

```

`pubspec.yml`

```yml
name: t3aisat
description: 'A new Flutter project.'
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.4.3 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6
  mapbox_maps_flutter: ^2.2.1
  xml: ^6.5.0
  geotypes: ^0.0.2
  geobase: ^1.3.0
  image_picker: ^1.1.2
  flutter_dotenv: ^5.1.0
  logging: ^1.2.0
  path_provider: ^2.1.4
  path: ^1.9.0
  image_gallery_saver: ^2.0.3
  permission_handler: ^11.3.1
  geolocator: ^13.0.1
  http: ^1.2.2
  image: ^4.2.0
  intl: ^0.19.0
  native_exif: ^0.6.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  collection: ^1.18.0
  http_parser: ^4.0.2
  leak_tracker: ^10.0.5
  leak_tracker_flutter_testing: ^3.0.5
  material_color_utilities: ^0.11.1
  meta: ^1.12.0
  string_scanner: ^1.2.0
  test_api: ^0.7.2
  vm_service: ^14.2.1
flutter:
  uses-material-design: true
  assets:
    - .env.development
    - .env.production
    - assets/fonts/roboto_black/Roboto-Black_100_size_white_color.ttf.zip
```

Ahora te escribo los README de los paquetes de Flutter

[image_picker: ^1.1.2](https://pub.dev/packages/image_picker)

````markdown
# Image Picker plugin for Flutter

<?code-excerpt path-base="example/lib"?>

[![pub package](https://img.shields.io/pub/v/image_picker.svg)](https://pub.dev/packages/image_picker)

A Flutter plugin for iOS and Android for picking images from the image library,
and taking new pictures with the camera.

|             | Android | iOS     | Linux | macOS  | Web                                                                                                         | Windows     |
| ----------- | ------- | ------- | ----- | ------ | ----------------------------------------------------------------------------------------------------------- | ----------- |
| **Support** | SDK 21+ | iOS 12+ | Any   | 10.14+ | [See `image_picker_for_web`](https://pub.dev/packages/image_picker_for_web#limitations-on-the-web-platform) | Windows 10+ |

## Setup

### iOS

Starting with version **0.8.1** the iOS implementation uses PHPicker to pick
(multiple) images on iOS 14 or higher.
As a result of implementing PHPicker it becomes impossible to pick HEIC images
on the iOS simulator in iOS 14+. This is a known issue. Please test this on a
real device, or test with non-HEIC images until Apple solves this issue.
[63426347 - Apple known issue](https://www.google.com/search?q=63426347+apple&sxsrf=ALeKk01YnTMid5S0PYvhL8GbgXJ40ZS[…]t=gws-wiz&ved=0ahUKEwjKh8XH_5HwAhWL_rsIHUmHDN8Q4dUDCA8&uact=5)

Add the following keys to your _Info.plist_ file, located in
`<project root>/ios/Runner/Info.plist`:

- `NSPhotoLibraryUsageDescription` - describe why your app needs permission for
  the photo library. This is called _Privacy - Photo Library Usage Description_ in
  the visual editor.
  - This permission will not be requested if you always pass `false` for
    `requestFullMetadata`, but App Store policy requires including the plist
    entry.
- `NSCameraUsageDescription` - describe why your app needs access to the camera.
  This is called _Privacy - Camera Usage Description_ in the visual editor.
- `NSMicrophoneUsageDescription` - describe why your app needs access to the
  microphone, if you intend to record videos. This is called
  _Privacy - Microphone Usage Description_ in the visual editor.

### Android

Starting with version **0.8.1** the Android implementation support to pick
(multiple) images on Android 4.3 or higher.

No configuration required - the plugin should work out of the box. It is however
highly recommended to prepare for Android killing the application when low on memory. How to prepare for this is discussed in the
[Handling MainActivity destruction on Android](#handling-mainactivity-destruction-on-android)
section.

It is no longer required to add `android:requestLegacyExternalStorage="true"` as
an attribute to the `<application>` tag in AndroidManifest.xml, as
`image_picker` has been updated to make use of scoped storage.

#### Handling MainActivity destruction

When under high memory pressure the Android system may kill the MainActivity of
the application using the image_picker. On Android the image_picker makes use
of the default `Intent.ACTION_GET_CONTENT` or `MediaStore.ACTION_IMAGE_CAPTURE`
intents. This means that while the intent is executing the source application
is moved to the background and becomes eligible for cleanup when the system is
low on memory. When the intent finishes executing, Android will restart the
application. Since the data is never returned to the original call use the
`ImagePicker.retrieveLostData()` method to retrieve the lost data. For example:

<?code-excerpt "readme_excerpts.dart (LostData)"?>

```dart
Future<void> getLostData() async {
  final ImagePicker picker = ImagePicker();
  final LostDataResponse response = await picker.retrieveLostData();
  if (response.isEmpty) {
    return;
  }
  final List<XFile>? files = response.files;
  if (files != null) {
    _handleLostFiles(files);
  } else {
    _handleError(response.exception);
  }
}
```
````

This check should always be run at startup in order to detect and handle this
case. Please refer to the
[example app](https://pub.dev/packages/image_picker/example) for a more complete
example of handling this flow.

#### Permanently storing images and videos

Images and videos picked using the camera are saved to your application's local
cache, and should therefore be expected to only be around temporarily.
If you require your picked image to be stored permanently, it is your
responsibility to move it to a more permanent location.

#### Android Photo Picker

On Android 13 and above this package uses the
[Android Photo Picker](https://developer.android.com/training/data-storage/shared/photopicker)
. On Android 12 and below use of Android Photo Picker is optional.
[Learn how to use it](https://pub.dev/packages/image_picker_android).

#### Using `launchMode: singleInstance`

Launching the image picker from an `Activity` with `launchMode: singleInstance`
will always return `RESULT_CANCELED`.
In this launch mode, new activities are created in a separate [Task](https://developer.android.com/guide/components/activities/tasks-and-back-stack).
As activities cannot communicate between tasks, the image picker activity cannot
send back its eventual result to the calling activity.
To work around this problem, consider using `launchMode: singleTask` instead.

### Windows, macOS, and Linux

This plugin currently has limited support for the three desktop platforms,
serving as a wrapper around the [`file_selector`](https://pub.dev/packages/file_selector)
plugin with appropriate file type filters set. Selection modification options,
such as max width and height, are not yet supported.

By default, `ImageSource.camera` is not supported, since unlike on Android and
iOS there is no system-provided UI for taking photos. However, the desktop
implementations allow delegating to a camera handler by setting a
`cameraDelegate` before using `image_picker`, such as in `main()`:

<?code-excerpt "readme_excerpts.dart (CameraDelegate)"?>

```dart
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
// ···
class MyCameraDelegate extends ImagePickerCameraDelegate {
  @override
  Future<XFile?> takePhoto(
      {ImagePickerCameraDelegateOptions options =
          const ImagePickerCameraDelegateOptions()}) async {
    return _takeAPhoto(options.preferredCameraDevice);
  }

  @override
  Future<XFile?> takeVideo(
      {ImagePickerCameraDelegateOptions options =
          const ImagePickerCameraDelegateOptions()}) async {
    return _takeAVideo(options.preferredCameraDevice);
  }
}
// ···
void setUpCameraDelegate() {
  final ImagePickerPlatform instance = ImagePickerPlatform.instance;
  if (instance is CameraDelegatingImagePickerPlatform) {
    instance.cameraDelegate = MyCameraDelegate();
  }
}
```

Once you have set a `cameraDelegate`, `image_picker` calls with
`ImageSource.camera` will work as normal, calling your provided delegate. We
encourage the community to build packages that implement
`ImagePickerCameraDelegate`, to provide options for desktop camera UI.

#### macOS installation

Since the macOS implementation uses `file_selector`, you will need to
add a filesystem access
[entitlement](https://flutter.dev/to/macos-entitlements):

```xml
  <key>com.apple.security.files.user-selected.read-only</key>
  <true/>
```

### Example

<?code-excerpt "readme_excerpts.dart (Pick)"?>

```dart
final ImagePicker picker = ImagePicker();
// Pick an image.
final XFile? image = await picker.pickImage(source: ImageSource.gallery);
// Capture a photo.
final XFile? photo = await picker.pickImage(source: ImageSource.camera);
// Pick a video.
final XFile? galleryVideo =
    await picker.pickVideo(source: ImageSource.gallery);
// Capture a video.
final XFile? cameraVideo = await picker.pickVideo(source: ImageSource.camera);
// Pick multiple images.
final List<XFile> images = await picker.pickMultiImage();
// Pick singe image or video.
final XFile? media = await picker.pickMedia();
// Pick multiple images and videos.
final List<XFile> medias = await picker.pickMultipleMedia();
```

## Migrating to 1.0

Starting with version 0.8.2 of the image_picker plugin, new methods were
added that return `XFile` instances (from the
[cross_file](https://pub.dev/packages/cross_file) package) rather than the
plugin's own `PickedFile` instances. The previous methods were supported through
0.8.9, and removed in 1.0.0.

#### Call the new methods

| Old API                                                      | New API                                                        |
| ------------------------------------------------------------ | -------------------------------------------------------------- |
| `PickedFile image = await _picker.getImage(...)`             | `XFile image = await _picker.pickImage(...)`                   |
| `List<PickedFile> images = await _picker.getMultiImage(...)` | `List<XFile> images = await _picker.pickMultiImage(...)`       |
| `PickedFile video = await _picker.getVideo(...)`             | `XFile video = await _picker.pickVideo(...)`                   |
| `LostData response = await _picker.getLostData()`            | `LostDataResponse response = await _picker.retrieveLostData()` |

````

[saver_gallery: ^3.0.6](https://pub.dev/packages/saver_gallery/example)


**Nota**: He desestimado gallery_saver porque lleva 2 años sin actualizar y me da problemas con otra dependencias, mientras que también está muy valorado saver_gallery (saver_gallery: ^3.0.6) que fue actualizado hace 42 días y este es su README

```markdown
---

# Saver Gallery

[![pub package](https://img.shields.io/pub/v/saver_gallery.svg)](https://pub.dartlang.org/packages/saver_gallery)
[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](https://choosealicense.com/licenses/mit/)

---

## Overview

The `saver_gallery` plugin enables you to save images and other media files (such as videos) directly to the Android and iOS gallery. While the `image_picker` plugin allows you to select images from the gallery, it does not support saving them back to the gallery. `saver_gallery` provides this essential functionality, making it easy to save media files in Flutter applications.

---

## Features

- Save images of various formats (`png`, `jpg`, `gif`, etc.) to the gallery.
- Save video and other media files to the gallery.
- Handle conditional saving with the `skipIfExists` parameter.
- Compatible with both Android and iOS platforms.

---

## Installation

To include `saver_gallery` in your project, add it as a dependency in your `pubspec.yaml` file:

```yaml
dependencies:
  saver_gallery: ^3.0.6
````

---

## iOS Configuration

If you are targeting iOS, ensure that your project is configured to use Swift. Add the following keys to your `Info.plist` file located at `<project_root>/ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need access to your photo library to save images.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to save images.</string>
```

**Explanation:**  
These keys provide descriptions for permission prompts shown to users when your app requests access to their photo library.

---

## Android Configuration

For Android, you need to handle storage permissions to save files to the gallery. Use the [`permission_handler`](https://pub.dev/packages/permission_handler) package to manage permissions.

### Required Permissions

Add the following permissions to your `AndroidManifest.xml` file:

```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" tools:ignore="ScopedStorage" />
<!-- Required if skipIfExists is set to true -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

### Handling Permissions

To handle permissions properly, use the `permission_handler` package. Depending on the Android SDK version, permissions requirements vary. Here's how you can implement permission handling:

```dart
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

Future<bool> checkAndRequestPermissions({required bool skipIfExists}) async {
  if (!Platform.isAndroid && !Platform.isIOS) {
    return false; // Only Android and iOS platforms are supported
  }

  if (Platform.isAndroid) {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = deviceInfo.version.sdkInt;

    if (skipIfExists) {
      // Read permission is required to check if the file already exists
      return sdkInt >= 33
          ? await Permission.photos.request().isGranted
          : await Permission.storage.request().isGranted;
    } else {
      // No read permission required for Android SDK 29 and above
      return sdkInt >= 29 ? true : await Permission.storage.request().isGranted;
    }
  } else if (Platform.isIOS) {
    // iOS permission for saving images to the gallery
    return skipIfExists
        ? await Permission.photos.request().isGranted
        : await Permission.photosAddOnly.request().isGranted;
  }

  return false; // Unsupported platforms
}
```

**Explanation:**

- **For Android:**

  - **SDK 29+**: Does not require read permission for writing files.
  - **SDK 33+**: Requires `Permission.photos` to check if a file exists.
  - **SDK < 29**: Requires `Permission.storage` for read and write operations.

- **For iOS:**
  - Uses `Permission.photos` to check if a file exists.
  - Uses `Permission.photosAddOnly` for saving files without needing full photo library access.

---

## Usage

### Saving an Image

To save an image (e.g., `png`, `jpg`, or `gif`) to the gallery from the internet:

```dart
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:saver_gallery/saver_gallery.dart';

_saveGif() async {
  var response = await Dio().get(
    "https://hyjdoc.oss-cn-beijing.aliyuncs.com/hyj-doc-flutter-demo-run.gif",
    options: Options(responseType: ResponseType.bytes),
  );

  String imageName = "test_image.gif";

  final result = await SaverGallery.saveImage(
    Uint8List.fromList(response.data),
    quality: 60,
    name: imageName,
    androidRelativePath: "Pictures/appName/images",
    skipIfExists: false,
  );

  print(result.toString());
  _showToast("$result");
}
```

**Explanation:**

- `quality`: Set the image quality (0-100) for compressing images. This only applies to `jpg` format.
- `name`: The name of the file being saved.
- `androidRelativePath`: Relative path in the Android gallery, e.g., `"Pictures/appName/images"`.
- `skipIfExists`: If `true`, skips saving the image if it already exists in the specified path.

---

### Saving a File (e.g., Video)

To save other types of files (e.g., videos) to the gallery:

```dart
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:saver_gallery/saver_gallery.dart';

_saveVideo() async {
  var tempDir = await getTemporaryDirectory();
  String videoPath = "${tempDir.path}/sample_video.mp4";

  await Dio().download(
    "http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4",
    videoPath,
  );

  final result = await SaverGallery.saveFile(
    file: videoPath,
    skipIfExists: true,
    name: 'sample_video.mp4',
    androidRelativePath: "Movies",
  );

  print(result);
}
```

**Explanation:**

- `file`: Path to the file being saved.
- `skipIfExists`: If `true`, skips saving the file if it already exists.
- `name`: Desired name of the file in the gallery.
- `androidRelativePath`: Relative path in the Android gallery, e.g., `"Movies"`.

---

## Additional Information

For more advanced usage and detailed API documentation, refer to the [official documentation](https://pub.dev/packages/saver_gallery).

---

## License

This project is licensed under the MIT License. For more details, see the [LICENSE](https://choosealicense.com/licenses/mit/) file.

---

````
Aquí tienes un ejemplo que tienen en su documentación

```dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Save image to gallery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Save image to gallery"),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              RepaintBoundary(
                key: _globalKey,
                child: Container(
                  width: 200,
                  height: 200,
                  color: Colors.red,
                ),
              ),
              Container(
                padding: EdgeInsets.only(top: 15),
                child: ElevatedButton(
                  onPressed: _saveScreen,
                  child: Text("Save Local Image"),
                ),
                width: 200,
                height: 44,
              ),
              Container(
                padding: EdgeInsets.only(top: 15),
                child: ElevatedButton(
                  onPressed: _getHttp,
                  child: Text("Save network image"),
                ),
                width: 200,
                height: 44,
              ),
              Container(
                padding: EdgeInsets.only(top: 15),
                child: ElevatedButton(
                  onPressed: _saveVideo,
                  child: Text("Save network video"),
                ),
                width: 200,
                height: 44,
              ),
              Container(
                padding: EdgeInsets.only(top: 15),
                child: ElevatedButton(
                  onPressed: _saveGif,
                  child: Text("Save Gif to gallery"),
                ),
                width: 200,
                height: 44,
              ),
            ],
          ),
        ));
  }

  _requestPermission() async {
    bool statuses;
    if (Platform.isAndroid) {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final deviceInfo = await deviceInfoPlugin.androidInfo;
      final sdkInt = deviceInfo.version.sdkInt;
      statuses =
          sdkInt < 29 ? await Permission.storage.request().isGranted : true;
      // statuses = await Permission.storage.request().isGranted;
    } else {
      statuses = await Permission.photosAddOnly.request().isGranted;
    }
    _toastInfo('requestPermission result: ${statuses}');
  }

  _saveScreen() async {
    RenderRepaintBoundary boundary =
        _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      String picturesPath = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final result = await SaverGallery.saveImage(byteData.buffer.asUint8List(),
          name: picturesPath, androidExistNotSave: false);
      debugPrint(result.toString());
      _toastInfo(result.toString());
    }
  }

  _getHttp() async {
    var response = await Dio().get(
        "https://ss0.baidu.com/94o3dSag_xI4khGko9WTAnF6hhy/image/h%3D300/sign=a62e824376d98d1069d40a31113eb807/838ba61ea8d3fd1fc9c7b6853a4e251f94ca5f46.jpg",
        options: Options(responseType: ResponseType.bytes));
    String picturesPath = "test_jpg.jpg";
    debugPrint(picturesPath);
    final result = await SaverGallery.saveImage(
        Uint8List.fromList(response.data),
        quality: 60,
        name: picturesPath,
        androidRelativePath: "Pictures/aa/bb",
        androidExistNotSave: true);
    debugPrint(result.toString());
    _toastInfo("$result");
  }

  _saveGif() async {
    var response = await Dio().get(
        "https://hyjdoc.oss-cn-beijing.aliyuncs.com/hyj-doc-flutter-demo-run.gif",
        options: Options(responseType: ResponseType.bytes));
    String picturesPath = "test_gif";
    debugPrint(picturesPath);
    final result = await SaverGallery.saveImage(
        Uint8List.fromList(response.data),
        quality: 60,
        name: picturesPath,
        androidRelativePath: "Pictures/appName/xx",
        androidExistNotSave: false);
    debugPrint(result.toString());
    _toastInfo("$result");
  }

  _saveVideo() async {
    final dir = await getTemporaryDirectory();
    String savePath =
        "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4";
    String fileUrl =
        "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4";
    await Dio().download(
      fileUrl,
      savePath,
      options: Options(
        sendTimeout: 10 * 60 * 1000,
        receiveTimeout: 10 * 60 * 1000,
      ),
      onReceiveProgress: (count, total) {
        debugPrint((count / total * 100).toStringAsFixed(0) + "%");
      },
    );
    final result = await SaverGallery.saveFile(file: savePath,androidExistNotSave: true, name: '123.mp4',androidRelativePath: "Movies");
    debugPrint(result.toString());
    _toastInfo("$result");
  }

  _toastInfo(String info) {
    Fluttertoast.showToast(msg: info, toastLength: Toast.LENGTH_LONG);
  }
}
````

¿Necesitas que te suminitre más información de mi proyecto o de estos paquetes u otros paquetes de Flutter?

**RECUERDA**:
El flujo que quiero que haga el usuario, si es posible hacerlo así es el siguiente, tanto para la foto como para el vídeo:

1. El usuario pulsa en la pantalla principal en "Captura con Ubicación".
2. Se abre la Cámara de image_picker para que el usuario pueda tomar una foto o grabar un vídeo.
3. El usuario pulsa el botón Aceptar o similar para aceptar la foto o vídeo que ha hecho en la Cámara de image_picker.
4. En la pantalla MediaLocationScreen se muestra la imagen como hasta ahora en el archivo media_location_screen.dart o si es un vídeo tendrá un visualizador de vídeos.
5. Añadirá los metadatos EXIT tal cual lo hace ahora a la imagen, y al vídeo también los añadirá.
6. La foto será guardada en la Galería de fotos de Android o en la App Fotos de iOS tal cual lo hace ahora, y el vídeo se guardará en la Galería de Android o Fotos de iOS con el paquete saver_gallery.

En resumen, lo que te pido es que me crees el flujo que quiero para el usuario tanto para las fotos como para los vídeos, si es posible de forma sencilla añadirle a los vídeos el texto de las coordenadas y la dirección en letra como en las fotos y además añadirle los metadatos EXIF. Entonces, en las fotos mantienes igual el código implementado en media_location_screen.dart, pues con total seguridad añade muy bien los metadatos EXIF a las fotos y la fotos las guarda perfectamente en la Galería de Android o en la App Fotos del iPhone, solamente cambiaría que en lugar de abrir la cámara nativa mediante image_picker, pues ahora la abriría con image_picker. Y sí tienes que añadir todas las funcionalidades que quiero para los vídeos (escribir texto en vídeo con coordenadas y dirección -si es posible-, añadir metadatos EXIF al mp4 -si es posible- y guardar el vídeo en la Galería de Android y en la App Fotos del iPhone). Entonces, para todo esto, actualízame el código en los archivos `lib/main.dart` y `lib/screens/media_location_screen.dart` para que solo tenga copiar y pegar en mi proyecto el código que me escribas. Y si tuviese que hacer algo más en otros archivos de mi proyecto también dime paso a paso lo que tengo que hacer para solo copiar y pegar.

## ASSISTANT MESSAGE

Aquí tienes el código actualizado para `lib/main.dart` y `lib/screens/media_location_screen.dart` que implementa las funcionalidades que deseas, incluyendo soporte para videos. También incluyo instrucciones paso a paso para cualquier cambio adicional que necesites hacer en otros archivos.

---

### **Archivo `lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:image_picker/image_picker.dart';
import 'screens/media_location_screen.dart';
import 'screens/parcel_map_screen.dart';

Future<void> main() async {
  _setupLogging();

  try {
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
            backgroundColor:
                MaterialStateProperty.all(const Color(0xFF388E3C)), // Dark green
            foregroundColor:
                MaterialStateProperty.all(const Color(0xFFFFFFFF)), // White
            textStyle: MaterialStateProperty.all(
              const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            padding: MaterialStateProperty.all(
              const EdgeInsets.all(16),
            ),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            shadowColor: MaterialStateProperty.all(Colors.black54),
            elevation: MaterialStateProperty.all(4),
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
      backgroundColor: const Color(0xFFE6E6E6), // Light gray
      appBar: AppBar(
        title: Text(
          'T3 AI Sat',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1976D2), // Navy blue
            shadows: [
              Shadow(
                blurRadius: 3.0,
                color:
                    Colors.black.withOpacity(0.25), // Light shadow behind title
                offset: const Offset(0, 2.0),
              ),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFE6E6E6), // Light gray
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: () async {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ListTile(
                            leading: const Icon(Icons.photo_camera),
                            title: const Text('Tomar Foto'),
                            onTap: () async {
                              Navigator.pop(context);
                              final ImagePicker picker = ImagePicker();
                              final XFile? photo =
                                  await picker.pickImage(source: ImageSource.camera);
                              if (photo != null && context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MediaLocationScreen(
                                      mediaPath: photo.path,
                                      isVideo: false,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.videocam),
                            title: const Text('Grabar Video'),
                            onTap: () async {
                              Navigator.pop(context);
                              final ImagePicker picker = ImagePicker();
                              final XFile? video =
                                  await picker.pickVideo(source: ImageSource.camera);
                              if (video != null && context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MediaLocationScreen(
                                      mediaPath: video.path,
                                      isVideo: true,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.cancel),
                            title: const Text('Cancelar'),
                            onTap: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: const Text('Captura con Ubicación'),
            ),
            const SizedBox(height: 40),
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
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
```

---

### **Archivo `lib/screens/media_location_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:native_exif/native_exif.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:video_player/video_player.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:flutter/cupertino.dart';

class MediaLocationScreen extends StatefulWidget {
  final String mediaPath;
  final bool isVideo;

  const MediaLocationScreen({super.key, required this.mediaPath, required this.isVideo});

  @override
  MediaLocationScreenState createState() => MediaLocationScreenState();
}

class MediaLocationScreenState extends State<MediaLocationScreen> {
  Position? _currentPosition;
  String? _address;
  final Logger log = Logger('MediaLocationScreen');
  String? _updatedMediaPath;
  bool _isLoading = true;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      log.severe('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        log.severe('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      log.severe('Location permissions are permanently denied');
      return;
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      log.info('Current position: $_currentPosition');

      await _getAddressFromCoordinates(
          _currentPosition!.latitude, _currentPosition!.longitude);

      if (widget.isVideo) {
        await _overlayTextOnVideoAndSaveToGallery(widget.mediaPath);
        if (_updatedMediaPath != null) {
          _videoController = VideoPlayerController.file(File(_updatedMediaPath!))
            ..initialize().then((_) {
              setState(() {});
            });
        }
      } else {
        await _writeTextOnImageAndSaveToGallery(widget.mediaPath);
      }
    } catch (e) {
      log.severe('Failed to obtain location or process media: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getAddressFromCoordinates(double lat, double lon) async {
    final accessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'];
    final url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$lon,$lat.json?access_token=$accessToken';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'].isNotEmpty) {
          setState(() {
            final addressParts = data['features'][0]['place_name'].split(',');
            _address =
                "${addressParts[0].trim()}\n${addressParts[1].trim()}\n${addressParts[2].trim()}";
          });
          log.info('Address: $_address');
        }
      } else {
        log.severe('Failed to get address from coordinates');
      }
    } catch (e) {
      log.severe('Error fetching address: $e');
    }
  }

  String _convertToDMS(double decimal) {
    final degrees = decimal.truncate();
    final minutes = ((decimal - degrees) * 60).truncate();
    final seconds = (((decimal - degrees) * 60) - minutes) * 60;

    return '${degrees.abs()}°${minutes.abs()}\'${seconds.abs().toStringAsFixed(2)}" ${decimal >= 0 ? (decimal == _currentPosition!.latitude ? 'N' : 'E') : (decimal == _currentPosition!.latitude ? 'S' : 'W')}';
  }

  Future<void> _addExifData(String imagePath) async {
    try {
      final exif = await Exif.fromPath(imagePath);

      if (_currentPosition != null) {
        await exif.writeAttributes({
          'GPSLatitude': _currentPosition!.latitude.toString(),
          'GPSLongitude': _currentPosition!.longitude.toString(),
        });
      }

      final now = DateTime.now().toUtc();
      await exif.writeAttributes({
        'GPSDateStamp': DateFormat('yyyy:MM:dd').format(now),
        'GPSTimeStamp': DateFormat('HH:mm:ss').format(now),
      });

      await exif.writeAttributes({
        'DateTimeOriginal':
            DateFormat('yyyy:MM:dd HH:mm:ss').format(DateTime.now()),
        'UserComment':
            't3AI-SAT App. Dirección en la que fue tomada la foto: ${_address ?? 'Sin dirección'}',
        'ProfileDescription': 'sRGB',
        'ColorSpace': '1',
      });

      await exif.close();
    } catch (e) {
      log.severe('Error writing EXIF data: $e');
    }
  }

  Future<String> _getExternalStoragePath() async {
    Directory? externalDir = Directory('/storage/emulated/0/DCIM/Camera');
    if (await externalDir.exists()) {
      return externalDir.path;
    } else {
      externalDir.create(recursive: true);
      return externalDir.path;
    }
  }

  Future<void> _writeTextOnImageAndSaveToGallery(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final img.Image originalImage = img.decodeImage(bytes)!;

      final fontData = await rootBundle
          .load('assets/fonts/roboto_black/Roboto-Black_100_size_white_color.ttf.zip');
      final font = img.BitmapFont.fromZip(fontData.buffer.asUint8List());

      final latitudeDMS = _convertToDMS(_currentPosition!.latitude);
      final longitudeDMS = _convertToDMS(_currentPosition!.longitude);

      final now = DateTime.now();
      final timeZoneName = now.timeZoneName;

      final networkTime = now.add(const Duration(seconds: 1));

      final formattedNetworkTime =
          '${DateFormat('dd MMM yyyy HH:mm:ss').format(networkTime)} $timeZoneName';
      final formattedLocalTime =
          '${DateFormat('dd MMM yyyy HH:mm:ss').format(now)} $timeZoneName';

      final formattedLocation = 'Lat: $latitudeDMS\nLon: $longitudeDMS';
      log.info('Formatted location: $formattedLocation');

      final formattedAddress = _address?.split(',').join('\n');

      final formattedText = '''
Network: $formattedNetworkTime
Local: $formattedLocalTime
$latitudeDMS $longitudeDMS
$formattedAddress
''';

      final updatedImage = img.drawString(
        originalImage,
        formattedText,
        font: font,
        x: 60,
        y: originalImage.height - 850,
        color: img.ColorRgba8(255, 255, 255, 255),
      );

      final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(now);

      String updatedImagePath;

      if (Platform.isAndroid) {
        final externalStoragePath = await _getExternalStoragePath();
        updatedImagePath = path.join(
          externalStoragePath,
          't3aisat_$formattedDate.jpg',
        );
      } else if (Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        updatedImagePath = path.join(
          directory.path,
          't3aisat_$formattedDate.jpg',
        );
      } else {
        log.severe('Unsupported platform');
        return;
      }

      final updatedImageFile = File(updatedImagePath);
      log.info('Updated image path: $updatedImagePath');
      log.info('Updated image file path: ${updatedImageFile.path}');

      await updatedImageFile.writeAsBytes(img.encodeJpg(updatedImage));

      if (await updatedImageFile.exists()) {
        log.info('File created successfully: ${updatedImageFile.path}');
      } else {
        log.severe('File not created: ${updatedImageFile.path}');
        return;
      }

      await _addExifData(updatedImageFile.path);

      var status = await Permission.photos.status;
      if (!status.isGranted) {
        status = await Permission.photos.request();
      }

      if (status.isGranted) {
        if (Platform.isAndroid) {
          final result = await SaverGallery.saveFile(
            file: updatedImageFile.path,
            name: path.basename(updatedImageFile.path),
            androidRelativePath: 'Pictures/T3AISat',
            skipIfExists: false,
          );
          log.info('Updated image saved to gallery on Android: $result');
        } else if (Platform.isIOS) {
          await _saveImageToGalleryWithExifIOS(updatedImagePath);
          log.info('Updated image saved to gallery on iOS');
        }
      } else {
        log.severe('Permission denied to access photos');
      }

      setState(() {
        _updatedMediaPath = updatedImagePath;
      });
    } catch (e) {
      log.severe('Failed to process image: $e');
    }
  }

  Future<void> _saveImageToGalleryWithExifIOS(String imagePath) async {
    try {
      const platform = MethodChannel('com.t3aisat/save_to_gallery');
      await platform
          .invokeMethod('saveImageWithExif', {'imagePath': imagePath});
      log.info('Updated image saved to gallery on iOS');
    } catch (e) {
      log.severe(
          'Failed to save image to gallery on iOS with EXIF metadata: $e');
    }
  }

  Future<void> _overlayTextOnVideoAndSaveToGallery(String videoPath) async {
    try {
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(now);
      String outputVideoPath;

      if (Platform.isAndroid) {
        final externalStoragePath = await _getExternalStoragePath();
        outputVideoPath = path.join(
          externalStoragePath,
          't3aisat_$formattedDate.mp4',
        );
      } else if (Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        outputVideoPath = path.join(
          directory.path,
          't3aisat_$formattedDate.mp4',
        );
      } else {
        log.severe('Unsupported platform');
        return;
      }

      final latitudeDMS = _convertToDMS(_currentPosition!.latitude);
      final longitudeDMS = _convertToDMS(_currentPosition!.longitude);

      final formattedAddress = _address?.split(',').join('\n') ?? '';
      final formattedText = '''
Lat: $latitudeDMS
Lon: $longitudeDMS
$formattedAddress
''';

      final tempDir = await getTemporaryDirectory();
      final textFile = File('${tempDir.path}/overlay.txt');
      await textFile.writeAsString(formattedText);

      final fontData =
          await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final fontFile = File('${tempDir.path}/Roboto-Regular.ttf');
      await fontFile.writeAsBytes(fontData.buffer.asUint8List());

      final ffmpegCommand = '''
-i "$videoPath" -vf "drawtext=textfile='${textFile.path}':fontfile='${fontFile.path}':fontcolor=white:fontsize=24:x=(w-text_w)/2:y=(h-text_h)-50" -metadata comment="Coordinates: $latitudeDMS, $longitudeDMS; Address: ${_address ?? ''}" -codec:a copy "$outputVideoPath"
''';

      log.info('Running FFmpeg command: $ffmpegCommand');

      final session = await FFmpegKit.execute(ffmpegCommand);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        log.info('Video processed successfully: $outputVideoPath');
      } else {
        final logs = await session.getAllLogsAsString();
        final failStackTrace = await session.getFailStackTrace();
        log.severe('Failed to process video');
        log.severe('FFmpeg logs: $logs');
        log.severe('FFmpeg fail stack trace: $failStackTrace');
        return;
      }

      var status = await Permission.photos.status;
      if (!status.isGranted) {
        status = await Permission.photos.request();
      }

      if (status.isGranted) {
        final result = await SaverGallery.saveFile(
          file: outputVideoPath,
          name: path.basename(outputVideoPath),
          androidRelativePath: 'Movies/T3AISat',
          skipIfExists: false,
        );
        log.info('Video saved to gallery: $result');
      } else {
        log.severe('Permission denied to access photos');
      }

      setState(() {
        _updatedMediaPath = outputVideoPath;
      });
    } catch (e) {
      log.severe('Failed to process video: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoPosición',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1976D2),
            )),
        backgroundColor: const Color(0xFFE6E6E6),
        foregroundColor: const Color(0xFF1976D2),
        elevation: 0,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(
                color: Color(0xFF1976D2),
              )
            : Column(
                children: [
                  if (_updatedMediaPath != null)
                    Expanded(
                      child: widget.isVideo
                          ? _videoController != null &&
                                  _videoController!.value.isInitialized
                              ? AspectRatio(
                                  aspectRatio:
                                      _videoController!.value.aspectRatio,
                                  child: VideoPlayer(_videoController!),
                                )
                              : const Center(child: CircularProgressIndicator())
                          : Image.file(
                              File(_updatedMediaPath!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                    ),
                  const SizedBox(height: 20),
                  if (_currentPosition != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFF388E3C),
                            size: 30,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Latitud: ${_currentPosition?.latitude}\nLongitud: ${_currentPosition?.longitude}',
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 16,
                                  color: Color(0xFF424242)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_address != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.home,
                            color: Color(0xFF388E3C),
                            size: 30,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$_address',
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 16,
                                  color: Color(0xFF424242)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
      ),
      floatingActionButton: widget.isVideo && _videoController != null
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                });
              },
              child: Icon(
                _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
}
```

---

### **Cambios adicionales en otros archivos**

#### **1. `pubspec.yaml`**

Agrega las siguientes dependencias a tu archivo `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  # Otras dependencias existentes
  saver_gallery: ^3.0.6
  ffmpeg_kit_flutter: ^4.5.1
  video_player: ^2.5.0
  permission_handler: ^11.3.1
```

Asegúrate también de agregar el archivo de fuente (fuente) que utilizaremos para superponer texto en el video. Incluye el archivo de fuente en tu carpeta `assets/fonts` y actualiza la sección `assets`:

```yaml
flutter:
  assets:
    - assets/fonts/Roboto-Regular.ttf
```

#### **2. Agregar el archivo de fuente**

Crea una carpeta `assets/fonts` en tu proyecto y coloca allí el archivo `Roboto-Regular.ttf`. Puedes descargar esta fuente desde [Google Fonts](https://fonts.google.com/specimen/Roboto).

#### **3. Permisos en Android e iOS**

Ya que utilizas `permission_handler` y `saver_gallery`, asegúrate de que los permisos necesarios estén configurados:

- **Android**: Tu archivo `AndroidManifest.xml` ya parece tener los permisos necesarios.
- **iOS**: Asegúrate de que tu `Info.plist` contenga las claves necesarias para acceder a la galería y la ubicación, lo cual ya está incluido según tu descripción.

#### **4. Configuración de FFmpeg**

Es posible que necesites agregar configuraciones adicionales para `ffmpeg_kit_flutter`. Sigue estos pasos:

- **Android**:

  - Agrega el siguiente código en `android/app/build.gradle` dentro de `android { ... }`:

    ```groovy
    packagingOptions {
        pickFirst 'lib/x86/libc++_shared.so'
        pickFirst 'lib/x86_64/libjsc.so'
        pickFirst 'lib/arm64-v8a/libc++_shared.so'
        pickFirst 'lib/armeabi-v7a/libc++_shared.so'
    }
    ```

- **iOS**:

  - En el archivo `ios/Podfile`, asegúrate de tener:

    ```ruby
    platform :ios, '11.0'
    use_frameworks!
    ```

#### **5. Solicitar Permisos**

Antes de guardar en la galería, se solicitan los permisos necesarios utilizando `permission_handler` en el código proporcionado.

---

### **Notas adicionales**

- **Superposición de texto en video**: La superposición de texto en videos es más compleja y requiere el uso de FFmpeg. El comando utilizado en el código puede necesitar ajustes dependiendo de tus requerimientos específicos. Asegúrate de probarlo y ajustar los parámetros como la posición (`x` y `y`), tamaño de fuente (`fontsize`), y color (`fontcolor`).

- **Metadatos en videos**: Añadir metadatos a archivos MP4 es limitado y no tan estándar como en imágenes. El código proporcionado añade un campo `comment` utilizando FFmpeg, pero la disponibilidad y visibilidad de este metadato puede variar según el reproductor de video utilizado.

- **Reproductor de video**: Se utiliza el paquete `video_player` para reproducir el video en la pantalla. Se ha añadido un `FloatingActionButton` para reproducir y pausar el video.

- **Actualización de paquetes**: Asegúrate de ejecutar `flutter pub get` después de actualizar tu `pubspec.yaml` para instalar las nuevas dependencias.

- **Pruebas**: Dado que el procesamiento de video puede ser intensivo y propenso a errores, te recomiendo probar la funcionalidad en diferentes dispositivos y escenarios para asegurar que todo funcione correctamente.

---

Espero que esta actualización cumpla con tus requisitos. Si necesitas más asistencia o tienes preguntas adicionales, no dudes en preguntar.
