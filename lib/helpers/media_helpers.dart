import 'dart:io' show Platform;
import 'package:photo_manager/photo_manager.dart';
import 'package:native_exif/native_exif.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:objectbox/objectbox.dart';
import '../model/photo_model.dart';
import '../objectbox.g.dart';

Future<bool> isValidPhoto(AssetEntity media, Store store) async {
  final box = store.box<Photo>();

  if (Platform.isAndroid) {
    final file = await media.file;
    if (file == null) return false;
    final exif = await Exif.fromPath(file.path);
    final userComment = await exif.getAttribute('UserComment');
    await exif.close();
    return userComment != null && userComment.contains('Think Tank InnoTech');
  } else if (Platform.isIOS) {
    final List<Photo> savedPhotos = box.getAll();
    for (var photo in savedPhotos) {
      if (photo.galleryId == media.id) {
        return true;
      }
    }
  }

  return false;
}

Future<bool> isValidVideo(AssetEntity media) async {
  final file = await media.file;
  if (file == null) return false;

  final session = await FFmpegKit.execute("-i ${file.path} -f ffmetadata -");
  final returnCode = await session.getReturnCode();

  if (returnCode != null && ReturnCode.isSuccess(returnCode)) {
    final output = await session.getAllLogsAsString();
    final RegExp commentRegex = RegExp(r'comment\s*:\s*"(.+)"');
    final match = output != null ? commentRegex.firstMatch(output) : null;

    if (match != null) {
      final comment = match.group(1) ?? '';
      return comment.trim().endsWith('Think Tank InnoTech');
    }
  }

  return false;
}
