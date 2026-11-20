// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

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
  String get profileSaveError => 'تعذر حفظ ملفك الشخصي. حاول مرة أخرى.';

  @override
  String get sessionExpired => 'يرجى تسجيل الدخول مرة أخرى.';
}
