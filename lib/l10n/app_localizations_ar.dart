// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get recipeSignIn => 'سجل الدخول لحفظ المفضلة.';

  @override
  String recipeLoadFavoritesError(String error) {
    return 'تعذر تحميل المفضلة: $error';
  }

  @override
  String recipeSaveFavoriteError(String error) {
    return 'تعذر حفظ الوصفة في المفضلة: $error';
  }

  @override
  String get recipeDeviceSaveError => 'لم يحفظ الجهاز الوصفة في المفضلة.';

  @override
  String recipeLogged(String name, String kcal) {
    return 'تم تسجيل $name ($kcal سعرة)';
  }

  @override
  String recipeLogError(String error) {
    return 'تعذر تسجيل الوصفة: $error';
  }

  @override
  String get recipeDatabaseError => 'تعذر تحميل قاعدة بيانات الطعام.';

  @override
  String get recipeSampleNotice =>
      'وصفات نموذجية. تُحفظ المفضلة على هذا الجهاز.';

  @override
  String get recipeLoadingActivity => 'جارٍ تحميل نشاط اليوم...';

  @override
  String get recipeActivityUnavailable => 'نشاط اليوم غير متاح.';

  @override
  String get recipeTargetUnavailable => 'الهدف اليومي غير متاح.';

  @override
  String recipeRemaining(String kcal, String protein) {
    return 'المتبقي اليوم: $kcal سعرة · $protein جم بروتين';
  }

  @override
  String get recipeTargetReached => 'لقد وصلت إلى هدف اليوم';

  @override
  String get recipeBestFit => 'الأنسب لليوم';

  @override
  String get recipeAll => 'كل الوصفات';

  @override
  String get recipeFilterAll => 'الكل';

  @override
  String get recipeFits => 'تناسب اليوم';

  @override
  String get recipeHighProtein => 'غنية بالبروتين';

  @override
  String get recipeHighFiber => 'غنية بالألياف';

  @override
  String get recipeLight => 'خفيفة';

  @override
  String get recipeQuick => 'سريعة';

  @override
  String get recipeRetryFavorites => 'إعادة تحميل المفضلة';

  @override
  String get recipeNoMatches => 'لا توجد وصفات تطابق هذا الفلتر.';

  @override
  String get recipeRemoveFavorite => 'إزالة من المفضلة';

  @override
  String get recipeAddFavorite => 'إضافة إلى المفضلة';

  @override
  String recipeKcal(String amount) {
    return '$amount سعرة';
  }

  @override
  String recipeMacro(String amount, String macro) {
    return '$amount جم $macro';
  }

  @override
  String recipeSummary(String minutes, String difficulty, String meal) {
    return '$minutes دقيقة · $difficulty · $meal';
  }

  @override
  String get recipeDifficultyEasy => 'سهلة';

  @override
  String get recipeDifficultyEasyMedium => 'سهلة إلى متوسطة';

  @override
  String get recipeDifficultyInstant => 'فورية';

  @override
  String get recipeEstimated => 'تقدير حسب المكونات';

  @override
  String recipeOver(String kcal) {
    return 'تتجاوز المتبقي بـ $kcal سعرة';
  }

  @override
  String get recipeNutritionUnavailable => 'المعلومات الغذائية غير متاحة';

  @override
  String get recipeLogging => 'جارٍ التسجيل...';

  @override
  String get recipeLog => 'تسجيل';

  @override
  String get recipePhotosError => 'تعذر تحميل صور الوصفات.';

  @override
  String get recipePhotoIllustration => 'الصورة للتوضيح';

  @override
  String recipePhotoCredit(String credit) {
    return 'الصورة: $credit';
  }

  @override
  String get recipeDetails => 'تفاصيل الوصفة';

  @override
  String get recipeNutritionPerServing => 'القيم الغذائية للحصة';

  @override
  String recipeMacroLine(String protein, String carbs, String fat) {
    return 'بروتين $protein جم · كربوهيدرات $carbs جم · دهون $fat جم';
  }

  @override
  String recipeMicroLine(String fiber, String sugar, String sodium) {
    return 'ألياف $fiber جم · سكر $sugar جم · صوديوم $sodium مجم';
  }

  @override
  String get recipeIngredients => 'المكونات';

  @override
  String recipeIngredientAmount(String name, String amount) {
    return '$name: $amount جم';
  }

  @override
  String get recipeIngredientUnavailable => 'تفاصيل المكونات غير متاحة.';

  @override
  String get recipeHowToCook => 'طريقة التحضير';

  @override
  String recipeStep(String number, String step) {
    return '$number. $step';
  }

  @override
  String get cravingLogin => 'يرجى تسجيل الدخول مرة أخرى.';

  @override
  String cravingLoadError(String error) {
    return 'تعذر تحميل الرغبات: $error';
  }

  @override
  String cravingLimitError(String error) {
    return 'يحتوي الشهر المحدد بالفعل على رغبتين. $error';
  }

  @override
  String cravingSaveError(String error) {
    return 'تعذر الحفظ: $error';
  }

  @override
  String get cravingValidate => 'أدخل من 1 إلى 200 حرف.';

  @override
  String get cravingDeleteTitle => 'حذف الرغبة؟';

  @override
  String get cravingPreviousMonth => 'الشهر السابق';

  @override
  String get cravingNextMonth => 'الشهر التالي';

  @override
  String get cravingMonday => 'ن';

  @override
  String get cravingTuesday => 'ث';

  @override
  String get cravingWednesday => 'ر';

  @override
  String get cravingThursday => 'خ';

  @override
  String get cravingFriday => 'ج';

  @override
  String get cravingSaturday => 'س';

  @override
  String get cravingSunday => 'ح';

  @override
  String cravingUsed(String count) {
    return 'استخدمت $count من 2 هذا الشهر';
  }

  @override
  String get cravingMonthlyLimit =>
      'بلغت الحد الشهري. عدّل أو احذف إدخالاً لإضافة آخر.';

  @override
  String cravingDay(String day) {
    return 'رغبة يوم $day';
  }

  @override
  String get cravingCharacters => 'من 1 إلى 200 حرف';

  @override
  String get cravingAdd => 'إضافة رغبة';

  @override
  String get cravingEmpty => 'لم تضف أي وجبات بعد.';

  @override
  String get cravingEdit => 'تعديل';

  @override
  String get cravingEditTitle => 'تعديل الرغبة';

  @override
  String get cravingNotes => 'ملاحظات';

  @override
  String cravingDate(String date) {
    return 'التاريخ: $date';
  }

  @override
  String get academyAllGuides => 'كل الأدلة';

  @override
  String get academyGymLifts => 'تمارين الحديد';

  @override
  String get academySportMechanics => 'مهارات الرياضة';

  @override
  String get academyStarterRules => 'أساسيات البداية';

  @override
  String get academyDisclaimer =>
      'معلومات عامة وليست نصيحة متخصصة. استشر مدرباً مؤهلاً أو طبيباً.';

  @override
  String get academyCues => 'إرشادات التنفيذ الأساسية';

  @override
  String get academyMistakes => 'أخطاء شائعة يجب تجنبها';

  @override
  String get academyMastered => 'فهمت الإرشادات';

  @override
  String get academySubtitle =>
      'دروس في حركة تمارين الحديد والإعداد الرياضي وأساسيات اللياقة.';

  @override
  String get academySearch =>
      'ابحث عن البنش أو السكوات أو كرة السلة أو التغذية...';

  @override
  String get academyEmpty => 'لا توجد أدلة تطابق بحثك.';

  @override
  String academyMuscles(String muscles) {
    return 'العضلات: $muscles';
  }

  @override
  String academyBurn(String kcal, String minutes) {
    return 'حوالي $kcal سعرة / $minutes دقيقة';
  }

  @override
  String get academyLifetime => 'معرفة مدى الحياة';

  @override
  String get academyLearn => 'تعلّم';

  @override
  String get plannerTitle => 'منظم الخطة';

  @override
  String get plannerSubtitle => 'التقويم الأسبوعي وجدول التمارين';

  @override
  String get plannerCancel => 'إلغاء';

  @override
  String get plannerDelete => 'حذف';

  @override
  String get plannerSave => 'حفظ';

  @override
  String get plannerRetry => 'إعادة المحاولة';

  @override
  String get plannerAddSplit => 'إضافة تقسيمة';

  @override
  String get plannerEditSplit => 'تعديل التقسيمة';

  @override
  String get plannerEditDay => 'تعديل هذا اليوم';

  @override
  String get plannerPlanDay => 'خطط لهذا اليوم';

  @override
  String get plannerRestDay => 'يوم راحة';

  @override
  String get plannerRest => 'راحة';

  @override
  String get plannerWorkout => 'تمرين';

  @override
  String get plannerSplitUnavailable => 'التقسيمة لم تعد متاحة.';

  @override
  String get plannerLogOnlyToday => 'يمكن تسجيل التمرين في يومه فقط.';

  @override
  String get plannerPreviousWeek => 'الأسبوع السابق';

  @override
  String get plannerNextWeek => 'الأسبوع التالي';

  @override
  String get plannerPlannedWorkout => 'تمرين مخطط';

  @override
  String get plannerCompletedWorkout => 'تمرين مكتمل';

  @override
  String get plannerRestLegend => '— يوم راحة';

  @override
  String get plannerNothingPlanned => 'لا توجد خطة لهذا اليوم.';

  @override
  String get plannerWorkoutLogged => 'تم تسجيل التمرين';

  @override
  String get plannerWorkoutNotLogged => 'لم يُسجل التمرين';

  @override
  String get plannerRemove => 'إزالة';

  @override
  String get plannerRemoveDayTitle => 'إزالة خطة اليوم؟';

  @override
  String get plannerRemoveDayDetails => 'لن يُحذف أي تمرين مسجل.';

  @override
  String get plannerLogWorkout => 'سجل هذا التمرين';

  @override
  String get plannerAvailableOnDay => 'متاح في يوم التمرين';

  @override
  String get plannerMySplits => 'تقسيماتي';

  @override
  String get plannerNoSplits =>
      'لا توجد تقسيمات بعد. أنشئ تقسيمة أو أضف تقسيمات جاهزة.';

  @override
  String get plannerCreateFirst => 'أنشئ أول تقسيمة';

  @override
  String get plannerAddStarters => 'أضف تقسيمات جاهزة';

  @override
  String get plannerDeleteDetails => 'ستبقى الأيام المخططة كما هي.';

  @override
  String get plannerDeleteExplanation =>
      'عند حذف تقسيمة، تبقى الأيام المخططة كما هي.';

  @override
  String get plannerToday => 'اليوم';

  @override
  String get plannerName => 'الاسم';

  @override
  String get plannerType => 'النوع';

  @override
  String get plannerDuration => 'المدة (بالدقائق)';

  @override
  String get plannerDurationHint => 'من 1 إلى 600 دقيقة';

  @override
  String get plannerEffort => 'المجهود (%)';

  @override
  String get plannerEffortHint => 'من 0 إلى 100';

  @override
  String get plannerInvalidName => 'أدخل اسماً من 1 إلى 100 حرف.';

  @override
  String get plannerInvalidDuration => 'أدخل مدة من 1 إلى 600 دقيقة.';

  @override
  String get plannerInvalidEffort => 'أدخل مجهوداً من 0 إلى 100%.';

  @override
  String get plannerPush => 'دفع';

  @override
  String get plannerPull => 'سحب';

  @override
  String get plannerLegs => 'ساقين';

  @override
  String plannerSaveError(String error) {
    return 'تعذر الحفظ: $error';
  }

  @override
  String plannerLoadError(String error) {
    return 'تعذر تحميل الخطة: $error';
  }

  @override
  String plannerOpenError(String error) {
    return 'تعذر فتح تسجيل التمرين: $error';
  }

  @override
  String plannerSelectedDay(String date) {
    return 'اليوم المحدد: $date';
  }

  @override
  String plannerWorkoutSummary(String minutes, String effort) {
    return 'تمرين · $minutes دقيقة · مجهود $effort%';
  }

  @override
  String plannerSplitSummary(String minutes, String effort) {
    return '$minutes دقيقة · مجهود $effort%';
  }

  @override
  String plannerEditName(String name) {
    return 'تعديل $name';
  }

  @override
  String plannerDeleteName(String name) {
    return 'حذف $name';
  }

  @override
  String plannerDeleteQuestion(String name) {
    return 'هل تريد حذف $name؟';
  }

  @override
  String get splitPushDay => 'تمرين الدفع';

  @override
  String get splitPullDay => 'تمرين السحب';

  @override
  String get splitLegDay => 'تمرين تضخيم الساقين';

  @override
  String get splitUpper => 'قوة الجزء العلوي';

  @override
  String get splitCalisthenics => 'تمارين وزن الجسم والجذع';

  @override
  String get splitOlympic => 'رفع الأثقال الأولمبي';

  @override
  String get sportBasketball => 'كرة السلة';

  @override
  String get sportFootball => 'كرة القدم';

  @override
  String get sportTennis => 'التنس';

  @override
  String get sportBoxing => 'الملاكمة والفنون القتالية';

  @override
  String get sportSwimming => 'السباحة';

  @override
  String get sportSprints => 'فترات العدو السريع';

  @override
  String get intensityLight => 'خفيف';

  @override
  String get intensityModerate => 'متوسط';

  @override
  String get intensityVigorous => 'شديد';

  @override
  String get mergeTitle => 'دمج التمارين والرياضات';

  @override
  String get mergeSubtitle => 'اجمع تقسيمات النادي مع الرياضات اليومية.';

  @override
  String get mergeManage => 'إدارة التقسيمات';

  @override
  String get mergeSignIn => 'يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get mergeInvalidTotal => 'أدخل مددًا صحيحة بمجموع من 1 إلى 600 دقيقة.';

  @override
  String get mergeNameTooLong => 'يجب ألا يزيد الاسم المدمج على 100 حرف.';

  @override
  String get mergeReplaceTitle => 'استبدال الخطة الحالية؟';

  @override
  String get mergeReplace => 'استبدال';

  @override
  String get mergeSuccess => 'تمت إضافة الخطة بنجاح.';

  @override
  String get mergeWorkoutSplit => 'تقسيمة التمرين';

  @override
  String get mergeSplit => 'التقسيمة';

  @override
  String get mergeSport => 'الرياضة';

  @override
  String get mergeUnavailable => 'غير متاح';

  @override
  String get mergeInvalidDuration => 'مدة غير صالحة';

  @override
  String get mergeSprintEstimate =>
      'تستخدم فترات العدو السريع تقدير التمرين المتقطع أو الدائري.';

  @override
  String get mergeAddWeight => 'تقدير السعرات غير متاح - أضف وزنك';

  @override
  String get mergeCompleteProfile => 'أكمل ملفك الشخصي';

  @override
  String get mergeSportUnavailable => 'تقدير السعرات غير متاح لهذه الرياضة.';

  @override
  String get mergeEstimateNote =>
      'التقدير مبني على نوع النشاط ومدته وشدته ووزنك.';

  @override
  String get mergePlanDate => 'خطط في يوم محدد';

  @override
  String get mergeLogWorkout => 'سجل التمرين';

  @override
  String get mergeLogSport => 'سجل الرياضة';

  @override
  String get mergePlannerEffort => 'مجهود الخطة (%)';

  @override
  String get mergeContinue => 'متابعة';

  @override
  String mergeLoadError(String error) {
    return 'تعذر تحميل التقسيمات: $error';
  }

  @override
  String mergePlanError(String error) {
    return 'تعذر التخطيط: $error';
  }

  @override
  String mergeReplaceDetails(String date, String name) {
    return 'توجد بالفعل خطة باسم \"$name\" في $date. هل تريد استبدالها؟';
  }

  @override
  String mergeSavedName(String name) {
    return '$name (تقسيمتي)';
  }

  @override
  String mergeMinutesLabel(String label) {
    return 'مدة $label بالدقائق';
  }

  @override
  String mergeCombinedDuration(String duration) {
    return 'المدة الإجمالية: $duration';
  }

  @override
  String mergeMinutes(String minutes) {
    return '$minutes دقيقة';
  }

  @override
  String mergeShortMinutes(String minutes) {
    return '$minutes دقيقة';
  }

  @override
  String mergeNamedValue(String name, String value) {
    return '$name: $value';
  }

  @override
  String mergeCalories(String calories) {
    return '$calories سعرة';
  }

  @override
  String mergeEstimatedCalories(String value) {
    return 'السعرات المحروقة المقدرة: $value';
  }

  @override
  String mergeDate(String date) {
    return 'التاريخ: $date';
  }

  @override
  String get caloriesSubtitle => 'الوجبات والعناصر الغذائية والنشاط';

  @override
  String get foodLog => 'سجل الطعام';

  @override
  String get activity => 'النشاط';

  @override
  String get foodUnavailable =>
      'لم يعد هذا الطعام متاحًا في قاعدة البيانات. لم تتغير الوجبة.';

  @override
  String foodOpenError(String error) {
    return 'تعذر فتح الطعام: $error';
  }

  @override
  String activitySaveError(String error) {
    return 'تعذر حفظ النشاط: $error';
  }

  @override
  String burnedAmount(String amount) {
    return '$amount سعرة محروقة';
  }

  @override
  String deleteNamed(String name) {
    return 'حذف $name';
  }

  @override
  String get noWorkouts => 'لم تسجل أي تمارين اليوم بعد.';

  @override
  String get manualInvalidCalories => 'أدخل عدد سعرات أكبر من صفر.';

  @override
  String get manualTitle => 'سجل الطعام أو التمرين';

  @override
  String get manualFood => 'الطعام (+)';

  @override
  String get manualBurn => 'حرق التمرين (+)';

  @override
  String get manualFoodHint => 'مثال: شريحة لحم';

  @override
  String get manualBurnHint => 'مثال: رفع الأثقال';

  @override
  String get caloriesKcal => 'السعرات (سعرة)';

  @override
  String get manualProtein => '🔴 بروتين';

  @override
  String get manualCarbs => '🔵 كربوهيدرات';

  @override
  String get manualFats => '🟠 دهون';

  @override
  String get manualGreens => '🟢 خضروات';

  @override
  String get manualStrength => '🟡 قوة / نادي';

  @override
  String get manualCardio => '🔷 كارديو / رياضة';

  @override
  String get manualMobility => '🟢 مرونة / حركة';

  @override
  String get saveActivity => 'حفظ النشاط';

  @override
  String get activityTitle => 'حلقات النشاط والتمارين';

  @override
  String get activitySubtitle => 'تابع التمارين والسعرات المحروقة';

  @override
  String get burned => 'المحروق';

  @override
  String burnTarget(String amount) {
    return '/ هدف $amount سعرة';
  }

  @override
  String get burnGoalNote => 'هدف الحرق اليومي • يشمل الإجمالي تمارين الحركة';

  @override
  String get burnRingNote => 'تستخدم كل حلقة هدف الحرق اليومي.';

  @override
  String totalBurn(String amount) {
    return 'إجمالي الحرق ($amount سعرة)';
  }

  @override
  String strengthBurn(String amount) {
    return 'حرق القوة ($amount سعرة)';
  }

  @override
  String cardioBurn(String amount) {
    return 'حرق الكارديو ($amount سعرة)';
  }

  @override
  String get burnStats => 'إحصاءات الحرق';

  @override
  String get strengthBurnLabel => 'حرق القوة';

  @override
  String get cardioBurnLabel => 'حرق الكارديو';

  @override
  String get burnTypeStrength => 'قوة';

  @override
  String get burnTypeCardio => 'كارديو';

  @override
  String get burnTypeMobility => 'حركة';

  @override
  String workoutLogs(String count) {
    return 'سجل التمارين ($count)';
  }

  @override
  String get workoutInvalidDuration => 'أدخل مدة من 1 إلى 600 دقيقة.';

  @override
  String get workoutInvalidCalories => 'أدخل سعرات من 0 إلى 5000.';

  @override
  String get workoutSaved => 'تم تسجيل التمرين.';

  @override
  String get workoutRefreshError =>
      'تم الحفظ، لكن تعذر تحديث قائمة النشاط. يرجى المحاولة مرة أخرى.';

  @override
  String workoutSaveError(String error) {
    return 'تعذر حفظ التمرين: $error';
  }

  @override
  String get workoutStrength => 'تمارين القوة';

  @override
  String get workoutWalking => 'المشي';

  @override
  String get workoutRunning => 'الجري';

  @override
  String get workoutCycling => 'ركوب الدراجة';

  @override
  String get workoutSwimming => 'السباحة';

  @override
  String get workoutFootball => 'كرة القدم';

  @override
  String get workoutBasketball => 'كرة السلة';

  @override
  String get workoutTennis => 'التنس';

  @override
  String get workoutCircuit => 'تمرين متقطع أو دائري';

  @override
  String get workoutMartialArts => 'الملاكمة أو الفنون القتالية';

  @override
  String get workoutYoga => 'اليوغا أو الإطالة';

  @override
  String get workoutJumpRope => 'نط الحبل';

  @override
  String get workoutOther => 'أخرى';

  @override
  String workoutActivityLabel(String icon, String name) {
    return '$icon $name';
  }

  @override
  String workoutSavedTitle(String name, String minutes) {
    return '$name - $minutes دقيقة';
  }

  @override
  String get justNow => 'الآن';

  @override
  String get workoutIntensity => 'الشدة';

  @override
  String get workoutEstimateUnavailable =>
      'التقدير غير متاح — أدخل السعرات يدويًا.';

  @override
  String workoutEstimate(String amount) {
    return '≈ $amount سعرة محروقة';
  }

  @override
  String get workoutFormula => 'معامل النشاط × الوزن × الساعات';

  @override
  String get workoutEstimateNote => 'السعرات المحروقة تقديرية.';

  @override
  String get workoutManualOther => 'الأنشطة الأخرى تتطلب إدخال السعرات يدويًا.';

  @override
  String get workoutCaloriesEditable => 'السعرات المحروقة (قابلة للتعديل)';

  @override
  String get workoutCaloriesHint => 'من 0 إلى 5000 سعرة';

  @override
  String get workoutUseEstimate => 'استخدم التقدير';

  @override
  String get workoutSaving => 'جارٍ الحفظ...';

  @override
  String get workoutSave => 'حفظ التمرين';

  @override
  String get foodEaten => 'سعرة تم تناولها';

  @override
  String get foodBalance => 'توازن الطاقة اليومي';

  @override
  String get foodTargetUnavailable => 'الهدف غير متاح';

  @override
  String get foodOver => 'سعرة فوق الهدف';

  @override
  String get foodLeft => 'سعرة متبقية';

  @override
  String get foodEstimated => ' • تقديري';

  @override
  String foodGoalSummary(String goal, String estimated, String count) {
    return 'الهدف: $goal$estimated • العناصر المسجلة: $count';
  }

  @override
  String get foodProtein => 'بروتين';

  @override
  String get foodCarbs => 'كربوهيدرات';

  @override
  String get foodFats => 'دهون';

  @override
  String get foodFiber => 'ألياف';

  @override
  String get foodSugar => 'سكر';

  @override
  String get foodSodium => 'صوديوم';

  @override
  String foodGrams(String amount) {
    return '$amount جم';
  }

  @override
  String foodMilligrams(String amount) {
    return '$amount مجم';
  }

  @override
  String foodMacroGoal(String eaten, String goal) {
    return '$eaten / $goal جم';
  }

  @override
  String foodLabelValue(String label, String value) {
    return '$label $value';
  }

  @override
  String get foodAdd => 'إضافة طعام';

  @override
  String get foodCompleteProfile => 'أكمل ملفك الشخصي للحصول على هدف أدق';

  @override
  String get foodDismissReminder => 'إغلاق تذكير الملف الشخصي';

  @override
  String get foodToday => 'سجل طعام اليوم';

  @override
  String get foodAll => 'الكل';

  @override
  String get foodBreakfast => 'الإفطار';

  @override
  String get foodLunch => 'الغداء';

  @override
  String get foodDinner => 'العشاء';

  @override
  String get foodSnacks => 'الوجبات الخفيفة';

  @override
  String get foodSnacksHeading => 'الوجبات الخفيفة والإضافات';

  @override
  String get foodEmpty => 'سجلك اليومي فارغ';

  @override
  String get foodEmptyHint => 'أضف وجبة لبدء التتبع اليوم.';

  @override
  String foodHeading(String icon, String name) {
    return '$icon $name';
  }

  @override
  String foodGroupTotals(String calories, String protein) {
    return '$calories سعرة • $protein جم بروتين';
  }

  @override
  String foodNoItems(String meal) {
    return 'لا توجد عناصر مسجلة في $meal.';
  }

  @override
  String foodUncheck(String name) {
    return 'إلغاء تسجيل $name';
  }

  @override
  String foodLogNamed(String name) {
    return 'تسجيل $name';
  }

  @override
  String get foodManualEntry => 'إدخال يدوي';

  @override
  String foodCustomGrams(String amount) {
    return '$amount جم مخصص';
  }

  @override
  String foodServing(String name, String amount) {
    return '$name ($amount)';
  }

  @override
  String foodProteinShort(String amount) {
    return '$amount بروتين';
  }

  @override
  String foodCarbsShort(String amount) {
    return '$amount كربوهيدرات';
  }

  @override
  String foodFatsShort(String amount) {
    return '$amount دهون';
  }

  @override
  String foodCaloriesLines(String amount) {
    return '$amount\nسعرة';
  }

  @override
  String foodEditPortion(String name) {
    return 'تعديل حصة $name';
  }

  @override
  String foodDuplicate(String name) {
    return 'نسخ $name';
  }

  @override
  String get foodDuplicateUnavailable => 'لم يعد هذا الطعام متاحًا للنسخ.';

  @override
  String get foodSavedRefreshError =>
      'تم حفظ الطعام، لكن تعذر تحديث قائمة النشاط. يرجى المحاولة مرة أخرى.';

  @override
  String get foodDeletedRefreshError =>
      'تم حذف الطعام، لكن تعذر تحديث قائمة النشاط. يرجى المحاولة مرة أخرى.';

  @override
  String get foodDuplicated => 'تم نسخ الطعام.';

  @override
  String get foodDeleted => 'تم حذف الطعام.';

  @override
  String foodDuplicateError(String error) {
    return 'تعذر نسخ الطعام: $error';
  }

  @override
  String foodDeleteError(String error) {
    return 'تعذر حذف الطعام: $error';
  }

  @override
  String foodUpdateError(String error) {
    return 'تعذر تحديث الوجبة: $error';
  }

  @override
  String get explorerLoadError => 'تعذر تحميل قاعدة بيانات الطعام.';

  @override
  String get explorerManual => 'لم تجد طعامك؟ أضفه يدويًا';

  @override
  String get explorerSearch => 'ابحث عن الطعام بالعربية أو الإنجليزية...';

  @override
  String get explorerClear => 'مسح البحث';

  @override
  String explorerShowing(String shown, String total) {
    return 'عرض $shown من $total';
  }

  @override
  String get explorerEmpty => 'لم يتم العثور على أطعمة مطابقة';

  @override
  String get explorerEmptyHint => 'جرب بحثًا آخر أو أزل أحد المرشحات.';

  @override
  String get explorerDisclaimer => 'القيم الغذائية تقديرية وتقريبية.';

  @override
  String explorerPer100(String calories) {
    return 'لكل 100 جم: $calories سعرة';
  }

  @override
  String get explorerLog => '+ تسجيل';

  @override
  String get explorerStandard => 'الكمية القياسية 100 جم';

  @override
  String get explorerInvalidWeight => 'أدخل وزنًا من 1 إلى 3000 جم.';

  @override
  String explorerUpdated(String name) {
    return 'تم تحديث $name.';
  }

  @override
  String explorerLogged(String name, String calories) {
    return 'تم تسجيل $name ($calories سعرة)';
  }

  @override
  String explorerSaveError(String error) {
    return 'تعذر حفظ الطعام: $error';
  }

  @override
  String get explorerPortions => 'حصص منزلية وحصص المطاعم';

  @override
  String get explorerExactWeight => 'الوزن الدقيق (جم)';

  @override
  String get unitGrams => 'جم';

  @override
  String explorerNutrient(String name, String amount) {
    return '$name: $amount';
  }

  @override
  String get explorerMeal => 'التسجيل في الوجبة';

  @override
  String get explorerAdd => '+ إضافة إلى السجل اليومي';

  @override
  String get explorerSaveChanges => 'حفظ التغييرات';

  @override
  String get foodFat => 'دهون';

  @override
  String get foodSnackSingular => 'وجبة خفيفة';

  @override
  String get groupAmerican => 'أمريكي ولاتيني';

  @override
  String get groupAsian => 'آسيوي';

  @override
  String get groupCafes => 'المقاهي والمخابز';

  @override
  String get groupEgyptian => 'مصري';

  @override
  String get groupEuropean => 'أوروبي';

  @override
  String get groupMiddleEastern => 'الشرق الأوسط وأفريقيا';

  @override
  String get groupRaw => 'مكونات خام وأطعمة رياضية';

  @override
  String get groupRestaurants => 'المطاعم والوجبات السريعة';

  @override
  String get groupSnacks => 'وجبات خفيفة';

  @override
  String get tagProtein => 'عالي البروتين';

  @override
  String get tagFitness => 'أطعمة رياضية';

  @override
  String get tagStreet => 'طعام الشارع';

  @override
  String get tagVegan => 'نباتي';

  @override
  String get tagKeto => 'مناسب للكيتو';

  @override
  String get tagLowCarb => 'قليل الكربوهيدرات';

  @override
  String get tagOils => 'زيوت';

  @override
  String get tagToppings => 'إضافات';

  @override
  String get tagDesserts => 'حلويات';

  @override
  String get tagRaw => 'نيء';

  @override
  String get tagCooked => 'مطبوخ';

  @override
  String get profileInvalid =>
      'أدخل تاريخ ميلاد صحيحًا (العمر 13–100)، والجنس والنشاط والوزن (30–300 كجم) والطول (120–230 سم).';

  @override
  String profileSaveError(String error) {
    return 'تعذر حفظ ملفك الشخصي. حاول مرة أخرى.';
  }

  @override
  String get profileWeight => 'الوزن (كجم)';

  @override
  String get profileHeight => 'الطول (سم)';

  @override
  String get profileChooseBirth => 'اختر تاريخ الميلاد';

  @override
  String profileBirth(String date) {
    return 'تاريخ الميلاد: $date';
  }

  @override
  String get profileSex => 'الجنس لحساب التقدير';

  @override
  String get profileMale => 'ذكر';

  @override
  String get profileFemale => 'أنثى';

  @override
  String get profileUnspecified => 'أفضل عدم الإفصاح';

  @override
  String get profileActivity => 'مستوى النشاط';

  @override
  String get profileSedentary => 'قليل الحركة';

  @override
  String get profileSedentaryDescription => 'جلوس معظم الوقت وتمارين قليلة.';

  @override
  String get profileLightDescription => 'تمارين خفيفة 1–3 أيام أسبوعيًا.';

  @override
  String get profileModerateDescription => 'تمارين 3–5 أيام أسبوعيًا.';

  @override
  String get profileVeryActive => 'نشط جدًا';

  @override
  String get profileVeryActiveDescription => 'تمارين شاقة 6–7 أيام أسبوعيًا.';

  @override
  String get profileAthlete => 'رياضي';

  @override
  String get profileAthleteDescription => 'تدريب يومي مكثف أو عمل بدني شاق.';

  @override
  String profileTarget(String target, String estimated) {
    return 'هدفك اليومي: $target$estimated';
  }

  @override
  String profileBmr(String bmr, String maintenance) {
    return 'الأيض الأساسي: $bmr • الاحتياج للمحافظة: $maintenance';
  }

  @override
  String get profileCompleteFields => 'أكمل جميع الحقول للحصول على تقدير شخصي.';

  @override
  String profileAdjustment(String amount, String minor) {
    return 'تعديل الهدف: $amount سعرة$minor';
  }

  @override
  String get profileMinor => ' (المحافظة لمن هم دون 18 عامًا)';

  @override
  String get profileDisclaimer => 'التقديرات ليست نصيحة طبية.';

  @override
  String get profileSave => 'حفظ الملف';

  @override
  String get memberFree => 'مجانية';

  @override
  String get memberSilver => 'فضية';

  @override
  String get memberGold => 'ذهبية';

  @override
  String get membershipTitle => 'عضوية بريفيلج';

  @override
  String get membershipLoading => 'جارٍ تحميل العضوية...';

  @override
  String get membershipUnavailable => 'العضوية غير متاحة';

  @override
  String get membershipUnavailableConnection =>
      'العضوية غير متاحة. تحقق من اتصالك.';

  @override
  String membershipCurrent(String tier) {
    return 'العضوية الحالية: $tier';
  }

  @override
  String membershipProfile(String tier) {
    return 'عضوية بريفيلج $tier';
  }

  @override
  String get membershipRetry => 'إعادة تحميل العضوية';

  @override
  String get membershipBenefits => 'المتاح في التطبيق';

  @override
  String get membershipFood => 'تسجيل الطعام والتمارين';

  @override
  String get membershipCommunity => 'المجتمع ومتابعة الاستمرارية';

  @override
  String get membershipAcademy => 'أدلة تمارين الأكاديمية';

  @override
  String get membershipRewards => 'المكافآت والإنجازات';

  @override
  String get membershipSplits => 'إنشاء التقسيمات الخاصة وحفظها';

  @override
  String membershipBenefit(String benefit) {
    return '• $benefit';
  }

  @override
  String get membershipComingSoon => 'قريبًا. الدفع غير متاح بعد.';

  @override
  String get profileTitle => 'ملف الرياضي';

  @override
  String get profileEdit => 'تعديل الملف';

  @override
  String get profileUpdated => 'تم تحديث الملف بنجاح!';

  @override
  String get profileFullName => 'الاسم الكامل';

  @override
  String get profileFullNameHint => 'الاسم الكامل';

  @override
  String get profileGoal => 'الهدف';

  @override
  String get profileChooseGoal => 'اختر هدفًا';

  @override
  String get profileBio => 'نبذة عنك';

  @override
  String profileHandle(String username) {
    return '@$username';
  }

  @override
  String get profileSaveChanges => 'حفظ التغييرات';

  @override
  String get profileAddBio => 'أضف نبذة عنك';

  @override
  String profileQuotedBio(String bio) {
    return '“$bio”';
  }

  @override
  String get profileCurrentWeight => 'الوزن الحالي';

  @override
  String get profileHeightLabel => 'الطول';

  @override
  String get profileCalorieGoal => 'هدف السعرات';

  @override
  String get profileNotSet => 'غير محدد';

  @override
  String profileKg(String amount) {
    return '$amount كجم';
  }

  @override
  String profileCm(String amount) {
    return '$amount سم';
  }

  @override
  String profileCalorieValue(String amount, String estimated) {
    return '$amount$estimated';
  }

  @override
  String get profileCompleteCalorie => 'أكمل ملف السعرات';

  @override
  String get profileEditCalorie => 'تعديل ملف السعرات';

  @override
  String get profileRewards => 'متجر المكافآت';

  @override
  String get profileBadges => 'الشارات والإنجازات';

  @override
  String get profileActiveTarget => 'الهدف الحالي:';

  @override
  String get profileTrack => 'تابع ←';

  @override
  String get profileSignOut => 'تسجيل الخروج من بريفيلج';

  @override
  String get alertsUnavailable => 'التنبيهات (التحديثات غير متاحة)';

  @override
  String get alertsTitle => 'التنبيهات';

  @override
  String get alertsTryAgain => 'حاول مرة أخرى';

  @override
  String get notificationSettings => 'إعدادات التنبيهات';

  @override
  String get alertsMarkRead => 'تحديد الكل كمقروء';

  @override
  String get alertsEmpty => 'لا توجد تنبيهات جديدة.';

  @override
  String get alertsGroupMissing => 'هذه المجموعة لم تعد متاحة.';

  @override
  String get alertsNoDestination => 'لا توجد وجهة لهذا التنبيه.';

  @override
  String get alertsLikes => 'الإعجابات';

  @override
  String get alertsComments => 'التعليقات';

  @override
  String get alertsFriendPosts => 'منشورات الأصدقاء';

  @override
  String get alertsFriendRequests => 'طلبات الصداقة والقبول والمتابعات';

  @override
  String get alertSomeone => 'شخص ما';

  @override
  String alertFriendRequest(String name) {
    return 'أرسل إليك $name طلب صداقة.';
  }

  @override
  String alertFriendAccepted(String name) {
    return 'قبل $name طلب صداقتك.';
  }

  @override
  String alertCommentBody(String name, String body) {
    return 'علّق $name: $body';
  }

  @override
  String alertComment(String name) {
    return 'علّق $name على منشورك.';
  }

  @override
  String alertPostLike(String name) {
    return 'أعجب $name بمنشورك.';
  }

  @override
  String alertCommentLike(String name) {
    return 'أعجب $name بتعليقك.';
  }

  @override
  String alertFollow(String name) {
    return 'بدأ $name بمتابعتك.';
  }

  @override
  String alertFriendPost(String name) {
    return 'شارك $name منشورًا جديدًا.';
  }

  @override
  String alertChallengeInvite(String name) {
    return 'دعاك $name إلى تحدٍ.';
  }

  @override
  String get alertChallengeResult => 'نتائج التحدي جاهزة.';

  @override
  String get alertBadge => 'حصلت على شارة!';

  @override
  String get alertAchievement => 'حققت إنجازًا!';

  @override
  String get alertLevel => 'وصلت إلى مستوى جديد!';

  @override
  String get alertReward => 'تم استبدال مكافأتك.';

  @override
  String alertGroupRequest(String name) {
    return 'طلب $name الانضمام إلى مجموعتك.';
  }

  @override
  String alertGroupApproved(String name) {
    return 'وافق $name على طلبك للانضمام إلى المجموعة.';
  }

  @override
  String alertGroupRemoved(String name) {
    return 'أزالك $name من مجموعة.';
  }

  @override
  String alertGroupBanned(String name) {
    return 'حظرك $name من مجموعة.';
  }

  @override
  String alertGroupInvited(String name) {
    return 'دعاك $name إلى مجموعة.';
  }

  @override
  String get alertUnknown => 'لديك تنبيه جديد.';

  @override
  String get progressLoadError => 'تعذر تحميل التقدم. تحقق من اتصالك.';

  @override
  String get progressNoLevels => 'لا توجد مستويات متاحة بعد.';

  @override
  String get levelBeginner => 'مبتدئ';

  @override
  String get levelIntermediate => 'متوسط';

  @override
  String get levelPro => 'محترف';

  @override
  String get levelBronze => 'برونزي';

  @override
  String get levelSilver => 'فضي';

  @override
  String get levelGold => 'ذهبي';

  @override
  String get levelPlatinum => 'بلاتيني';

  @override
  String get levelDiamond => 'ماسي';

  @override
  String get levelElite => 'النخبة';

  @override
  String get levelChampion => 'بطل';

  @override
  String progressLevel(String name) {
    return 'المستوى: $name';
  }

  @override
  String progressHighest(String xp) {
    return '$xp نقطة خبرة · أعلى مستوى';
  }

  @override
  String progressNext(String xp, String remaining, String name) {
    return '$xp نقطة خبرة · تبقى $remaining نقطة للوصول إلى $name';
  }

  @override
  String progressFreeze(String count) {
    return 'رموز التجميد: $count';
  }

  @override
  String progressPoints(String count) {
    return '$count نقطة في المتجر';
  }

  @override
  String rewardConfirm(String name) {
    return 'استبدال $name؟';
  }

  @override
  String rewardSpend(String count) {
    return 'استخدام $count نقطة من المتجر؟';
  }

  @override
  String get rewardRedeem => 'استبدال';

  @override
  String get rewardRequestSaveError => 'تعذر حفظ طلب الاستبدال.';

  @override
  String get rewardRequestClearError => 'تعذر مسح طلب الاستبدال المكتمل.';

  @override
  String get rewardDone => 'تم استبدال المكافأة.';

  @override
  String rewardFreezeCount(String count) {
    return 'رموز التجميد: $count / 3';
  }

  @override
  String get rewardInfo =>
      'عناصر رقمية فقط. تُحفظ السمات والإطارات والألقاب ضمن مكافآتك؛ تطبيقها غير متاح بعد.';

  @override
  String get rewardEmpty => 'لا توجد مكافآت متاحة حاليًا.';

  @override
  String get rewardUnlimited => 'مخزون غير محدود';

  @override
  String rewardRemaining(String count) {
    return 'المتبقي $count';
  }

  @override
  String rewardDetails(String cost, String tier, String stock) {
    return '$cost نقطة · الفئة $tier · $stock';
  }

  @override
  String rewardRequires(String tier) {
    return 'يتطلب الفئة $tier';
  }

  @override
  String rewardNeedPoints(String count) {
    return 'تحتاج إلى $count نقطة إضافية';
  }

  @override
  String get rewardRedeeming => 'جارٍ الاستبدال...';

  @override
  String get rewardOwned => 'تمتلكها';

  @override
  String get rewardOutOfStock => 'نفد المخزون';

  @override
  String get rewardErrorPoints => 'نقاط المتجر غير كافية.';

  @override
  String get rewardErrorStock => 'نفد مخزون هذه المكافأة.';

  @override
  String get rewardErrorTier => 'فئة عضويتك لا تؤهلك لهذه المكافأة.';

  @override
  String get rewardErrorTokens => 'يمكنك امتلاك 3 رموز تجميد كحد أقصى.';

  @override
  String get rewardErrorOwned => 'تمتلك هذا العنصر بالفعل.';

  @override
  String get rewardErrorUnavailable => 'لم تعد هذه المكافأة متاحة.';

  @override
  String get rewardErrorGeneral =>
      'تعذر تأكيد الاستبدال. تحقق من اتصالك وحاول مجددًا.';

  @override
  String get progressBadges => 'الشارات';

  @override
  String get progressNoBadges => 'لا توجد شارات متاحة بعد.';

  @override
  String get progressEarned => 'مكتسبة';

  @override
  String get progressLocked => 'مقفلة';

  @override
  String progressBadgeDetails(String description, String status) {
    return '$description\n$status';
  }

  @override
  String get progressAchievements => 'الإنجازات';

  @override
  String get progressNoAchievements => 'لا توجد إنجازات متاحة بعد.';

  @override
  String progressAchievementValue(
      String progress, String threshold, String xp) {
    return '$progress / $threshold · $xp نقطة خبرة';
  }

  @override
  String get progressCompleted => 'مكتمل';

  @override
  String pathSaveError(String error) {
    return 'تعذر حفظ قائمة المتابعة: $error';
  }

  @override
  String pathTracked(String value) {
    return 'يتابعه التطبيق · $value';
  }

  @override
  String get pathSelfReported => 'أبلغت عنه بنفسك، غير موثق';

  @override
  String get pathOutside => 'يتم خارج التطبيق';

  @override
  String get pathLoading => 'جارٍ التحميل';

  @override
  String get pathTitle => 'مسارك';

  @override
  String get pathDisclaimer => 'التقدم مُبلغ عنه ذاتيًا، وغير موثق أو معتمد';

  @override
  String get pathLoadingChecks => 'جارٍ تحميل قائمة المتابعة...';

  @override
  String pathLoadError(String error) {
    return 'تعذر تحميل قائمة المتابعة: $error';
  }

  @override
  String get pathFoundation => 'الأساس';

  @override
  String get pathLongestStreak => 'أطول سلسلة استمرارية';

  @override
  String pathDays(String days) {
    return '$days يوم';
  }

  @override
  String get pathSetGoal => 'حدد هدفًا شخصيًا للتدريب';

  @override
  String get pathLearnBasics => 'تعلم أساسيات رياضتك المختارة';

  @override
  String get pathNovice => 'المبتدئ';

  @override
  String get pathWorkouts => 'التمارين المسجلة منذ البداية';

  @override
  String get pathRoutine => 'التزم بروتين منتظم';

  @override
  String get pathCoach => 'اطلب ملاحظات من مدرب مؤهل';

  @override
  String get pathCompetitor => 'الاستعداد للمنافسة';

  @override
  String get pathMeals => 'الوجبات المتناولة المسجلة منذ البداية';

  @override
  String get pathSkills => 'تدرب على مهارات المنافسة';

  @override
  String get pathRequirements => 'راجع متطلبات منظم الحدث';

  @override
  String get pathNational => 'المستوى الوطني';

  @override
  String get pathAppLevel => 'مستوى التطبيق';

  @override
  String get pathNotAvailable => 'غير متاح';

  @override
  String get pathMilestone => 'خطط لمرحلة التدريب التالية';

  @override
  String get pathEvents => 'استكشف الفعاليات الوطنية وقواعدها';

  @override
  String get pathPro => 'مسار الاحتراف';

  @override
  String get pathPreparation => 'ضع خطة استعداد طويلة المدى';

  @override
  String get pathResearch => 'ابحث عن المسار الرسمي لرياضتك';

  @override
  String get pathRegister =>
      'للتسجيل: راجع الموقع الرسمي للمنظم لمعرفة القواعد وطريقة التسجيل';

  @override
  String plannerWeekRange(String start, String end) {
    return 'من $start إلى $end';
  }

  @override
  String get language => 'Language / اللغة';

  @override
  String get languageError => 'تعذر حفظ اللغة. حاول مرة أخرى.';

  @override
  String get settings => 'الإعدادات';

  @override
  String get settingsSubtitle => 'اجعل بريفيلج يناسبك';

  @override
  String get profilePhoto => 'الصورة الشخصية';

  @override
  String get photoPrivate => 'محفوظة بشكل خاص على هذا الجهاز';

  @override
  String get opening => 'جارٍ الفتح…';

  @override
  String get changePhoto => 'تغيير الصورة';

  @override
  String get remove => 'إزالة';

  @override
  String get appearance => 'مظهر التطبيق';

  @override
  String get chooseTheme => 'اختر ألوان التطبيق';

  @override
  String get savedDevice => 'يُحفظ اختيارك على هذا الجهاز.';

  @override
  String get choosePhotos => 'اختر من الصور';

  @override
  String get takePhoto => 'التقط صورة';

  @override
  String get smallerPhoto => 'اختر صورة أصغر من 900 كيلوبايت.';

  @override
  String get photoUpdated => 'تم تحديث الصورة الشخصية.';

  @override
  String get photoRemoved => 'تمت إزالة الصورة الشخصية.';

  @override
  String get cameraError => 'تعذر فتح الكاميرا أو مكتبة الصور.';

  @override
  String get savePhotoError => 'تعذر حفظ الصورة الشخصية.';

  @override
  String get saveThemeError => 'تعذر حفظ المظهر.';

  @override
  String get themePrivilege => 'بريفيلج';

  @override
  String get themeOcean => 'المحيط العميق';

  @override
  String get themeForest => 'الغابة الخضراء';

  @override
  String get themeViolet => 'البنفسجي';

  @override
  String get themePrivilegeDescription => 'أحمر حيوي بلمسة ذهبية';

  @override
  String get themeOceanDescription => 'أزرق داكن مع لون مائي مشرق';

  @override
  String get themeForestDescription => 'أخضر داكن مع لمسة نعناع';

  @override
  String get themeVioletDescription => 'بنفسجي داكن بلمسة مشرقة';

  @override
  String get home => 'الرئيسية';

  @override
  String get splits => 'التمارين';

  @override
  String get calories => 'السعرات';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get community => 'المجتمع';

  @override
  String get recipes => 'الوصفات';

  @override
  String get arena => 'ساحة التحديات';

  @override
  String get cheatMeals => 'وجبات المكافأة';

  @override
  String get cravingsTitle => 'الرغبات والمكافآت';

  @override
  String get classified => 'المستوى المصنف';

  @override
  String get academy => 'الأكاديمية';

  @override
  String get academyTitle => 'أكاديمية اللياقة';

  @override
  String get vipPlans => 'خطط VIP';

  @override
  String get botTooltip => 'مدرب بريفيلج الذكي';

  @override
  String get createYourAccount => 'أنشئ حسابك';

  @override
  String get welcomeBack => 'مرحباً بعودتك';

  @override
  String get createAccountDescription =>
      'أنشئ حساباً ببريدك الإلكتروني وكلمة المرور.';

  @override
  String get loginDescription => 'سجّل الدخول ببريدك الإلكتروني وكلمة المرور.';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get passwordHint => 'استخدم 8-72 حرفاً مع حرف ورقم واحد على الأقل.';

  @override
  String get pleaseWait => 'يرجى الانتظار…';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get logIn => 'تسجيل الدخول';

  @override
  String get alreadyAccount => 'لديك حساب؟ سجّل الدخول';

  @override
  String get newAccount => 'جديد هنا؟ أنشئ حساباً';

  @override
  String get loginUnavailableFeatures =>
      'ستتوفر إعادة تعيين كلمة المرور وتسجيل الدخول الاجتماعي بعد الإعداد.';

  @override
  String get invalidEmail => 'أدخل بريداً إلكترونياً صالحاً.';

  @override
  String get enterPassword => 'أدخل كلمة المرور.';

  @override
  String get invalidPassword =>
      'يجب أن تتكون كلمة المرور من 8-72 حرفاً وتحتوي على حرف ورقم.';

  @override
  String get passwordMismatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get invalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get emailNotConfirmed =>
      'يرجى تأكيد بريدك الإلكتروني قبل تسجيل الدخول.';

  @override
  String get networkError => 'تعذر الاتصال. تحقق من الإنترنت وحاول مرة أخرى.';

  @override
  String get signInError => 'تعذر تسجيل الدخول الآن. حاول مرة أخرى.';

  @override
  String get registrationError => 'تعذر تسجيل الدخول. حاول مرة أخرى.';

  @override
  String get registrationCreated => 'تم إنشاء الحساب. سجّل الدخول للمتابعة.';

  @override
  String get registrationConfirm =>
      'إذا كان بالإمكان تسجيل هذا البريد، تحقق من رسالة التأكيد ثم سجّل الدخول.';

  @override
  String get setupTitle => 'إعداد أهدافك الرياضية';

  @override
  String get setupSubtitle => 'خصص تمارينك وأهداف السعرات';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get exampleName => 'مثال: أحمد محمد';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get usernameHint => 'حروف إنجليزية وأرقام وشرطة سفلية';

  @override
  String get weight => 'الوزن';

  @override
  String get height => 'الطول';

  @override
  String get primaryGoal => 'الهدف الأساسي';

  @override
  String get goalChampionship => 'التأهل لبطولة طبيعية';

  @override
  String get goalMuscle => 'زيادة الكتلة العضلية';

  @override
  String get goalSports => 'الجمع بين الرياضة وتمارين القوة';

  @override
  String get goalFatLoss => 'خسارة الدهون وتقليل السعرات';

  @override
  String get estimatedTarget => 'هدف السعرات التقديري:';

  @override
  String get enterDetails => 'أدخل البيانات واختر هدفاً';

  @override
  String get kcalPerDay => 'سعرة/يوم';

  @override
  String get saving => 'جارٍ الحفظ...';

  @override
  String get completeSetup => 'إكمال الإعداد والدخول';

  @override
  String get invalidUsername =>
      'اسم المستخدم من 3 إلى 20 حرفاً إنجليزياً أو رقماً أو شرطة سفلية.';

  @override
  String get invalidName => 'أدخل اسمك، بحد أقصى 60 حرفاً.';

  @override
  String get missingMeasurements => 'أدخل الوزن والطول.';

  @override
  String get invalidMeasurements =>
      'يجب أن يكون الوزن 35-250 كجم والطول 120-230 سم.';

  @override
  String get chooseGoal => 'اختر هدفاً أساسياً.';

  @override
  String get usernameTaken => 'اسم المستخدم مستخدم بالفعل.';

  @override
  String get sessionExpired => 'يرجى تسجيل الدخول مرة أخرى.';
}
