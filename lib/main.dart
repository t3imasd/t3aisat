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
  bool _isRequestingPermissions = false;

  @override
  void initState() {
    super.initState();
    _checkTermsAccepted();
  }

  void _checkTermsAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _termsAccepted = prefs.getBool('termsAccepted') ?? false;
    });
    if (!_termsAccepted) {
      if (!mounted) return;
      _showTermsAndConditionsDialog();
    } else {
      await _initializeCameras();
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
                    await _initializeCameras(); // Only initialize cameras, no permission requests
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
      _cameras = await availableCameras();
    } catch (e) {
      Logger.root.severe('Error initializing cameras: $e');
    }
  }

  Future<Map<Permission, bool>> _checkAllPermissions() async {
    Map<Permission, bool> permissionStatus = {
      Permission.camera: await Permission.camera.isGranted,
      Permission.microphone: await Permission.microphone.isGranted,
      Permission.photos: await Permission.photos.isGranted,
      Permission.location: await Permission.location.isGranted,
    };
    return permissionStatus;
  }

  Future<void> _requestPermissions(List<Permission> permissions) async {
    if (_isRequestingPermissions) return;
    
    try {
      _isRequestingPermissions = true;
      Map<Permission, String> permissionDescriptions = {
        Permission.camera: 'Cámara - para capturar fotos y vídeos de las parcelas',
        Permission.microphone: 'Micrófono - para grabar audio en los vídeos',
        Permission.photos: 'Galería - para guardar las capturas realizadas',
        Permission.location: 'Ubicación - para geolocalizar las fotos y vídeos',
      };

      Map<Permission, PermissionStatus> statuses = {};
      for (var permission in permissions) {
        statuses[permission] = await permission.request();
      }

      List<String> deniedPermissions = [];
      for (var entry in statuses.entries) {
        if (entry.value.isDenied || entry.value.isPermanentlyDenied) {
          deniedPermissions.add(permissionDescriptions[entry.key] ?? '');
        }
      }

      if (deniedPermissions.isNotEmpty && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permisos necesarios'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Para poder realizar capturas necesitamos acceso a:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...deniedPermissions.map((permission) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('• $permission'),
                )),
                const SizedBox(height: 12),
                const Text(
                  'Estos permisos son necesarios para el correcto funcionamiento de la aplicación.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: const Text('Ir a Ajustes'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        );
      }
    } finally {
      _isRequestingPermissions = false;
    }
  }

  Future<void> _showLocationPermissionDialog() async {
    if (!mounted) return;
    
    final bool? dialogResult = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Acceso a ubicación requerido'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'El acceso a tu ubicación es necesario para:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('• Ubicar las parcelas en el mapa'),
              Text('• Mostrar tu posición actual en el mapa'),
              SizedBox(height: 12),
              Text(
                'Sin este permiso, no podrás ver tu posición en el mapa ni ubicar las parcelas correctamente.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Permitir ubicación'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Ahora no'),
            ),
          ],
        );
      },
    );

    if (!mounted || dialogResult != true) return;

    final status = await Permission.location.request();
    if (!mounted) return;

    if (status.isGranted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ParcelMapScreen()),
      );
    } else if (status.isPermanentlyDenied) {
      if (!mounted) return;
      final bool? settingsDialogResult = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permiso denegado'),
          content: const Text(
            'Has denegado permanentemente el acceso a la ubicación. Para usar el mapa, necesitas habilitarlo en los ajustes del sistema.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Abrir Ajustes'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      );

      if (settingsDialogResult == true) {
        openAppSettings();
      }
    }
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
                List<Permission> requiredPermissions = [
                  Permission.camera,
                  Permission.microphone,
                  Permission.photos,
                  Permission.location,
                ];
                
                Map<Permission, bool> permissions = await _checkAllPermissions();
                bool allGranted = permissions.values.every((status) => status);

                if (!allGranted) {
                  await _requestPermissions(requiredPermissions);
                  permissions = await _checkAllPermissions();
                  allGranted = permissions.values.every((status) => status);
                }

                if (allGranted) {
                  if (_cameras.isEmpty) {
                    await _initializeCameras();
                  }
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraScreen(
                        cameras: _cameras,
                        store: store,
                      ),
                    ),
                  );
                }
              },
              child: const Text('Captura con Ubicación'),
            ),
            const SizedBox(height: 40), // Spacing between the buttons
            ElevatedButton(
              onPressed: () async {
                final status = await Permission.location.status;
                
                if (!mounted) return;
                
                if (status.isGranted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ParcelMapScreen()),
                  );
                } else if (status.isDenied) {
                  _showLocationPermissionDialog();
                } else if (status.isPermanentlyDenied) {
                  final bool? settingsDialogResult = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Permiso denegado'),
                      content: const Text(
                        'Para usar el mapa necesitas habilitar el acceso a la ubicación en los ajustes del sistema.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Abrir Ajustes'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar'),
                        ),
                      ],
                    ),
                  );

                  if (settingsDialogResult == true) {
                    openAppSettings();
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
