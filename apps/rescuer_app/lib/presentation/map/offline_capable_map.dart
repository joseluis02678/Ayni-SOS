import 'package:flutter/material.dart';
import 'package:geo_service/geo_service.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// MapLibre map with hooks for offline MBTiles (Phase 10).
///
/// When [mbtilesAbsolutePath] is provided, callers can use
/// [OfflineMapConfig.mbtilesProtocolUrl] with MapLibre OfflineManager /
/// a custom style JSON that references the local archive.
class OfflineCapableMap extends StatelessWidget {
  const OfflineCapableMap({
    super.key,
    required this.config,
    this.onMapCreated,
    this.mbtilesAbsolutePath,
    this.myLocationEnabled = true,
  });

  final OfflineMapConfig config;
  final void Function(MapLibreMapController)? onMapCreated;
  final String? mbtilesAbsolutePath;
  final bool myLocationEnabled;

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      styleString: config.styleUrl,
      initialCameraPosition: CameraPosition(
        target: LatLng(config.initialLatitude, config.initialLongitude),
        zoom: config.initialZoom,
      ),
      myLocationEnabled: myLocationEnabled,
      compassEnabled: true,
      onMapCreated: (controller) {
        onMapCreated?.call(controller);
        // Offline pack path available for OfflineManager.downloadRegion /
        // style switch when MBTiles asset is present.
        assert(() {
          if (mbtilesAbsolutePath != null) {
            // ignore: avoid_print
            print(
              'Offline MBTiles ready: '
              '${config.mbtilesProtocolUrl(mbtilesAbsolutePath!)}',
            );
          }
          return true;
        }());
      },
    );
  }
}
