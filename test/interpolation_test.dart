import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../lib/animation/interpolation_engine.dart';

void main() {
  group('Interpolation Tests', () {
    test('Linear interpolation should work correctly', () {
      final start = Point(coordinates: Position(0, 0));
      final end = Point(coordinates: Position(10, 10));
      
      final mid = InterpolationEngine.linearInterpolate(start, end, 0.5);
      
      expect(mid.coordinates.lng, equals(5.0));
      expect(mid.coordinates.lat, equals(5.0));
    });
    
    test('Bearing interpolation should handle wrap-around', () {
      final result = InterpolationEngine.interpolateBearing(350, 10, 0.5);
      expect(result, equals(0.0));
    });
  });
}