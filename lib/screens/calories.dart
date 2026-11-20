import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n_strings.dart';
import '../logic/fitness_logic.dart';
import '../logic/workout_estimate.dart';
import '../services/food_database.dart';
import '../services/activity_repository.dart';
import '../state.dart';
import '../ui.dart';
import 'calories_food_explorer.dart';
import 'calories_food_summary.dart';
import 'calorie_profile_sheet.dart';
import 'workout_logger_sheet.dart';

class CaloriesSection extends StatelessWidget {
  const CaloriesSection({super.key, this.state, this.database});
  final AppState? state;
  final FoodDatabase? database;

  @override
  Widget build(BuildContext context) => TabbedPage(
        title: strings(context).calories,
        subtitle: strings(context).caloriesSubtitle,
        labels: [strings(context).foodLog, strings(context).activity],
        children: [
          FoodLogTab(state: state ?? appState, database: database),
          ActivityTab(state: state ?? appState),
        ],
      );
}

class FoodLogTab extends StatelessWidget {
  const FoodLogTab({super.key, required this.state, this.database});
  final AppState state;
  final FoodDatabase? database;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, constraints) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            children: [
              CaloriesFoodSummary(
                state: state,
                database: database,
                compact: constraints.maxHeight < 380,
                onCompleteProfile: () =>
                    showCalorieProfileSheet(context, state),
                onEdit: (meal) => _editFood(context, meal),
                onAdd: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (pageContext) => FoodExplorerPage(
                    state: state,
                    database: database,
                    onManual: () => _manualForm(pageContext),
                  ),
                )),
              ),
            ],
          ));

  void _manualForm(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _AddForm(
                state: state, onClose: () => Navigator.pop(sheetContext)),
          ),
        ),
      );

  Future<void> _editFood(BuildContext context, MealItem meal) async {
    try {
      final foods = database ?? FoodDatabase();
      await foods.load();
      final matches = foods.foods.where((food) => food.id == meal.foodId);
      if (!context.mounted) return;
      if (matches.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(strings(context).foodUnavailable),
        ));
        return;
      }
      await showFoodPortionSheet(context, state, matches.first, log: meal);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(strings(context).foodOpenError(friendlyError(error, localizations: strings(context))))));
      }
    }
  }
}

// ───────────────────────── painters ─────────────────────────

/// Rings for total, strength, and cardio burn against the daily burn goal.
class RingsPainter extends CustomPainter {
  RingsPainter(this.outer, this.middle, this.inner);
  final double outer, middle, inner; // 0..1

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 160);
    const c = Offset(80, 80);

    void ring(double r, Color track, Color color, double frac) {
      canvas.drawCircle(
          c,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10
            ..color = track);
      if (frac <= 0) return;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        2 * math.pi * frac,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }

    ring(66, kRed.withAlpha(28), kRed, outer);
    ring(52, kGold.withAlpha(28), kGold, middle);
    ring(38, kCyan.withAlpha(28), kCyan, inner);
  }

  @override
  bool shouldRepaint(RingsPainter o) =>
      o.outer != outer || o.middle != middle || o.inner != inner;
}

// ───────────────────────── shared pieces ─────────────────────────

Color _burnColor(BurnType t) =>
    t == BurnType.strength ? kGold : (t == BurnType.cardio ? kCyan : kGreen);

Widget _activityCard(CaloriesPalette palette, Widget child) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: child,
    );

Widget _burnTile(BuildContext context, CaloriesPalette palette, BurnItem b,
    {VoidCallback? onRemove}) {
  final l = strings(context);
  final generated = WorkoutActivity.values
      .where((item) => b.title == '${item.label} - ${b.durationMin} min')
      .firstOrNull;
  final title = generated == null
      ? b.title
      : l.workoutSavedTitle(
          localizedWorkoutActivityName(l, generated), b.durationMin.toString());
  return _activityCard(
    palette,
    Row(children: [
      Text(b.icon, style: const TextStyle(fontSize: 22)),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            const SizedBox(width: 6),
            tag(
                switch (b.type) {
                  BurnType.strength => strings(context).burnTypeStrength,
                  BurnType.cardio => strings(context).burnTypeCardio,
                  BurnType.mobility => strings(context).burnTypeMobility,
                },
                _burnColor(b.type)),
          ]),
          Text(b.createdAt != null
                  ? l.activityTimeDuration(
                      formatActivityTime(b.createdAt!, l),
                      b.durationMin.toString())
                  : b.time == 'Just now' ? l.justNow : b.time,
              style: TextStyle(fontSize: 11, color: palette.muted)),
          Text(strings(context).burnedAmount(fmt(b.calories)),
              style: TextStyle(
                  color: palette.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 12)),
        ]),
      ),
      if (onRemove != null)
        IconButton(
            tooltip: strings(context).deleteNamed(title),
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: onRemove),
    ]),
  );
}

Widget _activityStatus(
    BuildContext context, AppState state, CaloriesPalette palette) {
  if (state.activityLoading && state.burns.isEmpty) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(child: CircularProgressIndicator()),
    );
  }
  if (state.activityError != null) {
    return _activityCard(
      palette,
      Column(children: [
        Text(friendlyError(state.activityError!, localizations: strings(context)),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: state.loadActivity,
          icon: const Icon(Icons.refresh),
          label: Text(strings(context).plannerRetry),
        ),
      ]),
    );
  }
  if (!state.activityLoading && state.burns.isEmpty) {
    return _activityCard(
      palette,
      Text(
        strings(context).noWorkouts,
        textAlign: TextAlign.center,
        style: TextStyle(color: palette.muted),
      ),
    );
  }
  return const SizedBox.shrink();
}

Future<void> _runActivityAction(
    BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(strings(context).activitySaveError(friendlyError(error, localizations: strings(context))))));
  }
}

class _AddForm extends StatefulWidget {
  const _AddForm({required this.state, required this.onClose});
  final AppState state;
  final VoidCallback onClose;

  @override
  State<_AddForm> createState() => _AddFormState();
}

class _AddFormState extends State<_AddForm> {
  final _name = TextEditingController();
  final _cals = TextEditingController(text: '450');
  bool _meal = true;
  String _macro = 'protein';
  BurnType _burn = BurnType.strength;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _cals.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cals = int.tryParse(_cals.text.trim());
    if (cals == null || cals <= 0) {
      setState(() => _error = strings(context).manualInvalidCalories);
      return;
    }
    final typed = _name.text.trim();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_meal) {
        final title = typed.isNotEmpty ? typed : 'High-Protein Fuel';
        final type = _macro;
        await widget.state.addMeal(MealItem(
          id: '',
          name: title,
          time: 'Just now',
          calories: cals,
          proteinGrams: _mealProtein(cals, type),
          carbsGrams: _mealCarbs(cals, type),
          fatGrams: _mealFat(cals, type),
          fiberGrams: type == 'greens' ? 12 : 4,
          icon: type == 'greens' ? '🥗' : (type == 'carbs' ? '🥔' : '🥩'),
          consumed: true,
          category: _mealCategory(type),
        ));
      } else {
        final title = typed.isNotEmpty ? typed : 'Athletic Training';
        final type = _burn;
        await widget.state.addBurn(BurnItem(
          id: '',
          title: title,
          time: 'Just now',
          calories: cals,
          type: type,
          durationMin: math.max(1, (cals / 8).round()),
          icon: type == BurnType.strength
              ? '🏋️'
              : (type == BurnType.cardio ? '⚡' : '🧘'),
        ));
      }
      if (mounted) widget.onClose();
    } catch (error) {
      if (mounted) {
        setState(() =>
            _error = strings(context).activitySaveError(friendlyError(error, localizations: strings(context))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int _mealProtein(int calories, String type) =>
      type == 'protein' ? (calories * 0.45 / 4).round() : 25;

  int _mealCarbs(int calories, String type) =>
      type == 'carbs' ? (calories * 0.5 / 4).round() : 35;

  int _mealFat(int calories, String type) =>
      type == 'fats' ? (calories * 0.4 / 9).round() : 10;

  MealCategory _mealCategory(String type) => switch (type) {
        'protein' => MealCategory.lunch,
        'carbs' => MealCategory.lunch,
        'fats' => MealCategory.lunch,
        'greens' => MealCategory.lunch,
        _ => MealCategory.snack,
      };

  @override
  Widget build(BuildContext context) {
    final l = strings(context);
    return Panel(
      borderColor: kGold.withAlpha(110),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.manualTitle,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          appChip(l.manualFood, _meal, () => setState(() => _meal = true)),
          appChip(l.manualBurn, !_meal, () => setState(() => _meal = false)),
        ]),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 10),
        TextField(
          controller: _name,
          decoration:
              fieldDecoration(_meal ? l.manualFoodHint : l.manualBurnHint),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cals,
          keyboardType: TextInputType.number,
          decoration: fieldDecoration(l.caloriesKcal),
        ),
        const SizedBox(height: 8),
        if (_meal)
          Wrap(spacing: 8, children: [
            appChip(l.manualProtein, _macro == 'protein',
                () => setState(() => _macro = 'protein')),
            appChip(l.manualCarbs, _macro == 'carbs',
                () => setState(() => _macro = 'carbs')),
            appChip(l.manualFats, _macro == 'fats',
                () => setState(() => _macro = 'fats')),
            appChip(l.manualGreens, _macro == 'greens',
                () => setState(() => _macro = 'greens')),
          ])
        else
          Wrap(spacing: 8, children: [
            appChip(l.manualStrength, _burn == BurnType.strength,
                () => setState(() => _burn = BurnType.strength)),
            appChip(l.manualCardio, _burn == BurnType.cardio,
                () => setState(() => _burn = BurnType.cardio)),
            appChip(l.manualMobility, _burn == BurnType.mobility,
                () => setState(() => _burn = BurnType.mobility)),
          ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: TextButton(
                  onPressed: widget.onClose, child: Text(l.plannerCancel))),
          const SizedBox(width: 8),
          Expanded(
            child: PrimaryButton(l.saveActivity,
                gold: true, expand: false, onPressed: _saving ? null : _submit),
          ),
        ]),
      ]),
    );
  }
}

// ───────────────────────── Activity Rings ─────────────────────────

class ActivityTab extends StatelessWidget {
  const ActivityTab({super.key, required this.state});
  final AppState state;

  Widget _title(CaloriesPalette p, String title) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(title,
            style: TextStyle(
                color: p.text, fontSize: 16, fontWeight: FontWeight.w800)),
      );

  Widget _stat(CaloriesPalette p, String label, String value, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(color: p.muted))),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style:
                      TextStyle(color: p.text, fontWeight: FontWeight.w800))),
        ]),
      );

  Widget _legend(CaloriesPalette p, Color c, String t) => Row(children: [
        CircleAvatar(radius: 4, backgroundColor: c),
        const SizedBox(width: 8),
        Expanded(child: Text(t, style: TextStyle(fontSize: 12, color: p.text))),
      ]);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final l = strings(context);
        final s = state;
        final p = CaloriesPalette(Theme.of(context));
        final t = s.totals;
        final outer = math.min(1.0, t.totalBurnedCalories / t.burnTarget);
        final middle = math.min(1.0, t.strengthBurnCalories / t.burnTarget);
        final inner = math.min(1.0, t.cardioBurnCalories / t.burnTarget);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          children: [
            _title(p, l.activityTitle),
            Text(l.activitySubtitle,
                style: TextStyle(fontSize: 12, color: p.muted)),
            const SizedBox(height: 10),
            _activityStatus(context, s, p),
            _activityCard(
              p,
              Column(children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(alignment: Alignment.center, children: [
                    CustomPaint(
                        size: const Size(200, 200),
                        painter: RingsPainter(outer, middle, inner)),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(l.burned,
                          style: TextStyle(fontSize: 11, color: p.muted)),
                      Text(fmt(t.totalBurnedCalories),
                          style: TextStyle(
                              color: p.text,
                              fontSize: 28,
                              fontWeight: FontWeight.w800)),
                      Text(l.burnTarget(t.burnTarget.toString()),
                          style: TextStyle(fontSize: 10, color: p.muted)),
                    ]),
                  ]),
                ),
                Text(l.burnGoalNote,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: p.muted)),
                Text(l.burnRingNote,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: p.muted)),
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _legend(p, kRed,
                            l.totalBurn(t.totalBurnedCalories.toString())),
                        const SizedBox(height: 4),
                        _legend(p, kGold,
                            l.strengthBurn(t.strengthBurnCalories.toString())),
                        const SizedBox(height: 4),
                        _legend(p, kCyan,
                            l.cardioBurn(t.cardioBurnCalories.toString())),
                      ]),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: p.accent,
                      foregroundColor: p.onAccent,
                      minimumSize: const Size(44, 48),
                    ),
                    onPressed: () => showWorkoutLogger(context, s),
                    icon: const Icon(Icons.fitness_center),
                    label: Text(l.mergeLogWorkout),
                  ),
                ),
              ]),
            ),
            _title(p, l.burnStats),
            _activityCard(
              p,
              Column(children: [
                _stat(p, l.strengthBurnLabel,
                    l.mergeCalories(t.strengthBurnCalories.toString()), kGold),
                _stat(p, l.cardioBurnLabel,
                    l.mergeCalories(t.cardioBurnCalories.toString()), kCyan),
              ]),
            ),
            _title(p, l.workoutLogs(s.burns.length.toString())),
            for (final b in s.burns)
              _burnTile(context, p, b,
                  onRemove: () =>
                      _runActivityAction(context, () => s.removeBurn(b.id))),
          ],
        );
      },
    );
  }
}
