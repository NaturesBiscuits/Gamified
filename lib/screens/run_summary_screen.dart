import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/run_provider.dart';
import '../widgets/metric_card.dart';

class RunSummaryScreen extends StatelessWidget {
  const RunSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final runProvider = Provider.of<RunProvider>(context);
    final currentRun = runProvider.currentRun;

    if (currentRun == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Run Summary'),
        ),
        body: const Center(
          child: Text('No run data available'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Run Summary'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map with route
            SizedBox(
              height: 200,
              child: _buildRouteMap(currentRun),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Run title and date
                  Text(
                    'Run Completed!',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    currentRun.formattedDate,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),

                  const SizedBox(height: 24),

                  // Main metrics
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          title: 'Distance',
                          value: currentRun.formattedDistance,
                          unit: 'km',
                          icon: Icons.straighten,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MetricCard(
                          title: 'Duration',
                          value: _formatDuration(currentRun.duration),
                          unit: '',
                          icon: Icons.timer,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          title: 'Avg. Speed',
                          value: currentRun.formattedAvgSpeed,
                          unit: 'km/h',
                          icon: Icons.speed,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MetricCard(
                          title: 'Calories',
                          value: currentRun.formattedCalories,
                          unit: 'kcal',
                          icon: Icons.local_fire_department,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          title: 'Elevation',
                          value: currentRun.formattedElevationGain,
                          unit: 'm',
                          icon: Icons.terrain,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MetricCard(
                          title: 'Chase Result',
                          value: _getChaserResult(runProvider),
                          unit: '',
                          icon: Icons.emoji_events,
                          color: _getChaserResultColor(runProvider),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Achievement section
                  _buildAchievementSection(context, currentRun),

                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/',
                              (route) => false,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Back to Home'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/setup',
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('New Run'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteMap(dynamic currentRun) {
    const defaultPosition = LatLng(37.7749, -122.4194);

    final List<LatLng> routePoints = currentRun.route.isNotEmpty
        ? currentRun.route.map((p) => LatLng(p.latitude, p.longitude)).toList()
        : [defaultPosition];

    return FlutterMap(
      options: MapOptions(
        initialCenter:
            routePoints.isNotEmpty ? routePoints[0] : defaultPosition,
        initialZoom: 14,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: routePoints,
              color: Colors.blue,
              strokeWidth: 4.0,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            if (routePoints.isNotEmpty)
              Marker(
                point: routePoints.first,
                width: 20,
                height: 20,
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.green,
                  size: 20,
                ),
              ),
            if (routePoints.length > 1)
              Marker(
                point: routePoints.last,
                width: 20,
                height: 20,
                child: const Icon(
                  Icons.flag,
                  color: Colors.red,
                  size: 20,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievementSection(BuildContext context, dynamic currentRun) {
    // In a real app, you would calculate achievements based on the run data
    // For this example, we'll use some placeholder achievements

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildAchievementItem(
                  context,
                  icon: Icons.local_fire_department,
                  title: 'Calorie Crusher',
                  description: 'Burned over 200 calories in a single run',
                  achieved: currentRun.calories > 200,
                ),
                const Divider(),
                _buildAchievementItem(
                  context,
                  icon: Icons.speed,
                  title: 'Speed Demon',
                  description: 'Maintained an average speed above 10 km/h',
                  achieved: currentRun.avgSpeed > 10,
                ),
                const Divider(),
                _buildAchievementItem(
                  context,
                  icon: Icons.timer,
                  title: 'Endurance Master',
                  description: 'Ran for more than 30 minutes',
                  achieved: currentRun.duration.inMinutes > 30,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool achieved,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: achieved ? Colors.amber : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: achieved ? Colors.white : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: achieved ? null : Colors.grey[600],
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          Icon(
            achieved ? Icons.check_circle : Icons.radio_button_unchecked,
            color: achieved ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m ${seconds}s';
    }
  }

  String _getChaserResult(RunProvider runProvider) {
    final chaserDistance = runProvider.chaserDistance;

    if (chaserDistance <= 0) {
      return 'Caught';
    } else if (chaserDistance < 50) {
      return 'Close Call';
    } else {
      return 'Escaped';
    }
  }

  Color _getChaserResultColor(RunProvider runProvider) {
    final chaserDistance = runProvider.chaserDistance;

    if (chaserDistance <= 0) {
      return Colors.red;
    } else if (chaserDistance < 50) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
