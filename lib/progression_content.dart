typedef ProgressionContent = ({String name, String description});

const _badgeMetrics = <String, (String, String)>{
  'meals': ('الوجبات', 'الوجبات المتناولة المسجلة'),
  'workouts': ('التمارين', 'التمارين المكتملة المسجلة'),
  'active_days': ('أيام النشاط', 'الأيام التي سُجل فيها نشاط مؤهل'),
  'longest_streak': ('سلسلة النشاط', 'أطول سلسلة نشاط'),
  'challenges_joined': ('التحديات المشاركة', 'تحديات الساحة التي انضممت إليها'),
  'challenges_won': ('التحديات الفائزة', 'تحديات الساحة التي فزت بها'),
  'posts': ('منشورات المجتمع', 'منشورات المجتمع التي أنشأتها'),
};

const _badgeThresholds = <int>[1, 7, 30, 100, 365];

final Map<String, ProgressionContent> badgeTranslations = {
  for (final metric in _badgeMetrics.entries)
    for (final threshold in _badgeThresholds)
      '${metric.key}_$threshold': (
        name: '${metric.value.$1}: $threshold',
        description: '${metric.value.$2}: $threshold.',
      ),
};

const achievementTranslations = <String, ProgressionContent>{
  'meal_10': (name: 'مسجل الوجبات', description: 'سجل 10 وجبات متناولة.'),
  'meal_100': (name: 'منتظم في التغذية', description: 'سجل 100 وجبة متناولة.'),
  'workout_10': (name: 'بداية الحركة', description: 'سجل 10 تمارين مكتملة.'),
  'workout_100': (name: 'مئة تمرين', description: 'سجل 100 تمرين مكتمل.'),
  'days_30': (name: '30 يوم نشاط', description: 'سجل نشاطاً في 30 يوماً.'),
  'days_100': (name: '100 يوم نشاط', description: 'سجل نشاطاً في 100 يوم.'),
  'streak_7': (
    name: 'سلسلة أسبوع',
    description: 'واصل نشاطك لمدة 7 أيام متتالية.'
  ),
  'streak_30': (
    name: 'سلسلة 30 يوماً',
    description: 'واصل نشاطك لمدة 30 يوماً متتالياً.'
  ),
  'join_1': (name: 'مشارك في الساحة', description: 'انضم إلى تحدٍ.'),
  'win_1': (name: 'فائز في الساحة', description: 'افز في تحدٍ.'),
  'post_1': (name: 'أول منشور', description: 'أنشئ منشوراً في المجتمع.'),
  'post_10': (
    name: 'مشارك في المجتمع',
    description: 'أنشئ 10 منشورات في المجتمع.'
  ),
};

const rewardTranslations = <String, ProgressionContent>{
  'Streak freeze token': (
    name: 'رمز تجميد السلسلة',
    description:
        'يغطي تلقائياً يوماً مؤهلاً فاتك بعد استخدام التجميد الشهري المجاني.'
  ),
  'Sunrise theme': (
    name: 'مظهر الشروق',
    description: 'مظهر رقمي للملف الشخصي.'
  ),
  'Midnight theme': (
    name: 'مظهر منتصف الليل',
    description: 'مظهر رقمي للملف الشخصي.'
  ),
  'Forest theme': (name: 'مظهر الغابة', description: 'مظهر رقمي للملف الشخصي.'),
  'Ocean theme': (name: 'مظهر المحيط', description: 'مظهر رقمي للملف الشخصي.'),
  'Ember theme': (name: 'مظهر الجمر', description: 'مظهر رقمي للملف الشخصي.'),
  'Aurora theme': (name: 'مظهر الشفق', description: 'مظهر رقمي للملف الشخصي.'),
  'Galaxy theme': (name: 'مظهر المجرة', description: 'مظهر رقمي للملف الشخصي.'),
  'Bronze frame': (name: 'إطار برونزي', description: 'إطار رقمي للملف الشخصي.'),
  'Silver frame': (name: 'إطار فضي', description: 'إطار رقمي للملف الشخصي.'),
  'Gold frame': (name: 'إطار ذهبي', description: 'إطار رقمي للملف الشخصي.'),
  'Platinum frame': (
    name: 'إطار بلاتيني',
    description: 'إطار رقمي للملف الشخصي.'
  ),
  'Diamond frame': (name: 'إطار ماسي', description: 'إطار رقمي للملف الشخصي.'),
  'Flame frame': (name: 'إطار اللهب', description: 'إطار رقمي للملف الشخصي.'),
  'Leaf frame': (name: 'إطار الورقة', description: 'إطار رقمي للملف الشخصي.'),
  'Wave frame': (name: 'إطار الموجة', description: 'إطار رقمي للملف الشخصي.'),
  'Early Riser title': (
    name: 'لقب المستيقظ مبكراً',
    description: 'لقب رقمي للملف الشخصي.'
  ),
  'Steady Steps title': (
    name: 'لقب الخطوات الثابتة',
    description: 'لقب رقمي للملف الشخصي.'
  ),
  'Trailblazer title': (
    name: 'لقب رائد الطريق',
    description: 'لقب رقمي للملف الشخصي.'
  ),
  'Focused title': (
    name: 'لقب صاحب التركيز',
    description: 'لقب رقمي للملف الشخصي.'
  ),
  'Momentum title': (
    name: 'لقب الانطلاقة',
    description: 'لقب رقمي للملف الشخصي.'
  ),
  'Determined title': (
    name: 'لقب صاحب العزيمة',
    description: 'لقب رقمي للملف الشخصي.'
  ),
  'Champion Spirit title': (
    name: 'لقب روح البطل',
    description: 'لقب رقمي للملف الشخصي.'
  ),
  'Community Builder title': (
    name: 'لقب باني المجتمع',
    description: 'لقب رقمي للملف الشخصي.'
  ),
  'Challenge winner': (
    name: 'الفائز بالتحدي',
    description: 'تُمنح للفائز في تحدٍ تم التحقق منه.'
  ),
  'Consistency badge': (
    name: 'شارة الاستمرار',
    description: 'تُمنح تقديراً للنشاط المنتظم.'
  ),
};

ProgressionContent localizedProgressionContent(
    Map<String, ProgressionContent> translations, String? key,
    {required String name, required String description, required bool arabic}) {
  if (arabic && key != null) {
    final translation = translations[key];
    if (translation != null) return translation;
  }
  return (name: name, description: description);
}
