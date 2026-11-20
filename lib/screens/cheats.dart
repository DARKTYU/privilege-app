import 'package:flutter/material.dart';

import '../services/cravings_repository.dart';
import '../services/planner_repository.dart';
import '../state.dart';
import '../ui.dart';

class CheatsScreen extends StatefulWidget {
  const CheatsScreen({super.key, this.state});
  final AppState? state;
  @override
  State<CheatsScreen> createState() => _CheatsScreenState();
}

class _CheatsScreenState extends State<CheatsScreen> {
  late final AppState state = widget.state ?? appState;
  final input = TextEditingController();
  DateTime? month, selected;
  List<Craving> meals = [];
  String? account, error, inputError;
  bool loading = false, saving = false;
  int generation = 0;
  bool activityWasLoading = false;

  @override
  void initState() {
    super.initState();
    account = state.cravingsAccountId;
    activityWasLoading = state.activityLoading;
    state.addListener(_changed);
    if (!activityWasLoading) _initialize();
  }

  void _changed() {
    if (account != state.cravingsAccountId) {
      account = state.cravingsAccountId;
      generation++;
      setState(() {
        month = selected = null;
        meals = [];
        input.clear();
        error = null;
        loading = false;
      });
      if (!state.activityLoading) _initialize();
    }
    final finished = activityWasLoading && !state.activityLoading;
    activityWasLoading = state.activityLoading;
    if (finished && month == null) _initialize();
  }

  Future<void> _initialize() async {
    final token = ++generation;
    final user = state.cravingsAccountId;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (user == null) throw StateError('Please log in again.');
      final today = parsePlannerDate(await state.plannerLocalToday());
      if (!mounted || token != generation || user != state.cravingsAccountId) {
        return;
      }
      setState(() {
        selected = today;
        month = DateTime.utc(today.year, today.month);
      });
      await _load();
    } catch (e) {
      if (mounted && token == generation && user == state.cravingsAccountId) {
        setState(() {
          loading = false;
          error = e.toString();
        });
      }
    }
  }

  Future<void> _load() async {
    final current = month!;
    final user = state.cravingsAccountId;
    final token = ++generation;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final rows = await state.loadCravings(plannerDate(current),
          plannerDate(DateTime.utc(current.year, current.month + 1)));
      if (!mounted || token != generation || user != state.cravingsAccountId) {
        return;
      }
      setState(() => meals = rows);
    } catch (e) {
      if (mounted && token == generation && user == state.cravingsAccountId) {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted && token == generation && user == state.cravingsAccountId) {
        setState(() => loading = false);
      }
    }
  }

  void _message(Object e) {
    final text = e.toString();
    final message = text.toLowerCase().contains('cheat meal limit')
        ? 'The selected month already has 2 cravings. $text'
        : 'Could not save: $text';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validate(String value) {
    final length = value.trim().runes.length;
    return length < 1 || length > 200 ? 'Enter 1 to 200 characters.' : null;
  }

  Future<void> _add() async {
    if (saving || loading || error != null || meals.length >= 2) return;
    final validation = _validate(input.text);
    setState(() => inputError = validation);
    if (validation != null) return;
    final user = state.cravingsAccountId;
    final date = plannerDate(selected!);
    setState(() => saving = true);
    try {
      await state.addCraving(date, input.text);
      if (mounted && user == state.cravingsAccountId) {
        input.clear();
        await _load();
      }
    } catch (e) {
      if (mounted && user == state.cravingsAccountId) {
        _message(e);
        if (e.toString().toLowerCase().contains('cheat meal limit')) {
          await _load();
        }
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _edit(Craving meal) async {
    if (saving) return;
    final user = state.cravingsAccountId;
    setState(() => saving = true);
    try {
      final result = await showDialog<(String, String)>(
          context: context, builder: (_) => _EditCravingDialog(meal: meal));
      if (!mounted || result == null || user != state.cravingsAccountId) return;
      await state.editCraving(meal.id, result.$1, result.$2,
          originalDate: meal.date);
      if (mounted && user == state.cravingsAccountId) await _load();
    } catch (e) {
      if (mounted && user == state.cravingsAccountId) {
        _message(e);
        if (e.toString().toLowerCase().contains('cheat meal limit')) {
          await _load();
        }
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _delete(Craving meal) async {
    if (saving) return;
    final user = state.cravingsAccountId;
    setState(() => saving = true);
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete craving?'),
          content: Text(meal.notes),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete')),
          ],
        ),
      );
      if (!mounted || confirm != true || user != state.cravingsAccountId) {
        return;
      }
      await state.deleteCraving(meal.id);
      if (mounted && user == state.cravingsAccountId) await _load();
    } catch (e) {
      if (mounted && user == state.cravingsAccountId) _message(e);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _move(int direction) {
    final value = month!;
    setState(() {
      month = DateTime.utc(value.year, value.month + direction);
      selected = month;
      meals = [];
    });
    _load();
  }

  @override
  void dispose() {
    state.removeListener(_changed);
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (month == null) {
      return Center(
          child: error == null
              ? const CircularProgressIndicator()
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Could not load cravings: $error'),
                  TextButton(
                      onPressed: _initialize, child: const Text('Retry')),
                ]));
    }
    final current = month!;
    final lead = current.weekday - 1;
    final count = DateTime.utc(current.year, current.month + 1, 0).day;
    final available = !loading && error == null;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        IconButton(
            tooltip: 'Previous month',
            onPressed: saving ? null : () => _move(-1),
            icon: const Icon(Icons.chevron_left)),
        Expanded(
            child: Text(
                MaterialLocalizations.of(context).formatMonthYear(current),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18))),
        IconButton(
            tooltip: 'Next month',
            onPressed: saving ? null : () => _move(1),
            icon: const Icon(Icons.chevron_right)),
      ]),
      if (loading) const LinearProgressIndicator(),
      if (error != null) ...[
        Text('Could not load cravings: $error'),
        TextButton(onPressed: _load, child: const Text('Retry')),
      ],
      Panel(
          child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 0.7,
        children: [
          for (final l in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
            Center(child: Text(l, style: TextStyle(color: kMuted))),
          for (var i = 0; i < lead; i++) const SizedBox(),
          for (var d = 1; d <= count; d++)
            InkWell(
              key: ValueKey('craving-day-$d'),
              onTap: saving
                  ? null
                  : () => setState(() =>
                      selected = DateTime.utc(current.year, current.month, d)),
              child: Container(
                decoration: BoxDecoration(
                    color: selected?.day == d ? kMaroon : kCard2,
                    borderRadius: BorderRadius.circular(10)),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$d',
                          maxLines: 1, style: const TextStyle(fontSize: 13)),
                      if (available &&
                          meals.any((m) =>
                              m.date ==
                              plannerDate(DateTime.utc(
                                  current.year, current.month, d))))
                        Icon(Icons.circle,
                            key: ValueKey('craving-marker-$d'),
                            size: 6,
                            color: kGold),
                    ]),
              ),
            ),
        ],
      )),
      if (available) ...[
        Text('${meals.length} of 2 used this month'),
        if (meals.length >= 2)
          const Text(
              'Monthly limit reached. Edit or delete an entry to make room.'),
        const SizedBox(height: 12),
        TextField(
            controller: input,
            enabled: !saving && meals.length < 2,
            maxLength: 200,
            decoration: InputDecoration(
                labelText: 'Craving for day ${selected!.day}',
                helperText: '1 to 200 characters',
                errorText: inputError)),
        Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
                onPressed: saving || meals.length >= 2 ? null : _add,
                child: const Text('Add craving'))),
        if (meals.isEmpty) const Text('No meals added yet.'),
        for (final meal in meals)
          Panel(
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meal.notes),
                    Text(MaterialLocalizations.of(context)
                        .formatMediumDate(parsePlannerDate(meal.date))),
                    Wrap(children: [
                      TextButton(
                          onPressed: saving ? null : () => _edit(meal),
                          child: const Text('Edit')),
                      TextButton(
                          onPressed: saving ? null : () => _delete(meal),
                          child: const Text('Delete')),
                    ]),
                  ])),
      ],
    ]);
  }
}

class _EditCravingDialog extends StatefulWidget {
  const _EditCravingDialog({required this.meal});
  final Craving meal;
  @override
  State<_EditCravingDialog> createState() => _EditCravingDialogState();
}

class _EditCravingDialogState extends State<_EditCravingDialog> {
  late final notes = TextEditingController(text: widget.meal.notes);
  late DateTime date = parsePlannerDate(widget.meal.date);
  String? error;
  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Edit craving'),
        content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: notes,
              maxLength: 200,
              decoration: InputDecoration(
                  labelText: 'Notes',
                  helperText: '1 to 200 characters',
                  errorText: error)),
          TextButton(
              onPressed: () async {
                final chosen = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100, 12, 31));
                if (chosen != null && mounted) setState(() => date = chosen);
              },
              child: Text(
                  'Date: ${MaterialLocalizations.of(context).formatMediumDate(date)}')),
        ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                final text = notes.text.trim();
                if (text.isEmpty || text.runes.length > 200) {
                  setState(() => error = 'Enter 1 to 200 characters.');
                  return;
                }
                Navigator.pop(context, (plannerDate(date), text));
              },
              child: const Text('Save')),
        ],
      );
}
