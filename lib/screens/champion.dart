import 'package:flutter/material.dart';

import '../l10n_strings.dart';
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
        setState(() => loadError = friendlyError(e, localizations: strings(context)));
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
          ..showSnackBar(SnackBar(
              content: Text(strings(context).pathSaveError(friendlyError(e, localizations: strings(context))))));
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
        subtitle: Text(strings(context).pathTracked(value)),
      );

  Widget _selfReported(String key, String title) => CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text(strings(context).pathSelfReported),
        value: _reported.contains(key),
        onChanged: loading || loadError != null || saving.contains(key)
            ? null
            : (value) => _toggle(key, value == true),
      );

  Widget _outside(String title) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text(strings(context).pathOutside),
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
          final l = strings(context);
          final activity = state.activityLoading
              ? l.pathLoading
              : state.activityError != null
                  ? l.mergeUnavailable
                  : null;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l.pathTitle,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(l.pathDisclaimer),
              if (loading) Text(l.pathLoadingChecks),
              if (loadError != null) ...[
                Text(l.pathLoadError(loadError!)),
                TextButton(onPressed: _loadChecks, child: Text(l.plannerRetry)),
              ],
              const SizedBox(height: 12),
              _step(l.pathFoundation, [
                _tracked(l.pathLongestStreak,
                    activity ?? l.pathDays(state.longestStreak)),
                _selfReported('foundation_goal', l.pathSetGoal),
                _outside(l.pathLearnBasics),
              ]),
              _step(l.pathNovice, [
                LiveProgress<ActivityCounts>(
                  repository: _progression,
                  load: _progression.activityCounts,
                  builder: (context, counts) =>
                      _tracked(l.pathWorkouts, fmt(counts.workouts)),
                ),
                _selfReported('novice_routine', l.pathRoutine),
                _outside(l.pathCoach),
              ]),
              _step(l.pathCompetitor, [
                LiveProgress<ActivityCounts>(
                  repository: _progression,
                  load: _progression.activityCounts,
                  builder: (context, counts) =>
                      _tracked(l.pathMeals, fmt(counts.meals)),
                ),
                _selfReported('competitor_skills', l.pathSkills),
                _outside(l.pathRequirements),
              ]),
              _step(l.pathNational, [
                LiveProgress<LevelProgress?>(
                  repository: _progression,
                  load: _progression.level,
                  builder: (context, level) => _tracked(
                      l.pathAppLevel,
                      level == null
                          ? l.pathNotAvailable
                          : localizedLevelName(context, level.name)),
                ),
                _selfReported('national_milestone', l.pathMilestone),
                _outside(l.pathEvents),
              ]),
              _step(l.pathPro, [
                _selfReported('pro_preparation', l.pathPreparation),
                _outside(l.pathResearch),
              ]),
              Text(l.pathRegister),
            ],
          );
        },
      );
}
