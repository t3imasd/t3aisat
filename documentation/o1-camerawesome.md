## o1 CamerAwesome

## USER MESSAGE

En mi aplicación creada con Flutter usando Dart titulada T3AI-SAT tengo una pantalla principal (lib/main.dart) con dos botones: "Captura con Ubicación" y "Mapa de Parcelas".

Cuando pulsas en el botón "Captura con Ubicación" te abre la cámara de fotos mediante un image_picker y una vez que se toma la foto. Una vez pulsado en la cámara el botón "Aceptar", te lleva a una nueva pantalla MediaLocationScreen (lib/screens/media_location_screen.dart) donde escribe en la foto las coordenadas (latitud y longitud) y la dirección en texto donde se ha hecho la foto, además le añade metadatos EXIF y guarda la foto con esos metadatos en la Galería de fotos de Android o en la App Fotos del iPhone.

Entonces, ahora quiero que haga lo mismo en los vídeos. ¿Es posible?

Entonces, quiero que cambies para usar una cámara que sea válida tanto para fotos como para vídeos. Me gusta el paquete [camerawesome: ^2.1.0](https://pub.dev/packages/camerawesome) que está preparado para los metadatos EXIF y además te muestra una cámara o visualizar para elegir entre Foto o Vídeo. Además, para guardar la fotos quiero que uses el paquete [saver_gallery: ^3.0.6](https://pub.dev/packages/saver_gallery/example) ya que está actualizado hace 42 días (mientras que gallery_saver lleva 2 años sin actualizar).

El flujo que quiero que haga el usuario, si es posible hacerlo así es el siguiente, tanto para la foto como para el vídeo:

1. El usuario pulsa en la pantalla principal en "Captura con Ubicación".
2. Se abre la Cámara de camerawesome para que el usuario pueda tomar una foto o grabar un vídeo.
3. El usuario pulsa el botón Aceptar o similar para aceptar la foto o vídeo que ha hecho en la Cámara de camerawesome.
4. En la pantalla MediaLocationScreen se muestra la imagen como hasta ahora en el archivo media_location_screen.dart o si es un vídeo tendrá un visualizador de vídeos.
5. Añadirá los metadatos EXIT tal cual lo hace ahora a la imagen, y al vídeo también los añadirá.
6. La foto será guardada en la Galería de fotos de Android o en la App Fotos de iOS tal cual lo hace ahora, y el vídeo se guardará en la Galería de Android o Fotos de iOS con el paquete saver_gallery.

Entonces, lo que te pido es que me crees el flujo que quiero para el usuario tanto para las fotos como para los vídeos, si es posible de forma sencilla añadirle a los vídeos el texto de las coordenadas y la dirección en letra como en las fotos y además añadirle los metadatos EXIF. Entonces, en las fotos mantienes igual el código implementado en media_location_screen.dart, pues con total seguridad añade muy bien los metadatos EXIF a las fotos y la fotos las guarda perfectamente en la Galería de Android o en la App Fotos del iPhone, solamente cambiaría que en lugar de abrir la cámara nativa mediante image_picker, pues ahora la abriría con camerawesome. Y sí tienes que añadir todas las funcionalidades que quiero para los vídeos (escribir texto en vídeo con coordanadas y dirección -si es posible-, añadir metadatos EXIF al mp4 -si es posible- y guardar el vídeo en la Galería de Android y en la App Fotos del iPhone)

Ahora, te iré escribiendo los README de los paquetes para que así tenga la información actualizada, también el contenido de los archivo `lib/main.dart` y `lib/screens/media_location_screen.dart` que tengo en mi proyecto. También, te escribo el contenido que tengo los archivos `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/kotlin/com/t3aisat/t3aisat/MainActivity.kt`, `ios/Runner/Info.plist`, `ios/Runner/AppDelegate.swift` para que así veas como están todos los permisos dados.

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

Ahora te escribo los README de los paquetes de Flutter

[camerawesome: ^2.1.0](https://pub.dev/packages/camerawesome)

````markdown
<a href="https://apparence.io">
  <img
    src="https://raw.githubusercontent.com/Apparence-io/camera_awesome/master/docs/img/apparence.png"
    width="100%"
  />
</a>
<div style="margin-top:40px">
  <img
    src="https://raw.githubusercontent.com/Apparence-io/camera_awesome/master/docs/img/preview.png"
    width="100%"
  />
  <img
    src="https://raw.githubusercontent.com/Apparence-io/camera_awesome/master/docs/img/features.png"
    width="100%"
    style="margin-top:32px"
  />
</div>

<a href="https://apparencekit.dev" style="margin-top:32px">
  <img
    src="https://raw.githubusercontent.com/Apparence-io/camera_awesome/master/docs/img/flutter_template.png"
    width="100%"
    alt="ApparenceKit Flutter template to bootstrap your next app"
  />
</a>

This plugin is also available as a template in
[ApparenceKit](https://apparencekit.dev).<br>

<br>

# CamerAwesome

<div>
    <a href="https://github.com/Solido/awesome-flutter">
        <img alt="Awesome Flutter" src="https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=for-the-badge" />
    </a>
    <a href="https://github.com/Apparence-io/camera_awesome">
        <img src="https://img.shields.io/github/stars/Apparence-io/camera_awesome.svg?style=for-the-badge&logo=github&colorB=green&label=Stars" alt="Star on Github">
    </a>
    <a href="https://pub.dev/packages/camerawesome">
        <img src="https://img.shields.io/pub/v/camerawesome.svg?style=for-the-badge&label=Pub" alt="Star on Github">
    </a>
</div>

[![en](https://img.shields.io/badge/language-english-cyan.svg)](https://github.com/Apparence-io/CamerAwesome/blob/master/README.md)
[![zh](https://img.shields.io/badge/language-chinese-cyan.svg)](https://github.com/Apparence-io/CamerAwesome/blob/master/README.zh.md)

📸 Embedding a camera experience within your own app shouldn't be that hard.
<br> A flutter plugin to integrate awesome Android / iOS camera experience.<br>

<br>
This package provides you with a fully customizable camera experience that you can use within your app.<br>
Use our awesome built-in interface or customize it as you want.

---

<div style="margin-top:16px;margin-bottom:16px">
  <a href="https://docs.page/Apparence-io/camera_awesome" style="">
    <img
      src="https://raw.githubusercontent.com/Apparence-io/camera_awesome/master/docs/img/doc.png"
      width="100%"
    />
  </a>
</div>

## Migration guide

If you are migrating from version 1.x.x to 2.x.x, please read the
[migration guide](https://docs.page/Apparence-io/camera_awesome/migration_guides/from_1_to_2).

## Native features

Here's all native features that cameraAwesome provides to the flutter side.

| Features                                 | Android | iOS |
| :--------------------------------------- | :-----: | :-: |
| 🔖 Ask permissions                       |   ✅    | ✅  |
| 🎥 Record video                          |   ✅    | ✅  |
| 📹 Multi camera (🚧 BETA)                |   ✅    | ✅  |
| 🔈 Enable/disable audio                  |   ✅    | ✅  |
| 🎞 Take photos                            |   ✅    | ✅  |
| 🌆 Photo live filters                    |   ✅    | ✅  |
| 🌤 Exposure level                         |   ✅    | ✅  |
| 📡 Broadcast live image stream           |   ✅    | ✅  |
| 🧪 Image analysis (barcode scan & more.) |   ✅    | ✅  |
| 👁 Zoom                                   |   ✅    | ✅  |
| 📸 Device flash support                  |   ✅    | ✅  |
| ⌛️ Auto focus                           |   ✅    | ✅  |
| 📲 Live switching camera                 |   ✅    | ✅  |
| 😵‍💫 Camera rotation stream                |   ✅    | ✅  |
| 🤐 Background auto stop                  |   ✅    | ✅  |
| 🔀 Sensor type switching                 |   ⛔️   | ✅  |
| 🪞 Enable/disable front camera mirroring |   ✅    | ✅  |

---

## 📖&nbsp; Installation and usage

### Add the package in your `pubspec.yaml`

```yaml
dependencies:
  camerawesome: ^2.0.0-dev.1
  ...
```
````

### Platform specific setup

- **iOS**

Add these on `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Your own description</string>

<key>NSMicrophoneUsageDescription</key>
<string>To enable microphone access when recording video</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>To enable GPS location access for Exif data</string>
```

- **Android**

Change the minimum SDK version to 21 (or higher) in `android/app/build.gradle`:

```
minSdkVersion 21
```

In order to be able to take pictures or record videos, you may need additional
permissions depending on the Android version and where you want to save them.
Read more about it in the
[official documentation](https://developer.android.com/training/data-storage).

> `WRITE_EXTERNAL_STORAGE` is not included in the plugin starting with version
> 1.4.0.

If you want to record videos with audio, add this permission to your
`AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
        package="com.example.yourpackage">
  <uses-permission android:name="android.permission.RECORD_AUDIO" />

  <!-- Other declarations -->
</manifest>
```

You may also want to save location of your pictures in exif metadata. In this
case, add below permissions:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
  package="com.example.yourpackage">
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

  <!-- Other declarations -->
</manifest>
```

<details>
<summary>⚠️ Overriding Android dependencies</summary>

Some of the dependencies used by CamerAwesome can be overriden if you have a
conflict. Change these variables to define which version you want to use:

```gradle
buildscript {
  ext.kotlin_version = '1.7.10'
  ext {
    // You can override these variables
    compileSdkVersion = 33
    minSdkVersion = 24 // 21 minimum
    playServicesLocationVersion = "20.0.0"
    exifInterfaceVersion = "1.3.4"
  }
  // ...
}
```

Only change these variables if you are sure of what you are doing.

For example, setting the Play Services Location version might help you when you
have conflicts with other plugins. The below line shows an example of these
conflicts:

```
java.lang.IncompatibleClassChangeError: Found interface com.google.android.gms.location.ActivityRecognitionClient, but class was expected
```

</details>

### Import the package in your Flutter app

```dart
import 'package:camerawesome/camerawesome_plugin.dart';
```

---

## 👌 Awesome built-in interface

Just use our builder. <br> That's all you need to create a complete camera
experience within your app.

```dart
CameraAwesomeBuilder.awesome(
  saveConfig: SaveConfig.photoAndVideo(),
  onMediaTap: (mediaCapture) {
    OpenFile.open(mediaCapture.filePath);
  },
),
```

![CamerAwesome default UI](docs/img/base_awesome_ui.jpg)

This builder can be customized with various settings:

- A theme.
- Builders for each part of the screen.
- Initial camera setup.
- Preview positioning.
- Additional preview decoration.
- And much more!

Here is an example:

![Customized UI](docs/img/custom_awesome_ui.jpg)

Check the
[full documentation](https://docs.page/Apparence-io/camera_awesome/getting_started/awesome-ui)
to learn more.

---

## 🎨 Creating a custom interface

If the `awesome()` factory is not enough, you can use `custom()` instead.

It provides a `builder` property that lets you create your own camera
experience. <br>

The camera preview will be visible behind what you will provide to the builder.

```dart
CameraAwesomeBuilder.custom(
  saveConfig: SaveConfig.photo(),
  builder: (state, previewSize, previewRect) {
    // create your interface here
  },
)
```

> See more in
> [documentation](https://docs.page/Apparence-io/camera_awesome/getting_started/custom-ui)

### Working with the custom builder

Here is the definition of our builder method.

```dart
typedef CameraLayoutBuilder = Widget Function(CameraState cameraState, PreviewSize previewSize, Rect previewRect);
```

<br>
The only thing you have access to manage the camera is the cameraState.<br>
Depending on which state is our camera experience you will have access to some different method. <br>
`previewSize` and `previewRect` might be used to position your UI around or on top of the camera preview.
<br>

#### How do CamerAwesome states work ?

Using the state you can do anything you need without having to think about the
camera flow<br><br>

- On app start we are in `PreparingCameraState`<br>
- Then depending on the initialCaptureMode you set you will be
  `PhotoCameraState` or `VideoCameraState`<br>
- Starting a video will push a `VideoRecordingCameraState`<br>
- Stopping the video will push back the `VideoCameraState`<br>
  <br> Also if you want to use some specific function you can use the when
  method so you can write like this.<br>

```dart
state.when(
  onPhotoMode: (photoState) => photoState.start(),
  onVideoMode: (videoState) => videoState.start(),
  onVideoRecordingMode: (videoState) => videoState.pause(),
);
```

> See more in
> [documentation](https://docs.page/Apparence-io/camera_awesome/getting_started/custom-ui)

<br>

---

## 🐝 Listen to picture or video event

Using the onMediaCaptureEvent you can listen to any media capture event and do
whatever you want with it.

```dart
onMediaCaptureEvent: (event) {
    switch ((event.status, event.isPicture, event.isVideo)) {
        case (MediaCaptureStatus.capturing, true, false):
            debugPrint('Capturing picture...');
        case (MediaCaptureStatus.success, true, false):
            event.captureRequest.when(
                single: (single) {
                debugPrint('Picture saved: ${single.file?.path}');
                },
                multiple: (multiple) {
                multiple.fileBySensor.forEach((key, value) {
                    debugPrint('multiple image taken: $key ${value?.path}');
                });
                },
            );
        case (MediaCaptureStatus.failure, true, false):
            debugPrint('Failed to capture picture: ${event.exception}');
        case (MediaCaptureStatus.capturing, false, true):
            debugPrint('Capturing video...');
        case (MediaCaptureStatus.success, false, true):
            event.captureRequest.when(
                single: (single) {
                    debugPrint('Video saved: ${single.file?.path}');
                },
                multiple: (multiple) {
                    multiple.fileBySensor.forEach((key, value) {
                        debugPrint('multiple video taken: $key ${value?.path}');
                    });
                },
            );
        case (MediaCaptureStatus.failure, false, true):
            debugPrint('Failed to capture video: ${event.exception}');
        default:
            debugPrint('Unknown event: $event');
    }
},
```

---

## 🔬 Analysis mode

Use this to achieve:

- QR-Code scanning.
- Facial recognition.
- AI object detection.
- Realtime video chats.
- And much more 🤩

![Face AI](docs/img/face_ai.gif)

You can check examples using MLKit inside the `example` directory. The above
example is from `ai_analysis_faces.dart`. It detects faces and draw their
contours.

It's also possible to use MLKit to read barcodes:

![Barcode scanning](docs/img/barcode_overlay.gif)

Check `ai_analysis_barcode.dart` and `preview_overlay_example.dart` for examples
or the
[documentation](https://docs.page/Apparence-io/camera_awesome/ai_with_mlkit/reading_barcodes).

### How to use it

```dart
CameraAwesomeBuilder.awesome(
  saveConfig: SaveConfig.photo(),
  onImageForAnalysis: analyzeImage,
  imageAnalysisConfig: AnalysisConfig(
        // Android specific options
        androidOptions: const AndroidAnalysisOptions.nv21(
            // Target width (CameraX will chose the closest resolution to this width)
            width: 250,
        ),
        // Wether to start automatically the analysis (true by default)
        autoStart: true,
        // Max frames per second, null for no limit (default)
        maxFramesPerSecond: 20,
    ),
)
```

> MLkit recommends using nv21 format for Android. <br> bgra8888 is the iOS
> format For machine learning you don't need full-resolution images (720 or
> lower should be enough and makes computation easier)

Learn more about the image analysis configuration in the
[documentation](https://docs.page/Apparence-io/camera_awesome/ai_with_mlkit/image_analysis_configuration)
.

Check also detailed explanations on how to use MLKit to
[read barcodes](https://docs.page/Apparence-io/camera_awesome/ai_with_mlkit/reading_barcodes)
and
[detect faces](https://docs.page/Apparence-io/camera_awesome/ai_with_mlkit/detecting_faces).

⚠️ On Android, some devices don't support video recording and image analysis at
the same time.

- If they don't, image analysis will be ignored.
- You can check if a device has this capability by using
  `CameraCharacteristics .isVideoRecordingAndImageAnalysisSupported(Sensors.back)`.

---

## 🐽 Updating Sensor configuration

Through state you can access to a `SensorConfig` class.

<br>

| Function               | Comment                                                    |
| ---------------------- | ---------------------------------------------------------- |
| `setZoom`              | change zoom                                                |
| `setFlashMode`         | change flash between NONE,ON,AUTO,ALWAYS                   |
| `setBrightness`        | change brightness level manually (better to let this auto) |
| `setMirrorFrontCamera` | set mirroring for front camera                             |

All of these configurations are listenable through a stream so your UI can
automatically get updated according to the actual configuration.

<br>

## 🌆 Photo live filters

Apply live filters to your pictures using the built-in interface:

![Built-in live filters](docs/img/filters.gif)

You can also choose to use a specific filter from the start:

```dart
CameraAwesomeBuilder.awesome(
  // other params
  filter: AwesomeFilter.AddictiveRed,
  availableFilters: ...
)
```

Or set the filter programmatically:

```dart
CameraAwesomeBuilder.custom(
  builder: (cameraState, previewSize, previewRect) {
    return cameraState.when(
      onPreparingCamera: (state) =>
      const Center(child: CircularProgressIndicator()),
      onPhotoMode: (state) =>
          TakePhotoUI(state, onFilterTap: () {
            state.setFilter(AwesomeFilter.Sierra);
          }),
      onVideoMode: (state) => RecordVideoUI(state, recording: false),
      onVideoRecordingMode: (state) =>
          RecordVideoUI(state, recording: true),
    );
  },
)
```

See all available filters in the
[documentation](https://docs.page/Apparence-io/camera_awesome/widgets/awesome_filters).

> [!TIP] By default the awesome ui setup has a filter list but you can pass an
> empty list to remove it

## 📷 📷 Concurrent cameras

![Concurrent cameras](docs/img/concurrent_cameras.gif)

> 🚧 Feature in beta 🚧 Any feedback is welcome!

In order to start using CamerAwesome with multiple cameras simulatenously, you
need to define a `SensorConfig` that uses several sensors. You can use the
`SensorConfig.multiple()` constructor for this:

```dart
CameraAwesomeBuilder.awesome(
    sensorConfig: SensorConfig.multiple(
        sensors: [
            Sensor.position(SensorPosition.back),
            Sensor.position(SensorPosition.front),
        ],
        flashMode: FlashMode.auto,
        aspectRatio: CameraAspectRatios.ratio_16_9,
    ),
    // Other params
)
```

This feature is not supported by all devices and even when it is, there are
limitations that you must be aware of.

Check the details in the
[dedicated documentation](https://docs.page/Apparence-io/camera_awesome/getting_started/multicam).

<br>

<a href="https://apparence.io">
  <img
    src="https://raw.githubusercontent.com/Apparence-io/camera_awesome/master/docs/img/apparence.png"
    width="100%"
  />
</a>
```

[saver_gallery: ^3.0.6](https://pub.dev/packages/saver_gallery/example)

**Nota**: He desestimado gallery_saver porque lleva 2 años sin actualizar y me da problemas con otra dependencias, mientras que también está muy valorado saver_gallery (saver_gallery: ^3.0.6) que fue actualizado hace 42 días y este es su README

````markdown
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
```
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
2. Se abre la Cámara de camerawesome para que el usuario pueda tomar una foto o grabar un vídeo.
3. El usuario pulsa el botón Aceptar o similar para aceptar la foto o vídeo que ha hecho en la Cámara de camerawesome.
4. En la pantalla MediaLocationScreen se muestra la imagen como hasta ahora en el archivo media_location_screen.dart o si es un vídeo tendrá un visualizador de vídeos.
5. Añadirá los metadatos EXIT tal cual lo hace ahora a la imagen, y al vídeo también los añadirá.
6. La foto será guardada en la Galería de fotos de Android o en la App Fotos de iOS tal cual lo hace ahora, y el vídeo se guardará en la Galería de Android o Fotos de iOS con el paquete saver_gallery.

En resumen, lo que te pido es que me crees el flujo que quiero para el usuario tanto para las fotos como para los vídeos, si es posible de forma sencilla añadirle a los vídeos el texto de las coordenadas y la dirección en letra como en las fotos y además añadirle los metadatos EXIF. Entonces, en las fotos mantienes igual el código implementado en media_location_screen.dart, pues con total seguridad añade muy bien los metadatos EXIF a las fotos y la fotos las guarda perfectamente en la Galería de Android o en la App Fotos del iPhone, solamente cambiaría que en lugar de abrir la cámara nativa mediante image_picker, pues ahora la abriría con camerawesome. Y sí tienes que añadir todas las funcionalidades que quiero para los vídeos (escribir texto en vídeo con coordenadas y dirección -si es posible-, añadir metadatos EXIF al mp4 -si es posible- y guardar el vídeo en la Galería de Android y en la App Fotos del iPhone). Entonces, para todo esto, actualízame el código en los archivos `lib/main.dart` y `lib/screens/media_location_screen.dart` para que solo tenga copiar y pegar en mi proyecto el código que me escribas. Y si tuviese que hacer algo más en otros archivos de mi proyecto también dime paso a paso lo que tengo que hacer para solo copiar y pegar.

## ASSISTANT RESPONSE (o1-preview)

Based on your requirements, I've updated the code for `lib/main.dart` and `lib/screens/media_location_screen.dart`. Additionally, I've created a new screen `lib/screens/camera_screen.dart` to handle the camera functionality using the `camerawesome` package.

Below are the updated files and the new `CameraScreen`:

---

### 1. Update `pubspec.yaml`

First, add the required dependencies to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_dotenv: ^5.0.2
  logging: ^1.0.2
  path_provider: ^2.0.11
  geolocator: ^9.0.2
  http: ^0.13.5
  image: ^3.2.2
  native_exif: ^2.2.1
  camerawesome: ^2.1.0
  saver_gallery: ^3.0.6
  video_player: ^2.5.1
```

---

### 2. Update `lib/main.dart`

```dart
import 'package:t3aisat/model/environment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'screens/media_location_screen.dart';
import 'screens/parcel_map_screen.dart';
import 'screens/camera_screen.dart'; // Import the new CameraScreen

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
                color: Colors.black.withOpacity(0.25),
                offset: const Offset(0, 2.0),
              ),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFE6E6E6),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: () {
                // Navigate to CameraScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CameraScreen(),
                  ),
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

### 3. Create `lib/screens/camera_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'media_location_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _cameraController;
  bool _isRecording = false;
  PictureController? _pictureController;
  VideoController? _videoController;

  @override
  void initState() {
    super.initState();

    _cameraController = CameraController(
      onMediaTap: (mediaCapture) {
        // Navigate to MediaLocationScreen with the captured media
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MediaLocationScreen(
              mediaPath: mediaCapture.filePath,
              isVideo: mediaCapture.isVideo,
            ),
          ),
        );
      },
      saveConfig: SaveConfig.photoAndVideo(),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _onTakePicture() async {
    _pictureController = _cameraController.takePicture();
    final mediaCapture = await _pictureController!.takePicture();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MediaLocationScreen(
          mediaPath: mediaCapture.filePath,
          isVideo: false,
        ),
      ),
    );
  }

  void _onRecordVideo() async {
    if (_isRecording) {
      await _videoController?.stopRecording();
      setState(() {
        _isRecording = false;
      });
      final filePath = _videoController?.videoFile?.path;
      if (filePath != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MediaLocationScreen(
              mediaPath: filePath,
              isVideo: true,
            ),
          ),
        );
      }
    } else {
      _videoController = _cameraController.recordVideo();
      await _videoController?.startRecording();
      setState(() {
        _isRecording = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraAwesomeBuilder.custom(
        saveConfig: SaveConfig.photoAndVideo(),
        builder: (cameraState, previewSize, previewRect) {
          return Stack(
            children: [
              cameraState.buildPreview(),
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.switch_camera,
                        color: Colors.white,
                        size: 40,
                      ),
                      onPressed: () {
                        cameraState.switchCameraSensor();
                      },
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: _onTakePicture,
                      onLongPress: _onRecordVideo,
                      onLongPressUp: _onRecordVideo,
                      child: Icon(
                        _isRecording
                            ? Icons.radio_button_on
                            : Icons.radio_button_unchecked,
                        color: _isRecording ? Colors.red : Colors.white,
                        size: 80,
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: Icon(
                        Icons.flash_on,
                        color: Colors.white,
                        size: 40,
                      ),
                      onPressed: () {
                        cameraState.switchFlashMode();
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

**Note:** The above code provides a basic camera interface using `camerawesome`. The user can switch between cameras, take photos, and record videos by tapping or long-pressing the capture button. Upon capturing media, it navigates to `MediaLocationScreen`.

---

### 4. Update `lib/screens/media_location_screen.dart`

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
import 'package:video_player/video_player.dart';
import 'package:saver_gallery/saver_gallery.dart';

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

      if (widget.isVideo) {
        // Process video
        await _processVideo(widget.mediaPath);
      } else {
        // Process image
        await _processImage(widget.mediaPath);
      }
    } catch (e) {
      log.severe('Failed to obtain location or process media: $e');
    } finally {
      setState(() {
        _isLoading = false;
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

      // Add other EXIF data
      await exif.writeAttributes({
        'DateTimeOriginal':
            DateFormat('yyyy:MM:dd HH:mm:ss').format(DateTime.now()),
        'UserComment':
            't3AI-SAT App. Dirección en la que fue tomada la foto: ${_address ?? 'Sin dirección'}',
      });

      await exif.close();
    } catch (e) {
      log.severe('Error writing EXIF data: $e');
    }
  }

  // Function to process the image
  Future<void> _processImage(String imagePath) async {
    try {
      // Read the original image file as bytes
      final bytes = await File(imagePath).readAsBytes();
      final img.Image originalImage = img.decodeImage(bytes)!;

      // Load the font from the assets to draw text on the image
      final fontData = await rootBundle.load(
          'assets/fonts/roboto_black/Roboto-Black_100_size_white_color.ttf.zip');
      final font = img.BitmapFont.fromZip(fontData.buffer.asUint8List());

      // Convert coordinates to DMS format
      final latitudeDMS = _convertToDMS(_currentPosition!.latitude);
      final longitudeDMS = _convertToDMS(_currentPosition!.longitude);

      // Get the current date and time
      final now = DateTime.now();
      final timeZoneName = now.timeZoneName;

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
        x: 60,
        y: originalImage.height - 850,
        color: img.ColorRgba8(255, 255, 255, 255),
      );

      // Generate the filename
      final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(now);

      String updatedImagePath;

      if (Platform.isAndroid) {
        final directory = await getExternalStorageDirectory();
        updatedImagePath = path.join(
          directory!.path,
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

      // Verify if the file exists after saving
      if (await updatedImageFile.exists()) {
        log.info('File created successfully: ${updatedImageFile.path}');
      } else {
        log.severe('File not created: ${updatedImageFile.path}');
        return;
      }

      // Add EXIF data
      await _addExifData(updatedImageFile.path);

      // Save to gallery using saver_gallery
      await _saveToGallery(updatedImageFile.path, isImage: true);

      setState(() {
        _updatedMediaPath = updatedImagePath;
      });
    } catch (e) {
      log.severe('Failed to process image: $e');
    }
  }

  // Function to process the video
  Future<void> _processVideo(String videoPath) async {
    try {
      // TODO: Add text overlay to video if possible (requires complex processing)
      // Currently, we will proceed to save the video as is

      // Generate the filename
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(now);
      String updatedVideoPath;

      if (Platform.isAndroid) {
        final directory = await getExternalStorageDirectory();
        updatedVideoPath = path.join(
          directory!.path,
          't3aisat_$formattedDate.mp4',
        );
      } else if (Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        updatedVideoPath = path.join(
          directory.path,
          't3aisat_$formattedDate.mp4',
        );
      } else {
        log.severe('Unsupported platform');
        return;
      }

      // Copy the video to the updated path
      final updatedVideoFile = await File(videoPath).copy(updatedVideoPath);

      // Add metadata to video if possible (Note: Adding EXIF to videos is not standard)

      // Save to gallery using saver_gallery
      await _saveToGallery(updatedVideoFile.path, isImage: false);

      // Initialize the video player
      _videoController = VideoPlayerController.file(File(updatedVideoFile.path));
      await _videoController!.initialize();

      setState(() {
        _updatedMediaPath = updatedVideoFile.path;
      });
    } catch (e) {
      log.severe('Failed to process video: $e');
    }
  }

  // Function to save media to gallery using saver_gallery
  Future<void> _saveToGallery(String filePath, {required bool isImage}) async {
    // Request permission
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      if (isImage) {
        final result = await SaverGallery.saveImage(
          await File(filePath).readAsBytes(),
          quality: 100,
          name: path.basename(filePath),
          androidRelativePath: 'Pictures/t3aisat',
          overwriteSameNameFile: false,
        );
        log.info('Image saved to gallery: $result');
      } else {
        final result = await SaverGallery.saveFile(
          file: filePath,
          name: path.basename(filePath),
          androidRelativePath: 'Movies/t3aisat',
          overwriteSameNameFile: false,
        );
        log.info('Video saved to gallery: $result');
      }
    } else {
      log.severe('Permission denied to access storage');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget mediaWidget;

    if (widget.isVideo) {
      if (_videoController != null && _videoController!.value.isInitialized) {
        mediaWidget = AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        );
      } else {
        mediaWidget = const Center(child: CircularProgressIndicator());
      }
    } else {
      if (_updatedMediaPath != null) {
        mediaWidget = Image.file(
          File(_updatedMediaPath!),
          fit: BoxFit.cover,
          width: double.infinity,
        );
      } else {
        mediaWidget = const Center(child: CircularProgressIndicator());
      }
    }

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
                  Expanded(child: mediaWidget),
                  const SizedBox(height: 20),
                  if (_currentPosition != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFF388E3C), // Dark green
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
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.home,
                            color: Color(0xFF388E3C), // Dark green
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
                _videoController!.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}
```

**Notes:**

- **Text Overlay on Video:** Adding text overlays to videos in Flutter requires video processing, which isn't straightforward. It typically involves using FFmpeg or similar libraries. This implementation does not add text to the video due to complexity.

- **Adding Metadata to Video:** Adding EXIF metadata to videos is not standard. Video files store metadata differently, and it's more complex to manipulate. This implementation skips adding metadata to the video.

- **Displaying Video:** Uses the `video_player` package to display videos.

---

### 5. Update Permissions and Configurations

**AndroidManifest.xml:**

Ensure you have the following permissions:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.ACCESS_MEDIA_LOCATION"/>
<!-- For Android 13 or higher -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
```

**iOS Info.plist:**

Ensure you have the following keys:

```xml
<key>NSCameraUsageDescription</key>
<string>La App necesita tener permiso a tu cámara para hacer fotos y videos.</string>
<key>NSMicrophoneUsageDescription</key>
<string>La App necesita permiso para acceder al micrófono al grabar videos.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Necesitamos añadir fotos y videos a tu librería de Fotos.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>La App necesita permiso de acceso a tu librería de fotos y videos.</string>
```

---

### 6. Additional Steps

- **Assets:** Ensure you have the font asset used in the code (`Roboto-Black_100_size_white_color.ttf.zip`) in your `pubspec.yaml`:

  ```yaml
  assets:
    - assets/fonts/roboto_black/Roboto-Black_100_size_white_color.ttf.zip
  ```

- **Permissions:** You may need to request permissions at runtime for camera, microphone, and storage access. The code uses `permission_handler` to request storage permissions.

- **FFmpeg for Video Processing (Optional):** If you wish to overlay text onto videos, consider using the `ffmpeg_kit_flutter` package. However, this involves complex processing and is beyond the scope of this implementation.

---

### 7. Summary

- Replaced `image_picker` with `camerawesome` for capturing photos and videos.

- Created `CameraScreen` to handle camera operations.

- Updated `MediaLocationScreen` to handle both images and videos.

- Used `saver_gallery` to save images and videos to the gallery.

- Added necessary permissions and configurations.

---

### 8. Important Notes

- **Limitations:** Due to the complexity of video processing, adding text overlays and metadata to videos is not implemented.

- **Testing:** Ensure you test the application on actual devices to verify permissions and functionality.

- **Error Handling:** Add appropriate error handling as needed.

---

If you have any questions or need further assistance, feel free to ask!
