import 'package:flutter/material.dart';

import '../services/progression_repository.dart';
import '../state.dart';
import '../ui.dart';
import 'progression.dart';

class ChampionScreen extends StatefulWidget {
  const ChampionScreen({super.key, this.progressionRepository, this.state});
  final ProgressionDataSource? progressionRepository;
  final AppState? state;

  @override
  State<ChampionScreen> createState() => _ChampionScreenState();
}

class _ChampionScreenState extends State<ChampionScreen> {
  late final _progression =
      widget.progressionRepository ?? ProgressionRepository();
  late final AppState state = widget.state ?? appState;
  Set<String> _reported = {};
  String? account, loadError;
  bool loading = true;
  final Set<String> saving = {};
  int generation = 0;

  @override
  void initState() {
    super.initState();
    account = state.classifiedAccountId;
    state.addListener(_accountChanged);
    _loadChecks();
  }

  void _accountChanged() {
    if (account == state.classifiedAccountId) return;
    account = state.classifiedAccountId;
    generation++;
    setState(() {
      _reported = {};
      saving.clear();
    });
    _loadChecks();
  }

  Future<void> _loadChecks() async {
    final user = state.classifiedAccountId;
    final token = ++generation;
    setState(() {
      loading = true;
      loadError = null;
    });
    try {
      final result = await state.loadClassifiedChecks();
      if (mounted && token == generation && user == state.classifiedAccountId) {
        setState(() => _reported = result);
      }
    } catch (e) {
      if (mounted && token == generation && user == state.classifiedAccountId) {
        setState(() => loadError = e.toString());
      }
    } finally {
      if (mounted && token == generation && user == state.classifiedAccountId) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _toggle(String key, bool checked) async {
    if (saving.contains(key)) return;
    final user = state.classifiedAccountId;
    final token = generation;
    setState(() => saving.add(key));
    try {
      await state.setClassifiedChecked(key, checked);
      if (mounted && token == generation && user == state.classifiedAccountId) {
        setState(() {
          if (checked) {
            _reported.add(key);
          } else {
            _reported.remove(key);
          }
        });
      }
    } catch (e) {
      if (mounted && token == generation && user == state.classifiedAccountId) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
              SnackBar(content: Text('Could not save checklist: $e')));
      }
    } finally {
      if (mounted && token == generation) setState(() => saving.remove(key));
    }
  }

  @override
  void dispose() {
    state.removeListener(_accountChanged);
    super.dispose();
  }

  Widget _tracked(String title, String value) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text('Tracked by the app · $value'),
      );

  Widget _selfReported(String key, String title) => CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: const Text('Self-reported, not verified'),
        value: _reported.contains(key),
        onChanged: loading || loadError != null || saving.contains(key)
            ? null
            : (value) => _toggle(key, value == true),
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
        listenable: state,
        builder: (context, _) {
          final activity = state.activityLoading
              ? 'Loading'
              : state.activityError != null
                  ? 'Unavailable'
                  : null;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Your pathway',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Self-reported progress, not verified or certified'),
              if (loading) const Text('Loading checklist...'),
              if (loadError != null) ...[
                Text('Could not load checklist: $loadError'),
                TextButton(onPressed: _loadChecks, child: const Text('Retry')),
              ],
              const SizedBox(height: 12),
              _step('Foundation', [
                _tracked('Longest streak (all time)',
                    activity ?? '${state.longestStreak} days'),
                _selfReported(
                    'foundation_goal', 'Set a personal training goal'),
                _outside('Learn the basics of your chosen sport'),
              ]),
              _step('Novice', [
                LiveProgress<ActivityCounts>(
                  repository: _progression,
                  load: _progression.activityCounts,
                  builder: (context, counts) => _tracked(
                      'Workouts logged (all time)', '${counts.workouts}'),
                ),
                _selfReported(
                    'novice_routine', 'Practice a consistent routine'),
                _outside('Ask a qualified coach for feedback'),
              ]),
              _step('Competitor-ready', [
                LiveProgress<ActivityCounts>(
                  repository: _progression,
                  load: _progression.activityCounts,
                  builder: (context, counts) => _tracked(
                      'Consumed meals logged (all time)', '${counts.meals}'),
                ),
                _selfReported(
                    'competitor_skills', 'Practice your event skills'),
                _outside('Review an event organizer’s requirements'),
              ]),
              _step('National level', [
                LiveProgress<LevelProgress?>(
                  repository: _progression,
                  load: _progression.level,
                  builder: (context, level) =>
                      _tracked('App level', level?.name ?? 'Not available'),
                ),
                _selfReported(
                    'national_milestone', 'Plan your next training milestone'),
                _outside('Explore national events and their rules'),
              ]),
              _step('Pro pathway', [
                _selfReported(
                    'pro_preparation', 'Make a long-term preparation plan'),
                _outside('Research the official pathway for your sport'),
              ]),
              const Text(
                  "How to register: check the organizer's official site for rules and registration"),
            ],
          );
        },
      );
}
