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

class TakePhotoScreen extends StatefulWidget {
  final String imagePath;

  const TakePhotoScreen({super.key, required this.imagePath});

  @override
  TakePhotoScreenState createState() => TakePhotoScreenState();
}

class TakePhotoScreenState extends State<TakePhotoScreen> {
  Position? _currentPosition;
  String? _address;
  final Logger log = Logger('TakePhotoScreen');
  String?
      _updatedImagePath; // Variable to store the updated image route

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

    _currentPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    log.info('Current position: $_currentPosition');

    // Obtain address from coordinates
    await _getAddressFromCoordinates(
        _currentPosition!.latitude, _currentPosition!.longitude);

    // Write the text in the image and save in the gallery
    await _writeTextOnImageAndSaveToGallery(widget.imagePath);

    // Update the state to reflect the new location
    setState(() {});
  }

  // Function to get the address from the coordinates
  Future<void> _getAddressFromCoordinates(double lat, double lon) async {
    final accessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'];
    final url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$lon,$lat.json?access_token=$accessToken';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['features'].isNotEmpty) {
        setState(() {
          _address = data['features'][0]['place_name'];
        });
        log.info('Address: $_address');
      }
    } else {
      log.severe('Failed to get address from coordinates');
    }
  }

  // Function to save the photo with the location on the device and the gallery
  Future<void> _writeTextOnImageAndSaveToGallery(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final img.Image originalImage = img.decodeImage(bytes)!;

      // Load the source
      final fontData = await rootBundle.load(
          'assets/fonts/roboto_black/Roboto-Black_100_size_white_color.ttf.zip');
      final font = img.BitmapFont.fromZip(fontData.buffer.asUint8List());

      // Format direction and location
      final formattedAddress = _address?.split(',').join('\n');
      final formattedLocation =
          'Lat: ${_currentPosition?.latitude.toStringAsFixed(5)}\nLon: ${_currentPosition?.longitude.toStringAsFixed(5)}';

      // Draw the address and coordinates in the image
      final updatedImage = img.drawString(
        originalImage,
        '$formattedAddress\n$formattedLocation',
        font: font,
        x: 20,
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
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_updatedImagePath != null)
              Expanded(
                child: Image.file(File(_updatedImagePath!)),
              ),
            const SizedBox(height: 20),
            if (_currentPosition != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Ubicación\nLatitud: ${_currentPosition?.latitude}\nLongitud: ${_currentPosition?.longitude}',
                  textAlign: TextAlign.center,
                ),
              ),
            if (_address != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Dirección\n$_address',
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
