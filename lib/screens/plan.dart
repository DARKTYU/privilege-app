import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/planner_repository.dart';
import '../state.dart';
import '../ui.dart';
import 'workout_logger_sheet.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key, this.state});
  final AppState? state;

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> with WidgetsBindingObserver {
  late final AppState state = widget.state ?? appState;
  DateTime? week;
  DateTime? selected;
  bool busy = false;
  bool activityWasLoading = false;
  bool refreshAfterLoad = false;
  String? initialError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    state.addListener(_activityChanged);
    activityWasLoading = state.activityLoading;
    if (!activityWasLoading) _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    state.removeListener(_activityChanged);
    super.dispose();
  }

  void _activityChanged() {
    final finished = activityWasLoading && !state.activityLoading;
    activityWasLoading = state.activityLoading;
    if (finished) {
      if (week == null) {
        _initialize();
      } else if (state.plannerLoading) {
        refreshAfterLoad = true;
      } else {
        _loadWeek();
      }
    } else if (refreshAfterLoad && !state.plannerLoading && week != null) {
      refreshAfterLoad = false;
      _loadWeek();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed && week != null && !busy) {
      _loadWeek();
    }
  }

  Future<void> _initialize() async {
    try {
      final today = parsePlannerDate(await state.plannerLocalToday());
      if (!mounted) return;
      setState(() {
        selected = today;
        week = today.subtract(Duration(days: today.weekday % 7));
        initialError = null;
      });
      await _loadWeek();
    } catch (error) {
      if (mounted) setState(() => initialError = error.toString());
    }
  }

  Future<void> _loadWeek() => state.loadPlanner(
      plannerDate(week!), plannerDate(week!.add(const Duration(days: 6))));

  Future<void> _moveWeek(int offset) async {
    setState(() {
      week = week!.add(Duration(days: offset * 7));
      final today = state.plannerToday;
      selected = today != null &&
              today.compareTo(plannerDate(week!)) >= 0 &&
              today.compareTo(
                      plannerDate(week!.add(const Duration(days: 6)))) <=
                  0
          ? parsePlannerDate(today)
          : week;
    });
    final targetWeek = week!;
    final initialSelection = selected;
    await _loadWeek();
    if (!mounted ||
        week != targetWeek ||
        selected != initialSelection ||
        state.plannerStart != plannerDate(targetWeek)) {
      return;
    }
    final today = state.plannerToday;
    if (today != null &&
        today.compareTo(plannerDate(targetWeek)) >= 0 &&
        today.compareTo(plannerDate(targetWeek.add(const Duration(days: 6)))) <=
            0) {
      setState(() => selected = parsePlannerDate(today));
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $error')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete')),
          ],
        ),
      ) ??
      false;

  Future<void> _splitForm([PlannerSplit? split]) async {
    final result = await showDialog<PlannerSplit>(
      context: context,
      builder: (_) => _PlannerForm(
        title: split == null ? 'Add Split' : 'Edit split',
        name: split?.name ?? '',
        kind: split?.kind ?? 'workout',
        duration: split?.duration,
        effort: split?.effort,
        chooseKind: true,
        onSubmit: (name, kind, duration, effort) => PlannerSplit(
            id: split?.id ?? '',
            name: name,
            kind: kind,
            duration: duration,
            effort: effort),
      ),
    );
    if (result == null || !mounted) return;
    await _run(() => split == null
        ? state.createPlannerSplits([result])
        : state.editPlannerSplit(result));
  }

  Future<void> _dayForm(PlannerDay day) async {
    final result = await showDialog<PlannerDay>(
      context: context,
      builder: (_) => _PlannerForm<PlannerDay>(
        title: 'Edit this day',
        name: day.name,
        kind: day.kind,
        duration: day.duration,
        effort: day.effort,
        chooseKind: false,
        onSubmit: (name, kind, duration, effort) => PlannerDay(
          date: day.date,
          name: name,
          kind: kind,
          duration: duration,
          effort: effort,
          sourceSplitId: day.sourceSplitId,
        ),
      ),
    );
    if (result != null && mounted) {
      await _run(() => state.editPlannerDay(result));
    }
  }

  Future<void> _chooseDay() async {
    final date = plannerDate(selected!);
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Plan this day'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
                title: const Text('Rest day'),
                onTap: () => Navigator.pop(context, 'rest')),
            for (final split in [
              ...state.plannerSplits.where((item) => item.kind == 'workout'),
              ...state.plannerSplits.where((item) => item.kind == 'rest'),
            ])
              ListTile(
                  title: Text(split.name),
                  subtitle: Text(split.kind),
                  onTap: () => Navigator.pop(context, split.id)),
          ])),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'))
        ],
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == 'rest') {
      await _run(() => state.markPlannerRest(date));
    } else {
      final split =
          state.plannerSplits.where((item) => item.id == choice).firstOrNull;
      if (split == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('The split is no longer available.')));
        return;
      }
      await _run(() => state.planDayFromSplit(date, split));
    }
  }

  Future<void> _starterSplits() => _run(() async {
        if (state.plannerSplits.isNotEmpty) return;
        await state.createPlannerSplits([
          for (final name in ['Push', 'Pull', 'Legs'])
            PlannerSplit(
                id: '', name: name, kind: 'workout', duration: 60, effort: 70),
        ]);
      });

  Future<void> _logWorkout(PlannerDay day) async {
    try {
      final today = await state.plannerLocalToday();
      if (!mounted) return;
      if (plannerDate(selected!) != today || day.date != today) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Logging is available on the workout day only.')));
        await _loadWeek();
        return;
      }
      await showWorkoutLogger(context, state, initialDuration: day.duration);
      if (mounted) await _loadWeek();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open workout logger: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          if (week == null) {
            return Center(
                child: initialError == null
                    ? const CircularProgressIndicator()
                    : Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('Could not load planner: $initialError'),
                        TextButton(
                            onPressed: _initialize, child: const Text('Retry')),
                      ]));
          }
          final currentRange = state.plannerStart == plannerDate(week!) &&
              state.plannerEnd ==
                  plannerDate(week!.add(const Duration(days: 6)));
          final days = currentRange ? state.plannerDays : <PlannerDay>[];
          final date = plannerDate(selected!);
          final day = days.where((d) => d.date == date).firstOrNull;
          return ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                const ScreenHeader(
                    'Plan Organiser', 'Weekly calendar & schedule planner',
                    logo: true),
                Row(children: [
                  IconButton(
                      tooltip: 'Previous week',
                      onPressed: busy ? null : () => _moveWeek(-1),
                      icon: const Icon(Icons.chevron_left)),
                  Expanded(
                      child: Text(
                          '${plannerDate(week!)} – ${plannerDate(week!.add(const Duration(days: 6)))}',
                          textAlign: TextAlign.center)),
                  IconButton(
                      tooltip: 'Next week',
                      onPressed: busy ? null : () => _moveWeek(1),
                      icon: const Icon(Icons.chevron_right)),
                ]),
                if (state.plannerLoading) const LinearProgressIndicator(),
                if (state.plannerError != null) ...[
                  Text('Could not load planner: ${state.plannerError}',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                  TextButton(onPressed: _loadWeek, child: const Text('Retry')),
                ],
                Row(children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                        child:
                            _calendarDay(week!.add(Duration(days: i)), days)),
                ]),
                const SizedBox(height: 8),
                Wrap(spacing: 12, runSpacing: 4, children: [
                  _legend('Planned workout', false),
                  _legend('Completed workout', true),
                  const Text('— Rest day', style: TextStyle(fontSize: 11)),
                ]),
                const SizedBox(height: 16),
                if (currentRange &&
                    state.plannerError == null &&
                    !state.plannerLoading) ...[
                  Panel(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(
                            'Selected day: ${MaterialLocalizations.of(context).formatMediumDate(selected!)}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (day == null)
                          const Text('Nothing planned for this day.')
                        else ...[
                          Text(day.name),
                          if (day.kind != 'rest' ||
                              day.name.trim().toLowerCase() != 'rest day')
                            Text(day.kind == 'rest'
                                ? 'Rest day'
                                : 'Workout · ${day.duration} min · ${day.effort}% effort'),
                          if (day.kind == 'workout')
                            Text(state.plannerWorkoutDates.contains(date)
                                ? 'Workout logged'
                                : 'Workout not logged'),
                        ],
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 4, children: [
                          OutlinedButton(
                              onPressed: busy ? null : _chooseDay,
                              child: const Text('Plan this day')),
                          if (day != null) ...[
                            OutlinedButton(
                                onPressed: busy ? null : () => _dayForm(day),
                                child: const Text('Edit this day')),
                            OutlinedButton(
                                onPressed: busy
                                    ? null
                                    : () async {
                                        if (await _confirm(
                                                'Remove planned day?',
                                                'This does not delete any workout log.') &&
                                            mounted) {
                                          await _run(() =>
                                              state.removePlannerDay(date));
                                        }
                                      },
                                child: const Text('Remove')),
                          ],
                          if (day?.kind == 'workout' &&
                              date == state.plannerToday)
                            OutlinedButton(
                                onPressed:
                                    busy ? null : () => _logWorkout(day!),
                                child: const Text('Log this workout')),
                        ]),
                        if (day?.kind == 'workout' &&
                            state.plannerToday != null &&
                            date.compareTo(state.plannerToday!) > 0)
                          const Text('Available on the day'),
                      ])),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Expanded(
                        child: Text('My splits',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    TextButton.icon(
                        onPressed: busy ? null : () => _splitForm(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Split')),
                  ]),
                  if (state.plannerSplits.isEmpty) ...[
                    const Text(
                        'No splits yet. Create one or add starter splits.'),
                    Wrap(spacing: 8, children: [
                      OutlinedButton(
                          onPressed: busy ? null : () => _splitForm(),
                          child: const Text('Create your first split')),
                      OutlinedButton(
                          onPressed: busy ? null : _starterSplits,
                          child: const Text('Add starter splits')),
                    ]),
                  ],
                  for (final split in state.plannerSplits)
                    Panel(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(split.name),
                                Text(
                                    split.kind == 'rest'
                                        ? 'Rest'
                                        : '${split.duration} min · ${split.effort}% effort',
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                              ])),
                          IconButton(
                              tooltip: 'Edit ${split.name}',
                              onPressed: busy ? null : () => _splitForm(split),
                              icon: const Icon(Icons.edit_outlined)),
                          IconButton(
                              tooltip: 'Delete ${split.name}',
                              onPressed: busy
                                  ? null
                                  : () async {
                                      if (await _confirm(
                                              'Delete ${split.name}?',
                                              'Days already planned will stay unchanged.') &&
                                          mounted) {
                                        await _run(() =>
                                            state.deletePlannerSplit(split.id));
                                      }
                                    },
                              icon: const Icon(Icons.delete_outline)),
                        ])),
                  const Text(
                      'Deleting a split keeps the days already planned.'),
                ],
              ]);
        },
      );

  Widget _calendarDay(DateTime date, List<PlannerDay> days) {
    final key = plannerDate(date);
    final day = days.where((item) => item.date == key).firstOrNull;
    final complete =
        day?.kind == 'workout' && state.plannerWorkoutDates.contains(key);
    final label = const ['S', 'M', 'T', 'W', 'T', 'F', 'S'][date.weekday % 7];
    final background = selected == date ? kMaroon : kCard;
    final todayColor =
        background.computeLuminance() > 0.179 ? Colors.black : Colors.white;
    return InkWell(
      key: ValueKey('planner-date-$key'),
      onTap: () => setState(() => selected = date),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected == date ? kGold : kLine),
        ),
        child: Column(children: [
          Text(label),
          Text('${date.day}'),
          SizedBox(
            height: 3,
            child: key == state.plannerToday
                ? Semantics(
                    label: 'Today',
                    child: Container(
                      key: ValueKey('today-$key'),
                      width: 18,
                      height: 2,
                      color: todayColor,
                    ),
                  )
                : null,
          ),
          SizedBox(
              height: 12,
              child: Center(
                  child: day == null
                      ? null
                      : day.kind == 'rest'
                          ? Container(
                              key: ValueKey('rest-$key'),
                              width: 10,
                              height: 2,
                              color: kGold)
                          : Container(
                              key: ValueKey(
                                  '${complete ? 'completed' : 'planned'}-$key'),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: kGold),
                                  color:
                                      complete ? kGold : Colors.transparent)))),
        ]),
      ),
    );
  }

  Widget _legend(String text, bool filled) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kGold),
                color: filled ? kGold : Colors.transparent)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11)),
      ]);
}

class _PlannerForm<T> extends StatefulWidget {
  const _PlannerForm(
      {required this.title,
      required this.name,
      required this.kind,
      required this.duration,
      required this.effort,
      required this.chooseKind,
      required this.onSubmit});
  final String title, name, kind;
  final int? duration, effort;
  final bool chooseKind;
  final T Function(String, String, int?, int?) onSubmit;
  @override
  State<_PlannerForm<T>> createState() => _PlannerFormState<T>();
}

class _PlannerFormState<T> extends State<_PlannerForm<T>> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.name);
  late final duration = TextEditingController(text: '${widget.duration ?? 60}');
  late final effort = TextEditingController(text: '${widget.effort ?? 70}');
  late String kind = widget.kind;

  @override
  void dispose() {
    name.dispose();
    duration.dispose();
    effort.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: SingleChildScrollView(
            child: Form(
                key: form,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextFormField(
                      controller: name,
                      decoration: const InputDecoration(
                          labelText: 'Name', errorMaxLines: 3),
                      validator: (value) => value == null ||
                              value.trim().isEmpty ||
                              value.trim().runes.length > 100
                          ? 'Enter a name between 1 and 100 characters.'
                          : null),
                  if (widget.chooseKind) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                        initialValue: kind,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: const [
                          DropdownMenuItem(
                              value: 'workout', child: Text('Workout')),
                          DropdownMenuItem(value: 'rest', child: Text('Rest'))
                        ],
                        onChanged: (value) => setState(() => kind = value!)),
                  ],
                  if (kind == 'workout') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: duration,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                            labelText: 'Duration (minutes)',
                            helperText: '1 to 600 minutes',
                            errorMaxLines: 3),
                        validator: (value) {
                          final n = int.tryParse(value ?? '');
                          return n == null || n < 1 || n > 600
                              ? 'Enter 1 to 600 minutes.'
                              : null;
                        }),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: effort,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                            labelText: 'Effort (%)',
                            helperText: '0 to 100',
                            errorMaxLines: 3),
                        validator: (value) {
                          final n = int.tryParse(value ?? '');
                          return n == null || n < 0 || n > 100
                              ? 'Enter effort from 0 to 100%.'
                              : null;
                        }),
                  ],
                ]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                if (form.currentState!.validate()) {
                  Navigator.pop(
                      context,
                      widget.onSubmit(
                          name.text.trim(),
                          kind,
                          kind == 'workout' ? int.parse(duration.text) : null,
                          kind == 'workout' ? int.parse(effort.text) : null));
                }
              },
              child: const Text('Save')),
        ],
      );
}
