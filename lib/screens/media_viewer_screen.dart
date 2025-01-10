import 'package:flutter/material.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'dart:async'; // For Timer
import 'package:photo_manager/photo_manager.dart'; // Import photo_manager
import 'package:objectbox/objectbox.dart'; // Import ObjectBox
import '../objectbox.g.dart'; // Import the generated ObjectBox code
import 'package:share_plus/share_plus.dart';

class MediaViewerScreen extends StatefulWidget {
  final String mediaPath;
  final bool isVideo;
  final Store store; // Add Store parameter

  const MediaViewerScreen({
    super.key,
    required this.mediaPath,
    required this.isVideo,
    required this.store, // Initialize Store
  });

  @override
  MediaViewerScreenState createState() => MediaViewerScreenState();
}

class MediaViewerScreenState extends State<MediaViewerScreen> {
  VideoPlayerController? _videoController;
  bool _isMuted = false;
  bool _showControls = true;
  bool _isPlaying = false;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _initializeVideoPlayer();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    _videoController = VideoPlayerController.file(File(widget.mediaPath))
      ..initialize().then((_) {
        setState(() {
          _isPlaying = false;
        });
      });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
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
      body: Center(
        child: widget.isVideo
            ? _videoController != null && _videoController!.value.isInitialized
                ? GestureDetector(
                    onTap: _showControlsTemporarily, // Show controls on tap
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                        if (_showControls)
                          _buildVideoControls(), // Show controls
                      ],
                    ),
                  )
                : const CircularProgressIndicator()
            : _buildZoomableImage(), // Add zoom functionality for images
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        ),
                        minimumSize: MaterialStateProperty.all(const Size(0, 36)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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

  Widget _buildVideoControls() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Play/Pause Button
        Center(
          child: GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black
                    .withOpacity(0.7), // Dark background for visibility
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
          bottom: 80,
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
        Padding(
          padding:
              const EdgeInsets.only(bottom: 50.0), // Espacio desde el borde
          child: VideoProgressIndicator(
            _videoController!,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Colors.red, // Color de la barra de progreso
              backgroundColor: Colors.black38, // Color de fondo
            ),
          ),
        ),
      ],
    );
  }
}
