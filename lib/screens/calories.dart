import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/fitness_logic.dart';
import '../services/food_database.dart';
import '../state.dart';
import '../ui.dart';
import 'calories_food_explorer.dart';
import 'calories_food_summary.dart';

class CaloriesSection extends StatelessWidget {
  const CaloriesSection({super.key, this.state, this.database});
  final AppState? state;
  final FoodDatabase? database;

  @override
  Widget build(BuildContext context) => TabbedPage(
        title: 'Calories',
        subtitle: 'Rings, macros & meal logs',
        labels: ['Food Log', 'Activity'],
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'This food is no longer available in the food database. The meal was not changed.'),
        ));
        return;
      }
      await showFoodPortionSheet(context, state, matches.first, log: meal);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open food: $error')));
      }
    }
  }
}

// ───────────────────────── painters ─────────────────────────

/// Three concentric rings (burned / consumed / cardio), like the SVG in the React app.
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

Widget _burnTile(BurnItem b, {VoidCallback? onRemove}) => Panel(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      child: Row(children: [
        Text(b.icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(b.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              const SizedBox(width: 6),
              tag(b.type.name, _burnColor(b.type)),
            ]),
            Text(b.time, style: TextStyle(fontSize: 11, color: kMuted)),
          ]),
        ),
        Text('-${fmt(b.calories)} kcal',
            style: TextStyle(
                color: _burnColor(b.type),
                fontWeight: FontWeight.w800,
                fontSize: 12)),
        if (onRemove != null)
          IconButton(
              tooltip: 'Delete ${b.title}',
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onRemove),
      ]),
    );

Widget _activityStatus(AppState state) {
  if (state.activityLoading && state.meals.isEmpty && state.burns.isEmpty) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(child: CircularProgressIndicator()),
    );
  }
  if (state.activityError != null) {
    return Panel(
      child: Column(children: [
        Text(state.activityError!, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: state.loadActivity,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ]),
    );
  }
  if (!state.activityLoading && state.meals.isEmpty && state.burns.isEmpty) {
    return Panel(
      child: Text(
        'No meals or completed workouts logged today yet.',
        textAlign: TextAlign.center,
        style: TextStyle(color: kMuted),
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
      ..showSnackBar(
          SnackBar(content: Text('Could not save activity: $error')));
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
      setState(() => _error = 'Enter a calorie amount greater than zero.');
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
      if (mounted) setState(() => _error = 'Could not save activity: $error');
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
    return Panel(
      borderColor: kGold.withAlpha(110),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Log Nutrition or Workout Burn',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          appChip('Food Intake (+)', _meal, () => setState(() => _meal = true)),
          appChip(
              'Workout Burn (+)', !_meal, () => setState(() => _meal = false)),
        ]),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 10),
        TextField(
          controller: _name,
          decoration: fieldDecoration(
              _meal ? 'e.g. Grass-fed Steak' : 'e.g. Olympic Lifts'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cals,
          keyboardType: TextInputType.number,
          decoration: fieldDecoration('Calories (kcal)'),
        ),
        const SizedBox(height: 8),
        if (_meal)
          Wrap(spacing: 8, children: [
            appChip('🔴 Protein', _macro == 'protein',
                () => setState(() => _macro = 'protein')),
            appChip('🔵 Carbs', _macro == 'carbs',
                () => setState(() => _macro = 'carbs')),
            appChip('🟠 Fats', _macro == 'fats',
                () => setState(() => _macro = 'fats')),
            appChip('🟢 Greens', _macro == 'greens',
                () => setState(() => _macro = 'greens')),
          ])
        else
          Wrap(spacing: 8, children: [
            appChip('🟡 Strength / Gym', _burn == BurnType.strength,
                () => setState(() => _burn = BurnType.strength)),
            appChip('🔷 Cardio / Sports', _burn == BurnType.cardio,
                () => setState(() => _burn = BurnType.cardio)),
            appChip('🟢 Mobility / Stage', _burn == BurnType.mobility,
                () => setState(() => _burn = BurnType.mobility)),
          ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: TextButton(
                  onPressed: widget.onClose, child: const Text('Cancel'))),
          const SizedBox(width: 8),
          Expanded(
            child: PrimaryButton('Save activity',
                gold: true, expand: false, onPressed: _saving ? null : _submit),
          ),
        ]),
      ]),
    );
  }
}

// ───────────────────────── Activity Rings ─────────────────────────

class ActivityTab extends StatefulWidget {
  const ActivityTab({super.key, required this.state});
  final AppState state;

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  bool _adding = false;

  Widget _stat(String label, String value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(color: kMuted))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
      );

  Widget _legend(Color c, String t) => Row(children: [
        CircleAvatar(radius: 4, backgroundColor: c),
        const SizedBox(width: 8),
        Text(t, style: TextStyle(fontSize: 12, color: kMuted)),
      ]);

  Widget _adjust(
          String label, int now, int target, ValueChanged<int> onDelta) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: kCard2, borderRadius: BorderRadius.circular(12)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11, color: kMuted)),
            Text('(${fmt(now)} / $target)',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => onDelta(-100), child: const Text('−'))),
              const SizedBox(width: 6),
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => onDelta(100), child: const Text('+'))),
            ]),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final s = widget.state;
        final t = s.totals;
        final bal = s.calorieBalance;
        final outer = math.min(1.0, t.totalBurnedCalories / t.burnTarget);
        final middle = math.min(1.0, t.totalMealCalories / t.calorieTarget);
        final inner = math.min(
            1.0, (t.cardioBurnCalories + t.mobilityBurnCalories) / 600);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          children: [
            sectionTitle('Activity Rings & Workouts'),
            Row(children: [
              Expanded(
                  child: Text('Food intake synced with Food Log',
                      style: TextStyle(fontSize: 12, color: kMuted))),
              const SizedBox(width: 6),
              roundIcon(Icons.add, () => setState(() => _adding = !_adding),
                  tip: 'Log meal or burn'),
            ]),
            const SizedBox(height: 10),
            toastBanner(s.recentActionToast),
            _activityStatus(s),
            if (_adding)
              _AddForm(
                  state: s, onClose: () => setState(() => _adding = false)),
            Panel(
              child: Column(children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(alignment: Alignment.center, children: [
                    CustomPaint(
                        size: const Size(200, 200),
                        painter: RingsPainter(outer, middle, inner)),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('Burned',
                          style: TextStyle(fontSize: 11, color: kMuted)),
                      Text(fmt(t.totalBurnedCalories),
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w800)),
                      Text('/ ${t.burnTarget} kcal target',
                          style: TextStyle(fontSize: 10, color: kMuted)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _legend(kRed, 'Move Burn (${t.totalBurnedCalories})'),
                        const SizedBox(height: 4),
                        _legend(kGold, 'Food Intake (${t.totalMealCalories})'),
                        const SizedBox(height: 4),
                        _legend(
                            kCyan, 'Sports & Cardio (${t.cardioBurnCalories})'),
                      ]),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  _adjust(
                      'Calories Consumed',
                      t.totalMealCalories,
                      t.calorieTarget,
                      (delta) => _runActivityAction(
                          context, () => s.quickAdjustConsumed(delta))),
                  const SizedBox(width: 8),
                  _adjust(
                      'Calories Burned',
                      t.totalBurnedCalories,
                      t.burnTarget,
                      (delta) => _runActivityAction(
                          context, () => s.quickAdjustBurned(delta))),
                ]),
                const SizedBox(height: 12),
                if (t.calorieTarget > 0 &&
                    t.totalMealCalories < (t.calorieTarget * 0.5).round())
                  Row(children: [
                    Icon(Icons.info_outline, size: 18, color: kMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'You’re well below your daily target so far. Your intake can add up as you log meals today.',
                        style: TextStyle(fontSize: 12, color: kMuted),
                      ),
                    ),
                  ])
                else
                  Row(children: [
                    Icon(Icons.swap_vert, size: 18, color: kMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('Estimated balance (BMR 1800):',
                          style: TextStyle(fontSize: 12, color: kMuted)),
                    ),
                    Text(
                      '${bal.netDifference > 0 ? '+' : ''}${bal.netDifference} kcal',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: kMuted,
                      ),
                    ),
                  ]),
              ]),
            ),
            sectionTitle('Burn Stats'),
            Panel(
              child: Column(children: [
                _stat('Strength Burn', '${t.strengthBurnCalories} kcal', kGold),
                _stat('Cardio Burn', '${t.cardioBurnCalories} kcal', kCyan),
                _stat(
                    'Deficit Goal',
                    '${((t.totalMealCalories / math.max(1, t.calorieTarget)) * 100).round()}% of calorie goal',
                    kPurple),
              ]),
            ),
            sectionTitle('Workout Logs (${s.burns.length})'),
            for (final b in s.burns)
              _burnTile(b,
                  onRemove: () =>
                      _runActivityAction(context, () => s.removeBurn(b.id))),
          ],
        );
      },
    );
  }
}
