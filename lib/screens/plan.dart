import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n_strings.dart';
import '../logic/localized_dates.dart';
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

  String _displayName(String name) {
    final l = strings(context);
    switch (name) {
      case 'Push':
        return l.plannerPush;
      case 'Pull':
        return l.plannerPull;
      case 'Legs':
        return l.plannerLegs;
      case 'Rest':
        return l.plannerRest;
      case 'Rest day':
        return l.plannerRestDay;
      case 'Push Day':
        return l.splitPushDay;
      case 'Pull Day':
        return l.splitPullDay;
      case 'Leg Day Hypertrophy':
        return l.splitLegDay;
      case 'Upper Body Power':
        return l.splitUpper;
      case 'Calisthenics & Core':
        return l.splitCalisthenics;
      case 'Olympic Weightlifting':
        return l.splitOlympic;
      case 'Basketball':
        return l.sportBasketball;
      case 'Football / Soccer':
        return l.sportFootball;
      case 'Tennis':
        return l.sportTennis;
      case 'Boxing / MMA':
        return l.sportBoxing;
      case 'Swimming Laps':
        return l.sportSwimming;
      case 'Track Sprint Intervals':
        return l.sportSprints;
      default:
        return name;
    }
  }

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(strings(context).plannerSaveError(error.toString()))));
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
                child: Text(strings(context).plannerCancel)),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(strings(context).plannerDelete)),
          ],
        ),
      ) ??
      false;

  Future<void> _splitForm([PlannerSplit? split]) async {
    final result = await showDialog<PlannerSplit>(
      context: context,
      builder: (_) => _PlannerForm(
        title: split == null
            ? strings(context).plannerAddSplit
            : strings(context).plannerEditSplit,
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
        title: strings(context).plannerEditDay,
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
        title: Text(strings(context).plannerPlanDay),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
                title: Text(strings(context).plannerRestDay),
                onTap: () => Navigator.pop(context, 'rest')),
            for (final split in [
              ...state.plannerSplits.where((item) => item.kind == 'workout'),
              ...state.plannerSplits.where((item) => item.kind == 'rest'),
            ])
              ListTile(
                  title: Text(_displayName(split.name)),
                  subtitle: Text(split.kind == 'rest'
                      ? strings(context).plannerRest
                      : strings(context).plannerWorkout),
                  onTap: () => Navigator.pop(context, split.id)),
          ])),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings(context).plannerCancel))
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
            SnackBar(content: Text(strings(context).plannerSplitUnavailable)));
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
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings(context).plannerLogOnlyToday)));
        await _loadWeek();
        return;
      }
      await showWorkoutLogger(context, state, initialDuration: day.duration);
      if (mounted) await _loadWeek();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(strings(context).plannerOpenError(error.toString()))));
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
                        Text(strings(context).plannerLoadError(initialError!)),
                        TextButton(
                            onPressed: _initialize,
                            child: Text(strings(context).plannerRetry)),
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
                ScreenHeader(strings(context).plannerTitle,
                    strings(context).plannerSubtitle,
                    logo: true),
                Row(children: [
                  IconButton(
                      tooltip: strings(context).plannerPreviousWeek,
                      onPressed: busy ? null : () => _moveWeek(-1),
                      icon: const Icon(Icons.chevron_left)),
                  Expanded(
                      child: Text(
                          strings(context).plannerWeekRange(
                            '\u2068${localizedPlannerDate(week!, Localizations.localeOf(context).languageCode)}\u2069',
                            '\u2068${localizedPlannerDate(week!.add(const Duration(days: 6)), Localizations.localeOf(context).languageCode)}\u2069',
                          ),
                          textAlign: TextAlign.center)),
                  IconButton(
                      tooltip: strings(context).plannerNextWeek,
                      onPressed: busy ? null : () => _moveWeek(1),
                      icon: const Icon(Icons.chevron_right)),
                ]),
                if (state.plannerLoading) const LinearProgressIndicator(),
                if (state.plannerError != null) ...[
                  Text(strings(context).plannerLoadError(state.plannerError!),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                  TextButton(
                      onPressed: _loadWeek,
                      child: Text(strings(context).plannerRetry)),
                ],
                Row(children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                        child:
                            _calendarDay(week!.add(Duration(days: i)), days)),
                ]),
                const SizedBox(height: 8),
                Wrap(spacing: 12, runSpacing: 4, children: [
                  _legend(strings(context).plannerPlannedWorkout, false),
                  _legend(strings(context).plannerCompletedWorkout, true),
                  Text(strings(context).plannerRestLegend,
                      style: const TextStyle(fontSize: 11)),
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
                            strings(context).plannerSelectedDay(westernDigits(
                                MaterialLocalizations.of(context)
                                    .formatMediumDate(selected!))),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (day == null)
                          Text(strings(context).plannerNothingPlanned)
                        else ...[
                          Text(_displayName(day.name)),
                          if (day.kind != 'rest' ||
                              day.name.trim().toLowerCase() != 'rest day')
                            Text(day.kind == 'rest'
                                ? strings(context).plannerRestDay
                                : strings(context).plannerWorkoutSummary(
                                    '${day.duration}', '${day.effort}')),
                          if (day.kind == 'workout')
                            Text(state.plannerWorkoutDates.contains(date)
                                ? strings(context).plannerWorkoutLogged
                                : strings(context).plannerWorkoutNotLogged),
                        ],
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 4, children: [
                          OutlinedButton(
                              onPressed: busy ? null : _chooseDay,
                              child: Text(strings(context).plannerPlanDay)),
                          if (day != null) ...[
                            OutlinedButton(
                                onPressed: busy ? null : () => _dayForm(day),
                                child: Text(strings(context).plannerEditDay)),
                            OutlinedButton(
                                onPressed: busy
                                    ? null
                                    : () async {
                                        if (await _confirm(
                                                strings(context)
                                                    .plannerRemoveDayTitle,
                                                strings(context)
                                                    .plannerRemoveDayDetails) &&
                                            mounted) {
                                          await _run(() =>
                                              state.removePlannerDay(date));
                                        }
                                      },
                                child: Text(strings(context).plannerRemove)),
                          ],
                          if (day?.kind == 'workout' &&
                              date == state.plannerToday)
                            OutlinedButton(
                                onPressed:
                                    busy ? null : () => _logWorkout(day!),
                                child:
                                    Text(strings(context).plannerLogWorkout)),
                        ]),
                        if (day?.kind == 'workout' &&
                            state.plannerToday != null &&
                            date.compareTo(state.plannerToday!) > 0)
                          Text(strings(context).plannerAvailableOnDay),
                      ])),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: Text(strings(context).plannerMySplits,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold))),
                    TextButton.icon(
                        onPressed: busy ? null : () => _splitForm(),
                        icon: const Icon(Icons.add),
                        label: Text(strings(context).plannerAddSplit)),
                  ]),
                  if (state.plannerSplits.isEmpty) ...[
                    Text(strings(context).plannerNoSplits),
                    Wrap(spacing: 8, children: [
                      OutlinedButton(
                          onPressed: busy ? null : () => _splitForm(),
                          child: Text(strings(context).plannerCreateFirst)),
                      OutlinedButton(
                          onPressed: busy ? null : _starterSplits,
                          child: Text(strings(context).plannerAddStarters)),
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
                                Text(_displayName(split.name)),
                                Text(
                                    split.kind == 'rest'
                                        ? strings(context).plannerRest
                                        : strings(context).plannerSplitSummary(
                                            '${split.duration}',
                                            '${split.effort}'),
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                              ])),
                          IconButton(
                              tooltip: strings(context)
                                  .plannerEditName(_displayName(split.name)),
                              onPressed: busy ? null : () => _splitForm(split),
                              icon: const Icon(Icons.edit_outlined)),
                          IconButton(
                              tooltip: strings(context)
                                  .plannerDeleteName(_displayName(split.name)),
                              onPressed: busy
                                  ? null
                                  : () async {
                                      if (await _confirm(
                                              strings(context)
                                                  .plannerDeleteQuestion(
                                                      _displayName(split.name)),
                                              strings(context)
                                                  .plannerDeleteDetails) &&
                                          mounted) {
                                        await _run(() =>
                                            state.deletePlannerSplit(split.id));
                                      }
                                    },
                              icon: const Icon(Icons.delete_outline)),
                        ])),
                  Text(strings(context).plannerDeleteExplanation),
                ],
              ]);
        },
      );

  Widget _calendarDay(DateTime date, List<PlannerDay> days) {
    final key = plannerDate(date);
    final day = days.where((item) => item.date == key).firstOrNull;
    final complete =
        day?.kind == 'workout' && state.plannerWorkoutDates.contains(key);
    final label = localizedPlannerWeekday(
        date, Localizations.localeOf(context).languageCode);
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
          FittedBox(child: Text(label)),
          Text(date.day.toString()),
          SizedBox(
            height: 3,
            child: key == state.plannerToday
                ? Semantics(
                    label: strings(context).plannerToday,
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
                      decoration: InputDecoration(
                          labelText: strings(context).plannerName,
                          errorMaxLines: 3),
                      validator: (value) => value == null ||
                              value.trim().isEmpty ||
                              value.trim().runes.length > 100
                          ? strings(context).plannerInvalidName
                          : null),
                  if (widget.chooseKind) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                        initialValue: kind,
                        decoration: InputDecoration(
                            labelText: strings(context).plannerType),
                        items: [
                          DropdownMenuItem(
                              value: 'workout',
                              child: Text(strings(context).plannerWorkout)),
                          DropdownMenuItem(
                              value: 'rest',
                              child: Text(strings(context).plannerRest))
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
                        decoration: InputDecoration(
                            labelText: strings(context).plannerDuration,
                            helperText: strings(context).plannerDurationHint,
                            errorMaxLines: 3),
                        validator: (value) {
                          final n = int.tryParse(value ?? '');
                          return n == null || n < 1 || n > 600
                              ? strings(context).plannerInvalidDuration
                              : null;
                        }),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: effort,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                            labelText: strings(context).plannerEffort,
                            helperText: strings(context).plannerEffortHint,
                            errorMaxLines: 3),
                        validator: (value) {
                          final n = int.tryParse(value ?? '');
                          return n == null || n < 0 || n > 100
                              ? strings(context).plannerInvalidEffort
                              : null;
                        }),
                  ],
                ]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings(context).plannerCancel)),
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
              child: Text(strings(context).plannerSave)),
        ],
      );
}
