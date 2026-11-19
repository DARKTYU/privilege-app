import 'logic/fitness_logic.dart';

// ───────────────────────── recipes ─────────────────────────

class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.prepTime,
    required this.difficulty,
    required this.description,
    required this.ingredients,
    required this.emoji,
    required this.category,
  });
  final String id, name, prepTime, difficulty, description, emoji;
  final List<RecipeIngredient> ingredients;
  final MealCategory category;
}

class RecipeIngredient {
  const RecipeIngredient(this.foodId, this.grams);
  final String foodId;
  final double grams;
}

const recipes = <Recipe>[
  Recipe(
    id: 'burger',
    name: 'Beef and Baladi Bread',
    prepTime: '20 Mins',
    difficulty: 'Easy / Medium',
    description:
        'Lean ground beef with baladi bread. Beef weight is before cooking.',
    ingredients: [
      RecipeIngredient('raw_lean_ground_beef_90_10_raw', 150),
      RecipeIngredient('eg_baladi_bread_whole', 80),
    ],
    emoji: '🍔',
    category: MealCategory.lunch,
  ),
  Recipe(
    id: 'shake',
    name: 'Banana Peanut Protein Shake',
    prepTime: '5 Mins',
    difficulty: 'Instant',
    description: 'Blend the ingredients with water.',
    ingredients: [
      RecipeIngredient('raw_whey_protein_concentrate_powder', 30),
      RecipeIngredient('raw_banana_fresh_peeled', 100),
      RecipeIngredient('top_peanut_butter_natural', 15),
    ],
    emoji: '🥤',
    category: MealCategory.shake,
  ),
];

// ───────────────────────── splits & sports ─────────────────────────

class SplitOption {
  const SplitOption({
    required this.id,
    required this.name,
    required this.isSport,
    required this.durationMin,
    required this.calories,
    required this.icon,
    required this.focus,
  });
  final String id, name, icon, focus;
  final bool isSport;
  final int durationMin, calories;
}

const defaultWorkoutSplits = <SplitOption>[
  SplitOption(
      id: 'push',
      name: 'Push Day',
      isSport: false,
      durationMin: 60,
      calories: 450,
      icon: '🏋️',
      focus: 'Chest, Shoulders, Triceps'),
  SplitOption(
      id: 'pull',
      name: 'Pull Day',
      isSport: false,
      durationMin: 60,
      calories: 440,
      icon: '💪',
      focus: 'Lats, Rhomboids, Biceps'),
  SplitOption(
      id: 'legs',
      name: 'Leg Day Hypertrophy',
      isSport: false,
      durationMin: 70,
      calories: 550,
      icon: '🦵',
      focus: 'Quads, Hamstrings, Glutes'),
  SplitOption(
      id: 'upper',
      name: 'Upper Body Power',
      isSport: false,
      durationMin: 65,
      calories: 480,
      icon: '⚡',
      focus: 'Heavy Presses & Rows'),
  SplitOption(
      id: 'calisthenics',
      name: 'Calisthenics & Core',
      isSport: false,
      durationMin: 50,
      calories: 380,
      icon: '🤸',
      focus: 'Weighted Pullups, Dips & Abs'),
  SplitOption(
      id: 'olympic',
      name: 'Olympic Weightlifting',
      isSport: false,
      durationMin: 60,
      calories: 500,
      icon: '🥇',
      focus: 'Cleans, Snatches & Front Squats'),
];

const defaultSports = <SplitOption>[
  SplitOption(
      id: 'basketball',
      name: 'Basketball',
      isSport: true,
      durationMin: 60,
      calories: 520,
      icon: '🏀',
      focus: 'Full-court transition & jumps'),
  SplitOption(
      id: 'football',
      name: 'Football / Soccer',
      isSport: true,
      durationMin: 60,
      calories: 560,
      icon: '⚽',
      focus: 'High-speed sprints & deceleration'),
  SplitOption(
      id: 'tennis',
      name: 'Tennis',
      isSport: true,
      durationMin: 60,
      calories: 490,
      icon: '🎾',
      focus: 'Rotational torque & agility'),
  SplitOption(
      id: 'boxing',
      name: 'Boxing / MMA',
      isSport: true,
      durationMin: 50,
      calories: 580,
      icon: '🥊',
      focus: 'Heavy bag rounds & footwork'),
  SplitOption(
      id: 'swimming',
      name: 'Swimming Laps',
      isSport: true,
      durationMin: 45,
      calories: 430,
      icon: '🏊',
      focus: 'Freestyle endurance & breath control'),
  SplitOption(
      id: 'sprints',
      name: 'Track Sprint Intervals',
      isSport: true,
      durationMin: 40,
      calories: 460,
      icon: '🏃',
      focus: 'Max velocity anaerobic bursts'),
];

// ───────────────────────── academy ─────────────────────────

class ExerciseGuide {
  const ExerciseGuide({
    required this.id,
    required this.title,
    required this.category,
    required this.subCategory,
    required this.difficulty,
    required this.muscles,
    required this.cues,
    required this.mistakes,
    required this.burnRate,
  });
  final String id, title, category, subCategory, difficulty, burnRate;
  final List<String> muscles, cues, mistakes;
}

const guides = <ExerciseGuide>[
  ExerciseGuide(
    id: 'bench',
    title: 'Barbell Bench Press',
    category: 'gym',
    subCategory: 'Chest & Triceps Drive',
    difficulty: 'Beginner',
    muscles: ['Pectoralis Major', 'Anterior Deltoids', 'Triceps Brachii'],
    burnRate: '120 kcal / 15 mins',
    cues: [
      'Retract and depress scapulae firmly against the bench pad.',
      'Slight natural arch in lower back with feet planted flat for leg drive.',
      'Lower bar to mid-sternum at approximately a 45-degree elbow tuck.',
      'Drive bar upward over shoulders with controlled power.',
    ],
    mistakes: [
      'Flaring elbows out at 90 degrees (strains rotator cuff).',
      'Bouncing bar off chest instead of controlled touch.',
      'Lifting glutes off the bench during the press.',
    ],
  ),
  ExerciseGuide(
    id: 'squat',
    title: 'Barbell Back Squat',
    category: 'gym',
    subCategory: 'Leg Hypertrophy & Power',
    difficulty: 'Intermediate',
    muscles: ['Quadriceps', 'Gluteus Maximus', 'Hamstrings', 'Erector Spinae'],
    burnRate: '180 kcal / 15 mins',
    cues: [
      'Set feet shoulder-width apart, toes angled out 15-30 degrees.',
      'Take a deep belly breath and brace abdominal wall like bracing for a punch.',
      'Break at hips and knees simultaneously; drive knees out over toes.',
      'Hit hip crease below knee (parallel or deeper) before driving straight up.',
    ],
    mistakes: [
      'Knees collapsing inward (valgus collapse) on the ascent.',
      'Rounding lower back into flexion (butt wink).',
      'Rising onto toes rather than keeping weight distributed across tripod foot.',
    ],
  ),
  ExerciseGuide(
    id: 'deadlift',
    title: 'Conventional Deadlift',
    category: 'gym',
    subCategory: 'Posterior Chain Dominance',
    difficulty: 'Intermediate',
    muscles: ['Hamstrings', 'Glutes', 'Lats', 'Trapezius', 'Core'],
    burnRate: '200 kcal / 15 mins',
    cues: [
      'Bar directly over mid-foot with shins 1 inch away before setup.',
      'Hinge hips back, grip bar outside legs, pull chest tall to engage lats.',
      'Leg press the floor away until bar passes knees, then thrust hips forward.',
      'Lockout tall with glutes squeezed; do not hyperextend lower spine.',
    ],
    mistakes: [
      'Pulling with a rounded thoracic or lumbar spine.',
      'Letting the bar drift away from shins during the lift.',
      'Jerking the bar off the floor without taking out the barbell slack.',
    ],
  ),
  ExerciseGuide(
    id: 'basketball',
    title: 'Basketball Footwork & Plyometrics',
    category: 'sport',
    subCategory: 'Agility & Vertical Power',
    difficulty: 'Beginner',
    muscles: ['Calves', 'Quadriceps', 'Hip Flexors', 'Cardiovascular Engine'],
    burnRate: '250 kcal / 20 mins',
    cues: [
      'Maintain low athletic defensive stance with center of gravity centered.',
      'Lead with lead foot on lateral slides; never cross feet while guarding.',
      'Explode upward using triple extension (ankle, knee, hip) for rebounds.',
      'Absorb landing impact through soft knees on balls of the feet.',
    ],
    mistakes: [
      'Standing upright with locked knees on defense.',
      'Landing stiff-legged after vertical jump.',
    ],
  ),
  ExerciseGuide(
    id: 'boxing',
    title: 'Boxing Stance, Jab & Hip Torque',
    category: 'sport',
    subCategory: 'Rotational Power & Anaerobic HIIT',
    difficulty: 'Intermediate',
    muscles: ['Core Rotators', 'Shoulders', 'Lats', 'Calves'],
    burnRate: '280 kcal / 20 mins',
    cues: [
      'Bladed stance with knees soft, hands shielding chin, chin tucked.',
      'Step forward with lead foot while extending jab; snap fist at impact.',
      'Pivot rear foot on cross to transfer full kinetic chain power from hips.',
      'Exhale sharply with each strike to tense core.',
    ],
    mistakes: [
      'Dropping the non-punching guard hand.',
      'Overextending head past lead foot, losing balance.',
    ],
  ),
  ExerciseGuide(
    id: 'foundations',
    title: 'Start Your Fitness Life (Pillars 101)',
    category: 'foundation',
    subCategory: 'Nutrition, Overload & Recovery',
    difficulty: 'Beginner',
    muscles: ['Full Body Mindset', 'Metabolic Health'],
    burnRate: 'Lifetime Knowledge',
    cues: [
      'Target 1.6 - 2.2g of protein per kg of bodyweight to rebuild muscle.',
      'Progressive Overload: Add 1 rep, 1 set, or small weight every 1-2 weeks.',
      'Sleep 7.5 - 9 hours for maximum natural testosterone and growth hormone.',
      'Hydration: Drink 35-40ml water per kg daily + electrolytes for sports.',
    ],
    mistakes: [
      'Changing workout routines every week without progressive tracking.',
      'Cutting calories drastically while attempting to build lean muscle.',
    ],
  ),
];

// ───────────────────────── streak arena ─────────────────────────

class Reward {
  const Reward(this.name, this.cost, this.icon);
  final String name;
  final int cost;
  final String icon;
}

const rewards = <Reward>[
  Reward('Gym towel', 300, '🧺'),
  Reward('Protein shaker', 500, '🥤'),
  Reward('1 week of Privilege Pro', 800, '👑'),
  Reward('Championship badge', 1200, '🏆'),
];
