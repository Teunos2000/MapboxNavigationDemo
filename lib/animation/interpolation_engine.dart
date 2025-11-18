import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class InterpolationEngine {
  // Linear interpolation for smooth position transitions
  static Point linearInterpolate(Point start, Point end, double t) {
    final lat = start.coordinates.lat + (end.coordinates.lat - start.coordinates.lat) * t;
    final lng = start.coordinates.lng + (end.coordinates.lng - start.coordinates.lng) * t;
    return Point(coordinates: Position(lng, lat));
  }
  
  // Cubic Bezier interpolation for ultra-smooth movement
  static Point cubicBezierInterpolate(
    Point p0, Point p1, Point p2, Point p3, double t
  ) {
    final u = 1 - t;
    final tt = t * t;
    final uu = u * u;
    final uuu = uu * u;
    final ttt = tt * t;
    
    final lat = uuu * p0.coordinates.lat +
                3 * uu * t * p1.coordinates.lat +
                3 * u * tt * p2.coordinates.lat +
                ttt * p3.coordinates.lat;
    
    final lng = uuu * p0.coordinates.lng +
                3 * uu * t * p1.coordinates.lng +
                3 * u * tt * p2.coordinates.lng +
                ttt * p3.coordinates.lng;
    
    return Point(coordinates: Position(lng, lat));
  }
  
  // Smooth bearing interpolation (handles 360° wrap-around)
  static double interpolateBearing(double start, double end, double t) {
    double diff = end - start;
    
    // Handle 360° wrap-around
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    
    return (start + diff * t) % 360;
  }
}