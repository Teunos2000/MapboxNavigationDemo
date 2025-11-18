import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationSimulator {
  final List<SimulatedPoint> testRoute = [
    SimulatedPoint(37.7749, -122.4194, 0),
    SimulatedPoint(37.7750, -122.4193, 1),
    SimulatedPoint(37.7751, -122.4192, 2),
    SimulatedPoint(37.7752, -122.4191, 3),
    SimulatedPoint(37.7753, -122.4190, 4),
  ];
  
  Stream<Position> simulateMovement() async* {
    for (final point in testRoute) {
      await Future.delayed(Duration(seconds: point.timeSeconds));
      
      yield Position(
        latitude: point.latitude,
        longitude: point.longitude,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 0.0,
        heading: _calculateBearing(point),
        speed: 5.0,
        speedAccuracy: 1.0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
  }
  
  double _calculateBearing(SimulatedPoint point) {
    final index = testRoute.indexOf(point);
    if (index < testRoute.length - 1) {
      final next = testRoute[index + 1];
      return Geolocator.bearingBetween(
        point.latitude, point.longitude,
        next.latitude, next.longitude,
      );
    }
    return 0.0;
  }
}

class SimulatedPoint {
  final double latitude;
  final double longitude;
  final int timeSeconds;
  
  SimulatedPoint(this.latitude, this.longitude, this.timeSeconds);
}