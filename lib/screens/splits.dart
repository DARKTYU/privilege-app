import 'package:flutter/material.dart';

import '../data.dart';
import '../logic/fitness_logic.dart';
import '../services/progression_repository.dart';
import '../ui.dart';

class SplitsScreen extends StatefulWidget {
  const SplitsScreen({super.key, this.progressionRepository});
  final ProgressionDataSource? progressionRepository;

  @override
  State<SplitsScreen> createState() => _SplitsScreenState();
}

class _SplitsScreenState extends State<SplitsScreen> {
  late final List<SplitOption> _workouts = List.of(defaultWorkoutSplits);
  late final List<SplitOption> _sports = List.of(defaultSports);
  late SplitOption _workout = _workouts.first;
  late SplitOption _sport = _sports.first;
  MergeResult? _result;
  bool _merging = false;
  bool _openWorkout = false, _openSport = false;
  late final _progression =
      widget.progressionRepository ?? ProgressionRepository();
  bool _checkingMembership = false;

  Future<void> _merge() async {
    setState(() => _merging = true);
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() {
      _result = mergeWorkoutWithSport(
          _workout.name,
          _workout.calories,
          _workout.durationMin,
          _sport.name,
          _sport.calories,
          _sport.durationMin);
      _merging = false;
    });
  }

  Future<void> _addCustom() async {
    if (_checkingMembership) return;
    setState(() => _checkingMembership = true);
    try {
      final accountId = _progression.accountId;
      final membership = await _progression.subscriptionTier();
      if (!mounted || accountId != _progression.accountId) return;
      if (subscriptionTierRank(membership) < subscriptionTierRank('Silver')) {
        toast(context,
            'Custom splits require Silver or Gold membership. Paid upgrades are not available yet.');
        return;
      }
    } catch (error) {
      if (mounted) toast(context, 'Could not check membership: $error');
      return;
    } finally {
      if (mounted) setState(() => _checkingMembership = false);
    }
    var isSport = false;
    final name = TextEditingController();
    final duration = TextEditingController(text: '60');
    final kcal = TextEditingController(text: '480');
    final focus = TextEditingController();
    final created = await showDialog<SplitOption>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          backgroundColor: kCard2,
          title: const Text('Create Custom Split'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(
                    child: appChip('Gym Split', !isSport,
                        () => set(() => isSport = false))),
                const SizedBox(width: 8),
                Expanded(
                    child: appChip('Athletic Sport', isSport,
                        () => set(() => isSport = true))),
              ]),
              const SizedBox(height: 10),
              TextField(
                  controller: name,
                  decoration: fieldDecoration('e.g. Incline Bench & Dips')),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: duration,
                    keyboardType: TextInputType.number,
                    decoration: fieldDecoration('Minutes'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: kcal,
                    keyboardType: TextInputType.number,
                    decoration: fieldDecoration('Burn (kcal)'),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              TextField(
                  controller: focus,
                  decoration: fieldDecoration('e.g. Upper Chest, Deltoids')),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (name.text.trim().isEmpty) return;
                Navigator.pop(
                  ctx,
                  SplitOption(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name.text.trim(),
                    isSport: isSport,
                    durationMin: int.tryParse(duration.text) ?? 60,
                    calories: int.tryParse(kcal.text) ?? 450,
                    icon: isSport ? '🏅' : '🏋️',
                    focus: focus.text.trim().isEmpty
                        ? (isSport
                            ? 'Athletic Conditioning'
                            : 'Target Muscle Hypertrophy')
                        : focus.text.trim(),
                  ),
                );
              },
              child: const Text('Select (not saved)'),
            ),
          ],
        ),
      ),
    );
    if (created == null || !mounted) return;
    setState(() {
      if (created.isSport) {
        _sports.insert(0, created);
        _sport = created;
      } else {
        _workouts.insert(0, created);
        _workout = created;
      }
    });
  }

  Widget _pickCard(SplitOption o, String change, VoidCallback onTap) =>
      Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kCard2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kLine),
            ),
            child: Column(children: [
              Text(o.icon, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 6),
              Text(o.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13)),
              Text('${o.durationMin}m • ${o.calories} kcal',
                  style: TextStyle(fontSize: 11, color: kMuted)),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Flexible(
                  child: Text(change,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: kGold)),
                ),
                Icon(Icons.expand_more, size: 14, color: kGold),
              ]),
            ]),
          ),
        ),
      );

  Widget _picker(String title, List<SplitOption> list, SplitOption current,
          ValueChanged<SplitOption> pick) =>
      Panel(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(top: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.all(6),
            child: Text(title, style: TextStyle(fontSize: 11, color: kMuted)),
          ),
          for (final o in list)
            ListTile(
              dense: true,
              selected: o.id == current.id,
              selectedColor: kGold,
              title: Text('${o.icon}  ${o.name}',
                  style: const TextStyle(fontSize: 13)),
              trailing: Text('${o.durationMin}m',
                  style: TextStyle(fontSize: 12, color: kMuted)),
              onTap: () => pick(o),
            ),
        ]),
      );

  Widget _stat(IconData i, String label, String v, Color c) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: kCard2, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(i, size: 13, color: c),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 11, color: kMuted)),
            ]),
            const SizedBox(height: 4),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        ScreenHeader(
          'Splits & Sports Merge',
          'Combine gym splits with daily sports.',
          actions: [
            TextButton.icon(
              onPressed: _addCustom,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Split'),
            ),
          ],
        ),
        Panel(
          child: Column(children: [
            Row(children: [
              Expanded(
                  child: Text('Selected Split & Sport',
                      style: TextStyle(fontWeight: FontWeight.w800))),
              Text('Tap card to change',
                  style: TextStyle(fontSize: 11, color: kMuted)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _pickCard(
                  _workout,
                  'Change split',
                  () => setState(() {
                        _openWorkout = !_openWorkout;
                        _openSport = false;
                      })),
              const SizedBox(width: 10),
              _pickCard(
                  _sport,
                  'Change sport',
                  () => setState(() {
                        _openSport = !_openSport;
                        _openWorkout = false;
                      })),
            ]),
            if (_openWorkout)
              _picker(
                  'Select Workout Split:',
                  _workouts,
                  _workout,
                  (o) => setState(() {
                        _workout = o;
                        _openWorkout = false;
                      })),
            if (_openSport)
              _picker(
                  'Select Athletic Sport:',
                  _sports,
                  _sport,
                  (o) => setState(() {
                        _sport = o;
                        _openSport = false;
                      })),
            const SizedBox(height: 12),
            PrimaryButton(
              _merging
                  ? 'Computing Combined Fatigue...'
                  : '+ Merge Splits & Calculate Load',
              icon: Icons.auto_awesome,
              onPressed: _merging ? null : _merge,
            ),
          ]),
        ),
        if (r != null)
          Panel(
            borderColor: kGold.withAlpha(110),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.auto_awesome, size: 16, color: kGold),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('Combined Athletic Load',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                Text('${r.totalDurationMin} mins total',
                    style: TextStyle(fontSize: 11, color: kMuted)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _stat(Icons.local_fire_department, 'Burn',
                    '${r.totalCalories} kcal', kOrange),
                const SizedBox(width: 8),
                _stat(Icons.schedule, 'Rest', '${r.recoveryHoursRecommended}h',
                    kCyan),
                const SizedBox(width: 8),
                _stat(Icons.water_drop, 'Water', '${r.hydrationMlNeeded}ml',
                    kBlue),
              ]),
              const SizedBox(height: 10),
              Text('Estimates only, not medical or coaching advice.',
                  style: TextStyle(fontSize: 12, color: kMuted)),
              const SizedBox(height: 8),
              Text(r.advice, style: TextStyle(fontSize: 12, color: kMuted)),
            ]),
          ),
      ],
    );
  }
}
