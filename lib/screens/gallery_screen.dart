import 'dart:async'; // Import for Timer class
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart'; // For MethodChannel
import 'package:camera/camera.dart'; // Import for CameraDescription
import 'package:objectbox/objectbox.dart';
import 'media_viewer_screen.dart';
import '../model/photo_model.dart';
import '../model/media_model.dart';  // Import Media class
import '../objectbox.g.dart'; // Generated ObjectBox file
import '../main.dart'; // ValueNotifier imports from main.dart
import '../helpers/media_helpers.dart';
import 'dart:io'; // Add Platform import
import 'package:logging/logging.dart'; // Add Logger import

class GalleryScreen extends StatefulWidget {
  // Changed from StatelessWidget to StatefulWidget
  final Store store;
  final List<CameraDescription> cameras;

  const GalleryScreen({super.key, required this.store, required this.cameras});

  @override
  GalleryScreenState createState() => GalleryScreenState();
}

class GalleryScreenState extends State<GalleryScreen> {
  final Logger log = Logger('GalleryScreen'); // Add Logger instance
  AssetEntity? _lastAsset; // Variable to store the last media asset
  AssetEntity? _selectedAsset; // Variable to store the selected media asset
  Map<String, Media> _mediaCache = {}; // Cache de objetos Media

  // Método para obtener el objeto Media asociado a un AssetEntity
  Future<Media?> _getMediaForAsset(AssetEntity asset) async {
    log.info('Buscando Media para asset: ${asset.id} - Tipo: ${asset.type}');
    
    if (_mediaCache.containsKey(asset.id)) {
      log.info('Encontrado en caché');
      return _mediaCache[asset.id];
    }

    final box = widget.store.box<Media>();
    Media? media;
    
    if (Platform.isIOS) {
      final query = box.query(Media_.galleryId.equals(asset.id)).build();
      media = query.findFirst();
      log.info('Búsqueda iOS por galleryId: ${asset.id} -> ${media != null ? "✅" : "❌"}');
      query.close();
    } else {
      final assetFile = await asset.file;
      if (assetFile != null) {
        final fileName = assetFile.path.split('/').last;
        log.info('Buscando por nombre de archivo: $fileName');
        
        // Buscar primero por nombre de archivo
        final allMedia = box.getAll();
        media = allMedia.firstWhereOrNull((m) {
          final mediaFileName = m.path.split('/').last;
          final match = mediaFileName == fileName;
          log.info('Comparando: $mediaFileName con $fileName -> ${match ? "✅" : "❌"}');
          return match;
        });
        
        // Si no se encuentra, buscar por ruta completa
        if (media == null) {
          log.info('Buscando por ruta completa: ${assetFile.path}');
          final query = box.query(Media_.path.equals(assetFile.path)).build();
          media = query.findFirst();
          query.close();
        }
      }
    }

    if (media != null) {
      log.info('''
      ✅ Media encontrado:
      ID: ${media.id}
      Path: ${media.path}
      IsVideo: ${media.isVideo}
      GalleryId: ${media.galleryId}
      MediaStoreId: ${media.mediaStoreId}
      ''');
      _mediaCache[asset.id] = media;
    } else {
      log.info('❌ No se encontró Media para este asset');
    }

    return media;
  }

  // Method to load and filter media based on EXIF and metadata
  Future<List<AssetEntity>> _loadAndFilterMedia(List<Photo> photoList, List<Media> mediaList) async {
    log.info('Loading and filtering media files');
    
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.all,
    );

    if (albums.isNotEmpty) {
      final List<AssetEntity> mediaFiles = await albums[0].getAssetListPaged(
        page: 0,
        size: 100,
      );

      List<AssetEntity> filteredMedia = [];

      for (var media in mediaFiles) {
        log.info('Processing media: ${media.id} - Type: ${media.type}');
        
        final bool isValid = media.type == AssetType.image 
            ? await isValidPhoto(media, widget.store)
            : await isValidVideo(media);
            
        if (isValid) {
          log.info('Media validated successfully');
          await _getMediaForAsset(media); // Pre-cache media object
          filteredMedia.add(media);
        } else {
          log.info('Media validation failed');
        }
      }

      filteredMedia.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
      _lastAsset = filteredMedia.isNotEmpty ? filteredMedia[0] : null;
      
      log.info('Filtered media count: ${filteredMedia.length}');
      return filteredMedia;
    }

    log.info('No albums found');
    return [];
  }

  Future<void> _navigateToMediaViewer(AssetEntity asset, Media? media) async {
    log.info('Navigating to media viewer for asset: ${asset.id}');
    
    final file = await asset.file;
    if (file == null) {
      log.warning('Could not get file for asset: ${asset.id}');
      return;
    }

    if (!mounted) return;

    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => MediaViewerScreen(
          mediaPath: file.path,
          isVideo: asset.type == AssetType.video,
          store: widget.store,
          media: media, // Pass media even if dimensions are null
        ),
      ),
    );

    if (deleted == true) {
      setState(() {});
      if (_lastAsset?.id == asset.id) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Widget _buildGalleryGrid(List<AssetEntity> mediaFiles) {
    final orientation = MediaQuery.of(context).orientation;
    final crossAxisCount = orientation == Orientation.portrait ? 3 : 5;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: mediaFiles.length,
      itemBuilder: (context, index) {
        return FutureBuilder<Media?>(
          future: _getMediaForAsset(mediaFiles[index]),
          builder: (context, mediaSnapshot) {
            if (mediaSnapshot.connectionState == ConnectionState.done) {
              final media = mediaSnapshot.data;
              
              return GestureDetector(
                onTap: () => _navigateToMediaViewer(mediaFiles[index], media),
                child: FutureBuilder<Uint8List?>(
                  future: mediaFiles[index].thumbnailDataWithSize(
                    const ThumbnailSize.square(200),
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData) {
                      return Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                      );
                    }
                    return const SizedBox(
                      child: CircularProgressIndicator(),
                    );
                  },
                ),
              );
            }
            return const SizedBox(
              child: CircularProgressIndicator(),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme:
            const IconThemeData(color: Color(0xFF1976D2)), // Add this line
        title: const Text(
          "Galería de Fotos",
          style: TextStyle(color: Color(0xFF1976D2)),
        ),
      ),
      body: ValueListenableBuilder<List<Photo>>(
        valueListenable: photoNotifier, // Escucha cambios en photoNotifier
        builder: (context, photoList, _) {
          return ValueListenableBuilder<List<Media>>(
            valueListenable: mediaNotifier,
            builder: (context, mediaList, _) {
              return FutureBuilder<List<AssetEntity>>(
                future: _loadAndFilterMedia(photoList, mediaList), // Updated to take both lists
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData) {
                    final mediaFiles = snapshot.data!;
                    if (mediaFiles.isNotEmpty) {
                      return _buildGalleryGrid(mediaFiles);
                    }
                    return const Center(
                      child: Icon(
                        Icons.videocam_off,
                        size: 100,
                        color: Colors.grey,
                      ),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              );
            },
          );
        },
      ),
    );
  }

}
