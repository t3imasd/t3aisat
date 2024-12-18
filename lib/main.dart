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
import 'helpers/permission_handler.dart';
import 'model/photo_model.dart';
import 'screens/terms_and_condition_screen.dart';
import 'objectbox.g.dart'; // Import ObjectBox generated code
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:convert'; // Add this for jsonEncode
import 'package:device_info_plus/device_info_plus.dart'; // Add this for DeviceInfoPlugin

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
  bool _isRequestingPermissions = false;
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin(); // Add this line

  @override
  void initState() {
    super.initState();
    _initializeCameras();
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
          MaterialPageRoute(builder: (context) => const TermsAndConditionScreen()),
        );
        
        // If terms were not accepted, return early
        if (result != true) return;
      }

      final permissions = await PermissionHelper.getRequiredPermissions(destination);

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
              onPressed: () => _handlePermissionsAndNavigation('camera'),
              child: const Text('Captura con Ubicación'),
            ),
            const SizedBox(height: 40), // Spacing between the buttons
            ElevatedButton(
              onPressed: () => _handlePermissionsAndNavigation('map'),
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
