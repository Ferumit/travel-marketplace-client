import 'dart:math';

class DistanceCalculator {
  static const double _earthRadiusMeters =
      6371000.0; // Earth's radius in meters

  /// Calculate distance between two GPS coordinates using Haversine formula
  /// [lat1] Latitude of first point in degrees
  /// [lon1] Longitude of first point in degrees
  /// [lat2] Latitude of second point in degrees
  /// [lon2] Longitude of second point in degrees
  /// Returns distance in meters
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        pow(sin(dLat / 2), 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * pow(sin(dLon / 2), 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusMeters * c;
  }

  /// Format distance for display
  /// [meters] Distance in meters
  /// Returns formatted string like "50 m" or "1.2 km"
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()} m';
    } else {
      final km = meters / 1000.0;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  /// Parse GPS coordinates from payload metadata
  /// Format: "lat,lon" e.g., "37.7749,-122.4194"
  static (double, double)? parseCoordinates(String metadata) {
    try {
      final parts = metadata.split(',');
      if (parts.length == 2) {
        return (double.parse(parts[0]), double.parse(parts[1]));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Encode GPS coordinates to string for transmission
  static String encodeCoordinates(double latitude, double longitude) {
    return '$latitude,$longitude';
  }

  static double _toRadians(double degrees) => degrees * (pi / 180.0);
}

