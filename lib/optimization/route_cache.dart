import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class RouteCache {
  // Hash map for O(1) access to route segments
  final Map<String, RouteSegment> _segmentCache = {};
  final List<Point> _routePoints = [];
  
  void addRoutePoint(Point point) {
    _routePoints.add(point);
    _updateSegmentCache();
  }
  
  void _updateSegmentCache() {
    if (_routePoints.length < 2) return;
    
    final lastIndex = _routePoints.length - 1;
    final segmentKey = '${lastIndex - 1}_$lastIndex';
    
    _segmentCache[segmentKey] = RouteSegment(
      start: _routePoints[lastIndex - 1],
      end: _routePoints[lastIndex],
      index: lastIndex - 1,
    );
  }
  
  RouteSegment? getSegmentAt(int index) {
    final key = '${index}_${index + 1}';
    return _segmentCache[key];
  }
  
  Point? getNearestPointOnRoute(Point userPosition) {
    // Efficient O(n) search with early exit
    double minDistance = double.infinity;
    Point? nearestPoint;
    
    for (int i = 0; i < _routePoints.length - 1; i++) {
      final segment = getSegmentAt(i);
      if (segment == null) continue;
      
      final projectedPoint = _projectPointOnSegment(
        userPosition, segment.start, segment.end
      );
      final distance = _calculateDistance(userPosition, projectedPoint);
      
      if (distance < minDistance) {
        minDistance = distance;
        nearestPoint = projectedPoint;
      }
      
      // Early exit if distance is very small
      if (distance < 0.00001) break;
    }
    
    return nearestPoint;
  }
  
  Point _projectPointOnSegment(Point point, Point segStart, Point segEnd) {
    // Mathematical projection for map matching
    final dx = segEnd.coordinates.lng - segStart.coordinates.lng;
    final dy = segEnd.coordinates.lat - segStart.coordinates.lat;
    
    if (dx == 0 && dy == 0) return segStart;
    
    final t = ((point.coordinates.lng - segStart.coordinates.lng) * dx +
               (point.coordinates.lat - segStart.coordinates.lat) * dy) /
              (dx * dx + dy * dy);
    
    final clampedT = t.clamp(0.0, 1.0);
    
    return Point(
      coordinates: Position(
        segStart.coordinates.lng + clampedT * dx,
        segStart.coordinates.lat + clampedT * dy,
      ),
    );
  }
  
  double _calculateDistance(Point p1, Point p2) {
    final dx = p2.coordinates.lng - p1.coordinates.lng;
    final dy = p2.coordinates.lat - p1.coordinates.lat;
    return (dx * dx + dy * dy).toDouble();  // Squared distance for performance
  }
}

class RouteSegment {
  final Point start;
  final Point end;
  final int index;
  
  RouteSegment({
    required this.start,
    required this.end,
    required this.index,
  });
}