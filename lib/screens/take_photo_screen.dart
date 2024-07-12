import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';

class TakePhotoScreen extends StatefulWidget {
  const TakePhotoScreen({super.key});

  @override
  TakePhotoScreenState createState() => TakePhotoScreenState();
}

class TakePhotoScreenState extends State<TakePhotoScreen> {
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // Function to take a photo using the camera
  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      // Save the photo
      await _savePhoto(image);
      setState(() {
        _imageFile = image;
      });
    }
  }

  // Function to save the photo to the device and gallery
  Future<void> _savePhoto(XFile image) async {
    final log = Logger('TakePhotoScreen');

    // Save to application directory
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String appDirPath = appDir.path;
    final String fileName = path.basename(image.path);
    final String savedImagePath = path.join(appDirPath, fileName);
    await image.saveTo(savedImagePath);

    // Request permission to save to gallery
    if (await Permission.storage.request().isGranted) {
      // Save to gallery
      final result = await ImageGallerySaver.saveFile(savedImagePath);
      log.info('Image saved to gallery: $result');
    } else {
      log.severe('Permission denied to access storage');
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
            if (_imageFile != null) Image.file(File(_imageFile!.path)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _takePhoto,
              child: const Text('Take Photo'),
            ),
          ],
        ),
      ),
    );
  }
}
