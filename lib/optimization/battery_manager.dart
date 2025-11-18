import 'dart:async';
import 'package:geolocator/geolocator.dart';

class BatteryOptimizationManager {
  Timer? _throttleTimer;
  Position? _lastProcessedPosition;
  final double _minDistanceThreshold = 3.0; // meters
  final Duration _throttleDuration = const Duration(milliseconds: 500);
  
  bool shouldProcessUpdate(Position newPosition) {
    if (_lastProcessedPosition == null) {
      _lastProcessedPosition = newPosition;
      return true;
    }
    
    final distance = Geolocator.distanceBetween(
      _lastProcessedPosition!.latitude,
      _lastProcessedPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );
    
    // Only process if moved more than threshold
    if (distance >= _minDistanceThreshold) {
      _lastProcessedPosition = newPosition;
      return true;
    }
    
    return false;
  }
  
  void throttleOperation(Function operation) {
    _throttleTimer?.cancel();
    _throttleTimer = Timer(_throttleDuration, () {
      operation();
    });
  }
  
  void dispose() {
    _throttleTimer?.cancel();
  }
}