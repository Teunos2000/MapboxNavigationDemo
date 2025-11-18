import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapboxMapWidget extends StatefulWidget {
  const MapboxMapWidget({Key? key}) : super(key: key);
  
  @override
  State<MapboxMapWidget> createState() => _MapboxMapWidgetState();
}

class _MapboxMapWidgetState extends State<MapboxMapWidget> {
  MapboxMap? mapboxMap;
  
  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: const ValueKey("mapWidget"),
      onMapCreated: _onMapCreated,
      cameraOptions: CameraOptions(
        center: Point(coordinates: Position(-122.4194, 37.7749)),
        zoom: 14.0,
        pitch: 60.0,  // 3D tilt
      ),
    );
  }
  
  void _onMapCreated(MapboxMap map) {
    mapboxMap = map;
  }
}