import 'package:t3aisat/model/environment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'screens/media_location_screen.dart';
import 'screens/parcel_map_screen.dart';
import 'screens/gallery_screen.dart';
import 'model/photo_model.dart';
import 'objectbox.g.dart'; // Import ObjectBox generated code

List<CameraDescription> cameras = [];
late Store store; // ObjectBox store
late ValueNotifier<List<Photo>> photoNotifier;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  try {
    // Ensure permissions are granted before fetching cameras
    await _requestPermissions();
    cameras = await availableCameras();
  } on CameraException catch (e) {
    Logger.root.severe('Error in fetching the cameras: $e');
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

// Método auxiliar para obtener fotos desde el store
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

// Request necessary permissions for the app
Future<void> _requestPermissions() async {
  PermissionStatus cameraPermission = await Permission.camera.request();
  PermissionStatus microphonePermission = await Permission.microphone.request();
  PermissionStatus photoPermission = await Permission.photos.request();

  if (cameraPermission.isDenied ||
      microphonePermission.isDenied ||
      photoPermission.isDenied) {
    throw Exception('Camera, microphone, and photos permissions are required');
  }
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
                4), // Greater elevation for depth effect
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
          'Think Tank InnoTech',
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CameraScreen()),
                );
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

class LifecycleEventHandler extends WidgetsBindingObserver {
  final Future<void> Function()? onDetached;

  LifecycleEventHandler({this.onDetached});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      onDetached?.call();
    }
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? controller;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  AssetEntity? _lastCapturedAsset; // Variable to store the last captured media

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadLastCapturedAsset(); // Load the last captured asset
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) {
      // No cameras available
      Logger.root.severe('No cameras found');
      return;
    }

    controller = CameraController(cameras[0], ResolutionPreset.high);

    try {
      await controller?.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      Logger.root.severe('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onTakePictureButtonPressed() async {
    if (controller == null || !controller!.value.isInitialized) {
      Logger.root.severe('Camera is not initialized');
      return;
    }

    if (controller!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return;
    }

    try {
      XFile picture = await controller!.takePicture();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MediaLocationScreen(
            mediaPath: picture.path,
            isVideo: false,
            store: store, // Pass the ObjectBox store to MediaLocationScreen
          ),
        ),
      );
    } catch (e) {
      Logger.root.severe('Error taking picture: $e');
    }
  }

  void _onRecordVideoButtonPressed() async {
    if (controller == null || !controller!.value.isInitialized) {
      Logger.root.severe('Camera is not initialized');
      return;
    }

    if (_isRecording) {
      // Stop recording
      try {
        XFile videoFile = await controller!.stopVideoRecording();
        setState(() {
          _isRecording = false;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MediaLocationScreen(
              mediaPath: videoFile.path,
              isVideo: true,
              store: store, // Pass the ObjectBox store to MediaLocationScreen
            ),
          ),
        );
      } catch (e) {
        Logger.root.severe('Error stopping video recording: $e');
      }
    } else {
      // Start recording
      try {
        await controller!.prepareForVideoRecording();
        await controller!.startVideoRecording();
        setState(() {
          _isRecording = true;
        });
      } catch (e) {
        Logger.root.severe('Error starting video recording: $e');
      }
    }
  }

  // Load the last captured media from the app's gallery
  Future<void> _loadLastCapturedAsset() async {
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.all,
      filterOption: FilterOptionGroup(
        createTimeCond: DateTimeCond(
          min: DateTime.now().subtract(const Duration(days: 365)), // 1 year ago
          max: DateTime.now(), // Current date
        ),
      ),
    );

    if (albums.isNotEmpty) {
      final List<AssetEntity> mediaFiles = await albums[0].getAssetListRange(
        start: 0,
        end: 1,
      );

      if (mediaFiles.isNotEmpty) {
        setState(() {
          _lastCapturedAsset = mediaFiles.first;
        });
      }
    }
  }

  void _navigateToLastCapturedMedia(BuildContext context) async {
    // Retrieve the actual file from _lastCapturedAsset
    final file = await _lastCapturedAsset!.file;

    if (file != null) {
      // Navigate to MediaLocationScreen once the file is resolved
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MediaLocationScreen(
            mediaPath: file.path, // Access the file path
            isVideo: _lastCapturedAsset!.type == AssetType.video,
            store: store, // Pass the ObjectBox store to MediaLocationScreen
          ),
        ),
      );
    } else {
      // Handle the case where the file could not be loaded
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo cargar el archivo")),
      );
    }
  }

  void _navigateToGallery(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            GalleryScreen(store: store), // Navigate to GalleryScreen with store
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || controller == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cámara'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cámara'),
      ),
      body: Stack(
        children: [
          CameraPreview(controller!),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  onPressed: _onTakePictureButtonPressed,
                  heroTag: 'takePhotoFAB',
                  child: const Icon(Icons.photo_camera),
                ),
                FloatingActionButton(
                  onPressed: _onRecordVideoButtonPressed,
                  heroTag: 'recordVideoFAB',
                  child: Icon(_isRecording ? Icons.stop : Icons.videocam),
                ),
                // Third button showing the thumbnail of the last captured media
                if (_lastCapturedAsset != null)
                  FutureBuilder<Uint8List?>(
                    future: _lastCapturedAsset!
                        .thumbnailDataWithSize(ThumbnailSize(100, 100)),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
                        return FloatingActionButton(
                          onPressed: () {
                            _navigateToGallery(
                                context); // Navigate to the gallery screen instead of MediaLocationScreen
                          },
                          heroTag: 'lastCapturedMediaFAB',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                                8.0), // Rounded edges to match the button shape
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  8.0), // Rounded edges to match the button shape
                              child: FutureBuilder<Uint8List?>(
                                future: _lastCapturedAsset!
                                    .thumbnailDataWithSize(
                                        const ThumbnailSize.square(200)),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                          ConnectionState.done &&
                                      snapshot.hasData) {
                                    return Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit
                                          .cover, // This makes the image cover the entire button area
                                      width: double.infinity,
                                      height: double.infinity,
                                    );
                                  }
                                  return const CircularProgressIndicator(); // Show a loading indicator while the image loads
                                },
                              ),
                            ),
                          ),
                        );
                      }
                      return const FloatingActionButton(
                        onPressed: null,
                        heroTag: 'lastCapturedMediaFAB',
                        child: Icon(Icons.photo_library),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
