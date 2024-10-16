import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart'; // For MethodChannel
import 'package:intl/intl.dart'; // For date formatting
import 'package:native_exif/native_exif.dart'; // For EXIF data
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:video_player/video_player.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:archive/archive.dart'; // To decompress files

class MediaLocationScreen extends StatefulWidget {
  final String mediaPath;
  final bool isVideo;

  const MediaLocationScreen(
      {super.key, required this.mediaPath, required this.isVideo});

  @override
  MediaLocationScreenState createState() => MediaLocationScreenState();
}

class MediaLocationScreenState extends State<MediaLocationScreen> {
  Position? _currentPosition;
  String? _address;
  final Logger log = Logger('MediaLocationScreen');
  String?
      _updatedMediaPath; // Variable to store the updated media (image/video) path
  bool _isLoading = true; // Variable to manage the loading spinner

  VideoPlayerController? _videoController;

  Directory? _tempDir;
  String? _fontFilePath;

  @override
  void initState() {
    super.initState();

    _initializeFonts(); // Method to initialize fonts
    _listFFmpegFilters(); // Method to list the filters available

    _getCurrentLocation();
  }

  Future<void> _initializeFonts() async {
    try {
      // Load the TTF font directly from the Assets
      final fontData =
          await rootBundle.load('assets/fonts/roboto/Roboto-Bold.ttf');
      final fontBytes = fontData.buffer.asUint8List();

      // Write the font to a temporary file so that FFmpeg can access it
      _tempDir = await getTemporaryDirectory();
      final fontFile = File('${_tempDir!.path}/Roboto-Bold.ttf');
      await fontFile.writeAsBytes(fontBytes);

      // Verify that the font file exists
      if (!await fontFile.exists()) {
        log.severe(
            'The font file could not be written to the temporary directory.');
        return;
      }

      _fontFilePath = fontFile.path;

      // Register the font directories
      if (Platform.isAndroid) {
        await FFmpegKitConfig.setFontDirectoryList([
          '/system/fonts', // System Fonts Directory
          _tempDir!.path, // Temporary Directory where the font is
        ]);
      } else if (Platform.isIOS) {
        await FFmpegKitConfig.setFontDirectoryList([
          '/System/Library/Fonts', // System Fonts Directory
          _tempDir!.path, // Temporary Directory where the font is
        ]);
      }
    } catch (e) {
      log.severe('Error initializing fonts: $e');
    }
  }

  Future<void> _listFFmpegFilters() async {
    final session = await FFmpegKit.execute('-filters');
    final output = await session.getAllLogsAsString();
    // Check if drawtext filter is available
    final bool drawTextFilter = output?.contains('drawtext') ?? false;
    if (!drawTextFilter) {
      log.severe('drawtext filter is not available in FFmpeg');
    }
    log.info('FFmpeg filters:\n$output');
  }

  // Function to obtain the current location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      log.severe('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        log.severe('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      log.severe('Location permissions are permanently denied');
      return;
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      log.info('Current position: $_currentPosition');

      // Obtain address from coordinates
      await _getAddressFromCoordinates(
          _currentPosition!.latitude, _currentPosition!.longitude);

      // Write the text on the image or video and save it in the gallery
      if (widget.isVideo) {
        await _writeTextOnVideoAndSaveToGallery(widget.mediaPath);
      } else {
        await _writeTextOnImageAndSaveToGallery(widget.mediaPath);
      }
    } catch (e) {
      log.severe('Failed to obtain location or process media: $e');
    } finally {
      // Ensure the loading spinner is hidden
      setState(() {
        _isLoading = false; // Hide the loading spinner when processing is done
      });
    }
  }

  // Function to get the address from the coordinates
  Future<void> _getAddressFromCoordinates(double lat, double lon) async {
    final accessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'];
    final url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$lon,$lat.json?access_token=$accessToken';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'].isNotEmpty) {
          setState(() {
            // Adjust the address to be split into three lines
            final addressParts = data['features'][0]['place_name'].split(',');
            _address =
                "${addressParts[0].trim()}\n${addressParts[1].trim()}\n${addressParts[2].trim()}";
          });
          log.info('Address: $_address');
        }
      } else {
        log.severe('Failed to get address from coordinates');
      }
    } catch (e) {
      log.severe('Error fetching address: $e');
    }
  }

  // Function to convert decimal coordinates to DMS format
  String _convertToDMS(double decimal) {
    final degrees = decimal.truncate();
    final minutes = ((decimal - degrees) * 60).truncate();
    final seconds = (((decimal - degrees) * 60) - minutes) * 60;

    return '${degrees.abs()}°${minutes.abs()}\'${seconds.abs().toStringAsFixed(2)}" ${decimal >= 0 ? 'N' : 'S'}';
  }

  // TODO: To add ICC Profile data (e.g., RedMatrixColumn, GreenMatrixColumn, BlueMatrixColumn, MediaWhitePoint),
  // consider integrating an image processing library that supports full ICC profile handling, such as
  // ImageMagick or GraphicsMagick. You may need to extract the ICC profile from the image file, modify it,
  // and then re-embed it using a tool that provides robust support for ICC profiles.
  // This step would involve:
  // 1. Extracting the existing ICC profile from the image if present.
  // 2. Modifying or appending the necessary color profile metadata.
  //    - Profile Description
  //    - Red Matrix Column
  //    - Green Matrix Column
  //    - Blue Matrix Column
  //    - Media White Point
  //    - Red Tone Reproduction Curve
  //    - Green Tone Reproduction Curve
  //    - Blue Tone Reproduction Curve
  // 3. Re-embedding the updated ICC profile back into the image.
  // Note: Flutter does not natively support ICC profile editing, and this may need an external tool or plugin
  // to be implemented efficiently for both Android and iOS.
  // IMPORTANT: ICC Profile data is not essential to verify the integrity of the image, but it can be useful for color management.

  // Function to add EXIF data to the image
  Future<void> _addExifData(String imagePath) async {
    try {
      final exif = await Exif.fromPath(imagePath);

      if (_currentPosition != null) {
        // Add GPS coordinates
        await exif.writeAttributes({
          'GPSLatitude': _currentPosition!.latitude.toString(),
          'GPSLongitude': _currentPosition!.longitude.toString(),
        });
      }

      // Add GPS Date/Time in UTC
      final now = DateTime.now().toUtc();
      await exif.writeAttributes({
        'GPSDateStamp': DateFormat('yyyy:MM:dd').format(now),
        'GPSTimeStamp': DateFormat('HH:mm:ss').format(now),
      });

      // Add other EXIF data with ASCII encoding
      await exif.writeAttributes({
        'DateTimeOriginal':
            DateFormat('yyyy:MM:dd HH:mm:ss').format(DateTime.now()),
        'UserComment':
            't3AI-SAT App. Direccion donde se tomó la foto: ${_address ?? 'Sin direccion'}',
        'ProfileDescription': 'sRGB', // Add color profile description
        'ColorSpace': '1', // Add color space as sRGB (value 1 means sRGB)
      });

      await exif.close();
    } catch (e) {
      log.severe('Error writing EXIF data: $e');
    }
  }

  int countLinesInText(String text) {
    // Verify if the last two characters are '\ n'
    if (text.length >= 2 && text.substring(text.length - 2) == '\n\n') {
      // Eliminate the last two characters
      text = text.substring(0, text.length - 2);
    }

    // Obtain the correct number of lines with text
    int numberOfLines = text.split('\n').length;

    return numberOfLines;
  }

  // Function to get the directory path for saving on Android in the DCIM/Camera folder
  Future<String> _getExternalStoragePath() async {
    // Android DCIM directory
    Directory? externalDir = Directory('/storage/emulated/0/DCIM/Camera');
    if (await externalDir.exists()) {
      return externalDir.path;
    } else {
      // If the directory doesn't exist, create it
      externalDir.create(recursive: true);
      return externalDir.path;
    }
  }

  // Function to save the photo with the location on the device and the gallery
  Future<void> _writeTextOnImageAndSaveToGallery(String imagePath) async {
    try {
      // Read the original image file as bytes
      final bytes = await File(imagePath).readAsBytes();
      final img.Image originalImage = img.decodeImage(bytes)!;

      // Load the font from the assets to draw text on the image
      final fontData = await rootBundle.load(
          'assets/fonts/roboto_bold/Roboto-Bold-20-size-white-color.ttf.zip');
      final font = img.BitmapFont.fromZip(fontData.buffer.asUint8List());

      // Convert coordinates to Degrees, Minutes, Seconds (DMS) format
      final latitudeDMS = _convertToDMS(_currentPosition!.latitude);
      final longitudeDMS = _convertToDMS(_currentPosition!.longitude);

      // Get the current date and time
      final now = DateTime.now();
      final timeZoneName =
          now.timeZoneName; // Detects the time zone name (e.g., CEST, CET)

      // Add 1 second to the network time to simulate network synchronization
      final networkTime = now.add(const Duration(seconds: 1));

      // Format the network and local times
      final formattedNetworkTime =
          '${DateFormat('dd MMM yyyy HH:mm:ss').format(networkTime)} $timeZoneName';
      final formattedLocalTime =
          '${DateFormat('dd MMM yyyy HH:mm:ss').format(now)} $timeZoneName';

      final formattedLocation = 'Lat: $latitudeDMS\nLon: $longitudeDMS';
      log.info('Formatted location: $formattedLocation');

      // Format the address and location for displaying on the image
      final formattedAddress = _address?.split(',').join('\n');

      // Build the text that will be drawn on the image
      final formattedText = '''Network: $formattedNetworkTime
Local: $formattedLocalTime
$latitudeDMS $longitudeDMS
$formattedAddress
T3AI-SAT App''';

      // Calculate text size
      final numLineBreaks = countLinesInText(formattedText);

      final textHeight = font.lineHeight * numLineBreaks;

      // Draw the address and coordinates on the image
      final updatedImage = img.drawString(
        originalImage,
        formattedText,
        font: font,
        x: 20, // Left margin
        y: originalImage.height -
            textHeight -
            20, // Position the text at the bottom
        color: img.ColorRgba8(255, 255, 255, 255), // White color for text
      );

      // Generate the filename with the format t3aisat_yyyymmdd_hhmmss.jpg
      final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(now);

      String updatedImagePath;

      if (Platform.isAndroid) {
        // Use custom path for Android DCIM/Camera folder
        final externalStoragePath = await _getExternalStoragePath();
        updatedImagePath = path.join(
          externalStoragePath,
          't3aisat_$formattedDate.jpg', // Filename with the desired format
        );
      } else if (Platform.isIOS) {
        // Use application documents directory for initial save on iOS
        final directory = await getApplicationDocumentsDirectory();
        updatedImagePath = path.join(
          directory.path,
          't3aisat_$formattedDate.jpg', // Filename with the desired format
        );
      } else {
        log.severe('Unsupported platform');
        return;
      }

      // Save the updated image to the specified path
      final updatedImageFile = File(updatedImagePath);
      log.info('Updated image path: $updatedImagePath');
      log.info('Updated image file path: ${updatedImageFile.path}');

      // Write the updated image bytes to the file
      await updatedImageFile.writeAsBytes(img.encodeJpg(updatedImage));

      // Verify if the file exists after saving
      if (await updatedImageFile.exists()) {
        log.info('File created successfully: ${updatedImageFile.path}');
      } else {
        log.severe('File not created: ${updatedImageFile.path}');
        return;
      }

      // Add EXIF data (e.g., GPS coordinates, description) to the image
      await _addExifData(updatedImageFile.path);

      // Request permission to save in the gallery
      var status = await Permission.photos.status;
      if (!status.isGranted) {
        status = await Permission.photos.request();
      }

      if (status.isGranted) {
        if (Platform.isAndroid) {
          // Save to gallery using ImageGallerySaver for Android
          final result =
              await ImageGallerySaver.saveFile(updatedImageFile.path);
          if (result != null &&
              result['isSuccess'] != null &&
              result['isSuccess']) {
            log.info(
                'Updated image saved to gallery on Android: ${result['filePath']}');
          } else {
            log.severe('Failed to save image to gallery');
          }
        } else if (Platform.isIOS) {
          // Use platform channel to save the image with EXIF metadata on iOS
          await _saveImageToGalleryWithExifIOS(updatedImagePath);
          log.info('Updated image saved to gallery on iOS');
        }
      } else {
        log.severe('Permission denied to access photos');
      }

      // Update the state to reflect the new image path in the UI
      setState(() {
        _updatedMediaPath = updatedImagePath;
      });
    } catch (e) {
      // Log any errors that occur during the image processing
      log.severe('Failed to process image: $e');
    }
  }

  // Function to save the image to the gallery with EXIF metadata on iOS
  Future<void> _saveImageToGalleryWithExifIOS(String imagePath) async {
    try {
      // Create a method channel to interact with native iOS code
      const platform = MethodChannel('com.t3aisat/save_to_gallery');
      await platform
          .invokeMethod('saveImageWithExif', {'imagePath': imagePath});
      log.info('Updated image saved to gallery on iOS');
    } catch (e) {
      log.severe(
          'Failed to save image to gallery on iOS with EXIF metadata: $e');
    }
  }

  // Function to write text in the video and save it in the gallery
  Future<void> _writeTextOnVideoAndSaveToGallery(String videoPath) async {
    try {
      // Verify that the font file path is set
      if (_fontFilePath == null) {
        log.severe('Font file path is not initialized.');
        return;
      }

      // Verify that the input video exists
      final inputVideoFile = File(videoPath);
      if (!await inputVideoFile.exists()) {
        log.severe('Input video file does not exist at path: $videoPath');
        return;
      }

      // Convert the .temp file to .mp4 by copying it
      final String inputMp4Path = path.join(
        path.dirname(videoPath),
        '${path.basenameWithoutExtension(videoPath)}.mp4',
      );
      final inputMp4File = File(inputMp4Path);
      await inputVideoFile.copy(inputMp4Path);

      // Verify that the input video exists
      if (!await inputMp4File.exists()) {
        log.severe('Input video file does not exist at path: $inputMp4Path');
        return;
      }

      // Optionally, delete the original .temp file if no longer needed
      // await inputVideoFile.delete();

      // Verify that the file has a .mp4 extension
      if (path.extension(inputMp4Path).toLowerCase() != '.mp4') {
        log.severe('Input video file is not an MP4: $inputMp4Path');
        return;
      }

      // Convert coordinates to Degrees, Minutes, Seconds (DMS) format
      final latitudeDMS = _convertToDMS(_currentPosition!.latitude);
      final longitudeDMS = _convertToDMS(_currentPosition!.longitude);

      // Get the current date and time
      final now = DateTime.now();
      final timeZoneName =
          now.timeZoneName; // Detects the time zone name (e.g., CEST, CET)

      // Add 1 second to the network time to simulate network synchronization
      final networkTime = now.add(const Duration(seconds: 1));

      // Format the network and local times
      final formattedNetworkTime =
          '${DateFormat('dd MMM yyyy HH:mm:ss').format(networkTime)} $timeZoneName';
      final formattedLocalTime =
          '${DateFormat('dd MMM yyyy HH:mm:ss').format(now)} $timeZoneName';

      final formattedLocation = 'Lat: $latitudeDMS\nLon: $longitudeDMS';
      log.info('Formatted location: $formattedLocation');

      // Format the address and location for displaying on the video
      final formattedAddress = _address ?? '';

      // Build the text that will be drawn on the video
      final formattedText = '''Network: $formattedNetworkTime
Local: $formattedLocalTime
$latitudeDMS $longitudeDMS
$formattedAddress
T3AI-SAT App''';

      // Escape special characters for FFmpeg command
      String escapedText = formattedText
          .replaceAll('"', r'˝') // Escape double quotes
          .replaceAll(':', r'\:') // Escape colons
          .replaceAll('%', r'\%'); // Escape percent signs

      // Log the formatted and escaped text for debugging
      log.info('Formatted text:\n$formattedText');
      log.info('Escaped text:\n$escapedText');

      // Configure the output path
      // final Directory extDir = await getTemporaryDirectory();
      if (_tempDir == null) {
        log.severe('Temporary directory is not initialized.');
        return;
      }
      final Directory extDir = _tempDir!;
      final String dirPath = '${extDir.path}/Videos/flutter_test';
      await Directory(dirPath).create(recursive: true);
      final String outputPath = path.join(
        dirPath,
        't3aisat_${DateFormat('yyyyMMdd_HHmmss').format(now)}_temp.mp4',
      );

      // Log the paths for debugging
      log.info('Font file path: $_fontFilePath');
      log.info('Input video path: $inputMp4Path');
      log.info('Output video path: $outputPath');

      // Build FFmpeg command
      final String ffmpegCommand =
          "drawtext=fontfile='$_fontFilePath':text='$escapedText':fontcolor=white:fontsize=20:line_spacing=2:x=10:y=H-th-10";

      final command = [
        '-y',
        '-i',
        inputMp4Path,
        '-vf',
        ffmpegCommand,
        '-codec:a',
        'copy',
        outputPath,
      ];

      log.info('FFmpeg command: ffmpeg ${command.join(' ')}');

      // Execute FFmpeg command
      final session = await FFmpegKit.executeWithArguments(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        log.info('FFmpeg command executed successfully');
        final outputFile = File(outputPath);
        if (await outputFile.exists()) {
          final result = await SaverGallery.saveFile(
            file: outputPath,
            name: 't3aisat_${DateFormat('yyyyMMdd_HHmmss').format(now)}.mp4',
            androidRelativePath: 'Movies/t3aisat',
            androidExistNotSave: false,
          );
          log.info('Video saved to gallery: $result');

          setState(() {
            _updatedMediaPath = outputPath;
          });

          _videoController =
              VideoPlayerController.file(File(_updatedMediaPath!))
                ..initialize().then((_) {
                  setState(() {
                    _videoController!.play();
                  });
                });
        } else {
          log.severe('Processed video file does not exist.');
        }
      } else {
        final logs = await session.getAllLogsAsString();
        log.severe('FFmpeg command failed with return code $returnCode');
        log.severe('FFmpeg logs:\n$logs');
      }
    } catch (e) {
      log.severe('Error processing video: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Override back button behavior
      onWillPop: () async {
        // Navigate back to the main screen
        Navigator.of(context).popUntil((route) => route.isFirst);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('GeoPosición',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2), // Navy blue
              )),
          backgroundColor: const Color(0xFFE6E6E6), // Light gray
          foregroundColor: const Color(0xFF1976D2), // Navy blue for text
          elevation: 0, // No shadow in the AppBar
        ),
        body: Center(
          child: _isLoading
              ? const CircularProgressIndicator(
                  color: Color(0xFF1976D2), // Navy blue spinner
                )
              : Column(
                  children: [
                    if (_updatedMediaPath != null)
                      Expanded(
                        child: widget.isVideo
                            ? _videoController != null &&
                                    _videoController!.value.isInitialized
                                ? Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      AspectRatio(
                                        aspectRatio:
                                            _videoController!.value.aspectRatio,
                                        child: VideoPlayer(_videoController!),
                                      ),
                                      VideoProgressIndicator(
                                        _videoController!,
                                        allowScrubbing: true,
                                        colors: VideoProgressColors(
                                          playedColor: Colors.blue,
                                          bufferedColor: Colors.grey,
                                          backgroundColor: Colors.black,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Center(
                                    child: Text('Error loading video'),
                                  )
                            : Image.file(
                                File(_updatedMediaPath!),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                      ),
                    const SizedBox(height: 20),
                    if (_currentPosition != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Color(0xFF388E3C), // Dark green
                              size: 30, // Increased icon size
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Latitude: ${_currentPosition?.latitude}\nLongitude: ${_currentPosition?.longitude}',
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 16,
                                    color: Color(0xFF424242)), // Dark gray
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_address != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.home,
                              color: Color(0xFF388E3C), // Dark green
                              size: 30, // Increased icon size
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$_address',
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 16,
                                    color: Color(0xFF424242)), // Dark gray
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
        ),
      ),
    );
  }
}
