import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../provider/map_state_provider.dart';
import '../animation/smooth_animation_controller.dart';

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
        return Stack(
          children: [
            MapWidget(
              key: const ValueKey("mapWidget"),
              onMapCreated: _onMapCreated,
              onScrollListener: _onMapScroll,
              cameraOptions: CameraOptions(
                center: Point(coordinates: Position(-122.4194, 37.7749)),
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
    
    // Create user location marker
    final CircleAnnotationOptions markerOptions = CircleAnnotationOptions(
      geometry: Point(coordinates: Position(-122.4194, 37.7749)),
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
  
  Future<void> _animateCameraTracking(Point position, double bearing) async {
    await mapboxMap!.flyTo(
      CameraOptions(
        center: position,
        zoom: 17.0,
        bearing: bearing,
        pitch: 60.0,
      ),
      MapAnimationOptions(
        duration: 500,
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
  
  void _returnToTracking(MapStateProvider mapState) {
    mapState.setMode(MapMode.tracking);
    
    // Animate back to user position
    if (mapState.currentPosition != null) {
      final position = Point(
        coordinates: Position(
          mapState.currentPosition!.longitude,
          mapState.currentPosition!.latitude,
        ),
      );
      _animateCameraTracking(position, mapState.currentBearing);
    }
  }
  
  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }
}