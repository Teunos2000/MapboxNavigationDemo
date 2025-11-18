import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

enum MapMode { tracking, free }

class MapStateProvider extends ChangeNotifier {
  MapMode _mode = MapMode.tracking;
  Position? _currentPosition;
  double _currentBearing = 0.0;
  List<Position> _positionHistory = [];
  
  MapMode get mode => _mode;
  Position? get currentPosition => _currentPosition;
  double get currentBearing => _currentBearing;
  List<Position> get positionHistory => _positionHistory;
  
  void setMode(MapMode mode) {
    _mode = mode;
    notifyListeners();
  }
  
  void updatePosition(Position position) {
    _positionHistory.add(position);
    if (_positionHistory.length > 100) {
      _positionHistory.removeAt(0);  // Keep memory bounded
    }
    _currentPosition = position;
    notifyListeners();
  }
  
  void updateBearing(double bearing) {
    _currentBearing = bearing;
    notifyListeners();
  }
}