import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../models/chaser.dart';
import '../models/run_data.dart';

class RunSetupScreen extends StatefulWidget {
  const RunSetupScreen({super.key});

  @override
  State<RunSetupScreen> createState() => _RunSetupScreenState();
}

class _RunSetupScreenState extends State<RunSetupScreen> {
  Chaser _selectedChaser = Chaser.defaultChaser();
  bool _isGhostMode = false;
  RunData? _ghostRun;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if we have arguments for ghost mode
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('ghostRun')) {
      _ghostRun = args['ghostRun'] as RunData;
      _isGhostMode = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isGhostMode ? 'Ghost Run Setup' : 'Run Setup'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mode selection
                if (!_isGhostMode) ...[
                  Text(
                    'Choose Your Chaser',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),

                  // Chaser selection cards
                  _buildChaserGrid(),

                  const SizedBox(height: 24),

                  // Chaser details
                  _buildChaserDetails(),
                ] else ...[
                  // Ghost run details
                  Text(
                    'Ghost Run Mode',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),

                  _buildGhostRunDetails(),
                ],

                const SizedBox(height: 32),

                // Start button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _startRun,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isGhostMode ? 'Start Ghost Run' : 'Start Run',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChaserGrid() {
    final chasers = [
      Chaser.zombie(),
      Chaser.ghost(),
      Chaser.athlete(),
      Chaser.robot(),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: chasers.length,
      itemBuilder: (context, index) {
        final chaser = chasers[index];
        final isSelected = _selectedChaser.id == chaser.id;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedChaser = chaser;
            });
          },
          child: Card(
            elevation: isSelected ? 8 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Placeholder for chaser image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getChaserIcon(chaser),
                      size: 40,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    chaser.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chaser.difficultyString,
                    style: TextStyle(
                      color: _getDifficultyColor(chaser.difficulty),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChaserDetails() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedChaser.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedChaser.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.speed, size: 20),
                const SizedBox(width: 8),
                Text(
                    'Base Speed: ${_selectedChaser.baseSpeed.toStringAsFixed(1)} km/h'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.trending_up, size: 20),
                const SizedBox(width: 8),
                Text('Difficulty: ${_selectedChaser.difficultyString}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGhostRunDetails() {
    if (_ghostRun == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No ghost run selected'),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Race Against Your Past Self',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                Text('Date: ${_ghostRun!.formattedDate}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.straighten, size: 20),
                const SizedBox(width: 8),
                Text('Distance: ${_ghostRun!.formattedDistance} km'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer, size: 20),
                const SizedBox(width: 8),
                Text('Duration: ${_ghostRun!.formattedDuration}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.speed, size: 20),
                const SizedBox(width: 8),
                Text('Avg. Speed: ${_ghostRun!.formattedAvgSpeed} km/h'),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Try to beat your previous time! Your past self will be visualized on the map.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  void _startRun() {
    final runProvider = Provider.of<RunProvider>(context, listen: false);

    if (_isGhostMode && _ghostRun != null) {
      runProvider.startRun(ghostRunData: _ghostRun);
    } else {
      runProvider.startRun(customChaser: _selectedChaser);
    }

    Navigator.pushNamed(context, '/active_run');
  }

  IconData _getChaserIcon(Chaser chaser) {
    switch (chaser.id) {
      case 'zombie_1':
        return Icons.sports_kabaddi;
      case 'ghost_1':
        // Changed from Icons.ghost_outlined (which doesn't exist) to an alternative icon
        return Icons.blur_on_outlined; // Outlined version for consistency
      case 'athlete_1':
        return Icons.directions_run;
      case 'robot_1':
        return Icons.android;
      default:
        return Icons.person;
    }
  }

  Color _getDifficultyColor(ChaserDifficulty difficulty) {
    switch (difficulty) {
      case ChaserDifficulty.easy:
        return Colors.green;
      case ChaserDifficulty.medium:
        return Colors.blue;
      case ChaserDifficulty.hard:
        return Colors.orange;
      case ChaserDifficulty.extreme:
        return Colors.red;
    }
  }
}
