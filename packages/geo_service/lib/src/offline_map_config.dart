/// Offline map configuration for MapLibre + MBTiles.
class OfflineMapConfig {
  const OfflineMapConfig({
    this.styleUrl =
        'https://tiles.openfreemap.org/styles/liberty',
    this.mbtilesAssetPath = 'assets/maps/peru_risk_elnino.mbtiles',
    this.initialLatitude = -12.0464,
    this.initialLongitude = -77.0428,
    this.initialZoom = 11.0,
  });

  /// Online style (OpenFreeMap / OSM-compatible).
  final String styleUrl;

  /// Bundled MBTiles for El Niño risk zones (huaicos / inundaciones).
  final String mbtilesAssetPath;

  final double initialLatitude;
  final double initialLongitude;
  final double initialZoom;

  /// MapLibre protocol URL for local MBTiles.
  String mbtilesProtocolUrl(String absolutePath) => 'mbtiles://$absolutePath';
}
