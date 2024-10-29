import 'package:flutter/material.dart';
import 'dart:async'; // Import for Timer class
import 'package:flutter/services.dart'; // For MethodChannel
import 'package:native_exif/native_exif.dart'; // For EXIF data
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:photo_manager/photo_manager.dart';
import 'media_viewer_screen.dart'; // Import the new MediaViewerScreen

// Gallery Screen
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  // Method to load and filter media based on EXIF and metadata
  Future<List<AssetEntity>> _loadAndFilterMedia() async {
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
          // Check if the image has the correct EXIF UserComment
          final bool isValidPhoto = await _isValidPhoto(media);
          if (isValidPhoto) {
            filteredMedia.add(media);
          }
        } else if (media.type == AssetType.video) {
          // Check if the video has the correct MPEG Comment
          final bool isValidVideo = await _isValidVideo(media);
          if (isValidVideo) {
            filteredMedia.add(media);
          }
        }
      }

      // Sort media by creation date (newest first)
      filteredMedia
          .sort((a, b) => b.createDateTime.compareTo(a.createDateTime));

      return filteredMedia; // Return the filtered and sorted list
    }

    return []; // Return an empty list if no media found
  }

  // Method to check if the image has the correct EXIF UserComment
  Future<bool> _isValidPhoto(AssetEntity media) async {
    final file = await media.file;
    if (file == null) return false;

    // Use native_exif to extract EXIF data from the image
    final exif = await Exif.fromPath(file.path);
    // Get the 'UserComment' field from the EXIF data
    final userComment = await exif.getAttribute('UserComment');
    // Close the EXIF reader after reading attributes
    await exif.close();

    // Check if 'UserComment' starts with 'T3AI-SAT'
    if (userComment != null && userComment.startsWith('T3AI-SAT')) {
      return true;
    }

    return false;
  }

  // Method to check if the video has the correct MPEG Comment
  Future<bool> _isValidVideo(AssetEntity media) async {
    final file = await media.file;
    if (file == null) return false;

    // Use FFmpegKit to extract metadata from the video file
    final session = await FFmpegKit.execute("-i ${file.path} -f ffmetadata -");
    final returnCode = await session.getReturnCode();

    if (returnCode != null && ReturnCode.isSuccess(returnCode)) {
      final output = await session.getAllLogsAsString();
      // Updated regex to capture the 'comment' field properly including quotes
      final RegExp commentRegex = RegExp(r'comment\s*:\s*"(.+)"');
      final match = output != null ? commentRegex.firstMatch(output) : null;

      if (match != null) {
        final comment = match.group(1) ?? '';
        // Check if the comment ends with 'T3-AI SAT'
        return comment.trim().endsWith('T3-AI SAT');
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Galería de Fotos"),
      ),
      body: FutureBuilder<List<AssetEntity>>(
        future: _loadAndFilterMedia(), // Load and filter media by metadata
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            final mediaFiles = snapshot.data!;
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Number of columns in the grid
                crossAxisSpacing: 4, // Space between columns
                mainAxisSpacing: 4, // Space between rows
                childAspectRatio: 1, // Ensure square thumbnails
              ),
              itemCount: mediaFiles.length, // Total number of media files
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () async {
                    final file = await mediaFiles[index].file;
                    if (file != null) {
                      // Navigate to MediaViewerScreen on tap
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MediaViewerScreen(
                            mediaPath: file.path,
                            isVideo: mediaFiles[index].type == AssetType.video,
                          ),
                        ),
                      );
                    }
                  },
                  child: FutureBuilder<Uint8List?>(
                    future: mediaFiles[index].thumbnailDataWithSize(
                      const ThumbnailSize.square(
                          200), // Request square thumbnails (200x200)
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
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
          }
          return const Center(
            child:
                CircularProgressIndicator(), // Show loading indicator while fetching media
          );
        },
      ),
    );
  }
}
