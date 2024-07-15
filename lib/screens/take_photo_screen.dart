import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  const TakePhotoScreen({super.key});

  @override
  TakePhotoScreenState createState() => TakePhotoScreenState();
}

class TakePhotoScreenState extends State<TakePhotoScreen> {
  XFile? _imageFile;
  Position? _currentPosition;
  String? _address;
  final ImagePicker _picker = ImagePicker();
  final Logger log = Logger('TakePhotoScreen');

  // Function to take a photo using the camera
  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _imageFile = image;
      });

      // Get the current location
      await _getCurrentLocation();
      if (_currentPosition != null) {
        // Get the address from the coordinates
        await _getAddressFromCoordinates(
            _currentPosition!.latitude, _currentPosition!.longitude);

        // Write text on the image and save it to gallery
        await _writeTextOnImageAndSaveToGallery(image);
      }
    }
  }

  // Function to save the photo to the device and gallery
  Future<void> _writeTextOnImageAndSaveToGallery(XFile image) async {
    final bytes = await image.readAsBytes();
    final img.Image originalImage = img.decodeImage(bytes)!;

    // Load the font
    final fontData = await rootBundle.load(
        'assets/fonts/roboto_black/Roboto-Black_100_size_white_color.ttf.zip');
    final font = img.BitmapFont.fromZip(fontData.buffer.asUint8List());

    // Split address into multiple lines
    final formattedAddress = _address?.split(',').join('\n');
    // Format location with 5 decimal places
    final formattedLocation =
        'Lat: ${_currentPosition?.latitude.toStringAsFixed(5)}\nLon: ${_currentPosition?.longitude.toStringAsFixed(5)}';

    // Draw the address and coordinates
    final updatedImage = img.drawString(
      originalImage,
      '$formattedAddress\n$formattedLocation',
      font: font,
      x: 20, // x position
      y: originalImage.height - 750, // y position to move text down
      color: img.ColorRgba8(255, 255, 255, 255), // white color
    );

    // Save the updated image
    final updatedImagePath = path.join(
        (await getApplicationDocumentsDirectory()).path,
        'updated_${path.basename(image.path)}');
    final updatedImageFile = File(updatedImagePath);
    updatedImageFile.writeAsBytesSync(img.encodeJpg(updatedImage));

    // Request permission to save to gallery
    var status = await Permission.photos.status;
    if (!status.isGranted) {
      status = await Permission.photos.request();
    }

    if (status.isGranted) {
      // Save the updated image to gallery
      final result = await ImageGallerySaver.saveFile(updatedImagePath);
      log.info('Updated image saved to gallery: $result');
    } else {
      log.severe('Permission denied to access photos');
    }

    // Update the state to show the updated image
    setState(() {
      _imageFile = XFile(updatedImagePath);
    });
  }

  // Function to get the current location
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
        desiredAccuracy: LocationAccuracy.high);
    log.info('Current position: $_currentPosition');

    // Update the state to reflect the new location
    setState(() {});
  }

  // Function to get the address from the coordinates
  Future<void> _getAddressFromCoordinates(double lat, double lon) async {
    final apiKey = dotenv.env['MAPBOX_API_KEY'];
    final url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$lon,$lat.json?access_token=$apiKey';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take a Photo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_imageFile != null)
              Expanded(
                child: Image.file(File(_imageFile!.path)),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _takePhoto,
              child: const Text('Take Photo'),
            ),
            if (_currentPosition != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Location: \nLatitude: ${_currentPosition?.latitude}\nLongitude: ${_currentPosition?.longitude}',
                  textAlign: TextAlign.center,
                ),
              ),
            if (_address != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Address: $_address',
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
