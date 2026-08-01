import 'package:equatable/equatable.dart';

class GeoPoint extends Equatable {
  const GeoPoint({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;

  /// Compact SMS encoding: lat/lon × 10000 as integers.
  String toSmsPair() {
    final lat = (latitude * 10000).round();
    final lon = (longitude * 10000).round();
    return '$lat|$lon';
  }

  @override
  List<Object?> get props => [latitude, longitude, accuracyMeters];
}
