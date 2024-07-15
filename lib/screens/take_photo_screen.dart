import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class TakePhotoScreen extends StatefulWidget {
  const TakePhotoScreen({super.key});

  @override
  TakePhotoScreenState createState() => TakePhotoScreenState();
}

class TakePhotoScreenState extends State<TakePhotoScreen> {
  XFile? _imageFile;
  Position? _currentPosition;
  final ImagePicker _picker = ImagePicker();
  final Logger log = Logger('TakePhotoScreen');

  // Function to take a photo using the camera
  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      // Save the photo
      await _savePhoto(image);
      setState(() {
        _imageFile = image;
      });

      // Get the current location
      await _getCurrentLocation();
    }
  }

  // Function to save the photo to the device and gallery
  Future<void> _savePhoto(XFile image) async {
    // Save to application directory
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String appDirPath = appDir.path;
    final String fileName = path.basename(image.path);
    final String savedImagePath = path.join(appDirPath, fileName);
    await image.saveTo(savedImagePath);

    // Request permission to save to gallery
    var status = await Permission.photos.status;
    if (!status.isGranted) {
      status = await Permission.photos.request();
    }

    if (status.isGranted) {
      // Save to gallery
      final result = await ImageGallerySaver.saveFile(savedImagePath);
      log.info('Image saved to gallery: $result');
    } else {
      log.severe('Permission denied to access photos');
    }
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
            if (_imageFile != null) Image.file(File(_imageFile!.path)),
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
          ],
        ),
      ),
    );
  }
}
