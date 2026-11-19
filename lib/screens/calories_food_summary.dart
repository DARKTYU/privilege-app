import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/fitness_logic.dart';
import '../models/food_item.dart';
import '../services/food_database.dart';
import '../state.dart';
import '../ui.dart' show fmt;

class CaloriesPalette {
  const CaloriesPalette(this.theme);
  final ThemeData theme;
  Color get background => theme.scaffoldBackgroundColor;
  Color get card => theme.colorScheme.surface;
  Color get border => theme.colorScheme.outline;
  Color get inner => Color.alphaBlend(text.withAlpha(15), card);
  Color get text => theme.colorScheme.onSurface;
  Color get muted => theme.textTheme.bodySmall?.color ?? text;
  Color get track => border;
  Color get accent => theme.colorScheme.secondary;
  Color get onAccent => theme.colorScheme.onSecondary;
  Color get overBackground =>
      _contrast(over, card) >= 4.5 ? card : theme.colorScheme.scrim;
  Color get accentText {
    var color = accent;
    for (var i = 0; i < 10; i++) {
      if (_contrast(color, card) >= 4.5 && _contrast(color, inner) >= 4.5) {
        return color;
      }
      color = Color.lerp(color, text, .2)!;
    }
    return text;
  }

  static double _contrast(Color a, Color b) {
    final first = a.computeLuminance();
    final second = b.computeLuminance();
    return (math.max(first, second) + .05) / (math.min(first, second) + .05);
  }

  static const protein = Color(0xFF3B82F6);
  static const carbs = Color(0xFFF59E0B);
  static const fat = Color(0xFFF43F5E);
  static const sugar = Color(0xFFC084FC);
  static const sodium = Color(0xFF22D3EE);
  static const over = Color(0xFFF43F5E);
}

// replaced in Stage 4
({int protein, int carbs, int fat}) _macroGoals(int calories) => (
      protein: (calories * .3 / 4).round(),
      carbs: (calories * .4 / 4).round(),
      fat: (calories * .3 / 9).round(),
    );

enum _MealSlot {
  breakfast('Breakfast', 'الفطار', '☀️'),
  lunch('Lunch', 'الغداء', '🍽️'),
  dinner('Dinner', 'العشاء', '🌙'),
  snacks('Snacks & Toppings', 'سناكس وإضافات', '⚡');

  const _MealSlot(this.title, this.arabic, this.icon);
  final String title, arabic, icon;
}

_MealSlot _slot(MealCategory category) => switch (category) {
      MealCategory.breakfast => _MealSlot.breakfast,
      MealCategory.lunch => _MealSlot.lunch,
      MealCategory.dinner => _MealSlot.dinner,
      MealCategory.snack || MealCategory.shake => _MealSlot.snacks,
    };

class CaloriesFoodSummary extends StatefulWidget {
  const CaloriesFoodSummary({
    super.key,
    required this.state,
    required this.onAdd,
    this.onEdit,
    this.database,
    this.compact = false,
  });
  final AppState state;
  final VoidCallback onAdd;
  final ValueChanged<MealItem>? onEdit;
  final FoodDatabase? database;
  final bool compact;
  @override
  State<CaloriesFoodSummary> createState() => _CaloriesFoodSummaryState();
}

class _CaloriesFoodSummaryState extends State<CaloriesFoodSummary> {
  late final FoodDatabase database = widget.database ?? FoodDatabase();
  late final Future<void> loading = database.load();
  _MealSlot? selected;
  final Set<String> busy = {};

  Future<void> _act(MealItem meal, bool duplicate) async {
    if (!busy.add(meal.id)) return;
    setState(() {});
    try {
      if (duplicate) {
        if (meal.source == 'food_db') {
          await loading;
          FoodItem? food;
          for (final item in database.foods) {
            if (item.id == meal.foodId) {
              food = item;
              break;
            }
          }
          if (food == null || meal.grams == null) {
            throw StateError('This food is no longer available to duplicate.');
          }
          await widget.state.logFood(
              food,
              PortionResult(
                grams: meal.grams!,
                kcal: meal.calories,
                proteinG: meal.proteinGrams.toDouble(),
                carbsG: meal.carbsGrams.toDouble(),
                fatG: meal.fatGrams.toDouble(),
                fiberG: meal.fiberGrams.toDouble(),
                sugarG: meal.sugarG ?? 0,
                sodiumMg: meal.sodiumMg ?? 0,
              ),
              meal.category,
              servingLabel: meal.servingLabel);
        } else {
          await widget.state.addMeal(meal.copyWith(id: ''));
        }
      } else {
        await widget.state.removeMeal(meal.id);
      }
      if (mounted && widget.state.activityError != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text(
                  'Food was ${duplicate ? 'saved' : 'deleted'}, but the activity list could not be refreshed. Please retry.')));
      } else if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text(duplicate ? 'Food duplicated.' : 'Food deleted.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text(
                  'Could not ${duplicate ? 'duplicate' : 'delete'} food: $error')));
      }
    } finally {
      busy.remove(meal.id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _toggle(MealItem meal) async {
    try {
      await widget.state.toggleMeal(meal.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not update meal: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) {
          final palette = CaloriesPalette(Theme.of(context));
          final state = widget.state;
          final meals = state.meals;
          final consumed = meals.where((meal) => meal.consumed).toList();
          final totals = state.totals;
          final goal = state.targetCalories;
          final over = totals.totalMealCalories > goal;
          final colors = over ? CaloriesPalette.over : palette.accent;
          final goals = _macroGoals(goal);
          return DefaultTextStyle.merge(
            style: TextStyle(color: palette.text),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _card(
                      palette,
                      Padding(
                        padding: EdgeInsets.all(widget.compact ? 10 : 16),
                        child: Column(children: [
                          Row(children: [
                            SizedBox(
                              width: widget.compact ? 88 : 112,
                              height: widget.compact ? 88 : 112,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(
                                    end: goal > 0
                                        ? (totals.totalMealCalories / goal)
                                            .clamp(0, 1)
                                            .toDouble()
                                        : 0),
                                duration: const Duration(milliseconds: 500),
                                builder: (context, value, child) => CustomPaint(
                                  painter: CaloriesEnergyRingPainter(
                                      value, colors, palette.track),
                                  child: child,
                                ),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(fmt(totals.totalMealCalories),
                                          style: TextStyle(
                                              color: palette.text,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800)),
                                      Text('kcal eaten',
                                          style: TextStyle(
                                              color: palette.muted,
                                              fontSize: 11)),
                                    ]),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('DAILY ENERGY BALANCE',
                                      style: TextStyle(
                                          color: palette.accentText,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Container(
                                    decoration: over
                                        ? BoxDecoration(
                                            color: palette.overBackground,
                                            borderRadius:
                                                BorderRadius.circular(8))
                                        : null,
                                    padding: over
                                        ? const EdgeInsets.symmetric(
                                            horizontal: 4)
                                        : EdgeInsets.zero,
                                    child: Wrap(
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 5,
                                        children: [
                                          Text(
                                              fmt((goal -
                                                      totals.totalMealCalories)
                                                  .abs()),
                                              key: const ValueKey(
                                                  'calories-remaining'),
                                              style: TextStyle(
                                                  color: over
                                                      ? CaloriesPalette.over
                                                      : palette.accentText,
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.w800)),
                                          Text(over ? 'kcal over' : 'kcal left',
                                              style: TextStyle(
                                                  color: over
                                                      ? CaloriesPalette.over
                                                      : palette.accentText,
                                                  fontSize: 12)),
                                        ]),
                                  ),
                                  Text(
                                      'Goal: ${fmt(goal)} kcal • Logged items: ${consumed.length}',
                                      style: TextStyle(
                                          color: palette.muted, fontSize: 11)),
                                ])),
                          ]),
                          SizedBox(height: widget.compact ? 8 : 16),
                          Row(children: [
                            Expanded(
                                child: _macro(
                                    palette,
                                    'Protein',
                                    totals.proteinGrams,
                                    goals.protein,
                                    CaloriesPalette.protein)),
                            const SizedBox(width: 6),
                            Expanded(
                                child: _macro(
                                    palette,
                                    'Carbs',
                                    totals.carbsGrams,
                                    goals.carbs,
                                    CaloriesPalette.carbs)),
                            const SizedBox(width: 6),
                            Expanded(
                                child: _macro(palette, 'Fats', totals.fatGrams,
                                    goals.fat, CaloriesPalette.fat)),
                          ]),
                          SizedBox(height: widget.compact ? 8 : 14),
                          Divider(color: palette.border, height: 1),
                          SizedBox(height: widget.compact ? 6 : 12),
                          Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                _micro(palette, palette.accent, 'Fiber',
                                    '${totals.fiberGrams.toStringAsFixed(1)} g'),
                                _micro(palette, CaloriesPalette.sugar, 'Sugar',
                                    '${consumed.fold<double>(0, (v, m) => v + (m.sugarG ?? 0)).toStringAsFixed(1)} g'),
                                _micro(
                                    palette,
                                    CaloriesPalette.sodium,
                                    'Sodium',
                                    '${consumed.fold<double>(0, (v, m) => v + (m.sodiumMg ?? 0)).toStringAsFixed(1)} mg'),
                              ]),
                        ]),
                      )),
                  SizedBox(height: widget.compact ? 8 : 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: palette.accent,
                        foregroundColor: palette.onAccent,
                        minimumSize: const Size.fromHeight(48)),
                    onPressed: widget.onAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('Add food'),
                  ),
                  const SizedBox(height: 16),
                  _card(
                      palette,
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text("Today's Food Log",
                                  style: TextStyle(
                                      color: palette.text,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16)),
                              Text('سجل الوجبات اليومي',
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                      color: palette.muted, fontSize: 12)),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(children: [
                                    _tab(palette, 'All', null),
                                    _tab(palette, 'Breakfast',
                                        _MealSlot.breakfast),
                                    _tab(palette, 'Lunch', _MealSlot.lunch),
                                    _tab(palette, 'Dinner', _MealSlot.dinner),
                                    _tab(palette, 'Snacks', _MealSlot.snacks),
                                  ])),
                              const SizedBox(height: 12),
                              if (state.activityLoading && meals.isEmpty)
                                const Center(child: CircularProgressIndicator())
                              else if (state.activityError != null)
                                Column(children: [
                                  Text(state.activityError!,
                                      style: TextStyle(color: palette.text)),
                                  TextButton(
                                      onPressed: state.loadActivity,
                                      child: const Text('Retry')),
                                ])
                              else if (meals.isEmpty)
                                CustomPaint(
                                  painter: _DashedBorder(palette.track),
                                  child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(children: [
                                        Text('Your daily log is empty',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: palette.text,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        Text(
                                            'Add a meal to start tracking today.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: palette.muted,
                                                fontSize: 12)),
                                      ])),
                                )
                              else
                                FutureBuilder<void>(
                                  future: loading,
                                  builder: (context, snapshot) {
                                    final names = snapshot.connectionState ==
                                                ConnectionState.done &&
                                            !snapshot.hasError
                                        ? {
                                            for (final food in database.foods)
                                              food.id: food.nameAr
                                          }
                                        : <String, String>{};
                                    if (snapshot.hasError) {
                                      debugPrint(
                                          'Could not load food names: ${snapshot.error}');
                                    }
                                    return Column(children: [
                                      for (final slot in _MealSlot.values)
                                        if (selected == null ||
                                            selected == slot)
                                          _group(
                                              palette,
                                              slot,
                                              meals
                                                  .where((m) =>
                                                      _slot(m.category) == slot)
                                                  .toList(),
                                              names),
                                    ]);
                                  },
                                ),
                            ]),
                      )),
                ]),
          );
        },
      );

  Widget _card(CaloriesPalette p, Widget child) => Container(
        decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border)),
        child: child,
      );

  Widget _macro(
          CaloriesPalette p, String name, int eaten, int goal, Color color) =>
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: p.inner,
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 3, backgroundColor: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: p.text,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
          Text('$eaten / $goal g',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: p.text, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(
                end: goal > 0 ? (eaten / goal).clamp(0, 1).toDouble() : 0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  color: color,
                  backgroundColor: p.track),
            ),
          ),
        ]),
      );

  Widget _micro(CaloriesPalette p, Color color, String title, String value) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(radius: 4, backgroundColor: color),
        const SizedBox(width: 5),
        Text('$title $value', style: TextStyle(color: p.muted, fontSize: 11)),
      ]);

  Widget _tab(CaloriesPalette p, String label, _MealSlot? value) => Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Semantics(
          selected: selected == value,
          child: TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(40, 40),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              backgroundColor: selected == value ? p.inner : null,
              foregroundColor: selected == value ? p.accentText : p.muted,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => setState(() => selected = value),
            child: Text(label, style: const TextStyle(fontSize: 11)),
          ),
        ),
      );

  Widget _group(CaloriesPalette p, _MealSlot slot, List<MealItem> meals,
      Map<String, String> names) {
    final active = meals.where((m) => m.consumed);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: p.inner,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text('${slot.icon} ${slot.title} (${slot.arabic})',
                    style: TextStyle(
                        color: p.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 11)),
                Text(
                    '${active.fold<int>(0, (v, m) => v + m.calories)} kcal • ${active.fold<int>(0, (v, m) => v + m.proteinGrams)}g P',
                    style: TextStyle(
                        color: p.accentText,
                        fontWeight: FontWeight.bold,
                        fontSize: 11)),
              ]),
        ),
        if (meals.isEmpty)
          Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                  'No items logged for ${slot == _MealSlot.snacks ? 'snacks' : slot.title.toLowerCase()}.',
                  style: TextStyle(
                      color: p.muted,
                      fontSize: 11,
                      fontStyle: FontStyle.italic)))
        else
          for (final meal in meals) _meal(p, meal, names[meal.foodId]),
      ]),
    );
  }

  Widget _meal(CaloriesPalette p, MealItem meal, String? arabic) => Opacity(
        opacity: meal.consumed ? 1 : .6,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
          child: InkWell(
              onTap: meal.source == 'food_db' && widget.onEdit != null
                  ? () => widget.onEdit!(meal)
                  : null,
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                SizedBox(
                    width: 40,
                    height: 40,
                    child: Checkbox(
                      value: meal.consumed,
                      activeColor: p.accent,
                      checkColor: p.onAccent,
                      onChanged: (_) => _toggle(meal),
                      semanticLabel: meal.consumed
                          ? 'Uncheck ${meal.name}'
                          : 'Log ${meal.name}',
                    )),
                Expanded(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 40),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(meal.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: meal.consumed ? p.text : p.muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              if (meal.source == 'food_db' &&
                                  arabic != null &&
                                  arabic.isNotEmpty)
                                Text(arabic,
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.right,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: p.muted, fontSize: 11)),
                              Text(
                                  meal.servingLabel ??
                                      (meal.grams == null
                                          ? 'Manual entry'
                                          : '${meal.grams!.toStringAsFixed(1)} g'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      TextStyle(color: p.muted, fontSize: 11)),
                              Wrap(spacing: 5, children: [
                                _macroValue(p, CaloriesPalette.protein,
                                    '${meal.proteinGrams} P'),
                                _macroValue(p, CaloriesPalette.carbs,
                                    '${meal.carbsGrams} C'),
                                _macroValue(p, CaloriesPalette.fat,
                                    '${meal.fatGrams} F'),
                              ]),
                            ]))),
                const SizedBox(width: 4),
                Text('${meal.calories}\nkcal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: p.text,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                IconButton(
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                    padding: EdgeInsets.zero,
                    tooltip: 'Duplicate ${meal.name}',
                    onPressed:
                        busy.contains(meal.id) ? null : () => _act(meal, true),
                    icon: Icon(Icons.copy_outlined, size: 18, color: p.muted)),
                IconButton(
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                    padding: EdgeInsets.zero,
                    tooltip: 'Delete ${meal.name}',
                    onPressed:
                        busy.contains(meal.id) ? null : () => _act(meal, false),
                    icon: Icon(Icons.delete_outline, size: 18, color: p.muted)),
              ])),
        ),
      );

  Widget _macroValue(CaloriesPalette p, Color color, String value) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(radius: 3, backgroundColor: color),
        const SizedBox(width: 3),
        Text(value, style: TextStyle(color: p.text, fontSize: 10)),
      ]);
}

class CaloriesEnergyRingPainter extends CustomPainter {
  CaloriesEnergyRingPainter(this.progress, this.color, this.track);
  final double progress;
  final Color color, track;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final area = rect.deflate(5);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawOval(area, paint..color = track);
    if (progress > 0) {
      canvas.drawArc(
          area,
          -math.pi / 2,
          2 * math.pi * progress,
          false,
          paint
            ..color = color
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(CaloriesEnergyRingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

class _DashedBorder extends CustomPainter {
  _DashedBorder(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.5), const Radius.circular(12)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke;
    for (final metric in path.computeMetrics()) {
      for (double offset = 0; offset < metric.length; offset += 8) {
        canvas.drawPath(
            metric.extractPath(offset, math.min(offset + 4, metric.length)),
            paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}
