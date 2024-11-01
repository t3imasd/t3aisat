import 'package:objectbox/objectbox.dart';

@Entity()
class Photo {
  int id;
  String galleryId; // Store the gallery ID instead of the file path
  @Property(type: PropertyType.date)
  DateTime captureDate;

  Photo({
    this.id = 0,
    required this.galleryId,
    required this.captureDate,
  });
}
