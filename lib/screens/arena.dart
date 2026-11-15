import 'package:flutter/material.dart';

import '../state.dart';
import '../ui.dart';

class ArenaScreen extends StatelessWidget {
  const ArenaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final state = appState;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            sectionTitle('Your activity streak'),
            Panel(
              child: Column(children: [
                if (state.activityError != null) ...[
                  Text(state.activityError!, textAlign: TextAlign.center),
                  TextButton.icon(
                    onPressed: state.loadActivity,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  const SizedBox(height: 8),
                ],
                if (state.activityLoading && state.activityError == null)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: LinearProgressIndicator(),
                  ),
                Row(children: [
                  Icon(Icons.local_fire_department, color: kGold, size: 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your streak: ${state.streak} days',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Longest streak: ${state.longestStreak} days',
                          style: TextStyle(fontSize: 12, color: kMuted),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Icon(Icons.stars, color: kGold, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '${fmt(state.storePoints)} store points',
                    style: TextStyle(
                        color: kGold,
                        fontSize: 13,
                        fontWeight: FontWeight.w800),
                  ),
                ]),
                const SizedBox(height: 10),
                Text(
                  'Log a meal or completed workout to update your streak and earn 10 XP plus 10 store points once per active day.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: kMuted),
                ),
              ]),
            ),
            sectionTitle('Arena features'),
            Panel(
              child: Column(children: [
                const Icon(Icons.emoji_events_outlined, size: 34),
                const SizedBox(height: 8),
                const Text(
                  'Leaderboards and friend challenges are coming in Stage 3. Rewards and redemptions are coming in Stage 4.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Activity is self-reported and is not independently verified.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: kMuted),
                ),
              ]),
            ),
          ],
        );
      },
    );
  }
}
