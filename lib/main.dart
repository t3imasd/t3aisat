import 'package:t3aisat/model/environment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'screens/parcel_map_screen.dart';
import 'screens/camera_screen.dart';
import 'helpers/terms_helpers.dart';
import 'model/photo_model.dart';
import 'objectbox.g.dart'; // Import ObjectBox generated code
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

List<CameraDescription> cameras = [];
late Store store; // ObjectBox store
late ValueNotifier<List<Photo>> photoNotifier;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set Portrait Orientation for the app
  await _lockOrientationToPortrait();

  // Set up the logger
  _setupLogging();

  try {
    // Code from YouTube video https://www.youtube.com/watch?v=jMgrNw3_rZ0
    // Load the .env file
    await dotenv.load(fileName: Environment.fileName);
    Logger.root.info('Loaded ${Environment.fileName} file successfully');
  } catch (e) {
    Logger.root
        .severe('Could not load ${Environment.fileName} file. ERROR: $e');
  }

  store = await openStore(); // Initialize ObjectBox store
  photoNotifier = ValueNotifier<List<Photo>>(
      _getPhotosFromStore()); // Initialize the ValueNotifier after store

  runApp(const MyApp());

  // Close the store when the app terminates
  WidgetsBinding.instance.addObserver(
    LifecycleEventHandler(
      onDetached: () async {
        store.close();
      },
    ),
  );
}

/// Set the orientation of the Portrait screen
Future<void> _lockOrientationToPortrait() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
}

// Auxiliary method to get photos from the store
List<Photo> _getPhotosFromStore() {
  final box = store.box<Photo>();
  return box.getAll();
}

Future<Store> openStore() async {
  final dir = await getApplicationDocumentsDirectory();
  return Store(getObjectBoxModel(), directory: '${dir.path}/objectbox');
}

// Set up logging for the app
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
      title: 'T3AISAT',
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
                4), // Greater elevation for depth effect
          ),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  List<CameraDescription> _cameras = [];
  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();
    _checkTermsAccepted();
  }

  void _checkTermsAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    _termsAccepted = prefs.getBool('termsAccepted') ?? false;
    if (!_termsAccepted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTermsAndConditionsDialog();
      });
    } else {
      _initializeCameras();
    }
  }

  void _showTermsAndConditionsDialog() async {
    String termsContent = await loadTermsFromFile();
    bool isExpanded = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Evita cerrar el diálogo al tocar fuera
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 64),
              title: const Text('Términos y Condiciones'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Para continuar usando la app, debes aceptar nuestros términos y condiciones. Pulsa en "Leer Términos Completos" para ver el contenido completo.',
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isExpanded = !isExpanded;
                        });
                      },
                      child: Text(
                        isExpanded
                            ? 'Ocultar Términos Completos'
                            : 'Leer Términos Completos',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                    if (isExpanded)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: Markdown(
                              data: termsContent,
                              selectable: true,
                              styleSheet: MarkdownStyleSheet(
                                h1: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                                h2: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                                p: const TextStyle(fontSize: 14),
                                listBullet: const TextStyle(fontSize: 14),
                              ),
                              onTapLink: (text, href, title) {
                                // Abrir enlaces externos si es necesario
                                if (href != null) {
                                  launchUrl(Uri.parse(href));
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('termsAccepted', true);
                    setState(() {
                      _termsAccepted = true;
                    });
                    Navigator.of(context).pop();
                    _initializeCameras();
                  },
                  child: const Text('Acepto'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showMustAcceptDialog();
                  },
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMustAcceptDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Aviso'),
          content: const Text(
            'Debe aceptar los términos y condiciones para usar la aplicación.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showTermsAndConditionsDialog();
              },
              child: const Text('Aceptar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (Platform.isAndroid) {
                  SystemNavigator.pop();
                } else if (Platform.isIOS) {
                  exit(0);
                }
              },
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _initializeCameras() async {
    try {
      PermissionStatus cameraPermission = await Permission.camera.isGranted
          ? PermissionStatus.granted
          : await Permission.camera.request();
      PermissionStatus microphonePermission =
          await Permission.microphone.isGranted
              ? PermissionStatus.granted
              : await Permission.microphone.request();
      PermissionStatus photoPermission = await Permission.photos.isGranted
          ? PermissionStatus.granted
          : await Permission.photos.request();

      if (cameraPermission.isGranted &&
          photoPermission.isGranted &&
          microphonePermission.isGranted) {
        // Initialize cameras
        _cameras = await availableCameras();
      }
    } catch (e) {
      Logger.root.severe('Error initializing cameras: $e');
      // Optionally handle the error, e.g., show a dialog
    }
  }

  Future<void> _requestPermissions() async {
    PermissionStatus cameraPermission = await Permission.camera.isGranted
        ? PermissionStatus.granted
        : await Permission.camera.request();
    PermissionStatus microphonePermission =
        await Permission.microphone.isGranted
            ? PermissionStatus.granted
            : await Permission.microphone.request();
    PermissionStatus photoPermission = await Permission.photos.isGranted
        ? PermissionStatus.granted
        : await Permission.photos.request();

    if (cameraPermission.isDenied ||
        microphonePermission.isDenied ||
        photoPermission.isDenied) {
      await _showPermissionsDialog();
    } else if (cameraPermission.isPermanentlyDenied ||
        microphonePermission.isPermanentlyDenied ||
        photoPermission.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Future<void> _showPermissionsDialog() async {
    PermissionStatus cameraPermission = await Permission.camera.isGranted
        ? PermissionStatus.granted
        : await Permission.camera.request();
    PermissionStatus microphonePermission =
        await Permission.microphone.isGranted
            ? PermissionStatus.granted
            : await Permission.microphone.request();
    PermissionStatus photoPermission = await Permission.photos.isGranted
        ? PermissionStatus.granted
        : await Permission.photos.request();

    String cameraMessage =
        cameraPermission.isPermanentlyDenied || cameraPermission.isDenied
            ? 'Cámara'
            : '';
    String photoMessage =
        photoPermission.isPermanentlyDenied || photoPermission.isDenied
            ? 'Galería de fotos'
            : '';
    String microphoneMessage = microphonePermission.isPermanentlyDenied ||
            microphonePermission.isDenied
        ? 'Micrófono'
        : '';
    String microphoneAdditionalMessage = microphonePermission
                .isPermanentlyDenied ||
            microphonePermission.isDenied
        ? ' Algunas funcionalidades pueden estar limitadas sin el permiso del micrófono.'
        : '';

    String message = '';
    if (cameraMessage.isNotEmpty ||
        photoMessage.isNotEmpty ||
        microphoneMessage.isNotEmpty) {
      List<String> messages = [];
      if (cameraMessage.isNotEmpty) messages.add(cameraMessage);
      if (photoMessage.isNotEmpty) messages.add(photoMessage);
      if (microphoneMessage.isNotEmpty) messages.add(microphoneMessage);

      if (messages.isNotEmpty) {
        message =
            'La aplicación necesita permisos de acceso a ${messages.join(', ').replaceFirst(RegExp(r', (?=[^,]*$)'), ' y ')} para continuar.$microphoneAdditionalMessage';
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permisos requeridos'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Volver a solicitar permisos
              _requestPermissions();
            },
            child: const Text('Otorgar permisos'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  // New method to show location permission dialog
  Future<void> _showLocationPermissionDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permiso de Localización'),
          content: Text(
              'El permiso de localización es necesario para mostrar el mapa de parcelas.'),
          actions: [
            TextButton(
              child: Text('Otorgar permisos'),
              onPressed: () async {
                Navigator.of(context).pop();
                // Request permission again
                PermissionStatus status = await Permission.location.request();
                if (status.isGranted) {
                  // Permission granted, navigate to ParcelMapScreen
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => ParcelMapScreen()),
                  );
                } else if (status.isPermanentlyDenied) {
                  // Open app settings
                  await openAppSettings();
                }
              },
            ),
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build the UI regardless of permissions
    return Scaffold(
      backgroundColor: const Color(0xFFE6E6E6), // Light gray
      appBar: AppBar(
        title: Text(
          'T3 AI SAT',
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
        elevation: 0, // No shadow in the title bar
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
                bool cameraPermissionGranted =
                    await Permission.camera.isGranted;
                bool microphonePermissionGranted =
                    await Permission.microphone.isGranted;
                bool photoPermissionGranted = await Permission.photos.isGranted;

                if (cameraPermissionGranted &&
                    microphonePermissionGranted &&
                    photoPermissionGranted) {
                  if (_cameras.isEmpty) {
                    await _initializeCameras();
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraScreen(
                        cameras: _cameras,
                        store: store,
                      ),
                    ),
                  );
                } else {
                  _showPermissionsDialog();
                }
              },
              child: const Text('Captura con Ubicación'),
            ),
            const SizedBox(height: 40), // Spacing between the buttons
            ElevatedButton(
              onPressed: () async {
                // Check current permission status
                PermissionStatus status = await Permission.location.status;
                if (status.isGranted) {
                  // Navigate to ParcelMapScreen
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => ParcelMapScreen()),
                  );
                } else {
                  // Request permission
                  PermissionStatus newStatus =
                      await Permission.location.request();
                  if (newStatus.isGranted) {
                    // Permission granted, navigate to ParcelMapScreen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => ParcelMapScreen()),
                    );
                  } else if (newStatus.isDenied) {
                    // Show permission dialog
                    await _showLocationPermissionDialog();
                  } else if (newStatus.isPermanentlyDenied) {
                    // Open app settings
                    await openAppSettings();
                  }
                }
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

class LifecycleEventHandler extends WidgetsBindingObserver {
  final Future<void> Function()? onDetached;

  LifecycleEventHandler({this.onDetached});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      if (onDetached != null) {
        onDetached!();
      }
    }
  }
}
