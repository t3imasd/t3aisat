import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:logging/logging.dart';
import 'dart:async'; // For timers
import 'package:vibration/vibration.dart'; // For haptic feedback
import '../objectbox.g.dart';
import 'media_location_screen.dart';
import 'gallery_screen.dart';
import '../helpers/media_helpers.dart';
import 'dart:io';

// Add a personalized class for the Slider's Thumb with the sun icon
class SunThumbShape extends SliderComponentShape {
  final double thumbRadius;

  const SunThumbShape({required this.thumbRadius});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(thumbRadius * 2, thumbRadius * 2);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    const IconData sunIcon = Icons.wb_sunny;
    final TextSpan span = TextSpan(
      text: String.fromCharCode(sunIcon.codePoint),
      style: TextStyle(
        fontSize: thumbRadius * 1.5,
        fontFamily: sunIcon.fontFamily,
        package: sunIcon.fontPackage,
        color: Color(0xFFFFD700),
      ),
    );
    final TextPainter tp = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: textDirection,
    );
    tp.layout();
    tp.paint(
      canvas,
      center - Offset(tp.width / 2, tp.height / 2),
    );
  }
}

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

  // Zoom variables
  double _currentZoomLevel = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;

  // Flash variables, focus and exposure
  FlashMode _flashMode = FlashMode.auto;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;

  // variables for Zoom Indicator
  double _lastZoomLevel = 1.0;
  bool _isZooming = false;
  Timer? _zoomIndicatorTimer;

  // Variables for focus indicator
  Offset? _focusPoint;
  bool _isFocusing = false;
  AnimationController? _focusAnimationController;
  Animation<double>? _focusAnimation;

  // Variables for Flash Tooltip
  Timer? _flashTooltipTimer;
  String? _flashTooltipText;
  bool _showFlashTooltip = false;

  // Variables for exposure value indicator
  Timer? _exposureIndicatorTimer;
  bool _showExposureIndicator = false;

  // Add state variables for exposure slider
  bool _showExposureSlider = false;
  Timer? _exposureSliderTimer;

  final int _pointerCount = 0; // Add pointer count tracking

  // Add this to your state class
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;

  Uint8List? _lastCapturedThumbnail;

  // Add new properties for orientation handling
  DeviceOrientation? _currentOrientation;
  double? _previewAspectRatio;

  bool _isOrientationInitialized = false;
  bool _isInitializing = true;
  bool _wasResumed = false;

  // Add new properties for preview calculations
  Size? _previewSize;
  double _previewScale = 1.0;

  // Add new properties for preview calculations
  double _cameraAspectRatio = 1.0;
  double _screenAspectRatio = 1.0;
  BoxFit _previewFit = BoxFit.contain;

  // Add properties for preview calculations
  late ValueNotifier<Size> _previewSizeNotifier;
  late ValueNotifier<double> _scaleFactor;

  CameraDescription? _currentCamera;

  bool _isTransitioning = false;
  Completer<void>? _orientationCompleter;

  @override
  void initState() {
    super.initState();
    _previewSizeNotifier = ValueNotifier(Size.zero);
    _scaleFactor = ValueNotifier(1.0);
    WidgetsBinding.instance.addObserver(this);
    _initializeFocusAnimation();
  }

  void _initializeFocusAnimation() {
    _focusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    )..addListener(() {
        if (mounted) setState(() {});
      });

    _focusAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _focusAnimationController!,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitializing) {
      // Add delay to ensure stable orientation
      Future.delayed(const Duration(milliseconds: 100), () {
        _safeInitializeCamera();
      });
      _isInitializing = false;
    }
  }

  Future<void> _safeInitializeCamera() async {
    if (widget.cameras.isEmpty) {
      Logger.root.severe('No cameras available');
      return;
    }

    // Wait for any pending transitions
    if (_orientationCompleter != null) {
      await _orientationCompleter!.future;
    }

    _orientationCompleter = Completer<void>();

    try {
      // 1. Select camera safely
      _currentCamera ??= widget.cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => widget.cameras.first,
      );

      // 2. Create controller with safe configuration
      final newController = CameraController(
        _currentCamera!,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      // 3. Initialize controller with detailed error handling
      try {
        await newController.initialize();
      } catch (e) {
        Logger.root.severe('Camera controller initialization failed: $e');
        return;
      }

      if (!mounted) return;

      // 4. Configure camera after successful initialization
      controller = newController;

      // 5. Update camera parameters safely
      try {
        await Future.wait([
          controller!
              .getMaxZoomLevel()
              .then((value) => _maxAvailableZoom = value),
          controller!
              .getMinZoomLevel()
              .then((value) => _minAvailableZoom = value),
          controller!
              .getMaxExposureOffset()
              .then((value) => _maxAvailableExposureOffset = value),
          controller!
              .getMinExposureOffset()
              .then((value) => _minAvailableExposureOffset = value),
        ]);
      } catch (e) {
        Logger.root.warning('Error setting camera parameters: $e');
      }

      // 6. Update UI state and load last asset
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isOrientationInitialized = true;
        });

        // 7. Update preview configuration
        if (controller?.value.previewSize != null) {
          _previewSizeNotifier.value = controller!.value.previewSize!;
          _updatePreviewRatio(MediaQuery.of(context).size);
          _updatePreviewScaling(MediaQuery.of(context).size);
        }

        // 8. Load the last captured asset after camera is fully initialized
        await _loadLastCapturedAsset();
      }
    } catch (e) {
      Logger.root.severe('Error in safe camera initialization: $e');
    } finally {
      _orientationCompleter?.complete();
      _orientationCompleter = null;
    }
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) return;

    _currentCamera ??= widget.cameras.first;

    // 1. Primero detectar la orientación actual
    _currentOrientation = await _detectDeviceOrientation();

    // 2. Luego inicializar el controlador con la orientación correcta
    controller = CameraController(
      _currentCamera!,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // 3. Establecer la orientación antes de inicializar
    await controller!.lockCaptureOrientation(_currentOrientation);

    // 4. Inicializar el controlador
    await controller!.initialize();

    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (widget.cameras.length < 2) return;

    final CameraDescription newCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection != _currentCamera!.lensDirection,
      orElse: () => widget.cameras.first,
    );

    if (newCamera == _currentCamera) return;

    if (controller != null) {
      await controller!.dispose();
    }

    _currentCamera = newCamera;
    setState(() {
      _isCameraInitialized = false;
    });
    await _initializeCamera();
  }

  void _updatePreviewScaling(Size screenSize) {
    if (!mounted || controller?.value.previewSize == null) return;

    final previewSize = controller!.value.previewSize!;
    final isPortrait = _currentOrientation == DeviceOrientation.portraitUp;

    // Calculate screen and preview aspect ratios
    final screenAspectRatio = screenSize.width / screenSize.height;
    final previewAspectRatio = isPortrait
        ? previewSize.height / previewSize.width
        : previewSize.width / previewSize.height;

    // Calculate scaling factor
    double scale = 1.0;
    if (isPortrait) {
      // Portrait mode
      if (screenAspectRatio < previewAspectRatio) {
        scale = screenSize.width / (previewSize.height);
      } else {
        scale = screenSize.height / (previewSize.width);
      }
    } else {
      // Landscape mode
      if (screenAspectRatio > previewAspectRatio) {
        scale = screenSize.height / (previewSize.width);
      } else {
        scale = screenSize.width / (previewSize.height);
      }
    }

    _scaleFactor.value = scale;
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isDetached = state == AppLifecycleState.detached;

    // Handle app lifecycle changes
    switch (state) {
      case AppLifecycleState.resumed:
        if (_wasResumed) _resumeCamera();
        _wasResumed = true;
        break;
      case AppLifecycleState.inactive:
        _pauseCamera();
        break;
      case AppLifecycleState.paused:
        _pauseCamera();
        break;
      case AppLifecycleState.detached:
        if (mounted) dispose();
        break;
      default:
        break;
    }
  }

  Future<void> _pauseCamera() async {
    if (controller?.value.isInitialized ?? false) {
      await controller?.pausePreview();
    }
  }

  Future<void> _resumeCamera() async {
    if (controller?.value.isInitialized ?? false) {
      await controller?.resumePreview();
      _updateOrientationSafely();
    } else {
      await _initializeCamera();
    }
  }

  Future<DeviceOrientation> _detectDeviceOrientation() async {
    if (!mounted) return DeviceOrientation.portraitUp;

    try {
      final orientation = MediaQuery.of(context).orientation;
      return orientation == Orientation.portrait
          ? DeviceOrientation.portraitUp
          : DeviceOrientation.landscapeRight;
    } catch (e) {
      Logger.root.warning('Error detecting orientation: $e');
      return DeviceOrientation.portraitUp;
    }
  }

  void _updateOrientationSafely() async {
    if (_isTransitioning || !mounted) return;

    _isTransitioning = true;
    try {
      final newOrientation = await _detectDeviceOrientation();
      if (_currentOrientation != newOrientation) {
        await _handleOrientationChange(newOrientation);
      }
    } finally {
      _isTransitioning = false;
    }
  }

  Future<void> _handleOrientationChange(
      DeviceOrientation newOrientation) async {
    await _pauseCamera();
    await Future.delayed(const Duration(milliseconds: 200));

    _currentOrientation = newOrientation;
    await controller?.lockCaptureOrientation(newOrientation);
    _updatePreviewRatio(MediaQuery.of(context).size);

    await _resumeCamera();
  }

  void _updatePreviewRatio(Size screenSize) {
    if (!mounted || controller?.value.previewSize == null) return;

    try {
      final previewSize = controller!.value.previewSize!;
      final isPortrait = _currentOrientation == DeviceOrientation.portraitUp;

      // Calculate aspect ratios
      _screenAspectRatio = screenSize.width / screenSize.height;
      _cameraAspectRatio = isPortrait
          ? previewSize.height / previewSize.width
          : previewSize.width / previewSize.height;

      // Determine optimal preview fit
      _previewFit = _screenAspectRatio > _cameraAspectRatio
          ? BoxFit.fitHeight
          : BoxFit.fitWidth;

      // Calculate scale to fill screen
      _previewScale =
          _calculatePreviewScale(screenSize, previewSize, isPortrait);

      if (mounted) setState(() {});
    } catch (e) {
      Logger.root.warning('Error updating preview ratio: $e');
    }
  }

  double _calculatePreviewScale(
      Size screenSize, Size previewSize, bool isPortrait) {
    final screenAspectRatio = screenSize.width / screenSize.height;
    final previewAspectRatio = isPortrait
        ? previewSize.width / previewSize.height
        : previewSize.height / previewSize.width;

    // Calculate scale to fill screen completely
    double scale;
    if (screenAspectRatio > previewAspectRatio) {
      // Screen is wider than preview
      scale = screenSize.width /
          (isPortrait ? previewSize.height : previewSize.width);
    } else {
      // Screen is taller than preview
      scale = screenSize.height /
          (isPortrait ? previewSize.width : previewSize.height);
    }

    return scale * 1.1; // Add 10% extra scale to ensure full coverage
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    _focusAnimationController?.dispose();
    _zoomIndicatorTimer?.cancel();
    _flashTooltipTimer?.cancel();
    _exposureIndicatorTimer?.cancel();
    _recordingTimer?.cancel();
    _exposureSliderTimer?.cancel();
    super.dispose();
  }

  void _onTakePictureButtonPressed() async {
    if (controller == null || !controller!.value.isInitialized) {
      Logger.root.severe('Camera is not initialized');
      return;
    }

    if (controller!.value.isTakingPicture) return;

    try {
      if (_currentOrientation != null) {
        if (_currentCamera?.lensDirection == CameraLensDirection.front) {
          // For front camera:
          // In portrait mode, use portraitUp 
          // In landscape mode, use landscapeRight
          final orientation = MediaQuery.of(context).orientation;
          final targetOrientation = orientation == Orientation.portrait 
            ? DeviceOrientation.portraitUp
            : DeviceOrientation.landscapeRight;
          
          await controller?.lockCaptureOrientation(targetOrientation);
        } else {
          // For back camera keep current orientation
          await controller?.lockCaptureOrientation(_currentOrientation!);
        }
      }
      
      final XFile picture = await controller!.takePicture();
      await controller?.unlockCaptureOrientation();

      if (!mounted) return;

      // Navigate and update thumbnail after taking picture
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MediaLocationScreen(
            mediaPath: picture.path,
            isVideo: false,
            store: widget.store,
          ),
        ),
      );

      // Update thumbnail after returning
      await _loadLastCapturedAsset();
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
        _stopRecordingTimer();
        if (mounted) {
          setState(() {
            _isRecording = false;
          });
        }

        // Navigate and update thumbnail after recording
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MediaLocationScreen(
              mediaPath: videoFile.path,
              isVideo: true,
              store: widget.store,
            ),
          ),
        );

        // Update thumbnail after returning
        await _loadLastCapturedAsset();
      } catch (e) {
        Logger.root.severe('Error stopping video recording: $e');
      }
    } else {
      // Start recording
      try {
        await controller!.prepareForVideoRecording();
        await controller!.startVideoRecording();
        _startRecordingTimer();
        if (mounted) {
          setState(() {
            _isRecording = true;
          });
        }
      } catch (e) {
        Logger.root.severe('Error starting video recording: $e');
      }
    }
  }

  // Load the last asset captured and update the thumbnail
  Future<void> _loadLastCapturedAsset() async {
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.all,
      filterOption: FilterOptionGroup(
        createTimeCond: DateTimeCond(
          min: DateTime(2023),
          max: DateTime.now(),
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
          if (mounted) {
            setState(() {
              _lastCapturedAsset = asset;
            });
          }
          // Update Thumbnail after establishing _lastCapturedAsset
          await _updateLastCapturedThumbnail();
          return; // Exit after finding the most recent valid asset
        }
      }

      // If no valid asset is found, set _lastCapturedAsset to null
      if (mounted) {
        setState(() {
          _lastCapturedAsset = null;
          _lastCapturedThumbnail = null;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _lastCapturedAsset = null;
          _lastCapturedThumbnail = null;
        });
      }
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
        if (mounted) {
          setState(() {});
        }
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
        builder: (context) =>
            GalleryScreen(store: widget.store, cameras: widget.cameras),
      ),
    );

    if (deleted == true) {
      await _loadLastCapturedAsset(); // Update the thumbnail
      if (mounted) {
        setState(() {});
      }
    }
  }

  // Method to change flash mode
  void _onFlashModeButtonPressed() {
    if (mounted) {
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
          if (mounted) {
            setState(() {
              _showFlashTooltip = false;
            });
          }
        });
      });
    }
  }

  // Method to handle Zoom's gesture
  void _onScaleStart(ScaleStartDetails details) {
    _lastZoomLevel = _currentZoomLevel;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) async {
    double zoom = (_lastZoomLevel * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);
    await controller?.setZoomLevel(zoom);
    _currentZoomLevel = zoom;

    // Show zoom indicator
    if (mounted) {
      setState(() {
        _isZooming = true;
      });
    }

    // Cancel previous timer and start a new one
    _zoomIndicatorTimer?.cancel();
    _zoomIndicatorTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isZooming = false;
        });
      }
    });

    // Haptic feedback at zoom limits
    if ((zoom == _minAvailableZoom || zoom == _maxAvailableZoom)) {
      Vibration.vibrate(duration: 50);
    }
  }

  // Method to handle the manual approach
  void _onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    controller?.setExposurePoint(offset);
    controller?.setFocusPoint(offset);

    if (mounted) {
      setState(() {
        _focusPoint = details.localPosition;
        _isFocusing = true;
      });
    }

    // Start focus animation
    _focusAnimationController?.forward(from: 0.0);

    // Hide focus indicator after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isFocusing = false;
        });
      }
    });
  }

  // Add this widget to show the timer
  Widget _buildRecordingTimer() {
    return Positioned(
      top: 40,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          opacity: _isRecording ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(0, 0, 0, 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatDuration(_recordingDuration),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF Pro Display',
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Add this helper method
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  // Add these methods to handle timer
  void _startRecordingTimer() {
    _recordingDuration = Duration.zero;
    _isRecording = true;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      }
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _isRecording = false;
  }

  // Update Thumbnail when it changes _lastCapturedAsset
  Future<void> _updateLastCapturedThumbnail() async {
    if (_lastCapturedAsset != null) {
      final thumbnail = await _lastCapturedAsset!
          .thumbnailDataWithSize(ThumbnailSize(100, 100));
      if (mounted) {
        setState(() {
          _lastCapturedThumbnail = thumbnail;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _lastCapturedThumbnail = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final isPortrait = mediaQuery.orientation == Orientation.portrait;
    final padding = mediaQuery.padding;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Cámara',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: !_isCameraInitialized || controller == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                // Camera Preview
                _buildOptimizedCameraPreview(isPortrait, screenSize),

                // Controls Layer
                Positioned.fill(
                  child: SafeArea(
                    child:
                        _buildControlsOverlay(isPortrait, screenSize, padding),
                  ),
                ),

                // Recording Timer
                if (_isRecording) _buildRecordingTimer(),

                // Camera Controls at bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    minimum: EdgeInsets.only(bottom: isPortrait ? 20 : 10),
                    child: _buildCameraControls(isPortrait),
                  ),
                ),

                // Flash Tooltip
                if (_showFlashTooltip)
                  Positioned(
                    top: padding.top + 60,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _flashTooltipText ?? '',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                // Exposure Indicator
                if (_showExposureIndicator)
                  Positioned(
                    top: isPortrait ? padding.top + 60 : 60,
                    right: isPortrait ? 70 : padding.right + 70,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'EV: ${_currentExposureOffset.toStringAsFixed(1)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  // New optimized camera preview builder
  Widget _buildOptimizedCameraPreview(bool isPortrait, Size screenSize) {
    if (!_isCameraInitialized || !_isOrientationInitialized) {
      return const SizedBox.expand();
    }

    return ValueListenableBuilder<Size>(
      valueListenable: _previewSizeNotifier,
      builder: (context, previewSize, child) {
        if (previewSize == Size.zero) return const SizedBox.shrink();

        return ValueListenableBuilder<double>(
          valueListenable: _scaleFactor,
          builder: (context, scale, child) {
            return Container(
              color: Colors.black,
              child: Center(
                // Wrap everything in a Center widget
                child: AspectRatio(
                  aspectRatio: isPortrait
                      ? previewSize.height /
                          previewSize.width // When in portrait mode
                      : previewSize.width /
                          previewSize.height, // When in landscape mode
                  child: CameraPreview(
                    controller!,
                    child: _buildPreviewGestureDetector(screenSize),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPreviewGestureDetector(Size screenSize) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onTapDown: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final Offset localPoint = box.globalToLocal(details.globalPosition);

            _onViewFinderTap(
              TapDownDetails(localPosition: localPoint),
              constraints,
            );
          },
          onVerticalDragStart: (details) => _handleExposureDragStart(details),
          onVerticalDragUpdate: (details) => _handleExposureDragUpdate(details),
          onVerticalDragEnd: (details) => _handleExposureDragEnd(details),
        );
      },
    );
  }

  Widget _buildControlsOverlay(
      bool isPortrait, Size screenSize, EdgeInsets padding) {
    return Stack(
      children: [
        // Camera Switch Button - Solo en modo Portrait
        if (widget.cameras.length > 1 && isPortrait)
          Positioned(
            top: padding.top + 10,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              color: Colors.white,
              iconSize: 28,
              padding: const EdgeInsets.all(12),
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                shape: null,
              ),
              onPressed: _switchCamera,
            ),
          ),

        // Flash Control - Adjusted position
        Positioned(
          top: isPortrait ? padding.top + 10 : 10,
          right: isPortrait ? 20 : padding.right + 10,
          child: _buildFlashControl(),
        ),

        // Exposure Slider - iOS only with adjusted position
        if (Platform.isIOS)
          Positioned(
            right: isPortrait ? 20 : padding.right + 60,
            top: isPortrait ? screenSize.height * 0.25 : 10,
            bottom: isPortrait ? screenSize.height * 0.25 : null,
            child: _buildExposureSlider(isPortrait),
          ),

        // Focus Indicator
        if (_isFocusing && _focusPoint != null) _buildFocusIndicator(),

        // Zoom Indicator with adjusted position
        if (_isZooming)
          Positioned(
            top: isPortrait ? padding.top + 20 : 20,
            left: isPortrait ? 20 : padding.left + 20,
            child: _buildZoomIndicator(),
          ),
      ],
    );
  }

  Widget _buildCameraControls(bool isPortrait) {
    return Container(
      padding: EdgeInsets.symmetric(
        // Reduce horizontal padding in landscape mode by half
        horizontal: isPortrait ? 20 : 40,
        // Slightly adjust vertical padding
        vertical: isPortrait ? 20 : 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Change to center
        children: [
          SizedBox(
              width: isPortrait ? 20 : 40), // Add small spacing from left edge
          FloatingActionButton(
            heroTag: 'takePhotoFAB',
            onPressed: _onTakePictureButtonPressed,
            child: const Icon(Icons.photo_camera),
          ),
          SizedBox(
              width: isPortrait ? 40 : 60), // Add fixed spacing between buttons
          FloatingActionButton(
            heroTag: 'recordVideoFAB',
            onPressed: _onRecordVideoButtonPressed,
            child: Icon(
              _isRecording ? Icons.stop : Icons.videocam,
              color: _isRecording ? Colors.red : null,
            ),
          ),
          SizedBox(
              width: isPortrait ? 40 : 60), // Add fixed spacing between buttons
          _buildGalleryButton(),
          if (!isPortrait && widget.cameras.length > 1) ...[
            const SizedBox(width: 60),
            FloatingActionButton(
              heroTag: 'switchCameraFAB',
              onPressed: _switchCamera,
              child: const Icon(Icons.flip_camera_ios),
            ),
          ],
          SizedBox(
              width: isPortrait ? 20 : 40), // Add small spacing from right edge
        ],
      ),
    );
  }

  Widget _buildFlashControl() {
    return SizedBox(
      width: 40,
      height: 40,
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
        iconSize: 24, // Adjust the icon size
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildExposureSlider(bool isPortrait) {
    return RotatedBox(
      quarterTurns: 3,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 2,
          activeTrackColor: const Color(0xFFB0B0B0),
          inactiveTrackColor: const Color(0xFFB0B0B0),
          thumbShape: const SunThumbShape(thumbRadius: 15),
          overlayShape: SliderComponentShape.noOverlay,
          thumbColor: Colors.transparent,
        ),
        child: Slider(
          value: _currentExposureOffset,
          min: _minAvailableExposureOffset,
          max: _maxAvailableExposureOffset,
          onChanged: (value) {
            if (mounted) {
              setState(() {
                _currentExposureOffset = value;
                _showExposureIndicator = true;
              });
            }
            controller?.setExposureOffset(value);

            // Restart the timer to hide the indicator
            _exposureIndicatorTimer?.cancel();
            _exposureIndicatorTimer = Timer(const Duration(seconds: 1), () {
              if (mounted) {
                setState(() {
                  _showExposureIndicator = false;
                });
              }
            });

            // Restart the timer to hide the slider
            _exposureSliderTimer?.cancel();
            _exposureSliderTimer = Timer(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  _showExposureSlider = false;
                });
              }
            });
          },
          onChangeStart: (value) {
            if (mounted) {
              setState(() {
                _showExposureIndicator = true;
              });
            }
          },
          onChangeEnd: (value) {
            _exposureIndicatorTimer?.cancel();
            _exposureIndicatorTimer = Timer(const Duration(seconds: 1), () {
              if (mounted) {
                setState(() {
                  _showExposureIndicator = false;
                });
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildFocusIndicator() {
    return Positioned(
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
    );
  }

  Widget _buildZoomIndicator() {
    return Positioned(
      top: 20,
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.black.withAlpha(76), // 0.3 * 255 ≈ 76
        child: Text(
          '${_currentZoomLevel.toStringAsFixed(1)}x',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryButton() {
    return FloatingActionButton(
      heroTag: 'lastCapturedMediaFAB',
      onPressed: _lastCapturedThumbnail != null
          ? () {
              _navigateToLastCapturedMedia(context);
            }
          : () {
              _navigateToGallery(context);
            },
      child: _lastCapturedThumbnail != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.memory(
                _lastCapturedThumbnail!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            )
          : const Icon(Icons.photo_library),
    );
  }

  void _handleExposureDragStart(DragStartDetails details) {
    if (_pointerCount == 1) {
      // Show slider only for single-finger drag
      if (mounted) {
        setState(() {
          _showExposureSlider = true;
        });
      }
    }
  }

  void _handleExposureDragUpdate(DragUpdateDetails details) {
    if (Platform.isAndroid) {
      return; // Ignore exposure adjustments on Android
    }
    if (_pointerCount == 1) {
      // Update exposure only for single-finger drag
      // Update the exposure value based on vertical movement
      final double delta = details.primaryDelta ?? 0.0;
      final double sensitivity = 0.005;
      double newValue = _currentExposureOffset - delta * sensitivity;
      newValue = newValue.clamp(
          _minAvailableExposureOffset, _maxAvailableExposureOffset);
      if (mounted) {
        setState(() {
          _currentExposureOffset = newValue;
          _showExposureIndicator = true;
        });
      }
      controller?.setExposureOffset(_currentExposureOffset);

      // Restart the timer to hide the indicator
      _exposureIndicatorTimer?.cancel();
      _exposureIndicatorTimer = Timer(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _showExposureIndicator = false;
          });
        }
      });

      // Restart the timer to hide the slider
      _exposureSliderTimer?.cancel();
      _exposureSliderTimer = Timer(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _showExposureSlider = false;
          });
        }
      });
    }
  }

  void _handleExposureDragEnd(DragEndDetails details) {
    if (_pointerCount == 1) {
      // Hide slider after single-finger drag
      // Hide the slider after 1 second
      _exposureSliderTimer?.cancel();
      _exposureSliderTimer = Timer(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _showExposureSlider = false;
          });
        }
      });
    }
  }
}
