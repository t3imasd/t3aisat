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
import 'screens/parcel_map_screen.dart';
import 'screens/camera_screen.dart';
import 'helpers/permission_handler.dart';
import 'model/photo_model.dart';
import 'screens/terms_and_condition_screen.dart';
import 'objectbox.g.dart'; // Import ObjectBox generated code
// Add this for jsonEncode
import 'package:device_info_plus/device_info_plus.dart'; // Add this for DeviceInfoPlugin
import 'model/media_model.dart'; // Asegúrate de que este import existe

List<CameraDescription> cameras = [];
late Store store; // ObjectBox store
late ValueNotifier<List<Photo>> photoNotifier;
late ValueNotifier<List<Media>> mediaNotifier; // Add near the other global variables

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar el color de la barra de estado
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFF8F9FA), // Color del fondo
      statusBarIconBrightness:
          Brightness.dark, // Iconos oscuros para fondo claro
    ),
  );

  // Set allowed orientations for the app
  await _setAllowedOrientations();

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
  mediaNotifier = ValueNotifier<List<Media>>(_getMediaFromStore()); // Add this line
  _initializeMediaStore(); // Add this line

  // Initialize both notifiers
  photoNotifier.value = store.box<Photo>().getAll();
  mediaNotifier.value = store.box<Media>().getAll();

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

/// Set the allowed orientations
Future<void> _setAllowedOrientations() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
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

// Update this helper method
void _initializeMediaStore() {
  final box = store.box<Media>();
  try {
    // Try to access the box to verify it's working
    box.isEmpty;
    Logger.root.info('Media store initialized successfully');
  } catch (e) {
    Logger.root.severe('Failed to initialize Media store: $e');
  }
}

// Add this helper method similar to _getPhotosFromStore
List<Media> _getMediaFromStore() {
  final box = store.box<Media>();
  return box.getAll();
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
            backgroundColor: WidgetStateProperty.all(const Color(0xFF388E3C)),
            foregroundColor: WidgetStateProperty.all(Colors.white),
            textStyle: WidgetStateProperty.all(
              const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            elevation: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) return 2;
              return 4;
            }),
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

class MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  List<CameraDescription> _cameras = [];
  bool _isRequestingPermissions = false;
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin(); // Add this line

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeCameras();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      Logger.root.severe('Error initializing cameras: $e');
    }
  }

  Future<List<Permission>> getNotRequestedPermissions(
      List<Permission> permissions) async {
    List<Permission> notRequested = [];

    for (var permission in permissions) {
      if (!await PermissionHelper.hasBeenRequested(permission)) {
        notRequested.add(permission);
      }
    }

    return notRequested;
  }

  Future<void> _handlePermissionsAndNavigation(String destination) async {
    if (_isRequestingPermissions) return;

    try {
      _isRequestingPermissions = true;

      // Check if terms are accepted
      final prefs = await SharedPreferences.getInstance();
      final termsAccepted = prefs.getBool('termsAccepted') ?? false;

      if (!termsAccepted) {
        if (!mounted) return;
        // Show terms screen first
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const TermsAndConditionScreen()),
        );

        // If terms were not accepted, return early
        if (result != true) return;
      }

      final permissions =
          await PermissionHelper.getRequiredPermissions(destination);

      // Check current status of all permissions
      Map<Permission, PermissionStatus> statuses = {};
      for (var permission in permissions) {
        statuses[permission] = await permission.status;
      }

      // First, handle permissions that haven't been requested yet
      final notRequested = await getNotRequestedPermissions(permissions);

      if (notRequested.isNotEmpty) {
        if (!mounted) return;

        // Show informative dialog for each not requested permission
        final shouldContinue =
            await PermissionHelper.showInitialPermissionsDialog(
                context, notRequested, destination);

        if (!shouldContinue) return;
      }

      // Now request all needed permissions
      statuses = await PermissionHelper.requestPermissions(
          context, permissions, destination);

      // Check for denied permissions after request
      final denied = statuses.entries
          .where((e) => e.value.isDenied || e.value.isPermanentlyDenied)
          .map((e) => e.key)
          .toList();

      if (denied.isNotEmpty) {
        if (!mounted) return;
        await PermissionHelper.handleDeniedPermissions(
            context, denied, destination);
        return;
      }

      final allGranted = statuses.values.every((status) => status.isGranted);

      if (allGranted) {
        if (destination == 'camera' && _cameras.isEmpty) {
          await _initializeCameras();
        }

        if (!mounted) return;

        if (destination == 'camera') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CameraScreen(cameras: _cameras, store: store),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ParcelMapScreen()),
          );
        }
      }
    } finally {
      _isRequestingPermissions = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F9FA), // Mismo color que statusBarColor
      extendBodyBehindAppBar:
          true, // Extiende el contenido detrás de la barra de estado
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isPortrait = orientation == Orientation.portrait;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF8F9FA),
                  const Color(0xFFE9ECEF),
                  Colors.white.withAlpha(230),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isPortrait ? 24.0 : 16.0,
                ),
                child: Column(
                  children: [
                    SizedBox(height: isPortrait ? 60 : 20),
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1000),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Text(
                            'T3 AI SAT',
                            style: TextStyle(
                              fontSize: isPortrait ? 32 : 28,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1976D2),
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Center(
                          child: isPortrait
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: _buildButtons(spacing: 40.0),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: _buildButtons(spacing: 20.0),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildButtons({required double spacing}) {
    return [
      _buildAnimatedButton(
        'Captura con Ubicación',
        () => _handlePermissionsAndNavigation('camera'),
        const Duration(milliseconds: 200),
      ),
      SizedBox(width: spacing, height: spacing),
      _buildAnimatedButton(
        'Mapa de Parcelas',
        () => _handlePermissionsAndNavigation('map'),
        const Duration(milliseconds: 400),
      ),
    ];
  }

  Widget _buildAnimatedButton(
      String text, VoidCallback onPressed, Duration delay) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF388E3C).withAlpha(76),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: onPressed,
              child: Text(text),
            ),
          ),
        );
      },
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
