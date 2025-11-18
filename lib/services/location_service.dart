import 'package:geolocator/geolocator.dart';
import 'dart:async';

class LocationService {
  final StreamController<Position> _locationController = StreamController<Position>.broadcast();
  StreamSubscription<Position>? _positionSubscription;
  
  Stream<Position> get locationStream => _locationController.stream;
  
  // Throttled GPS updates for battery efficiency
  Future<void> startLocationTracking() async {
    final hasPermission = await _handlePermissions();
    if (!hasPermission) return;
    
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,  // Only update if moved 5 meters
      timeLimit: Duration(seconds: 2),  // Battery optimization
    );
    
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _locationController.add(position);
    });
  }
  
  Future<bool> _handlePermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    
    if (permission == LocationPermission.deniedForever) return false;
    
    return true;
  }
  
  void dispose() {
    _positionSubscription?.cancel();
    _locationController.close();
  }
}