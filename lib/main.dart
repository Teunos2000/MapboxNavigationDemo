import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:async';
import 'provider/map_state_provider.dart';
import 'services/location_service.dart';
import 'widgets/animated_map_widget.dart';
import 'package:flutter_compass/flutter_compass.dart';

void main() {
  // Ensure Flutter binding is initialized before using platform channels
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set the access token after binding is initialized
  const String mapboxAccessToken = '';
  MapboxOptions.setAccessToken(mapboxAccessToken);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MapStateProvider()),
      ],
      child: MaterialApp(
        title: 'Smooth Location Tracking',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const MapScreen(),
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  StreamSubscription<CompassEvent>? _compassSubscription;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() async {
    final mapState = context.read<MapStateProvider>();

    // Get initial position first
    final initialPosition = await _locationService.getCurrentPosition();
    if (initialPosition != null) {
      mapState.updatePosition(initialPosition);
    }

    // Mark as initialized
    setState(() {
      _isInitialized = true;
    });

    // Start location tracking
    await _locationService.startLocationTracking();

    // Listen to location updates
    _locationService.locationStream.listen((position) {
      mapState.updatePosition(position);
    });

    // Listen to compass for bearing
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (event.heading != null) {
        mapState.updateBearing(event.heading!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isInitialized
          ? AnimatedMapWidget()
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Getting your location...'),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _locationService.dispose();
    _compassSubscription?.cancel();
    super.dispose();
  }
}