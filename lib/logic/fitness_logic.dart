import 'dart:math' as math;
import 'dart:ui' show Color;

/// Port of src/utils/fitnessLogic.ts

// ───────────────────────── calories ─────────────────────────

class CalorieBalance {
  const CalorieBalance(
      this.consumed,
      this.burnedActive,
      this.bmr,
      this.totalBurned,
      this.netDifference,
      this.isSurplus,
      this.deficitPercent);
  final int consumed,
      burnedActive,
      bmr,
      totalBurned,
      netDifference,
      deficitPercent;
  final bool isSurplus;
}

CalorieBalance calculateCalorieBalance(int consumed, int burned,
    {required int bmr}) {
  final totalBurned = burned + bmr;
  final net = consumed - totalBurned;
  return CalorieBalance(
    consumed,
    burned,
    bmr,
    totalBurned,
    net,
    net > 0,
    totalBurned > 0
        ? (((totalBurned - consumed) / totalBurned) * 100).round()
        : 0,
  );
}

class CalorieAdjust {
  const CalorieAdjust(this.consumed, this.burned);
  final int consumed, burned;
}

CalorieAdjust adjustCalories(int currentConsumed, int currentBurned,
    {required bool isMeal, required int amount, bool isRemoval = false}) {
  final change = amount * (isRemoval ? -1 : 1);
  if (isMeal) {
    return CalorieAdjust(math.max(0, currentConsumed + change), currentBurned);
  }
  return CalorieAdjust(currentConsumed, math.max(0, currentBurned + change));
}

enum MealCategory { breakfast, lunch, shake, dinner, snack }

enum BurnType { strength, cardio, mobility }

class MealItem {
  const MealItem({
    required this.id,
    required this.name,
    required this.time,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.fiberGrams,
    required this.icon,
    required this.consumed,
    required this.category,
    this.foodId,
    this.grams,
    this.servingLabel,
    this.sugarG,
    this.sodiumMg,
    this.source = 'manual',
  });
  final String id, name, time, icon;
  final int calories, proteinGrams, carbsGrams, fatGrams, fiberGrams;
  final bool consumed;
  final MealCategory category;
  final String? foodId, servingLabel;
  final double? grams, sugarG, sodiumMg;
  final String source;

  MealItem copyWith({
    String? id,
    int? calories,
    bool? consumed,
    int? proteinGrams,
    int? carbsGrams,
    int? fatGrams,
    int? fiberGrams,
    double? grams,
    double? sugarG,
    double? sodiumMg,
    String? servingLabel,
    bool clearServingLabel = false,
  }) =>
      MealItem(
        id: id ?? this.id,
        name: name,
        time: time,
        calories: calories ?? this.calories,
        proteinGrams: proteinGrams ?? this.proteinGrams,
        carbsGrams: carbsGrams ?? this.carbsGrams,
        fatGrams: fatGrams ?? this.fatGrams,
        fiberGrams: fiberGrams ?? this.fiberGrams,
        icon: icon,
        consumed: consumed ?? this.consumed,
        category: category,
        foodId: foodId,
        grams: grams ?? this.grams,
        servingLabel:
            clearServingLabel ? null : servingLabel ?? this.servingLabel,
        sugarG: sugarG ?? this.sugarG,
        sodiumMg: sodiumMg ?? this.sodiumMg,
        source: source,
      );
}

class BurnItem {
  const BurnItem({
    required this.id,
    required this.title,
    required this.time,
    required this.calories,
    required this.type,
    required this.durationMin,
    required this.icon,
    this.createdAt,
  });
  final String id, title, time, icon;
  final int calories, durationMin;
  final BurnType type;
  final DateTime? createdAt;

  BurnItem copyWith({String? id}) => BurnItem(
        id: id ?? this.id,
        title: title,
        time: time,
        calories: calories,
        type: type,
        durationMin: durationMin,
        icon: icon,
        createdAt: createdAt,
      );
}

class MacroTotals {
  const MacroTotals({
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.fiberGrams,
    required this.totalMealCalories,
    required this.strengthBurnCalories,
    required this.cardioBurnCalories,
    required this.mobilityBurnCalories,
    required this.totalBurnedCalories,
    required this.calorieTarget,
    required this.burnTarget,
    required this.activeMealCount,
    required this.activeBurnCount,
  });
  final int proteinGrams, carbsGrams, fatGrams, fiberGrams;
  final int totalMealCalories;
  final int strengthBurnCalories,
      cardioBurnCalories,
      mobilityBurnCalories,
      totalBurnedCalories;
  final int calorieTarget, burnTarget, activeMealCount, activeBurnCount;

  int get proteinCalories => proteinGrams * 4;
  int get carbsCalories => carbsGrams * 4;
  int get fatCalories => fatGrams * 9;
  int get fiberCalories => fiberGrams * 2;
}

MacroTotals calculateMacroTotals(List<MealItem> meals, List<BurnItem> burns,
    {int calorieTarget = 2400, int burnTarget = 1200}) {
  var p = 0, c = 0, f = 0, fib = 0, cal = 0, count = 0;
  for (final m in meals) {
    if (m.consumed) {
      p += m.proteinGrams;
      c += m.carbsGrams;
      f += m.fatGrams;
      fib += m.fiberGrams;
      cal += m.calories;
      count++;
    }
  }
  var strength = 0, cardio = 0, mobility = 0, total = 0;
  for (final b in burns) {
    total += b.calories;
    switch (b.type) {
      case BurnType.strength:
        strength += b.calories;
      case BurnType.cardio:
        cardio += b.calories;
      case BurnType.mobility:
        mobility += b.calories;
    }
  }
  return MacroTotals(
    proteinGrams: p,
    carbsGrams: c,
    fatGrams: f,
    fiberGrams: fib,
    totalMealCalories: cal,
    strengthBurnCalories: strength,
    cardioBurnCalories: cardio,
    mobilityBurnCalories: mobility,
    totalBurnedCalories: total,
    calorieTarget: calorieTarget,
    burnTarget: burnTarget,
    activeMealCount: count,
    activeBurnCount: burns.length,
  );
}

// ───────────────────────── radial segments ─────────────────────────

enum SegmentCategory { meal, burn, target }

class RadialSegment {
  const RadialSegment({
    required this.id,
    required this.label,
    required this.category,
    required this.color,
    required this.calories,
    required this.gramsOrMin,
    required this.percentage,
    required this.arcLength,
    required this.startOffset,
  });
  final String id, label, gramsOrMin;
  final SegmentCategory category;
  final Color color;
  final int calories, percentage;
  final double arcLength,
      startOffset; // distances along the circle, in px of a 160x160 viewBox
}

class RadialResult {
  const RadialResult(this.segments, this.circumference, this.radius);
  final List<RadialSegment> segments;
  final double circumference, radius;
}

class _Base {
  const _Base(
      this.id, this.label, this.category, this.color, this.calories, this.text);
  final String id, label, text;
  final SegmentCategory category;
  final Color color;
  final int calories;
}

/// 7 colour-coded metrics, same colours as the React version.
RadialResult calculateRadialSegments(
  MacroTotals t, {
  double radius = 62,
  Color proteinColor = const Color(0xFFF43F5E),
  Color carbsColor = const Color(0xFF3B82F6),
  Color fatsColor = const Color(0xFFF97316),
  Color fiberColor = const Color(0xFF10B981),
  Color strengthColor = const Color(0xFFF59E0B),
  Color cardioColor = const Color(0xFF06B6D4),
  Color targetColor = const Color(0xFF8B5CF6),
}) {
  final circumference = 2 * math.pi * radius;
  final base = <_Base>[
    _Base('protein', 'Protein', SegmentCategory.meal, proteinColor,
        t.proteinCalories, '${t.proteinGrams}g'),
    _Base('carbs', 'Carbs', SegmentCategory.meal, carbsColor, t.carbsCalories,
        '${t.carbsGrams}g'),
    _Base('fats', 'Fats', SegmentCategory.meal, fatsColor, t.fatCalories,
        '${t.fatGrams}g'),
    _Base(
        'fiber',
        'Greens & Fiber',
        SegmentCategory.meal,
        fiberColor,
        t.fiberCalories != 0 ? t.fiberCalories : 60,
        '${t.fiberGrams != 0 ? t.fiberGrams : 15}g'),
    _Base('strength', 'Strength Burn', SegmentCategory.burn, strengthColor,
        t.strengthBurnCalories, '${t.strengthBurnCalories} kcal'),
    _Base('cardio', 'Cardio Burn', SegmentCategory.burn, cardioColor,
        t.cardioBurnCalories, '${t.cardioBurnCalories} kcal'),
    _Base(
        'goal',
        'Deficit Goal',
        SegmentCategory.target,
        targetColor,
        math.max(0, t.calorieTarget - t.totalMealCalories),
        '${((t.totalMealCalories / math.max(1, t.calorieTarget)) * 100).round()}%'),
  ];

  final sum = base.fold<double>(0, (a, b) => a + math.max(10, b.calories));
  var offset = 0.0;
  const gap = 3.0;
  final segments = <RadialSegment>[];
  for (final b in base) {
    final raw = math.max(10, b.calories);
    final fraction = raw / sum;
    final arc = math.max(8.0, fraction * circumference - gap);
    segments.add(RadialSegment(
      id: b.id,
      label: b.label,
      category: b.category,
      color: b.color,
      calories: b.calories,
      gramsOrMin: b.text,
      percentage: (fraction * 100).round(),
      arcLength: arc,
      startOffset: offset,
    ));
    offset += arc + gap;
  }
  return RadialResult(segments, circumference, radius);
}

// ───────────────────────── championship ─────────────────────────

class QualificationMetrics {
  const QualificationMetrics({
    required this.naturalVerified,
    required this.bodyFatPercent,
    required this.muscleMassKg,
    required this.mandatoryPosingRoutine,
  });
  final bool naturalVerified, mandatoryPosingRoutine;
  final int bodyFatPercent, muscleMassKg;
}

class QualificationResult {
  const QualificationResult(
      this.scorePercent, this.levelName, this.eligible, this.statusNotes);
  final int scorePercent;
  final String levelName;
  final bool eligible;
  final List<String> statusNotes;
}

QualificationResult calculateQualificationScore(QualificationMetrics m) {
  var score = 0;
  final notes = <String>[];

  if (m.naturalVerified) {
    score += 35;
    notes.add('100% Natural Status Verified');
  } else {
    notes.add('Drug-free verification pending');
  }

  if (m.bodyFatPercent <= 12 && m.bodyFatPercent >= 8) {
    score += 30;
    notes.add('Optimal Body Fat (${m.bodyFatPercent}%)');
  } else if (m.bodyFatPercent <= 15) {
    score += 20;
    notes.add('Acceptable Body Fat (${m.bodyFatPercent}%)');
  } else {
    score += 10;
    notes.add('High Body Fat for Show Prep (${m.bodyFatPercent}%)');
  }

  if (m.muscleMassKg >= 40) {
    score += 25;
    notes.add('Optimal Muscle Mass (${m.muscleMassKg}kg)');
  } else if (m.muscleMassKg >= 35) {
    score += 18;
    notes.add('Developing Muscle Mass (${m.muscleMassKg}kg)');
  } else {
    score += 10;
  }

  if (m.mandatoryPosingRoutine) {
    score += 10;
    notes.add('Posing routine registered');
  } else {
    score += 8;
  }

  final pct = math.min(100, math.max(0, score));
  var level = 'Bronze Contender';
  if (pct >= 85) level = 'Silver Beast';
  if (pct >= 95) level = 'Gold Champion';

  return QualificationResult(pct, level, pct >= 80 && m.naturalVerified, notes);
}

bool isDayAllowedForCheat(int dayOfMonth, List<int> allowedDays) =>
    allowedDays.contains(dayOfMonth);

// ───────────────────────── Privilege Bot fallback ─────────────────────────

String getPrivilegeBotFallback(String userQuery) {
  final q = userQuery.toLowerCase();
  bool has(List<String> words) => words.any(q.contains);

  if (has(['picture', 'photo', 'meal', 'image'])) {
    return 'Analyzing meal visual: Detected high-protein plate with grilled lean protein, wholesome complex carbohydrates, and leafy greens. Estimated: ~45g Protein, 480 kcal, 14g Fat. Perfect post-workout timing!';
  }
  if (has(['audio', 'voice', 'record'])) {
    return 'Voice transmission received and transcribed! Coach tip: On your heavy bench sets, keep your scapulae retracted and drive through the floor with your heels to maximize power transfer!';
  }
  if (has(['merge', 'workout', 'sport', 'basketball'])) {
    return 'You can merge with a personalized trainer avatar session or schedule. Merging your workout splits with sports maximizes athletic performance while scheduling optimal muscle recovery!';
  }
  if (has(['burger', 'protein', 'recipe', 'eat'])) {
    return 'Our signature High-Protein Burger packs 48g of lean protein with whole-grain brioche and healthy avocado fats. It fits perfectly into your post-workout anabolic window!';
  }
  if (has(['calorie', 'ring', 'burn'])) {
    return 'Your Calories Rings track active burn (1,206 kcal) and meal intake (2,855 kcal). Maintain a slight deficit for the Natural Championship cut, or a 200 kcal surplus for clean muscle mass.';
  }
  if (has(['cheat', 'craving', 'treat'])) {
    return 'Schedule your cheat meals on Day 8 and Day 20 after high-volume leg or sports merge sessions. This ensures the glycogen replenishes depleted muscle tissues rather than storing as fat!';
  }
  if (has(['championship', 'natural', 'silver', 'level'])) {
    return 'You are currently at 88% readiness (Silver Beast)! With 100% Natural Status verified, 11% Body Fat, and 42kg Muscle Mass, you are in prime shape for the Natural Championship qualification.';
  }
  return 'Privilege Bot ready! Ask me anything about your workout splits, sport mergers, high-protein recipes, calories tracking, photo analysis, or Road to Championship prep.';
}
