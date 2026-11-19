import 'logic/fitness_logic.dart';

// ───────────────────────── recipes ─────────────────────────

class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.minutes,
    required this.difficulty,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.emoji,
    required this.category,
  });
  final String id, name, nameAr, difficulty, description, emoji;
  final int minutes;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
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
    nameAr: 'لحم مفروم مع خبز بلدي',
    minutes: 20,
    difficulty: 'Easy / Medium',
    description:
        'Lean ground beef with baladi bread. Beef weight is before cooking.',
    ingredients: [
      RecipeIngredient('raw_lean_ground_beef_90_10_raw', 150),
      RecipeIngredient('eg_baladi_bread_whole', 80),
    ],
    steps: [
      'Weigh the raw beef.',
      'Cook the beef thoroughly.',
      'Warm the bread and serve with the beef.'
    ],
    emoji: '🍔',
    category: MealCategory.lunch,
  ),
  Recipe(
    id: 'shake',
    name: 'Banana Peanut Protein Shake',
    nameAr: 'مشروب البروتين بالموز وزبدة الفول السوداني',
    minutes: 5,
    difficulty: 'Instant',
    description:
        'Use fresh peeled banana and peanut butter made from roasted peanuts. Blend with water.',
    ingredients: [
      RecipeIngredient('raw_whey_protein_concentrate_powder', 30),
      RecipeIngredient('raw_banana_fresh_peeled', 100),
      RecipeIngredient('top_peanut_butter_natural', 15),
    ],
    steps: [
      'Peel and weigh the banana.',
      'Add the whey, peanut butter and water.',
      'Blend until smooth.'
    ],
    emoji: '🥤',
    category: MealCategory.shake,
  ),
  Recipe(
    id: 'areesh_bread',
    name: 'Areesh Cheese and Baladi Bread',
    nameAr: 'جبنة قريش مع خبز بلدي',
    minutes: 5,
    difficulty: 'Easy',
    description: 'A quick Egyptian breakfast.',
    ingredients: [
      RecipeIngredient('eg_areesh_cheese', 200),
      RecipeIngredient('eg_baladi_bread_whole', 50)
    ],
    steps: [
      'Weigh the cheese.',
      'Cut the bread.',
      'Serve the cheese with the bread.'
    ],
    emoji: '🧀',
    category: MealCategory.breakfast,
  ),
  Recipe(
    id: 'ful_egg',
    name: 'Ful and Boiled Eggs',
    nameAr: 'فول وبيض مسلوق',
    minutes: 10,
    difficulty: 'Easy',
    description: 'Use plain boiled ful without oil and already boiled eggs.',
    ingredients: [
      RecipeIngredient('eg_ful_medames_plain', 180),
      RecipeIngredient('raw_whole_chicken_egg_boiled', 100)
    ],
    steps: [
      'Weigh the prepared ful.',
      'Heat the ful until steaming.',
      'Peel and serve the boiled eggs alongside.'
    ],
    emoji: '🥚',
    category: MealCategory.breakfast,
  ),
  Recipe(
    id: 'chicken_rice',
    name: 'Chicken and Rice Bowl',
    nameAr: 'طبق دجاج وأرز',
    minutes: 10,
    difficulty: 'Easy',
    description: 'Use cooked grilled chicken and plain steamed or boiled rice.',
    ingredients: [
      RecipeIngredient('raw_chicken_breast_grilled_cooked', 150),
      RecipeIngredient('raw_white_rice_steamed_cooked', 100)
    ],
    steps: [
      'Weigh the cooked chicken and rice.',
      'Reheat until steaming hot.',
      'Slice the chicken and serve over the rice.'
    ],
    emoji: '🍚',
    category: MealCategory.lunch,
  ),
  Recipe(
    id: 'chicken_molokhia',
    name: 'Chicken and Molokhia',
    nameAr: 'دجاج وملوخية',
    minutes: 10,
    difficulty: 'Easy',
    description:
        'Use cooked grilled chicken and molokhia cooked with chicken broth and garlic.',
    ingredients: [
      RecipeIngredient('raw_chicken_breast_grilled_cooked', 120),
      RecipeIngredient('eg_molokhia_chicken_broth', 200)
    ],
    steps: [
      'Weigh the cooked chicken and molokhia.',
      'Reheat both until steaming hot.',
      'Slice the chicken and serve with the molokhia.'
    ],
    emoji: '🍲',
    category: MealCategory.dinner,
  ),
  Recipe(
    id: 'yogurt_banana',
    name: 'Greek Yogurt and Banana',
    nameAr: 'زبادي يوناني وموز',
    minutes: 5,
    difficulty: 'Easy',
    description: 'Use fresh peeled banana with chilled yogurt.',
    ingredients: [
      RecipeIngredient('snk_greek_yogurt_plain_lowfat', 200),
      RecipeIngredient('raw_banana_fresh_peeled', 100)
    ],
    steps: [
      'Weigh the yogurt.',
      'Peel and slice the banana.',
      'Serve the banana over the yogurt.'
    ],
    emoji: '🍌',
    category: MealCategory.snack,
  ),
  Recipe(
    id: 'areesh_egg',
    name: 'Areesh Cheese and Egg Plate',
    nameAr: 'طبق جبنة قريش وبيض',
    minutes: 5,
    difficulty: 'Easy',
    description: 'Use an already boiled egg.',
    ingredients: [
      RecipeIngredient('eg_areesh_cheese', 150),
      RecipeIngredient('raw_whole_chicken_egg_boiled', 50)
    ],
    steps: [
      'Weigh the cheese.',
      'Peel and weigh the boiled egg.',
      'Slice the egg and serve with the cheese.'
    ],
    emoji: '🥚',
    category: MealCategory.snack,
  ),
  Recipe(
    id: 'taameya_areesh',
    name: 'Baked Taameya and Areesh Plate',
    nameAr: 'طعمية مخبوزة وجبنة قريش',
    minutes: 10,
    difficulty: 'Easy',
    description: 'Use prepared baked or air-fried taameya.',
    ingredients: [
      RecipeIngredient('eg_taameya_airfried', 100),
      RecipeIngredient('eg_areesh_cheese', 100)
    ],
    steps: [
      'Weigh the prepared taameya.',
      'Reheat the taameya until hot.',
      'Serve with the cheese.'
    ],
    emoji: '🧆',
    category: MealCategory.dinner,
  ),
  Recipe(
    id: 'koshary_chicken',
    name: 'Koshary and Grilled Chicken',
    nameAr: 'كشري ودجاج مشوي',
    minutes: 10,
    difficulty: 'Easy',
    description:
        'Use prepared koshary with fried onions and sauce, and cooked grilled chicken.',
    ingredients: [
      RecipeIngredient('eg_koshary_traditional', 200),
      RecipeIngredient('raw_chicken_breast_grilled_cooked', 100)
    ],
    steps: [
      'Weigh the koshary and cooked chicken.',
      'Reheat both until steaming hot.',
      'Slice the chicken and serve with the koshary.'
    ],
    emoji: '🍽️',
    category: MealCategory.lunch,
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
