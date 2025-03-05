import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Start run if not already running
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final runProvider = Provider.of<RunProvider>(context, listen: false);
      if (!runProvider.isRunning) {
        Navigator.pushReplacementNamed(context, '/setup');
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

// For the _buildMap function:
  Widget _buildMap(RunProvider runProvider) {
    // Default position (will be updated with actual location)
    const defaultPosition = LatLng(37.7749, -122.4194); // San Francisco

    return StreamBuilder<Position>(
      stream: runProvider.locationStream as Stream<Position>?,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final position = snapshot.data!;
          final latLng = LatLng(position.latitude, position.longitude);

          // Center map on current position
          _mapController.move(latLng, 17);

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: latLng,
              initialZoom: 17,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: runProvider.currentRun?.route
                            .map((p) => LatLng(p.latitude, p.longitude))
                            .toList() ??
                        [],
                    color: Colors.blue,
                    strokeWidth: 4.0,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: latLng,
                    width: 20,
                    height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: defaultPosition,
              initialZoom: 17,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
            ],
          );
        }
      },
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
            // ignore: deprecated_member_use
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

// Mock Position class for the example
class Position {
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed;

  Position({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
  });
}
