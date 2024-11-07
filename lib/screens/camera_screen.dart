import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Añadido
import 'package:camera/camera.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:logging/logging.dart';
import 'dart:async'; // For timers
import 'package:vibration/vibration.dart'; // For haptic feedback
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
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? controller;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  AssetEntity? _lastCapturedAsset; // Variable to store the last captured media

  // Variables para zoom
  double _currentZoomLevel = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;

  // Variables para flash, enfoque y exposición
  FlashMode _flashMode = FlashMode.auto;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;

  // Variables for zoom indicator
  double _lastZoomLevel = 1.0;
  bool _isZooming = false;
  Timer? _zoomIndicatorTimer;

  // Variables for focus indicator
  Offset? _focusPoint;
  bool _isFocusing = false;
  AnimationController? _focusAnimationController;
  Animation<double>? _focusAnimation;

  // Variables for flash tooltip
  Timer? _flashTooltipTimer;
  String? _flashTooltipText;
  bool _showFlashTooltip = false;

  // Variables for exposure value indicator
  Timer? _exposureIndicatorTimer;
  bool _showExposureIndicator = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadLastCapturedAsset(); // Load the last captured asset

    // Initialize focus animation controller
    _focusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    )..addListener(() {
        setState(() {});
      });
    _focusAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _focusAnimationController!,
        curve: Curves.easeOut,
      ),
    );
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
      _maxAvailableZoom = await controller?.getMaxZoomLevel() ?? 1.0;
      _minAvailableZoom = await controller?.getMinZoomLevel() ?? 1.0;
      _maxAvailableExposureOffset = await controller?.getMaxExposureOffset() ?? 0.0;
      _minAvailableExposureOffset = await controller?.getMinExposureOffset() ?? 0.0;
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
    _focusAnimationController?.dispose();
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
            cameras: widget.cameras, // Pass the cameras to GalleryScreen
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
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => GalleryScreen(store: widget.store, cameras: widget.cameras),
      ),
    );

    if (deleted == true) {
      await _loadLastCapturedAsset(); // Update the thumbnail
      setState(() {});
    }
  }

  // Método para cambiar el modo de flash
  void _onFlashModeButtonPressed() {
    setState(() {
      // Cycle through flash modes
      if (_flashMode == FlashMode.auto) {
        _flashMode = FlashMode.always;
      } else if (_flashMode == FlashMode.always) {
        _flashMode = FlashMode.off;
      } else {
        _flashMode = FlashMode.auto;
      }
      controller?.setFlashMode(_flashMode);

      // Show flash tooltip
      _flashTooltipText = 'Flash: ${_flashMode.toString().split('.').last}';
      _showFlashTooltip = true;
      _flashTooltipTimer?.cancel();
      _flashTooltipTimer = Timer(const Duration(seconds: 1), () {
        setState(() {
          _showFlashTooltip = false;
        });
      });
    });
  }

  // Método para manejar el gesto de zoom
  void _onScaleStart(ScaleStartDetails details) {
    _lastZoomLevel = _currentZoomLevel;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) async {
    double zoom = (_lastZoomLevel * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);
    await controller?.setZoomLevel(zoom);
    _currentZoomLevel = zoom;

    // Show zoom indicator
    setState(() {
      _isZooming = true;
    });

    // Cancel previous timer and start a new one
    _zoomIndicatorTimer?.cancel();
    _zoomIndicatorTimer = Timer(const Duration(seconds: 1), () {
      setState(() {
        _isZooming = false;
      });
    });

    // Haptic feedback at zoom limits
    if ((zoom == _minAvailableZoom || zoom == _maxAvailableZoom)) {
      Vibration.vibrate(duration: 50);
    }
  }

  // Método para manejar el enfoque manual
  void _onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    controller?.setExposurePoint(offset);
    controller?.setFocusPoint(offset);

    setState(() {
      _focusPoint = details.localPosition;
      _isFocusing = true;
    });

    // Start focus animation
    _focusAnimationController?.forward(from: 0.0);

    // Hide focus indicator after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isFocusing = false;
      });
    });
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
          GestureDetector(
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onTapDown: (details) {
              // Maneja el toque para enfoque manual
              final size = MediaQuery.of(context).size;
              _onViewFinderTap(details, BoxConstraints(
                maxWidth: size.width,
                maxHeight: size.height,
              ));
            },
            child: CameraPreview(controller!),
          ),

          // Zoom indicator
          if (_isZooming)
            Positioned(
              top: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black.withOpacity(0.3),
                child: Text(
                  '${_currentZoomLevel.toStringAsFixed(1)}x',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

          // Focus indicator
          if (_isFocusing && _focusPoint != null)
            Positioned(
              left: _focusPoint!.dx - 25,
              top: _focusPoint!.dy - 25,
              child: Opacity(
                opacity: 1.0 - _focusAnimationController!.value,
                child: Transform.scale(
                  scale: _focusAnimation!.value,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFFFD700),
                        width: 2,
                      ),
                      shape: BoxShape.rectangle,
                    ),
                  ),
                ),
              ),
            ),

          // Flash tooltip
          if (_showFlashTooltip && _flashTooltipText != null)
            Positioned(
              top: 80,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black.withOpacity(0.4),
                child: Text(
                  _flashTooltipText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

          // Exposure value indicator
          if (_showExposureIndicator)
            Positioned(
              right: 60,
              top: MediaQuery.of(context).size.height / 2 - 20,
              child: Container(
                padding: const EdgeInsets.all(4),
                color: Colors.black.withOpacity(0.4),
                child: Text(
                  _currentExposureOffset.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

          // Exposure slider
          Positioned(
            right: 20,
            top: 100,
            bottom: 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '+2',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: 12,
                          elevation: 0,
                          pressedElevation: 0,
                        ),
                      ),
                      child: Slider(
                        value: _currentExposureOffset,
                        min: _minAvailableExposureOffset,
                        max: _maxAvailableExposureOffset,
                        activeColor: Colors.white,
                        inactiveColor: Colors.grey,
                        onChanged: (value) async {
                          setState(() {
                            _currentExposureOffset = value;
                            _showExposureIndicator = true;
                          });
                          await controller?.setExposureOffset(value);

                          // Timer to hide exposure indicator
                          _exposureIndicatorTimer?.cancel();
                          _exposureIndicatorTimer = Timer(const Duration(seconds: 1),
                              () {
                            setState(() {
                              _showExposureIndicator = false;
                            });
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const Text(
                  '-2',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Flash button
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              icon: Icon(
                _flashMode == FlashMode.always
                    ? Icons.flash_on
                    : _flashMode == FlashMode.off
                        ? Icons.flash_off
                        : Icons.flash_auto,
              ),
              color: _flashMode == FlashMode.always
                  ? const Color(0xFFFFD700)
                  : Colors.white,
              onPressed: _onFlashModeButtonPressed,
              iconSize: 48,
              padding: EdgeInsets.zero,
            ),
          ),

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
