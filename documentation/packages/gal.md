# Gal Library for Flutter

Dart3 plugin for saving images or videos to the gallery. More details available at [pub.dev](https://pub.dev/packages/gal).

Please [LIKE👍](https://pub.dev/packages/gal) and [STAR⭐️](https://github.com/natsuk4ze/gal) to support our volunteer efforts.

**Support** means that all functions have been tested manually or [automatically](https://github.com/natsuk4ze/gal/actions/runs/7517751549) whenever possible.

|             | Android | iOS | macOS | Windows | Linux                                                |
| ----------- | ------- | --- | ----- | ------- | ---------------------------------------------------- |
| **Support** | SDK 21+ | 11+ | 11+   | 10+     | See: [gal_linux](https://pub.dev/packages/gal_linux) |

|             | iOS                                                              | Android                                                                  |
| ----------- | ---------------------------------------------------------------- | ------------------------------------------------------------------------ |
| **Example** | ![ios](https://github.com/natsuk4ze/gal/raw/main/assets/ios.gif) | ![android](https://github.com/natsuk4ze/gal/raw/main/assets/android.gif) |

## ✨ Features

- Open gallery
- Save video
- Save image
- Save to album
- Save with metadata
- Handle permission
- Handle errors
- Lots of docs and wiki

## 🚀 Get started

### Add dependency

You can use the command to add gal as a dependency with the latest stable version:

```console
flutter pub add gal
```

### iOS

Add the following keys to the `ios/Runner/Info.plist`:

- `<key>NSPhotoLibraryAddUsageDescription</key>` Required
- `<key>NSPhotoLibraryUsageDescription</key>` Required for ios < 14 or saving to album

You can copy from [Info.plist in example](https://github.com/natsuk4ze/gal/blob/main/example/ios/Runner/Info.plist).

### Android

Add the following keys to the `android/app/src/main/AndroidManifest.xml`:

- `<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
             android:maxSdkVersion="29" />` Required for API <= 29
- `android:requestLegacyExternalStorage="true"` Required for saving to the album in API 29

You can copy from [AndroidManifest.xml from example](https://github.com/natsuk4ze/gal/blob/main/example/android/app/src/main/AndroidManifest.xml).

> **🔴 Warning:**
> Android emulators with API < 29 require SD card setup. Real devices don't.

### macOS

Add the following keys to the `macos/Runner/Info.plist`:

- `<key>NSPhotoLibraryAddUsageDescription</key>` Required
- `<key>NSPhotoLibraryUsageDescription</key>` Required for saving to album

You can copy from [Info.plist in example](https://github.com/natsuk4ze/gal/blob/main/example/macos/Runner/Info.plist).

> **🔴 Warning:**
> Flutter currently has a [fatal problem for loading info.plist](https://github.com/flutter/flutter/issues/134191), and permissions are always denied or app crashing in
> some code editors.

### Windows

Update [Visual Studio](https://visualstudio.microsoft.com) to the latest version for using `C++ 20`.

> **💡 If you can't compile**
>
> Try downloading a latest Windows SDK:
>
> 1. Open Visual Studio Installer
> 2. Select Modify
> 3. Select Windows SDK

### Linux

Currently does not officially support Linux, but it can be added through a non-endorsed federated plugin.
See: [gal_linux](https://pub.dev/packages/gal_linux)

## ✅ Usage

### Save from local

```dart
// Save Image (Supports two ways)
await Gal.putImage('$filePath');
await Gal.putImageBytes('$uint8List');

// Save Video
await Gal.putVideo('$filePath');

// Save to album
await Gal.putImage('$filePath', album: '$album')
...
```

### Download from the Internet

```console
flutter pub add dio
```

```dart
// Download Image
final imagePath = '${Directory.systemTemp.path}/image.jpg';
await Dio().download('$url',imagePath);
await Gal.putImage(imagePath);

// Download Video
final videoPath = '${Directory.systemTemp.path}/video.mp4';
await Dio().download('$url',videoPath);
await Gal.putVideo(videoPath);
```

### Save from Camera

```console
flutter pub add image_picker
```

```dart
// Shot and Save
final image = await ImagePicker.pickImage(source: ImageSource.camera);
await Gal.putImage(image.path);
```

```console
flutter pub add camera
```

```dart
// Record and Save
...
final video = await controller.stopVideoRecording();
await Gal.putVideo(video.path);
```

### Handle Permission

```dart
// Check for access permission
final hasAccess = await Gal.hasAccess();

// Request access permission
await Gal.requestAccess();

// ... for saving to album
final hasAccess = await Gal.hasAccess(toAlbum: true);
await Gal.requestAccess(toAlbum: true);
```

### Handle Errors

```dart
// Save Image with try-catch
try {
  await Gal.putImage('$filePath');
} on GalException catch (e) {
  log(e.type.message);
}

// Exception Type
enum GalExceptionType {
  accessDenied,
  notEnoughSpace,
  notSupportedFormat,
  unexpected;

  String get message => switch (this) {
        accessDenied => 'Permission to access the gallery is denied.',
        notEnoughSpace => 'Not enough space for storage.',
        notSupportedFormat => 'Unsupported file formats.',
        unexpected => 'An unexpected error has occurred.',
      };
}
```

## 📝 Documents

If you write an article about Gal, let us know in discussion and we will post the URL of the article in the wiki or readme 🤝

- ### [🎯 Example](https://github.com/natsuk4ze/gal/blob/main/example/lib/main.dart)

- ### [👌 Best Practice](https://github.com/natsuk4ze/gal/wiki/Best-Practice)

- ### [🏠 Wiki](https://github.com/natsuk4ze/gal/wiki)

- ### [💚 Contributing](https://github.com/natsuk4ze/gal/blob/main/CONTRIBUTING.md)

- ### [💬 Q&A](https://github.com/natsuk4ze/gal/discussions/categories/q-a)

## 💚 Trusted by huge projects

Although Gal has only been released for a short time, it is already trusted by huge projects.

- ### [localsend - 28k⭐️](https://github.com/localsend/localsend)

- ### [flutter-quill-extensions - 2.3k⭐️](https://github.com/singerdmx/flutter-quill)

- ### [Thunder - 660⭐️](https://github.com/thunder-app/thunder)

  and more...

## Example Code

```dart
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gal/gal.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() => runApp(const App());

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool toAlbum = false;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text('toAlbum'),
                Switch(
                    value: toAlbum,
                    onChanged: (_) => setState(() => toAlbum = !toAlbum)),
                FilledButton(
                  onPressed: () async => Gal.open(),
                  child: const Text('Open Gallery'),
                ),
                FilledButton(
                  onPressed: () async {
                    final path = await getFilePath('assets/done.mp4');
                    await Gal.putVideo(path, album: album);
                    showSnackbar();
                  },
                  child: const Text('Save Video from file path'),
                ),
                FilledButton(
                  onPressed: () async {
                    final path = await getFilePath('assets/done.jpg');
                    await Gal.putImage(path, album: album);
                    showSnackbar();
                  },
                  child: const Text('Save Image from file path'),
                ),
                FilledButton(
                  onPressed: () async {
                    final bytes = await getBytesData('assets/done.jpg');
                    await Gal.putImageBytes(bytes, album: album);
                    showSnackbar();
                  },
                  child: const Text('Save Image from bytes'),
                ),
                FilledButton(
                  onPressed: () async {
                    final path = '${Directory.systemTemp.path}/done.jpg';
                    await Dio().download(
                      'https://github.com/natsuk4ze/gal/raw/main/example/assets/done.jpg',
                      path,
                    );
                    await Gal.putImage(path, album: album);
                    showSnackbar();
                  },
                  child: const Text('Download Image'),
                ),
                FilledButton(
                  onPressed: () async {
                    final path = '${Directory.systemTemp.path}/done.mp4';
                    await Dio().download(
                      'https://github.com/natsuk4ze/gal/raw/main/example/assets/done.mp4',
                      path,
                    );
                    await Gal.putVideo(path, album: album);
                    showSnackbar();
                  },
                  child: const Text('Download Video'),
                ),
                FilledButton(
                  onPressed: () async {
                    final hasAccess = await Gal.hasAccess(toAlbum: toAlbum);
                    log('Has Access:${hasAccess.toString()}');
                  },
                  child: const Text('Has Access'),
                ),
                FilledButton(
                  onPressed: () async {
                    final requestGranted =
                        await Gal.requestAccess(toAlbum: toAlbum);
                    log('Request Granted:${requestGranted.toString()}');
                  },
                  child: const Text('Request Access'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? get album => toAlbum ? 'Album' : null;

  void showSnackbar() {
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Saved! ✅'),
      action: SnackBarAction(
        label: 'Gallery ->',
        onPressed: () async => Gal.open(),
      ),
    ));
  }

  Future<String> getFilePath(String path) async {
    final byteData = await rootBundle.load(path);
    final file = await File(
            '${Directory.systemTemp.path}${path.replaceAll('assets', '')}')
        .create();
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    return file.path;
  }

  Future<Uint8List> getBytesData(String path) async {
    final byteData = await rootBundle.load(path);
    final uint8List = byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    return Uint8List.fromList(uint8List);
  }
}
```
