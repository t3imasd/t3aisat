import 'dart:async'; // Import for Timer class
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter/services.dart'; // For MethodChannel
import 'package:camera/camera.dart'; // Import for CameraDescription
import 'package:objectbox/objectbox.dart';
import 'media_viewer_screen.dart';
import '../model/photo_model.dart';
import '../objectbox.g.dart'; // Generated ObjectBox file
import '../main.dart'; // ValueNotifier imports from main.dart
import '../helpers/media_helpers.dart';

class GalleryScreen extends StatefulWidget {
  // Changed from StatelessWidget to StatefulWidget
  final Store store;
  final List<CameraDescription> cameras;

  const GalleryScreen({super.key, required this.store, required this.cameras});

  @override
  GalleryScreenState createState() => GalleryScreenState();
}

class GalleryScreenState extends State<GalleryScreen> {
  AssetEntity? _lastAsset; // Variable to store the last media asset
  AssetEntity? _selectedAsset; // Variable to store the selected media asset

  // Method to load and filter media based on EXIF and metadata
  Future<List<AssetEntity>> _loadAndFilterMedia(List<Photo> photoList) async {
    // Fetch the list of media albums (both photos and videos)
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.all, // Fetch both photos and videos
    );

    if (albums.isNotEmpty) {
      // Load the first 100 media files from the first album
      final List<AssetEntity> mediaFiles = await albums[0].getAssetListPaged(
        page: 0,
        size: 100, // Limit to 100 files
      );

      // Filter media based on metadata
      List<AssetEntity> filteredMedia = [];

      for (var media in mediaFiles) {
        if (media.type == AssetType.image) {
          // Check if the image is valid on both platforms
          final bool photoValid = await isValidPhoto(media, store);
          if (photoValid) {
            filteredMedia.add(media);
          }
        } else if (media.type == AssetType.video) {
          // Check if the video has the correct MPEG Comment
          final bool videoValid = await isValidVideo(media);
          if (videoValid) {
            filteredMedia.add(media);
          }
        }
      }

      // Sort media by creation date (newest first)
      filteredMedia
          .sort((a, b) => b.createDateTime.compareTo(a.createDateTime));

      _lastAsset = filteredMedia.isNotEmpty ? filteredMedia[0] : null;

      return filteredMedia; // Return the filtered and sorted list
    }

    return []; // Return an empty list if no media found
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color(0xFF1976D2)), // Add this line
        title: const Text(
          "Galería de Fotos",
          style: TextStyle(color: Color(0xFF1976D2)),
        ),
      ),
      body: ValueListenableBuilder<List<Photo>>(
        valueListenable: photoNotifier, // Escucha cambios en photoNotifier
        builder: (context, photoList, _) {
          return FutureBuilder<List<AssetEntity>>(
            future: _loadAndFilterMedia(photoList),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                final mediaFiles = snapshot.data!;
                if (snapshot.hasData &&
                    snapshot.data!.isNotEmpty &&
                    mediaFiles.isNotEmpty) {
                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // Number of columns in the grid
                      crossAxisSpacing: 4, // Space between columns
                      mainAxisSpacing: 4, // Space between rows
                      childAspectRatio: 1, // Ensure square thumbnails
                    ),
                    itemCount: mediaFiles.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () async {
                          _selectedAsset = mediaFiles[index];
                          final file = await mediaFiles[index].file;
                          if (file != null) {
                            // Navigate to MediaViewerScreen on tap and await the result
                            final deleted = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MediaViewerScreen(
                                  mediaPath: file.path,
                                  isVideo:
                                      mediaFiles[index].type == AssetType.video,
                                  store: widget.store, // Pass the store
                                ),
                              ),
                            );

                            if (deleted == true) {
                              setState(() {
                                // Refresh the gallery
                              });
                              print('_lastAsset: $_lastAsset');
                              // Verify if _lastAsset is contained in the mediaFiles list
                              if (_lastAsset != null &&
                                  _selectedAsset != null) {
                                if (_lastAsset!.id == _selectedAsset!.id) {
                                  // Navigate directly to CameraScreen
                                  Navigator.of(context).pop(true);
                                }
                              }
                            }
                          }
                        },
                        child: FutureBuilder<Uint8List?>(
                          future: mediaFiles[index].thumbnailDataWithSize(
                            const ThumbnailSize.square(
                                200), // Request square thumbnails (200x200)
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.hasData) {
                              return Image.memory(
                                snapshot.data!, // Display the image thumbnail
                                fit: BoxFit
                                    .cover, // Ensure the image covers the square thumbnail space
                              );
                            }
                            return const SizedBox(
                              child:
                                  CircularProgressIndicator(), // Show loading while fetching thumbnail
                            );
                          },
                        ),
                      );
                    },
                  );
                } else {
                  // Display Icons.videocam_off when mediaFiles is empty
                  return GridView(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1, // Single column grid
                    ),
                    children: [
                      Center(
                        child: Icon(
                          Icons.videocam_off,
                          size: 100,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  );
                }
              }
              return const Center(child: CircularProgressIndicator());
            },
          );
        },
      ),
    );
  }

  Widget _emptyGalleryMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.photo_library_outlined,
            size: 100,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No hay fotos o videos de T3 AI SAT.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
