import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:logging/logging.dart';
import '../objectbox.g.dart';
import 'media_location_screen.dart';
import 'gallery_screen.dart';
import '../helpers/media_helpers.dart'; // Added import

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Store store;

  const CameraScreen({super.key, required this.cameras, required this.store});

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
    if (widget.cameras.isEmpty) {
      // No cameras available
      Logger.root.severe('No cameras found');
      return;
    }

    controller = CameraController(widget.cameras[0], ResolutionPreset.high);

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
            store:
                widget.store, // Pass the ObjectBox store to MediaLocationScreen
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
              store: widget
                  .store, // Pass the ObjectBox store to MediaLocationScreen
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
        end: 50, // Fetch the last 50 media files
      );

      // Iterate through the media files to find the first valid asset
      for (final AssetEntity asset in mediaFiles) {
        bool isValid = false;

        if (asset.type == AssetType.image) {
          isValid = await isValidPhoto(asset, widget.store);
        } else if (asset.type == AssetType.video) {
          isValid = await isValidVideo(asset);
        }

        if (isValid) {
          setState(() {
            _lastCapturedAsset = asset;
          });
          return; // Exit after setting the new asset
        }
      }

      // If no valid asset is found, set _lastCapturedAsset to null
      setState(() {
        _lastCapturedAsset = null;
      });
    } else {
      setState(() {
        _lastCapturedAsset = null;
      });
    }
  }

  void _navigateToLastCapturedMedia(BuildContext context) async {
    // Retrieve the actual file from _lastCapturedAsset
    final file = await _lastCapturedAsset!.file;

    if (file != null) {
      // Navigate to GalleryScreen once the file is resolved
      final deleted = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => GalleryScreen(
            store: widget.store, // Pass the ObjectBox store to GalleryScreen
          ),
        ),
      );

      if (deleted == true) {
        // If media was deleted, reload the last captured asset
        await _loadLastCapturedAsset();
        setState(() {});
      }
    } else {
      // Handle the case where the file could not be loaded
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo cargar el archivo")),
      );
    }
  }

  void _navigateToGallery(BuildContext context) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => GalleryScreen(store: widget.store),
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
                            _navigateToLastCapturedMedia(
                                context); // Navigate and handle deletion
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
                if (_lastCapturedAsset == null)
                  FloatingActionButton(
                    onPressed: () {
                      _navigateToGallery(context);
                    },
                    heroTag: 'lastCapturedMediaFAB',
                    child: const Icon(Icons.photo_library),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
