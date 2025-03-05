import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../widgets/recent_runs_list.dart';
import '../widgets/stats_summary.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final runProvider = Provider.of<RunProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chase Runner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                Text(
                  'Ready to run?',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Outrun your chasers and beat your personal records!',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),

                const SizedBox(height: 24),

                // Stats summary
                const StatsSummary(),

                const SizedBox(height: 24),

                // Recent runs
                Text(
                  'Recent Runs',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const RecentRunsList(),

                const SizedBox(height: 24),

                // Quick actions
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        'Start Quick Run',
                        Icons.directions_run,
                        Colors.blue,
                        () => Navigator.pushNamed(context, '/setup'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        'Run History',
                        Icons.history,
                        Colors.green,
                        () => Navigator.pushNamed(context, '/history'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        'Ghost Mode',
                        Icons
                            .nights_stay, // Changed from Icons.ghost to an existing icon
                        Colors.purple,
                        () {
                          if (runProvider.pastRuns.isNotEmpty) {
                            // Show dialog to select a past run
                            _showGhostRunDialog(context, runProvider);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'No past runs available for Ghost Mode'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        'Challenges',
                        Icons.emoji_events,
                        Colors.orange,
                        () {
                          // Show coming soon message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Challenges coming soon!'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGhostRunDialog(BuildContext context, RunProvider runProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select a past run'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: runProvider.pastRuns.length,
            itemBuilder: (context, index) {
              final run = runProvider.pastRuns[index];
              return ListTile(
                title:
                    Text('${run.formattedDate} - ${run.formattedDistance} km'),
                subtitle: Text('Duration: ${run.formattedDuration}'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/setup',
                    arguments: {'ghostRun': run},
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
