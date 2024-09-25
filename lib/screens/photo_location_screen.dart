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
import 'package:flutter/services.dart' show rootBundle;

class PhotoLocationScreen extends StatefulWidget {
  final String imagePath;

  const PhotoLocationScreen({super.key, required this.imagePath});

  @override
  PhotoLocationScreenState createState() => PhotoLocationScreenState();
}

class PhotoLocationScreenState extends State<PhotoLocationScreen> {
  Position? _currentPosition;
  String? _address;
  final Logger log = Logger('PhotoLocationScreen');
  String? _updatedImagePath; // Variable to store the updated image path
  bool _isLoading = true; // Variable to manage the loading spinner

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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

      // Write the text on the image and save it in the gallery
      await _writeTextOnImageAndSaveToGallery(widget.imagePath);
    } catch (e) {
      log.severe('Failed to obtain location or process image: $e');
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

  // Function to save the photo with the location on the device and the gallery
  Future<void> _writeTextOnImageAndSaveToGallery(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final img.Image originalImage = img.decodeImage(bytes)!;

      // Load the font
      final fontData = await rootBundle.load(
          'assets/fonts/roboto_black/Roboto-Black_100_size_white_color.ttf.zip');
      final font = img.BitmapFont.fromZip(fontData.buffer.asUint8List());

      // Format address and location
      final formattedAddress = _address?.split(',').join('\n');
      final formattedLocation =
          'Lat: ${_currentPosition?.latitude.toStringAsFixed(5)}\nLon: ${_currentPosition?.longitude.toStringAsFixed(5)}';

      // Draw the address and coordinates on the image with manual padding
      const paddingLeft = 60; // Increased padding from left
      final updatedImage = img.drawString(
        originalImage,
        '$formattedAddress\n$formattedLocation',
        font: font,
        x: paddingLeft, // Apply the padding
        y: originalImage.height - 750,
        color: img.ColorRgba8(255, 255, 255, 255),
      );

      // Save the updated image
      final updatedImagePath = path.join(
          (await getApplicationDocumentsDirectory()).path,
          'updated_${path.basename(imagePath)}');
      final updatedImageFile = File(updatedImagePath);
      updatedImageFile.writeAsBytesSync(img.encodeJpg(updatedImage));

      // Request permission to save in the gallery
      var status = await Permission.photos.status;
      if (!status.isGranted) {
        status = await Permission.photos.request();
      }

      if (status.isGranted) {
        // Save the updated image in the gallery
        final result = await ImageGallerySaver.saveFile(updatedImagePath);
        log.info('Updated image saved to gallery: $result');
      } else {
        log.severe('Permission denied to access photos');
      }

      setState(() {
        // Update the image shown in the UI
        _updatedImagePath = updatedImagePath;
      });
    } catch (e) {
      log.severe('Failed to process image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoPosición'),
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
                  if (_updatedImagePath != null)
                    Expanded(
                      child: Image.file(
                        File(_updatedImagePath!),
                        fit: BoxFit.cover, // Ensures the image fills the space
                        width: double.infinity,
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (_currentPosition != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment
                            .start, // Align content to the start of the row
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFF388E3C), // Dark green
                            size: 30, // Increased icon size
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            // Ensures text wraps and aligns properly
                            child: Text(
                              'Latitud: ${_currentPosition?.latitude}\nLongitud: ${_currentPosition?.longitude}',
                              textAlign: TextAlign.left,
                              style: const TextStyle(
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
                        crossAxisAlignment: CrossAxisAlignment
                            .start, // Align content to the start of the row
                        children: [
                          const Icon(
                            Icons.home,
                            color: Color(0xFF388E3C), // Dark green
                            size: 30, // Increased icon size
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            // Ensures text wraps and aligns properly
                            child: Text(
                              '$_address',
                              textAlign: TextAlign.left,
                              style: const TextStyle(
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
    );
  }
}
