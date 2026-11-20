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
    this.descriptionAr = '',
    required this.ingredients,
    required this.steps,
    this.stepsAr = const [],
    required this.emoji,
    required this.category,
  });
  final String id, name, nameAr, difficulty, description, emoji;
  final String descriptionAr;
  final int minutes;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final List<String> stepsAr;
  final MealCategory category;

  String localizedName(bool arabic) => localizedContent(name, nameAr, arabic);
  String localizedDescription(bool arabic) =>
      localizedContent(description, descriptionAr, arabic);
  String localizedStep(int index, bool arabic) => localizedContent(
      steps[index], index < stepsAr.length ? stepsAr[index] : '', arabic);
}

String localizedContent(String english, String arabic, bool useArabic) =>
    useArabic && arabic.trim().isNotEmpty ? arabic : english;

List<String> localizedContentList(
        List<String> english, List<String> arabic, bool useArabic) =>
    List.generate(
        english.length,
        (i) => localizedContent(
            english[i], i < arabic.length ? arabic[i] : '', useArabic));

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
    descriptionAr: 'لحم مفروم قليل الدهن مع خبز بلدي. وزن اللحم قبل الطهي.',
    ingredients: [
      RecipeIngredient('raw_lean_ground_beef_90_10_raw', 150),
      RecipeIngredient('eg_baladi_bread_whole', 80),
    ],
    steps: [
      'Weigh the raw beef.',
      'Cook the beef thoroughly.',
      'Warm the bread and serve with the beef.'
    ],
    stepsAr: [
      'زن اللحم النيء.',
      'اطهِ اللحم جيداً.',
      'سخّن الخبز وقدمه مع اللحم.'
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
    descriptionAr:
        'استخدم موزاً طازجاً مقشراً وزبدة فول سوداني من فول سوداني محمص. اخلطهما مع الماء.',
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
    stepsAr: [
      'قشّر الموز وزنه.',
      'أضف بروتين الواي وزبدة الفول السوداني والماء.',
      'اخلط حتى يصبح القوام ناعماً.'
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
    descriptionAr: 'فطور مصري سريع.',
    ingredients: [
      RecipeIngredient('eg_areesh_cheese', 200),
      RecipeIngredient('eg_baladi_bread_whole', 50)
    ],
    steps: [
      'Weigh the cheese.',
      'Cut the bread.',
      'Serve the cheese with the bread.'
    ],
    stepsAr: ['زن الجبنة.', 'قطّع الخبز.', 'قدم الجبنة مع الخبز.'],
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
    descriptionAr: 'استخدم فولاً مسلوقاً بدون زيت وبيضاً مسلوقاً جاهزاً.',
    ingredients: [
      RecipeIngredient('eg_ful_medames_plain', 180),
      RecipeIngredient('raw_whole_chicken_egg_boiled', 100)
    ],
    steps: [
      'Weigh the prepared ful.',
      'Heat the ful until steaming.',
      'Peel and serve the boiled eggs alongside.'
    ],
    stepsAr: [
      'زن الفول الجاهز.',
      'سخّن الفول حتى يتصاعد منه البخار.',
      'قشّر البيض المسلوق وقدمه بجانبه.'
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
    descriptionAr:
        'استخدم دجاجاً مشوياً مطهياً وأرزاً سادة مطهياً على البخار أو مسلوقاً.',
    ingredients: [
      RecipeIngredient('raw_chicken_breast_grilled_cooked', 150),
      RecipeIngredient('raw_white_rice_steamed_cooked', 100)
    ],
    steps: [
      'Weigh the cooked chicken and rice.',
      'Reheat until steaming hot.',
      'Slice the chicken and serve over the rice.'
    ],
    stepsAr: [
      'زن الدجاج والأرز المطهيين.',
      'أعد تسخينهما حتى يتصاعد منهما البخار.',
      'قطّع الدجاج وقدمه فوق الأرز.'
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
    descriptionAr:
        'استخدم دجاجاً مشوياً مطهياً وملوخية مطهية بمرق الدجاج والثوم.',
    ingredients: [
      RecipeIngredient('raw_chicken_breast_grilled_cooked', 120),
      RecipeIngredient('eg_molokhia_chicken_broth', 200)
    ],
    steps: [
      'Weigh the cooked chicken and molokhia.',
      'Reheat both until steaming hot.',
      'Slice the chicken and serve with the molokhia.'
    ],
    stepsAr: [
      'زن الدجاج والملوخية المطهيين.',
      'أعد تسخينهما حتى يتصاعد منهما البخار.',
      'قطّع الدجاج وقدمه مع الملوخية.'
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
    descriptionAr: 'استخدم موزاً طازجاً مقشراً مع زبادي بارد.',
    ingredients: [
      RecipeIngredient('snk_greek_yogurt_plain_lowfat', 200),
      RecipeIngredient('raw_banana_fresh_peeled', 100)
    ],
    steps: [
      'Weigh the yogurt.',
      'Peel and slice the banana.',
      'Serve the banana over the yogurt.'
    ],
    stepsAr: ['زن الزبادي.', 'قشّر الموز وقطّعه.', 'قدم الموز فوق الزبادي.'],
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
    descriptionAr: 'استخدم بيضة مسلوقة جاهزة.',
    ingredients: [
      RecipeIngredient('eg_areesh_cheese', 150),
      RecipeIngredient('raw_whole_chicken_egg_boiled', 50)
    ],
    steps: [
      'Weigh the cheese.',
      'Peel and weigh the boiled egg.',
      'Slice the egg and serve with the cheese.'
    ],
    stepsAr: [
      'زن الجبنة.',
      'قشّر البيضة المسلوقة وزنها.',
      'قطّع البيضة وقدمها مع الجبنة.'
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
    descriptionAr: 'استخدم طعمية جاهزة مخبوزة أو مطهية في القلاية الهوائية.',
    ingredients: [
      RecipeIngredient('eg_taameya_airfried', 100),
      RecipeIngredient('eg_areesh_cheese', 100)
    ],
    steps: [
      'Weigh the prepared taameya.',
      'Reheat the taameya until hot.',
      'Serve with the cheese.'
    ],
    stepsAr: [
      'زن الطعمية الجاهزة.',
      'أعد تسخين الطعمية حتى تصبح ساخنة.',
      'قدمها مع الجبنة.'
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
    descriptionAr:
        'استخدم كشري جاهزاً بالبصل المحمر والصلصة، ودجاجاً مشوياً مطهياً.',
    ingredients: [
      RecipeIngredient('eg_koshary_traditional', 200),
      RecipeIngredient('raw_chicken_breast_grilled_cooked', 100)
    ],
    steps: [
      'Weigh the koshary and cooked chicken.',
      'Reheat both until steaming hot.',
      'Slice the chicken and serve with the koshary.'
    ],
    stepsAr: [
      'زن الكشري والدجاج المطهي.',
      'أعد تسخينهما حتى يتصاعد منهما البخار.',
      'قطّع الدجاج وقدمه مع الكشري.'
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
    required this.icon,
    required this.focus,
  });
  final String id, name, icon, focus;
  final bool isSport;
  final int durationMin;
}

const defaultWorkoutSplits = <SplitOption>[
  SplitOption(
      id: 'push',
      name: 'Push Day',
      isSport: false,
      durationMin: 60,
      icon: '🏋️',
      focus: 'Chest, Shoulders, Triceps'),
  SplitOption(
      id: 'pull',
      name: 'Pull Day',
      isSport: false,
      durationMin: 60,
      icon: '💪',
      focus: 'Lats, Rhomboids, Biceps'),
  SplitOption(
      id: 'legs',
      name: 'Leg Day Hypertrophy',
      isSport: false,
      durationMin: 70,
      icon: '🦵',
      focus: 'Quads, Hamstrings, Glutes'),
  SplitOption(
      id: 'upper',
      name: 'Upper Body Power',
      isSport: false,
      durationMin: 65,
      icon: '⚡',
      focus: 'Heavy Presses & Rows'),
  SplitOption(
      id: 'calisthenics',
      name: 'Calisthenics & Core',
      isSport: false,
      durationMin: 50,
      icon: '🤸',
      focus: 'Weighted Pullups, Dips & Abs'),
  SplitOption(
      id: 'olympic',
      name: 'Olympic Weightlifting',
      isSport: false,
      durationMin: 60,
      icon: '🥇',
      focus: 'Cleans, Snatches & Front Squats'),
];

const defaultSports = <SplitOption>[
  SplitOption(
      id: 'basketball',
      name: 'Basketball',
      isSport: true,
      durationMin: 60,
      icon: '🏀',
      focus: 'Full-court transition & jumps'),
  SplitOption(
      id: 'football',
      name: 'Football / Soccer',
      isSport: true,
      durationMin: 60,
      icon: '⚽',
      focus: 'High-speed sprints & deceleration'),
  SplitOption(
      id: 'tennis',
      name: 'Tennis',
      isSport: true,
      durationMin: 60,
      icon: '🎾',
      focus: 'Rotational torque & agility'),
  SplitOption(
      id: 'boxing',
      name: 'Boxing / MMA',
      isSport: true,
      durationMin: 50,
      icon: '🥊',
      focus: 'Heavy bag rounds & footwork'),
  SplitOption(
      id: 'swimming',
      name: 'Swimming Laps',
      isSport: true,
      durationMin: 45,
      icon: '🏊',
      focus: 'Freestyle endurance & breath control'),
  SplitOption(
      id: 'sprints',
      name: 'Track Sprint Intervals',
      isSport: true,
      durationMin: 40,
      icon: '🏃',
      focus: 'Max velocity anaerobic bursts'),
];

// ───────────────────────── academy ─────────────────────────

class ExerciseGuide {
  const ExerciseGuide({
    required this.id,
    required this.title,
    this.titleAr = '',
    required this.category,
    required this.subCategory,
    this.subCategoryAr = '',
    required this.difficulty,
    this.difficultyAr = '',
    required this.muscles,
    this.musclesAr = const [],
    required this.cues,
    this.cuesAr = const [],
    required this.mistakes,
    this.mistakesAr = const [],
    required this.burnRate,
  });
  final String id, title, category, subCategory, difficulty, burnRate;
  final String titleAr, subCategoryAr, difficultyAr;
  final List<String> muscles, cues, mistakes;
  final List<String> musclesAr, cuesAr, mistakesAr;

  String localizedTitle(bool ar) => localizedContent(title, titleAr, ar);
  String localizedSubCategory(bool ar) =>
      localizedContent(subCategory, subCategoryAr, ar);
  String localizedDifficulty(bool ar) =>
      localizedContent(difficulty, difficultyAr, ar);
  List<String> localizedMuscles(bool ar) =>
      localizedContentList(muscles, musclesAr, ar);
  List<String> localizedCues(bool ar) => localizedContentList(cues, cuesAr, ar);
  List<String> localizedMistakes(bool ar) =>
      localizedContentList(mistakes, mistakesAr, ar);
}

const guides = <ExerciseGuide>[
  ExerciseGuide(
    id: 'bench',
    title: 'Barbell Bench Press',
    titleAr: 'بنش برس بالبار',
    category: 'gym',
    subCategory: 'Chest & Triceps Drive',
    subCategoryAr: 'قوة الصدر والترايسبس',
    difficulty: 'Beginner',
    difficultyAr: 'مبتدئ',
    muscles: ['Pectoralis Major', 'Anterior Deltoids', 'Triceps Brachii'],
    musclesAr: ['عضلة الصدر الكبرى', 'الكتف الأمامي', 'الترايسبس'],
    burnRate: '120 kcal / 15 mins',
    cues: [
      'Retract and depress scapulae firmly against the bench pad.',
      'Slight natural arch in lower back with feet planted flat for leg drive.',
      'Lower bar to mid-sternum at approximately a 45-degree elbow tuck.',
      'Drive bar upward over shoulders with controlled power.',
    ],
    cuesAr: [
      'اسحب لوحي الكتف للخلف ولأسفل وثبتهما على البنش.',
      'حافظ على تقوس طبيعي بسيط أسفل الظهر وثبّت قدميك على الأرض للمساعدة في الدفع.',
      'أنزل البار إلى منتصف الصدر مع إبقاء المرفقين بزاوية تقارب 45 درجة.',
      'ادفع البار لأعلى فوق الكتفين بقوة وتحكم.',
    ],
    mistakes: [
      'Flaring elbows out at 90 degrees (strains rotator cuff).',
      'Bouncing bar off chest instead of controlled touch.',
      'Lifting glutes off the bench during the press.',
    ],
    mistakesAr: [
      'فتح المرفقين بزاوية 90 درجة، مما يجهد عضلات الكتف.',
      'ترك البار يرتد عن الصدر بدلاً من ملامسته بتحكم.',
      'رفع المؤخرة عن البنش أثناء الدفع.',
    ],
  ),
  ExerciseGuide(
    id: 'squat',
    title: 'Barbell Back Squat',
    titleAr: 'سكوات خلفي بالبار',
    category: 'gym',
    subCategory: 'Leg Hypertrophy & Power',
    subCategoryAr: 'تضخيم الرجلين وقوتهما',
    difficulty: 'Intermediate',
    difficultyAr: 'متوسط',
    muscles: ['Quadriceps', 'Gluteus Maximus', 'Hamstrings', 'Erector Spinae'],
    musclesAr: [
      'عضلات الفخذ الأمامية',
      'عضلات المؤخرة',
      'عضلات الفخذ الخلفية',
      'عضلات الظهر الناصبة'
    ],
    burnRate: '180 kcal / 15 mins',
    cues: [
      'Set feet shoulder-width apart, toes angled out 15-30 degrees.',
      'Take a deep belly breath and brace abdominal wall like bracing for a punch.',
      'Break at hips and knees simultaneously; drive knees out over toes.',
      'Hit hip crease below knee (parallel or deeper) before driving straight up.',
    ],
    cuesAr: [
      'باعد قدميك بعرض الكتفين ووجّه أصابعهما للخارج بزاوية 15-30 درجة.',
      'خذ نفساً عميقاً في بطنك وشد عضلات البطن كأنك تستعد لتلقي لكمة.',
      'اثنِ الحوض والركبتين معاً، ووجّه الركبتين للخارج فوق أصابع القدم.',
      'انزل حتى يصبح مفصل الحوض أسفل الركبة، عند مستوى التوازي أو أعمق، ثم اصعد مباشرة.',
    ],
    mistakes: [
      'Knees collapsing inward (valgus collapse) on the ascent.',
      'Rounding lower back into flexion (butt wink).',
      'Rising onto toes rather than keeping weight distributed across tripod foot.',
    ],
    mistakesAr: [
      'انهيار الركبتين للداخل أثناء الصعود.',
      'تقويس أسفل الظهر أثناء النزول.',
      'الصعود على أصابع القدم بدلاً من توزيع الوزن على القدم بالكامل.',
    ],
  ),
  ExerciseGuide(
    id: 'deadlift',
    title: 'Conventional Deadlift',
    titleAr: 'ديدليفت تقليدي',
    category: 'gym',
    subCategory: 'Posterior Chain Dominance',
    subCategoryAr: 'تقوية عضلات الجسم الخلفية',
    difficulty: 'Intermediate',
    difficultyAr: 'متوسط',
    muscles: ['Hamstrings', 'Glutes', 'Lats', 'Trapezius', 'Core'],
    musclesAr: [
      'عضلات الفخذ الخلفية',
      'عضلات المؤخرة',
      'عضلات الظهر العريضة',
      'العضلة شبه المنحرفة',
      'عضلات الوسط'
    ],
    burnRate: '200 kcal / 15 mins',
    cues: [
      'Bar directly over mid-foot with shins 1 inch away before setup.',
      'Hinge hips back, grip bar outside legs, pull chest tall to engage lats.',
      'Leg press the floor away until bar passes knees, then thrust hips forward.',
      'Lockout tall with glutes squeezed; do not hyperextend lower spine.',
    ],
    cuesAr: [
      'ضع البار فوق منتصف القدم مباشرة، واترك مسافة بوصة بينه وبين الساقين قبل البدء.',
      'أرجع الحوض للخلف، وامسك البار خارج الرجلين وارفع صدرك لتشغيل عضلات الظهر.',
      'ادفع الأرض بقدميك حتى يمر البار بالركبتين، ثم ادفع الحوض للأمام.',
      'قف منتصباً مع شد المؤخرة، وتجنب المبالغة في تقويس أسفل الظهر.',
    ],
    mistakes: [
      'Pulling with a rounded thoracic or lumbar spine.',
      'Letting the bar drift away from shins during the lift.',
      'Jerking the bar off the floor without taking out the barbell slack.',
    ],
    mistakesAr: [
      'السحب مع تقويس أعلى الظهر أو أسفله.',
      'إبعاد البار عن الساقين أثناء الرفع.',
      'سحب البار من الأرض بعنف دون شدّه أولاً.',
    ],
  ),
  ExerciseGuide(
    id: 'basketball',
    title: 'Basketball Footwork & Plyometrics',
    titleAr: 'حركة القدمين والتمارين الانفجارية لكرة السلة',
    category: 'sport',
    subCategory: 'Agility & Vertical Power',
    subCategoryAr: 'الرشاقة وقوة القفز',
    difficulty: 'Beginner',
    difficultyAr: 'مبتدئ',
    muscles: ['Calves', 'Quadriceps', 'Hip Flexors', 'Cardiovascular Engine'],
    musclesAr: [
      'عضلات السمانة',
      'عضلات الفخذ الأمامية',
      'عضلات ثني الحوض',
      'القلب والتنفس'
    ],
    burnRate: '250 kcal / 20 mins',
    cues: [
      'Maintain low athletic defensive stance with center of gravity centered.',
      'Lead with lead foot on lateral slides; never cross feet while guarding.',
      'Explode upward using triple extension (ankle, knee, hip) for rebounds.',
      'Absorb landing impact through soft knees on balls of the feet.',
    ],
    cuesAr: [
      'حافظ على وضع دفاعي منخفض ومتوازن.',
      'ابدأ بالقدم الأمامية عند التحرك جانبياً، ولا تعبر قدميك أثناء الدفاع.',
      'اقفز بقوة باستخدام مد الكاحل والركبة والحوض لالتقاط الكرة المرتدة.',
      'خفف أثر الهبوط بثني الركبتين والهبوط على مقدمة القدمين.',
    ],
    mistakes: [
      'Standing upright with locked knees on defense.',
      'Landing stiff-legged after vertical jump.',
    ],
    mistakesAr: [
      'الوقوف منتصباً مع فرد الركبتين أثناء الدفاع.',
      'الهبوط برجلين مفرودتين بعد القفز.'
    ],
  ),
  ExerciseGuide(
    id: 'boxing',
    title: 'Boxing Stance, Jab & Hip Torque',
    titleAr: 'وقفة الملاكمة والجاب ودوران الحوض',
    category: 'sport',
    subCategory: 'Rotational Power & Anaerobic HIIT',
    subCategoryAr: 'قوة الدوران والتمارين عالية الشدة',
    difficulty: 'Intermediate',
    difficultyAr: 'متوسط',
    muscles: ['Core Rotators', 'Shoulders', 'Lats', 'Calves'],
    musclesAr: [
      'عضلات دوران الوسط',
      'الكتفان',
      'عضلات الظهر العريضة',
      'عضلات السمانة'
    ],
    burnRate: '280 kcal / 20 mins',
    cues: [
      'Bladed stance with knees soft, hands shielding chin, chin tucked.',
      'Step forward with lead foot while extending jab; snap fist at impact.',
      'Pivot rear foot on cross to transfer full kinetic chain power from hips.',
      'Exhale sharply with each strike to tense core.',
    ],
    cuesAr: [
      'قف بزاوية جانبية مع ثني الركبتين قليلاً، واحمِ ذقنك بيديك وأبقه منخفضاً.',
      'تقدم بالقدم الأمامية أثناء مد لكمة الجاب، واضرب بقبضتك بسرعة.',
      'أدر القدم الخلفية عند اللكمة المستقيمة لنقل القوة من الحوض عبر الجسم.',
      'أخرج الزفير بقوة مع كل لكمة لشد عضلات الوسط.',
    ],
    mistakes: [
      'Dropping the non-punching guard hand.',
      'Overextending head past lead foot, losing balance.',
    ],
    mistakesAr: [
      'إنزال اليد التي لا تضرب عن وضع الحماية.',
      'مد الرأس أمام القدم الأمامية أكثر من اللازم وفقدان التوازن.'
    ],
  ),
  ExerciseGuide(
    id: 'foundations',
    title: 'Start Your Fitness Life (Pillars 101)',
    titleAr: 'ابدأ رحلتك الرياضية: الأساسيات',
    category: 'foundation',
    subCategory: 'Nutrition, Overload & Recovery',
    subCategoryAr: 'التغذية وزيادة الحمل والتعافي',
    difficulty: 'Beginner',
    difficultyAr: 'مبتدئ',
    muscles: ['Full Body Mindset', 'Metabolic Health'],
    musclesAr: ['العناية بالجسم كله', 'صحة التمثيل الغذائي'],
    burnRate: 'Lifetime Knowledge',
    cues: [
      'Target 1.6 - 2.2g of protein per kg of bodyweight to rebuild muscle.',
      'Progressive Overload: Add 1 rep, 1 set, or small weight every 1-2 weeks.',
      'Sleep 7.5 - 9 hours for maximum natural testosterone and growth hormone.',
      'Hydration: Drink 35-40ml water per kg daily + electrolytes for sports.',
    ],
    cuesAr: [
      'استهدف 1.6 - 2.2 جم بروتين لكل كجم من وزن الجسم للمساعدة في بناء العضلات.',
      'زيادة الحمل التدريجية: أضف تكراراً أو مجموعة أو وزناً بسيطاً كل 1-2 أسبوع.',
      'نم 7.5 - 9 ساعات لدعم هرمونات الجسم الطبيعية والتعافي.',
      'اشرب 35-40 مل ماء لكل كجم من وزن الجسم يومياً، مع تعويض الأملاح عند ممارسة الرياضة.',
    ],
    mistakes: [
      'Changing workout routines every week without progressive tracking.',
      'Cutting calories drastically while attempting to build lean muscle.',
    ],
    mistakesAr: [
      'تغيير برنامج التمرين كل أسبوع دون متابعة التقدم.',
      'خفض السعرات بشدة أثناء محاولة بناء العضلات.'
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
