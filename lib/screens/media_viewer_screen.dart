import 'package:flutter/material.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'dart:async'; // For Timer
import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart'; // Import photo_manager
import 'package:objectbox/objectbox.dart'; // Import ObjectBox
import '../objectbox.g.dart'; // Import the generated ObjectBox code
import 'package:share_plus/share_plus.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geotypes/geotypes.dart' as geojson;
import '../model/media_model.dart';
import 'parcel_map_screen.dart';
import 'package:logging/logging.dart'; // Add Logger import
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Add dotenv import
import 'package:flutter/services.dart'; // for rootBundle
import 'dart:math' show min;
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart' show OneSequenceGestureRecognizer, PanGestureRecognizer, ScaleGestureRecognizer;

class MediaViewerScreen extends StatefulWidget {
  final String mediaPath;
  final bool isVideo;
  final Store store;
  final Media? media; // Add media parameter

  const MediaViewerScreen({
    super.key,
    required this.mediaPath,
    required this.isVideo,
    required this.store,
    this.media, // Optional media parameter
  });

  @override
  MediaViewerScreenState createState() => MediaViewerScreenState();
}

class MediaViewerScreenState extends State<MediaViewerScreen>
    with TickerProviderStateMixin {
  final Logger log = Logger('MediaViewerScreen'); // Add Logger instance
  // Add access token field
  final String accessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
  VideoPlayerController? _videoController;
  bool _isMuted = false;
  bool _showControls = true;
  bool _isPlaying = false;
  Timer? _hideControlsTimer;
  final List<mapbox.MapboxMap> _mapControllers = [];
  bool _isExpanded = false;
  String? _staticMapUrl;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isMapLoading = true;

  // Add map style state variables
  String _mapStyle = "mapbox://styles/mapbox/outdoors-v12";
  mapbox.MapboxMap? _mapController;
  bool _showMap = true; // Add this field

  @override
  void initState() {
    super.initState();
    // Set Mapbox Access Token
    mapbox.MapboxOptions.setAccessToken(accessToken);
    if (widget.isVideo) {
      _initializeVideoPlayer();
    }
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    if (widget.media != null) {
      setState(() {
        _staticMapUrl = _generateStaticMapUrl();
      });
    }
    _isMapLoading = true;
  }

  Future<void> _initializeVideoPlayer() async {
    _videoController = VideoPlayerController.file(File(widget.mediaPath))
      ..initialize().then((_) {
        setState(() {
          _isPlaying = false;
        });
        // Add listener for video completion
        _videoController!.addListener(() {
          if (_videoController!.value.position >= _videoController!.value.duration) {
            setState(() {
              _isPlaying = false;
              _showMap = true; // Show map when video ends
            });
          }
        });
      });
  }

  String _generateStaticMapUrl() {
    // Skip map generation for media without dimensions
    if (widget.media == null || widget.media?.width == null || widget.media?.height == null) {
      return '';
    }
    
    final accessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'];
    return 'https://api.mapbox.com/styles/v1/mapbox/outdoors-v12/static/'
           'pin-s+ff0000(${widget.media!.longitude},${widget.media!.latitude})/'
           '${widget.media!.longitude},${widget.media!.latitude},15,0/'
           '300x300@2x'
           '?access_token=$accessToken';
  }

  Future<String> _generateStaticMap(double lat, double lon) async {
    if (widget.media?.width == null || widget.media?.height == null) {
      return '';
    }

    final width = 300;
    final height = 300;
    final zoom = 15;

    return 'https://api.mapbox.com/styles/v1/mapbox/outdoors-v12/static/pin-s+ff0000($lon,$lat)/$lon,$lat,$zoom/$width'
        'x$height@2x?access_token=$accessToken';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _videoController?.dispose();
    _hideControlsTimer?.cancel();

    // Safe disposal of all map controllers
    for (final controller in _mapControllers) {
      try {
        controller.dispose();
      } catch (e) {
        log.warning('Error disposing map controller: $e');
      }
    }
    _mapControllers.clear();

    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
        _showMap = true; // Show map when paused
      } else {
        _videoController!.play();
        _isPlaying = true;
        _showMap = false; // Hide map when playing
        _startHideControlsTimer(); // Start hiding the controls
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _videoController!.setVolume(_isMuted ? 0 : 1);
    });
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _showControls = false; // Hide controls after 3 seconds
      });
    });
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    _startHideControlsTimer(); // Restart the timer when controls are shown
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme:
            const IconThemeData(color: Color(0xFF1976D2)), // Add this line
        title: Text(
          widget.isVideo ? 'Ver Vídeo' : 'Ver Foto',
          style: const TextStyle(color: Color(0xFF1976D2)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF1976D2)),
            onPressed: _shareMedia,
            tooltip: 'Compartir',
          ),
          IconButton(
            icon: Icon(
              Icons.delete,
              color: Colors.grey, // Subtle color
              size: 24,
            ),
            onPressed: _deleteMedia,
            splashColor: Colors.red, // Highlight color on press
            tooltip: 'Eliminar',
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: widget.isVideo
                ? _videoController?.value.isInitialized == true
                    ? _buildVideoPlayer()
                    : const CircularProgressIndicator()
                : _buildZoomableImage(),
          ),

          if (!_isExpanded && _staticMapUrl != null && (!widget.isVideo || _showMap))
            Positioned(
              top: widget.isVideo ? 16 : null,
              bottom: !widget.isVideo ? 8 : null,
                right: widget.isVideo 
                ? (MediaQuery.of(context).orientation == Orientation.landscape ? 36 : 16)
                : (MediaQuery.of(context).orientation == Orientation.landscape ? 36 : 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _isExpanded = true);
                  _animationController.forward();
                },
                child: _buildStaticMapThumbnail(),
              ),
            ),

          if (_isExpanded)
            Positioned.fill(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      _animationController.reverse().then((_) {
                        setState(() => _isExpanded = false);
                      });
                    },
                    child: Container(color: Colors.black54),
                  ),
                  Center(child: _buildExpandedMap()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _deleteMedia() async {
    // Show confirmation dialog
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(16.0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  widget.isVideo ? 'Eliminar vídeo' : 'Eliminar foto',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  widget.isVideo
                      ? '¿Estás seguro de que deseas eliminar este vídeo? Esta acción no se puede deshacer.'
                      : '¿Estás seguro de que deseas eliminar esta foto? Esta acción no se puede deshacer.',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: ButtonStyle(
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                        ),
                        minimumSize: WidgetStateProperty.all(const Size(0, 36)),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontSize: 14.0),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12.0),
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        'Eliminar',
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldDelete == true) {
      try {
        if (Platform.isIOS) {
          final requestType =
              widget.isVideo ? RequestType.video : RequestType.image;
          final List<AssetPathEntity> albums =
              await PhotoManager.getAssetPathList(type: requestType);
          AssetEntity? targetAsset;

          for (final album in albums) {
            final List<AssetEntity> assets =
                await album.getAssetListPaged(page: 0, size: 100);
            for (final asset in assets) {
              final file = await asset.file;
              if (file?.path == widget.mediaPath) {
                targetAsset = asset;
                break;
              }
            }
            if (targetAsset != null) break;
          }

          if (targetAsset != null) {
            final result =
                await PhotoManager.editor.deleteWithIds([targetAsset.id]);
            if (result.isNotEmpty) {
              Navigator.of(context).pop(true);
              return;
            }
          }

          throw Exception(widget.isVideo
              ? 'No se pudo eliminar el vídeo de la biblioteca de fotos'
              : 'No se pudo eliminar la foto de la biblioteca de fotos');
        } else {
          // For Android, save photo or video in the gallery
          final requestType =
              widget.isVideo ? RequestType.video : RequestType.image;
          final List<AssetPathEntity> albums =
              await PhotoManager.getAssetPathList(type: requestType);
          AssetEntity? targetAsset;

          for (final album in albums) {
            int page = 0;
            bool assetFound = false;

            while (true) {
              final List<AssetEntity> assets =
                  await album.getAssetListPaged(page: page, size: 100);
              if (assets.isEmpty) {
                break;
              }
              for (final asset in assets) {
                final file = await asset.file;
                if (file?.path == widget.mediaPath) {
                  targetAsset = asset;
                  assetFound = true;
                  break;
                }
              }
              if (assetFound) break;
              page++;
            }
            if (targetAsset != null) break;
          }

          if (targetAsset != null) {
            final result =
                await PhotoManager.editor.deleteWithIds([targetAsset.id]);
            if (result.isNotEmpty) {
              Navigator.of(context).pop(true);
              return;
            }
          }

          throw Exception(widget.isVideo
              ? 'No se pudo eliminar el vídeo de la biblioteca de fotos'
              : 'No se pudo eliminar la foto de la biblioteca de fotos');
        }
      } catch (e) {
        // Show error message if elimination fails
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al eliminar el archivo'),
              backgroundColor: Colors.red,
            ),
          );
        }
        Navigator.of(context).pop(false);
      }
    }
    Navigator.pop(context, true); // Indicate that media was deleted
  }

  void _shareMedia() async {
    if (widget.mediaPath.isNotEmpty) {
      await Share.shareXFiles([XFile(widget.mediaPath)]);
    }
  }

  Widget _buildZoomableImage() {
    return InteractiveViewer(
      panEnabled: true, // Allow panning (scrolling)
      minScale: 0.5, // Minimum zoom out
      maxScale: 4.0, // Maximum zoom in
      child: Image.file(
        File(widget.mediaPath),
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _showControlsTemporarily,
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_videoController!),
              if (_showControls) ...[
                Container(color: Colors.black.withOpacity(0.3)),
                _buildVideoControls(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoControls() {
    return Stack(
      children: [
        // Play/Pause Button
        Center(
          child: GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 56,
              ),
            ),
          ),
        ),
        // Mute/Unmute Button
        Positioned(
          bottom: 40,
          right: 30,
          child: GestureDetector(
            onTap: _toggleMute,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(
                _isMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
        // Video Progress Bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 20,
          child: VideoProgressIndicator(
            _videoController!,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Color(0xFF1976D2),
              backgroundColor: Colors.black38,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaticMapThumbnail() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    final mapSize = isLandscape ? screenWidth * 0.20 : screenWidth * 0.33;

    return Hero(
      tag: 'map-${widget.media!.id}',
      child: Container(
        width: mapSize,
        height: mapSize,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            _staticMapUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.map_outlined, size: 40),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedMap() {
    if (widget.media == null) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final size = min(screenWidth, screenHeight) * 0.8;

    return Hero(
      tag: 'map-${widget.media!.id}',
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: child,
          );
        },
        child: Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: [
                      mapbox.MapWidget(
                        key: ValueKey("${widget.media!.id}_overlay"),
                        mapOptions: mapbox.MapOptions(
                          pixelRatio: MediaQuery.of(context).devicePixelRatio,
                        ),
                        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                            Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
                            Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
                        },
                        onMapCreated: (controller) async {
                          _mapController = controller;
                          final coordinates = geojson.Position(
                            widget.media!.longitude,
                            widget.media!.latitude,
                          );
                          final point = mapbox.Point(coordinates: coordinates);

                          try {
                            await controller.loadStyleURI(_mapStyle);
                            await controller.setCamera(
                              mapbox.CameraOptions(
                                center: point,
                                zoom: 15.0,
                              ),
                            );

                            final ByteData bytes = await rootBundle.load('assets/images/location-marker.png');
                            final Uint8List list = bytes.buffer.asUint8List();

                            await controller.style.addStyleImage(
                              "custom-marker",
                              2.0,
                              mapbox.MbxImage(width: 44, height: 44, data: list),
                              false, [], [], null
                            );

                            final pointAnnotationManager = await controller.annotations.createPointAnnotationManager();
                            await pointAnnotationManager.create(
                              mapbox.PointAnnotationOptions(
                                geometry: point,
                                iconImage: "custom-marker",
                                iconSize: 0.8,
                              ),
                            );
                          } catch (e) {
                            log.severe('Error initializing overlay map: $e');
                            // Fallback to default marker if custom image fails
                            try {
                              final pointAnnotationManager = await controller.annotations.createPointAnnotationManager();
                              await pointAnnotationManager.create(
                                mapbox.PointAnnotationOptions(
                                  geometry: point,
                                  iconImage: "marker",
                                  iconSize: 1.0,
                                ),
                              );
                            } catch (e) {
                              log.severe('Error creating default marker in overlay: $e');
                            }
                          } finally {
                            setState(() {
                              _isMapLoading = false;
                            });
                          }
                        },
                      ),
                      if (_isMapLoading)
                        Container(
                          color: Colors.white.withOpacity(0.7),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Material(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        setState(() => _isMapLoading = true);
                        final newStyle = _mapStyle == "mapbox://styles/mapbox/outdoors-v12"
                            ? "mapbox://styles/mapbox/satellite-streets-v12"
                            : "mapbox://styles/mapbox/outdoors-v12";
                        
                        try {
                          await _mapController?.loadStyleURI(newStyle);
                          setState(() {
                            _mapStyle = newStyle;
                            _isMapLoading = false;
                          });
                        } catch (e) {
                          log.severe('Error changing map style: $e');
                          setState(() => _isMapLoading = false);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          _mapStyle == "mapbox://styles/mapbox/outdoors-v12"
                              ? Icons.satellite_alt
                              : Icons.terrain,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
