import 'package:flutter/material.dart';

import '../services/progression_repository.dart';
import '../state.dart';
import '../ui.dart';
import 'progression.dart';

class ChampionScreen extends StatefulWidget {
  const ChampionScreen({super.key, this.progressionRepository});
  final ProgressionDataSource? progressionRepository;

  @override
  State<ChampionScreen> createState() => _ChampionScreenState();
}

class _ChampionScreenState extends State<ChampionScreen> {
  late final _progression =
      widget.progressionRepository ?? ProgressionRepository();
  final Set<String> _reported = {};

  Widget _tracked(String title, String value) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text('Tracked by the app · $value'),
      );

  Widget _selfReported(String title) => CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: const Text('Self-reported'),
        value: _reported.contains(title),
        onChanged: (value) => setState(() {
          if (value == true) {
            _reported.add(title);
          } else {
            _reported.remove(title);
          }
        }),
      );

  Widget _outside(String title) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: const Text('Done outside the app'),
      );

  Widget _step(String title, List<Widget> children) => Panel(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.transparent,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ...children,
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final activity = appState.activityLoading
              ? 'Loading'
              : appState.activityError != null
                  ? 'Unavailable'
                  : null;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Your pathway',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Self-reported progress, not verified or certified'),
              const SizedBox(height: 12),
              _step('Foundation', [
                _tracked('Longest streak (all time)',
                    activity ?? '${appState.longestStreak} days'),
                _selfReported('Set a personal training goal'),
                _outside('Learn the basics of your chosen sport'),
              ]),
              _step('Novice', [
                LiveProgress<ActivityCounts>(
                  repository: _progression,
                  load: _progression.activityCounts,
                  builder: (context, counts) => _tracked(
                      'Workouts logged (all time)', '${counts.workouts}'),
                ),
                _selfReported('Practice a consistent routine'),
                _outside('Ask a qualified coach for feedback'),
              ]),
              _step('Competitor-ready', [
                LiveProgress<ActivityCounts>(
                  repository: _progression,
                  load: _progression.activityCounts,
                  builder: (context, counts) => _tracked(
                      'Consumed meals logged (all time)', '${counts.meals}'),
                ),
                _selfReported('Practice your event skills'),
                _outside('Review an event organizer’s requirements'),
              ]),
              _step('National level', [
                LiveProgress<LevelProgress?>(
                  repository: _progression,
                  load: _progression.level,
                  builder: (context, level) =>
                      _tracked('App level', level?.name ?? 'Not available'),
                ),
                _selfReported('Plan your next training milestone'),
                _outside('Explore national events and their rules'),
              ]),
              _step('Pro pathway', [
                _selfReported('Make a long-term preparation plan'),
                _outside('Research the official pathway for your sport'),
              ]),
              const Text(
                  "How to register: check the organizer's official site for rules and registration"),
            ],
          );
        },
      );
}
