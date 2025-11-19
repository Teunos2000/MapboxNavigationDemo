import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../provider/map_state_provider.dart';
import '../animation/smooth_animation_controller.dart';
import 'dart:math' as math;

class AnimatedMapWidget extends StatefulWidget {
  const AnimatedMapWidget({Key? key}) : super(key: key);
  
  @override
  State<AnimatedMapWidget> createState() => _AnimatedMapWidgetState();
}

class _AnimatedMapWidgetState extends State<AnimatedMapWidget> 
    with TickerProviderStateMixin {
  MapboxMap? mapboxMap;
  SmoothAnimationController? animationController;
  CircleAnnotationManager? circleAnnotationManager;
  CircleAnnotation? userMarker;
  
  @override
  void initState() {
    super.initState();
    animationController = SmoothAnimationController(vsync: this);
    animationController!.onUpdate = _updateMarkerAndCamera;
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<MapStateProvider>(
      builder: (context, mapState, child) {
        // Use current position if available, otherwise use a default
        final initialPosition = mapState.currentPosition != null
            ? Position(
                mapState.currentPosition!.longitude,
                mapState.currentPosition!.latitude,
              )
            : Position(5.0, 52.0); // Center of Netherlands as fallback

        return Stack(
          children: [
            MapWidget(
              key: const ValueKey("mapWidget"),
              onMapCreated: _onMapCreated,
              onScrollListener: _onMapScroll,
              cameraOptions: CameraOptions(
                center: Point(coordinates: initialPosition),
                zoom: 16.0,
                pitch: 60.0,
              ),
            ),
            if (mapState.mode == MapMode.free)
              Positioned(
                bottom: 50,
                right: 20,
                child: FloatingActionButton.extended(
                  onPressed: () => _returnToTracking(mapState),
                  label: const Text('Back to Tracking'),
                  icon: const Icon(Icons.my_location),
                ),
              ),
          ],
        );
      },
    );
  }
  
  void _onMapCreated(MapboxMap map) async {
    mapboxMap = map;
    await _setupUserMarker();
    _startListeningToLocationUpdates();
  }
  
  Future<void> _setupUserMarker() async {
    circleAnnotationManager = await mapboxMap!.annotations.createCircleAnnotationManager();

    // Get current position from provider
    final mapState = context.read<MapStateProvider>();
    final currentPos = mapState.currentPosition;

    // Use current position if available, otherwise use Netherlands center
    final markerPosition = currentPos != null
        ? Position(currentPos.longitude, currentPos.latitude)
        : Position(5.0, 52.0);

    // Create user location marker
    final CircleAnnotationOptions markerOptions = CircleAnnotationOptions(
      geometry: Point(coordinates: markerPosition),
      circleColor: Colors.blue.value,
      circleRadius: 10.0,
      circleStrokeColor: Colors.white.value,
      circleStrokeWidth: 2.0,
    );

    userMarker = await circleAnnotationManager!.create(markerOptions);
  }
  
  void _startListeningToLocationUpdates() {
    final mapState = context.read<MapStateProvider>();
    
    // Listen to position updates from provider
    mapState.addListener(() {
      if (mapState.currentPosition != null) {
        final newPoint = Point(
          coordinates: Position(
            mapState.currentPosition!.longitude,
            mapState.currentPosition!.latitude,
          ),
        );
        
        animationController!.animateToPosition(
          newPoint,
          mapState.currentBearing,
        );
      }
    });
  }
  
  void _updateMarkerAndCamera(Point position, double bearing) async {
    // Update marker position
    if (userMarker != null) {
      userMarker!.geometry = position;
      await circleAnnotationManager!.update(userMarker!);
    }
    
    // Update camera if in tracking mode
    final mapState = context.read<MapStateProvider>();
    if (mapState.mode == MapMode.tracking) {
      await _animateCameraTracking(position, bearing);
    }
  }
  
  /// Calculate camera position behind the user for navigation-style view
  /// This positions the camera so the user appears in the lower third of the screen
  Position _calculateCameraPositionBehind(Point userPosition, double bearing) {
    const double earthRadius = 6371000.0; // Earth's radius in meters
    const double cameraDistanceBehind = 120.0; // Distance behind user in meters

    final double userLat = userPosition.coordinates.lat.toDouble();
    final double userLon = userPosition.coordinates.lng.toDouble();

    // Convert bearing to radians and add 180 degrees (to go behind the user)
    final double bearingRad = (bearing + 180) * math.pi / 180.0;

    // Convert latitude to radians
    final double lat1Rad = userLat * math.pi / 180.0;

    // Calculate angular distance
    final double angularDistance = cameraDistanceBehind / earthRadius;

    // Calculate new latitude
    final double lat2Rad = math.asin(
      math.sin(lat1Rad) * math.cos(angularDistance) +
      math.cos(lat1Rad) * math.sin(angularDistance) * math.cos(bearingRad)
    );

    // Calculate new longitude
    final double lon2Rad = (userLon * math.pi / 180.0) + math.atan2(
      math.sin(bearingRad) * math.sin(angularDistance) * math.cos(lat1Rad),
      math.cos(angularDistance) - math.sin(lat1Rad) * math.sin(lat2Rad)
    );

    // Convert back to degrees
    final double cameraLat = lat2Rad * 180.0 / math.pi;
    final double cameraLon = lon2Rad * 180.0 / math.pi;

    return Position(cameraLon, cameraLat);
  }

  Future<void> _animateCameraTracking(Point position, double bearing) async {
    // Calculate camera position behind the user for navigation view
    final cameraPosition = _calculateCameraPositionBehind(position, bearing);

    // Use easeTo instead of flyTo for smoother, less intensive animations
    await mapboxMap!.easeTo(
      CameraOptions(
        center: Point(coordinates: cameraPosition),
        zoom: 17.5,
        bearing: bearing,
        pitch: 65.0, // Increased pitch for better 3D navigation view
      ),
      MapAnimationOptions(
        duration: 300, // Shorter duration to reduce animation conflicts
        startDelay: 0,
      ),
    );
  }
  
void _onMapScroll(MapContentGestureContext gestureContext) {
  // Switch to free mode when user manually moves map
  final mapState = context.read<MapStateProvider>();
  if (mapState.mode == MapMode.tracking) {
    mapState.setMode(MapMode.free);
  }

  // If you need the screen coordinate:
  final screenCoord = gestureContext.touchPosition;
  final geoPoint = gestureContext.point;
  // You can use screenCoord or geoPoint if needed
}
  
  void _returnToTracking(MapStateProvider mapState) async {
    if (mapState.currentPosition != null) {
      final position = Point(
        coordinates: Position(
          mapState.currentPosition!.longitude,
          mapState.currentPosition!.latitude,
        ),
      );

      // Calculate camera position behind the user
      final cameraPosition = _calculateCameraPositionBehind(position, mapState.currentBearing);

      // Immediately set camera position without animation to avoid conflicts
      await mapboxMap!.setCamera(
        CameraOptions(
          center: Point(coordinates: cameraPosition),
          zoom: 17.5,
          bearing: mapState.currentBearing,
          pitch: 65.0,
        ),
      );
    }

    // Set mode to tracking AFTER positioning camera to avoid animation conflicts
    mapState.setMode(MapMode.tracking);
  }
  
  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }
}