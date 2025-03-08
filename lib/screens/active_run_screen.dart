import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../providers/run_provider.dart';
import '../widgets/run_metrics_panel.dart';
import '../widgets/chase_visualization.dart';
import '../widgets/power_up_indicator.dart';

class ActiveRunScreen extends StatefulWidget {
  const ActiveRunScreen({super.key});

  @override
  State<ActiveRunScreen> createState() => _ActiveRunScreenState();
}

class _ActiveRunScreenState extends State<ActiveRunScreen>
    with WidgetsBindingObserver {
  final MapController _mapController = MapController();
  bool _showMetrics = true;
  Position? _currentPosition;
  List<LatLng> _routePoints = [];
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initLocationTracking();

    // Start run if not already running
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final runProvider = Provider.of<RunProvider>(context, listen: false);
      if (!runProvider.isRunning) {
        Navigator.pushReplacementNamed(context, '/setup');
      }
    });
  }

  Future<void> _initLocationTracking() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')),
          );
        }
        return;
      }

      // Check for location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied'),
            ),
          );
        }
        return;
      }

      // Get initial position
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        if (mounted) {
          setState(() {
            _currentPosition = position;
            _routePoints.add(LatLng(position.latitude, position.longitude));
          });
        }
      } catch (e) {
        debugPrint('Error getting current position: $e');
        return;
      }

      // Start listening to position updates
      _positionStreamSubscription?.cancel(); // Cancel any existing subscription
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen(
        (Position position) {
          if (mounted) {
            setState(() {
              _currentPosition = position;
              _routePoints.add(LatLng(position.latitude, position.longitude));
            });

            // Update the map view to follow the user
            _mapController.move(
              LatLng(position.latitude, position.longitude),
              _mapController.zoom,
            );
          }
        },
        onError: (e) {
          debugPrint('Error getting location updates: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Location error: $e')),
            );
          }
        },
      );
    } catch (e) {
      debugPrint('Error in location tracking: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final runProvider = Provider.of<RunProvider>(context, listen: false);

    if (state == AppLifecycleState.paused) {
      // Auto-pause run when app goes to background
      if (runProvider.isRunning && !runProvider.isPaused) {
        runProvider.pauseRun();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final runProvider = Provider.of<RunProvider>(context);

    if (_currentPosition == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Map
          _buildMap(runProvider),

          // Chase visualization
          const Positioned(
            left: 0,
            right: 0,
            bottom: 200,
            child: ChaseVisualization(),
          ),

          // Top controls
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: _buildTopControls(),
          ),

          // Bottom panel with metrics
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: 0,
            right: 0,
            bottom: _showMetrics ? 0 : -160,
            child: Column(
              children: [
                // Toggle handle
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showMetrics = !_showMetrics;
                    });
                  },
                  child: Container(
                    width: 60,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Metrics panel
                const RunMetricsPanel(),
              ],
            ),
          ),

          // Power-up indicators
          const Positioned(
            top: 100,
            right: 16,
            child: PowerUpIndicator(),
          ),

          // Pause overlay
          if (runProvider.isPaused)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'PAUSED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => runProvider.resumeRun(),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Resume'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            runProvider.stopRun();
                            Navigator.pushReplacementNamed(context, '/summary');
                          },
                          icon: const Icon(Icons.stop),
                          label: const Text('End Run'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: runProvider.isPaused
          ? null
          : FloatingActionButton(
              onPressed: () => runProvider.pauseRun(),
              child: const Icon(Icons.pause),
            ),
    );
  }

  Widget _buildMap(RunProvider runProvider) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: 16.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: _routePoints,
              color: Colors.blue,
              strokeWidth: 4.0,
            ),
          ],
        ),
        // MarkerLayer(
        //   markers: [
        //     if (_currentPosition != null)
        //       Marker(
        //         point: LatLng(
        //           _currentPosition!.latitude,
        //           _currentPosition!.longitude,
        //         ),
        //         builder: (ctx) => Container(
        //           width: 20,
        //           height: 20,
        //           decoration: BoxDecoration(
        //             color: Colors.blue.withOpacity(0.7),
        //             shape: BoxShape.circle,
        //             border: Border.all(
        //               color: Colors.white,
        //               width: 2,
        //             ),
        //           ),
        //           child: const Icon(
        //             Icons.location_on,
        //             color: Colors.red,
        //             size: 20,
        //           ),
        //         ),
        //       ),
        //   ],
        // ),
      ],
    );
  }

  Widget _buildTopControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              _showEndRunDialog();
            },
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.white),
            onPressed: () {
              // Re-center map on current location
              final runProvider =
                  Provider.of<RunProvider>(context, listen: false);
              if (runProvider.currentRun?.route.isNotEmpty ?? false) {
                final lastPosition = runProvider.currentRun!.route.last;
                _mapController.move(
                  LatLng(lastPosition.latitude, lastPosition.longitude),
                  17,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEndRunDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Run?'),
        content: const Text('Are you sure you want to end your current run?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final runProvider =
                  Provider.of<RunProvider>(context, listen: false);
              runProvider.stopRun();
              Navigator.pushReplacementNamed(context, '/summary');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('End Run'),
          ),
        ],
      ),
    );
  }
}
