import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'interpolation_engine.dart';

class SmoothAnimationController {
  final TickerProvider vsync;
  late AnimationController _animationController;
  Animation<double>? _animation;
  
  Point? _startPoint;
  Point? _endPoint;
  double _startBearing = 0;
  double _endBearing = 0;
  
  Function(Point, double)? onUpdate;
  
  SmoothAnimationController({required this.vsync}) {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: vsync,
    );
  }
  
  void animateToPosition(Point newPosition, double newBearing) {
    if (_startPoint == null) {
      _startPoint = newPosition;
      _startBearing = newBearing;
      return;
    }
    
    _endPoint = newPosition;
    _endBearing = newBearing;
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic),
    )..addListener(_onAnimationUpdate);
    
    _animationController.forward(from: 0);
  }
  
  void _onAnimationUpdate() {
    if (_animation == null || _startPoint == null || _endPoint == null) return;
    
    final t = _animation!.value;
    final interpolatedPoint = InterpolationEngine.linearInterpolate(
      _startPoint!, _endPoint!, t
    );
    final interpolatedBearing = InterpolationEngine.interpolateBearing(
      _startBearing, _endBearing, t
    );
    
    onUpdate?.call(interpolatedPoint, interpolatedBearing);
    
    if (t >= 1.0) {
      _startPoint = _endPoint;
      _startBearing = _endBearing;
    }
  }
  
  void dispose() {
    _animationController.dispose();
  }
}