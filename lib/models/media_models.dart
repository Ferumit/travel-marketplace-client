//Photo models
class Photo {
  final String id;
  final String url;
  final String? caption;
  final String uploadDate;

  const Photo({
    required this.id,
    required this.url,
    this.caption,
    required this.uploadDate,
  });
}

class PhotoAlbum {
  final String id;
  final String? bookingId;
  final String? routeId;
  final String title;
  final List<Photo> photos;
  final bool isPublic;
  final String createdDate;

  const PhotoAlbum({
    required this.id,
    this.bookingId,
    this.routeId,
    required this.title,
    required this.photos,
    required this.isPublic,
    required this.createdDate,
  });
}

