import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';

class RecentRunsList extends StatelessWidget {
  const RecentRunsList({super.key});

  @override
  Widget build(BuildContext context) {
    final runProvider = Provider.of<RunProvider>(context);
    final pastRuns = runProvider.pastRuns;

    if (pastRuns.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                Icons.directions_run,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'No runs yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Your recent runs will appear here',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    // Show only the 3 most recent runs
    final recentRuns = pastRuns.take(3).toList();

    return Column(
      children: [
        ...recentRuns
            .map((run) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withAlpha((0.1 * 255).toInt()),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.directions_run,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(run.formattedDate),
                    subtitle: Text("${run.distance} km"),
                  ),
                ))
            ,
      ],
    );
  }
}
