import 'package:objectbox/objectbox.dart';

@Entity()
class Media {
  @Id()
  int id = 0;

  String path;
  bool isVideo;
  double latitude;
  double longitude;
  String address;

  // Platform-specific identifiers
  String? galleryId; // iOS: PHAsset ID
  int? mediaStoreId; // Android: MediaStore _ID

  // Make dimensions nullable
  int? width;
  int? height;

  Media({
    required this.path,
    required this.isVideo,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.galleryId, // iOS
    this.mediaStoreId, // Android
    this.width,
    this.height,
  });
}
