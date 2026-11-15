import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/fitness_logic.dart';
import '../data.dart';
import '../state.dart';
import '../ui.dart';

/// Calories section: "Activity Rings" and "Progress & Meals" share the same live state.
class CaloriesSection extends StatelessWidget {
  const CaloriesSection({super.key});

  @override
  Widget build(BuildContext context) => TabbedPage(
        title: 'Calories',
        subtitle: 'Rings, macros & meal logs',
        labels: ['Activity Rings', 'Progress & Meals'],
        children: [RingsTab(), ProgressTab()],
      );
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

/// 7 colour-coded macro / burn segments around one circle.
class SegmentsPainter extends CustomPainter {
  SegmentsPainter(this.result, this.highlight);
  final RadialResult result;
  final String? highlight;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 160);
    const c = Offset(80, 80);
    final r = result.radius;
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11
          ..color = kCard2);
    for (final s in result.segments) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2 + s.startOffset / r,
        s.arcLength / r,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.id == highlight ? 14 : 11
          ..strokeCap = StrokeCap.round
          ..color = s.color,
      );
    }
  }

  @override
  bool shouldRepaint(SegmentsPainter o) => true;
}

// ───────────────────────── shared pieces ─────────────────────────

Widget _check(BuildContext context, bool on, VoidCallback onTap) => InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? kGreen : Colors.transparent,
          border: Border.all(color: on ? kGreen : kMuted),
        ),
        child: on
            ? Icon(
                Icons.check,
                size: 14,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Colors.black,
              )
            : null,
      ),
    );

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
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onRemove),
      ]),
    );

Widget _mealTile(BuildContext context, MealItem m,
    {required bool colored,
    required VoidCallback onToggle,
    required VoidCallback onRemove}) {
  final style = TextStyle(
      fontSize: 11, color: m.consumed ? kMuted : kMuted.withAlpha(120));
  return Panel(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(10),
    child: Row(children: [
      _check(context, m.consumed, onToggle),
      const SizedBox(width: 10),
      Text(m.icon, style: const TextStyle(fontSize: 22)),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m.name,
              maxLines: 2,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: m.consumed ? kCream : kMuted,
                decoration: m.consumed ? null : TextDecoration.lineThrough,
              )),
          if (colored)
            Wrap(spacing: 8, children: [
              Text('🔴 ${m.proteinGrams}g P', style: style),
              Text('🔵 ${m.carbsGrams}g C', style: style),
              Text('🟠 ${m.fatGrams}g F', style: style),
              Text('🟢 ${m.fiberGrams}g Fib', style: style),
            ])
          else
            Text(
                '${m.time} • P:${m.proteinGrams}g C:${m.carbsGrams}g F:${m.fatGrams}g',
                style: style),
        ]),
      ),
      Text('+${fmt(m.calories)}',
          style: TextStyle(
              color: m.consumed ? kGold : kMuted,
              fontWeight: FontWeight.w800,
              fontSize: 12)),
      IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          onPressed: onRemove),
    ]),
  );
}

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

/// "Log nutrition / workout burn" form used by both tabs.
class _AddForm extends StatefulWidget {
  const _AddForm({required this.detailed, required this.onClose});
  final bool
      detailed; // true = Activity Rings form (colour focus), false = Progress form
  final VoidCallback onClose;

  @override
  State<_AddForm> createState() => _AddFormState();
}

class _AddFormState extends State<_AddForm> {
  final _name = TextEditingController();
  late final TextEditingController _cals =
      TextEditingController(text: widget.detailed ? '450' : '420');
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
        final title = typed.isNotEmpty
            ? typed
            : (widget.detailed ? 'High-Protein Fuel' : 'Lean Nutrition Meal');
        final type = widget.detailed ? _macro : 'snack';
        await appState.addMeal(MealItem(
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
        final title = typed.isNotEmpty
            ? typed
            : (widget.detailed ? 'Athletic Training' : 'Cardio Agility Drill');
        final type = widget.detailed ? _burn : BurnType.cardio;
        await appState.addBurn(BurnItem(
          id: '',
          title: title,
          time: 'Just now',
          calories: cals,
          type: type,
          durationMin: widget.detailed ? math.max(1, (cals / 8).round()) : 30,
          icon: widget.detailed
              ? (type == BurnType.strength
                  ? '🏋️'
                  : (type == BurnType.cardio ? '⚡' : '🧘'))
              : '⚡',
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
        Text(
            widget.detailed
                ? 'Log Nutrition or Workout Burn'
                : 'Add to Progress & Activity Rings',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          appChip(widget.detailed ? 'Food Intake (+)' : '+ Meal', _meal,
              () => setState(() => _meal = true)),
          appChip(widget.detailed ? 'Workout Burn (+)' : '+ Workout Burn',
              !_meal, () => setState(() => _meal = false)),
        ]),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        ],
        const SizedBox(height: 10),
        TextField(
          controller: _name,
          decoration: fieldDecoration(_meal
              ? (widget.detailed
                  ? 'e.g. Grass-fed Steak'
                  : 'e.g. Avocado Toast & Eggs')
              : (widget.detailed ? 'e.g. Olympic Lifts' : 'e.g. HIIT Sprints')),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cals,
          keyboardType: TextInputType.number,
          decoration: fieldDecoration('Calories (kcal)'),
        ),
        if (widget.detailed) ...[
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
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: TextButton(
                  onPressed: widget.onClose, child: const Text('Cancel'))),
          const SizedBox(width: 8),
          Expanded(
            child: PrimaryButton(
                widget.detailed ? 'Sync to Activity Rings' : 'Sync Live',
                gold: true,
                expand: false,
                onPressed: _saving ? null : _submit),
          ),
        ]),
      ]),
    );
  }
}

// ───────────────────────── Activity Rings ─────────────────────────

class RingsTab extends StatefulWidget {
  const RingsTab({super.key});

  @override
  State<RingsTab> createState() => _RingsTabState();
}

class _RingsTabState extends State<RingsTab> {
  bool _adding = false;

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
      listenable: appState,
      builder: (context, _) {
        final s = appState;
        final t = s.totals;
        final bal = s.calorieBalance;
        final outer = math.min(1.0, t.totalBurnedCalories / t.burnTarget);
        final middle = math.min(1.0, t.totalMealCalories / t.calorieTarget);
        final inner = math.min(
            1.0, (t.cardioBurnCalories + t.mobilityBurnCalories) / 600);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            Row(children: [
              Expanded(
                  child: Text('Synced in real-time with Progress & Meals',
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
                  detailed: true,
                  onClose: () => setState(() => _adding = false)),
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
                Row(children: [
                  Icon(bal.isSurplus ? Icons.trending_up : Icons.trending_down,
                      size: 18, color: bal.isSurplus ? kOrange : kGreen),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text('Net Balance (BMR 1800):',
                          style: TextStyle(fontSize: 12, color: kMuted))),
                  Text(
                    '${bal.netDifference > 0 ? '+' : ''}${bal.netDifference} kcal'
                    '${bal.netDifference <= 0 ? ' (Natural Stage Cut)' : ' (Mass Lean Bulk)'}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: bal.isSurplus ? kOrange : kGreen),
                  ),
                ]),
              ]),
            ),
            sectionTitle('Active Logs (${s.meals.length + s.burns.length})'),
            for (final b in s.burns)
              _burnTile(b,
                  onRemove: () =>
                      _runActivityAction(context, () => s.removeBurn(b.id))),
            for (final m in s.meals)
              _mealTile(context, m,
                  colored: false,
                  onToggle: () =>
                      _runActivityAction(context, () => s.toggleMeal(m.id)),
                  onRemove: () =>
                      _runActivityAction(context, () => s.removeMeal(m.id))),
          ],
        );
      },
    );
  }
}

// ───────────────────────── Progress & Meals ─────────────────────────

class ProgressTab extends StatefulWidget {
  const ProgressTab({super.key});

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  bool _adding = false;
  String? _highlight;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final s = appState;
        final t = s.totals;
        final radial = calculateRadialSegments(
          t,
          proteinColor: kRed,
          carbsColor: kBlue,
          fatsColor: kOrange,
          fiberColor: kGreen,
          strengthColor: kGold,
          cardioColor: kCyan,
          targetColor: kPurple,
        );
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            Row(children: [
              Expanded(
                  child: Text(
                      'All 7 colors matched to macros & burned calories',
                      style: TextStyle(fontSize: 12, color: kMuted))),
              roundIcon(Icons.add, () => setState(() => _adding = !_adding),
                  tip: 'Quick add meal or burn'),
              TextButton.icon(
                onPressed: () => DefaultTabController.of(context).animateTo(0),
                icon: const Icon(Icons.show_chart, size: 16),
                label: const Text('Rings →'),
              ),
            ]),
            const SizedBox(height: 10),
            toastBanner(s.recentActionToast),
            _activityStatus(s),
            if (_adding)
              _AddForm(
                  detailed: false,
                  onClose: () => setState(() => _adding = false)),
            Panel(
              child: Column(children: [
                SizedBox(
                  width: 190,
                  height: 190,
                  child: Stack(alignment: Alignment.center, children: [
                    CustomPaint(
                        size: const Size(190, 190),
                        painter: SegmentsPainter(radial, _highlight)),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(fmt(t.totalMealCalories),
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w800)),
                      Text('kcal Consumed',
                          style: TextStyle(fontSize: 11, color: kMuted)),
                      Text(
                          '${t.activeMealCount} Meals • ${t.totalBurnedCalories} kcal Burned',
                          style: TextStyle(fontSize: 9, color: kMuted)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final seg in radial.segments)
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() =>
                          _highlight = _highlight == seg.id ? null : seg.id),
                      child: Container(
                        width: 140,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _highlight == seg.id
                              ? kCard2
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _highlight == seg.id ? seg.color : kLine),
                        ),
                        child: Row(children: [
                          CircleAvatar(radius: 5, backgroundColor: seg.color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(seg.label,
                                      style: TextStyle(
                                          fontSize: 11, color: kMuted)),
                                  Text(seg.gramsOrMin,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800)),
                                ]),
                          ),
                        ]),
                      ),
                    ),
                ]),
              ]),
            ),
            Row(children: [
              Expanded(
                  child: Text('Active Meals & Burn Logs',
                      style: TextStyle(fontWeight: FontWeight.w800))),
              Text('Tap checkbox to sync rings',
                  style: TextStyle(fontSize: 11, color: kMuted)),
            ]),
            const SizedBox(height: 8),
            for (final b in s.burns) _burnTile(b),
            for (final m in s.meals)
              _mealTile(context, m,
                  colored: true,
                  onToggle: () =>
                      _runActivityAction(context, () => s.toggleMeal(m.id)),
                  onRemove: () =>
                      _runActivityAction(context, () => s.removeMeal(m.id))),
            Panel(
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      avatar(avatarYou, 30),
                      const SizedBox(width: 2),
                      avatar(avatarPartner, 30),
                      const SizedBox(width: 8),
                      const Text('Team Iron',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ]),
                    tag('VS', kGold),
                    Row(children: [
                      const Text('Rivals',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      avatar(avatarRival1, 30),
                      const SizedBox(width: 2),
                      avatar(avatarRival2, 30),
                    ]),
                  ]),
            ),
          ],
        );
      },
    );
  }
}
