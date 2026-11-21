// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get genericError => 'حدث خطأ. حاول مرة أخرى.';

  @override
  String get splashSlogan => 'كُل جيداً؛ وعِش بصحة';

  @override
  String get postImageOpen => 'فتح صورة المنشور';

  @override
  String get postImageTitle => 'صورة المنشور';

  @override
  String get postImageUnavailable => 'صورة المنشور غير متاحة.';

  @override
  String get postImageRetry => 'صورة المنشور غير متاحة. حاول مجدداً';

  @override
  String get errorUnreadCount => 'تعذر تحميل عدد الإشعارات.';

  @override
  String get errorAccountChanged => 'تغير الحساب. حاول مرة أخرى.';

  @override
  String get errorPlannerBusy => 'يجري حفظ خطة بالفعل.';

  @override
  String get errorActivityLoad => 'تعذر تحميل نشاط اليوم.';

  @override
  String get errorPointsBalance => 'تعذر تحميل رصيد نقاط المتجر.';

  @override
  String get errorActivityDate => 'تعذر تحديد تاريخ نشاط اليوم.';

  @override
  String get errorFoodNotLinked =>
      'هذه الوجبة غير مرتبطة بطعام في قاعدة البيانات.';

  @override
  String get errorFoodChanged => 'تعذر العثور على سجل الطعام أو أنه تغير.';

  @override
  String get errorFoodUnavailable =>
      'لم يعد هذا الطعام متاحاً في قاعدة البيانات. لم تتغير الوجبة.';

  @override
  String get errorSplitMissing =>
      'لم يتم العثور على التمرين أو أنه حُذف بالفعل.';

  @override
  String get errorDayMissing =>
      'لم يتم العثور على اليوم المخطط أو أنه أُزيل بالفعل.';

  @override
  String get errorCravingMissing =>
      'لم يتم العثور على الوجبة أو أنها حُذفت بالفعل.';

  @override
  String get errorProfileInvalid => 'أدخل بيانات شخصية صحيحة قبل الحفظ.';

  @override
  String errorInvalidPlannerDate(String date) {
    return 'تاريخ الخطة غير صالح: $date';
  }

  @override
  String get errorProfileMissing =>
      'تعذر العثور على ملفك الشخصي. تواصل مع مسؤول التطبيق.';

  @override
  String get errorProfileNotSaved => 'تعذر حفظ ملفك الشخصي.';

  @override
  String get errorSignInSession => 'لم يتم إنشاء جلسة تسجيل دخول.';

  @override
  String get errorCompleteSignIn => 'تعذر إكمال تسجيل الدخول. حاول مرة أخرى.';

  @override
  String get errorLogInSetup => 'يرجى تسجيل الدخول مرة أخرى لإكمال الإعداد.';

  @override
  String errorReduceMeal(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount سعرة',
      many: '$amount سعرة',
      few: '$amount سعرات',
      two: 'سعرتين',
      one: 'سعرة واحدة',
      zero: '0 سعرة',
    );
    return 'لا توجد وجبة مسجلة يمكن تقليلها بمقدار $_temp0.';
  }

  @override
  String get errorReduceWorkout => 'لا يوجد تمرين مسجل يمكن تقليله.';

  @override
  String activityTimeDuration(String time, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      many: '$minutes دقيقة',
      few: '$minutes دقائق',
      two: 'دقيقتان',
      one: 'دقيقة واحدة',
      zero: '0 دقيقة',
    );
    return '$time • $_temp0';
  }

  @override
  String feedbackLoggedMeal(String name, int calories) {
    String _temp0 = intl.Intl.pluralLogic(
      calories,
      locale: localeName,
      other: '+$calories سعرة',
      many: '+$calories سعرة',
      few: '+$calories سعرات',
      two: '+سعرتان',
      one: '+سعرة واحدة',
      zero: '+0 سعرة',
    );
    return 'تم تسجيل $name ($_temp0)!';
  }

  @override
  String feedbackUncheckedMeal(String name, int calories) {
    String _temp0 = intl.Intl.pluralLogic(
      calories,
      locale: localeName,
      other: '-$calories سعرة',
      many: '-$calories سعرة',
      few: '-$calories سعرات',
      two: '-سعرتان',
      one: '-سعرة واحدة',
      zero: '-0 سعرة',
    );
    return 'تم إلغاء تسجيل $name ($_temp0)!';
  }

  @override
  String feedbackAddedMeal(String name, int calories) {
    String _temp0 = intl.Intl.pluralLogic(
      calories,
      locale: localeName,
      other: '+$calories سعرة',
      many: '+$calories سعرة',
      few: '+$calories سعرات',
      two: '+سعرتان',
      one: '+سعرة واحدة',
      zero: '+0 سعرة',
    );
    return 'تمت إضافة وجبة $name ($_temp0)!';
  }

  @override
  String feedbackUpdated(String name) {
    return 'تم تحديث $name.';
  }

  @override
  String feedbackRemovedMeal(String name, int calories) {
    String _temp0 = intl.Intl.pluralLogic(
      calories,
      locale: localeName,
      other: '-$calories سعرة',
      many: '-$calories سعرة',
      few: '-$calories سعرات',
      two: '-سعرتان',
      one: '-سعرة واحدة',
      zero: '-0 سعرة',
    );
    return 'تمت إزالة $name ($_temp0)!';
  }

  @override
  String feedbackAddedWorkout(String name, int calories) {
    String _temp0 = intl.Intl.pluralLogic(
      calories,
      locale: localeName,
      other: '-$calories سعرة محروقة',
      many: '-$calories سعرة محروقة',
      few: '-$calories سعرات محروقة',
      two: '-سعرتان محروقتان',
      one: '-سعرة واحدة محروقة',
      zero: '-0 سعرة محروقة',
    );
    return 'تمت إضافة تمرين $name ($_temp0)!';
  }

  @override
  String feedbackRemovedWorkout(String name, int calories) {
    String _temp0 = intl.Intl.pluralLogic(
      calories,
      locale: localeName,
      other: '-$calories سعرة محروقة',
      many: '-$calories سعرة محروقة',
      few: '-$calories سعرات محروقة',
      two: '-سعرتان محروقتان',
      one: '-سعرة واحدة محروقة',
      zero: '-0 سعرة محروقة',
    );
    return 'تمت إزالة $name ($_temp0)!';
  }

  @override
  String feedbackDeductFood(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount سعرة',
      many: '$amount سعرة',
      few: '$amount سعرات',
      two: 'سعرتين',
      one: 'سعرة واحدة',
      zero: '0 سعرة',
    );
    return 'تم خصم $_temp0 من الطعام!';
  }

  @override
  String feedbackDeductWorkout(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount سعرة',
      many: '$amount سعرة',
      few: '$amount سعرات',
      two: 'سعرتين',
      one: 'سعرة واحدة',
      zero: '0 سعرة',
    );
    return 'تم خصم $_temp0 من حرق التمرين!';
  }

  @override
  String get groupTitle => 'المجموعة';

  @override
  String get groupReport => 'إبلاغ';

  @override
  String get groupReason => 'السبب';

  @override
  String get groupBanQuestion => 'حظر العضو؟';

  @override
  String get groupRemoveQuestion => 'إزالة العضو؟';

  @override
  String get groupBanDetails =>
      'سيُحظر العضو حتى تلغي حظره. ستُخفى منشوراته وتعليقاته في هذه المجموعة ولن يتمكن من الانضمام مجدداً.';

  @override
  String get groupRemoveDetails =>
      'ستتم إزالة العضو وإخفاء منشوراته وتعليقاته في هذه المجموعة. يمكنه الانضمام مجدداً.';

  @override
  String get groupCancel => 'إلغاء';

  @override
  String get groupBan => 'حظر';

  @override
  String get groupRemove => 'إزالة';

  @override
  String get groupUnavailableInvitation =>
      'هذه المجموعة غير متاحة. تحتاج المجموعات الخاصة إلى دعوة.';

  @override
  String get groupAcceptInvitation => 'قبول الدعوة';

  @override
  String groupHeaderDetails(String category, String members) {
    return '$category · $members';
  }

  @override
  String get groupMenuSettings => 'الإعدادات';

  @override
  String get groupInvitePeople => 'دعوة أشخاص';

  @override
  String get groupBannedMembers => 'الأعضاء المحظورون';

  @override
  String get groupReportGroup => 'الإبلاغ عن المجموعة';

  @override
  String groupRulesValue(String rules) {
    return 'القواعد: $rules';
  }

  @override
  String get groupLeave => 'مغادرة المجموعة';

  @override
  String get groupCancelRequest => 'إلغاء الطلب';

  @override
  String get groupRequestJoin => 'طلب الانضمام';

  @override
  String get groupInvitationRequired => 'تحتاج إلى دعوة';

  @override
  String get groupJoin => 'انضمام';

  @override
  String get groupJoinToSee => 'انضم لرؤية المنشورات والأعضاء.';

  @override
  String get groupPosts => 'المنشورات';

  @override
  String get groupCreatePost => 'إنشاء منشور';

  @override
  String get groupModeratorsPost => 'يمكن للمشرفين فقط النشر.';

  @override
  String get groupNoPosts => 'لا توجد منشورات بعد.';

  @override
  String get groupMembers => 'الأعضاء';

  @override
  String get groupNoMembers => 'لم يتم العثور على أعضاء.';

  @override
  String get groupJoinRequests => 'طلبات الانضمام';

  @override
  String get groupUnbanQuestion => 'إلغاء حظر العضو؟';

  @override
  String get groupUnbanDetails =>
      'يمكنه الانضمام مجدداً. ستبقى المنشورات والتعليقات المخفية سابقاً مخفية.';

  @override
  String get groupUnban => 'إلغاء الحظر';

  @override
  String get groupNoBanned => 'لا يوجد أعضاء محظورون.';

  @override
  String groupBannedDate(String date) {
    return 'تاريخ الحظر: $date';
  }

  @override
  String groupBannedBy(String name) {
    return 'بواسطة $name';
  }

  @override
  String get groupSearchUsers => 'البحث عن مستخدمين';

  @override
  String get groupSearch => 'بحث';

  @override
  String get groupSearchInvite => 'ابحث عن شخص لدعوته.';

  @override
  String get groupNoPeople => 'لم يتم العثور على أشخاص.';

  @override
  String get groupInvitationSent => 'تم إرسال الدعوة.';

  @override
  String get groupInvite => 'دعوة';

  @override
  String get groupWritePost => 'اكتب منشوراً';

  @override
  String get groupAddImage => 'إضافة صورة';

  @override
  String get groupImageChooseError => 'تعذر اختيار الصورة. حاول مرة أخرى.';

  @override
  String get groupImageTypeSizeError =>
      'اختر صورة JPG أو PNG أو WebP أصغر من 8 ميجابايت.';

  @override
  String get groupImageReadError => 'تعذرت قراءة الصورة. اخترها مرة أخرى.';

  @override
  String get groupImageUploadError => 'تعذر رفع الصورة. حاول مرة أخرى.';

  @override
  String get groupShare => 'مشاركة';

  @override
  String get groupProfileUnavailable => 'الملف الشخصي غير متاح';

  @override
  String get groupOwner => 'المالك';

  @override
  String get groupModerator => 'مشرف';

  @override
  String get groupApproveRequest => 'قبول الطلب';

  @override
  String get groupRemoveModerator => 'إزالة دور المشرف';

  @override
  String get groupMakeModerator => 'تعيين مشرف';

  @override
  String get groupReportMember => 'الإبلاغ عن العضو';

  @override
  String get groupImageRetry => 'الصورة غير متاحة. حاول مجدداً';

  @override
  String get groupImageUnavailable => 'الصورة غير متاحة.';

  @override
  String get groupLikesRetry => 'تعذر تحميل الإعجابات. حاول مجدداً';

  @override
  String get groupNoComments => 'لا توجد تعليقات بعد.';

  @override
  String get groupComment => 'تعليق';

  @override
  String get groupSendComment => 'إرسال التعليق';

  @override
  String get groupsDiscover => 'اكتشف';

  @override
  String get groupsMine => 'مجموعاتي';

  @override
  String get groupsCreate => 'إنشاء مجموعة';

  @override
  String get groupsSearch => 'البحث عن مجموعات';

  @override
  String get groupsCategory => 'الفئة';

  @override
  String get groupsAll => 'الكل';

  @override
  String get groupsWeightLoss => 'إنقاص الوزن';

  @override
  String get groupsMuscleBuilding => 'بناء العضلات';

  @override
  String get groupsRunning => 'الجري والتمارين الهوائية';

  @override
  String get groupsYoga => 'اليوغا والمرونة';

  @override
  String get groupsNutrition => 'التغذية';

  @override
  String get groupsBeginners => 'المبتدئون';

  @override
  String get groupsFitness => 'اللياقة العامة';

  @override
  String get groupsOther => 'أخرى';

  @override
  String get groupsPublic => 'عامة';

  @override
  String get groupsPrivate => 'خاصة';

  @override
  String get groupsOpen => 'مفتوح';

  @override
  String get groupsApproval => 'تحتاج إلى موافقة';

  @override
  String get groupsInviteOnly => 'بالدعوة فقط';

  @override
  String get groupsEveryone => 'الجميع';

  @override
  String get groupsModerators => 'المشرفون';

  @override
  String get groupsInvitations => 'الدعوات';

  @override
  String get groupsInvitation => 'دعوة إلى مجموعة';

  @override
  String get groupsOpenToAccept => 'افتح لقبول الدعوة';

  @override
  String get groupsNone => 'لم يتم العثور على مجموعات.';

  @override
  String groupsSummary(String category, String visibility) {
    return '$category · $visibility';
  }

  @override
  String groupsPendingSummary(String summary) {
    return '$summary · الطلب قيد الانتظار';
  }

  @override
  String groupsMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عضو',
      many: '$count عضوًا',
      few: '$count أعضاء',
      two: 'عضوان',
      one: 'عضو واحد',
      zero: '0 عضو',
    );
    return '$_temp0';
  }

  @override
  String get groupsMember => 'عضو';

  @override
  String get groupsRetry => 'حاول مرة أخرى';

  @override
  String get groupsSettings => 'إعدادات المجموعة';

  @override
  String get groupsChoosePhoto => 'اختيار صورة';

  @override
  String get groupsRemovePhoto => 'إزالة الصورة';

  @override
  String get groupsName => 'الاسم';

  @override
  String get groupsDescription => 'الوصف';

  @override
  String get groupsVisibility => 'الظهور';

  @override
  String get groupsJoinMode => 'طريقة الانضمام';

  @override
  String get groupsPrivateInvitation => 'تحتاج المجموعات الخاصة إلى دعوة.';

  @override
  String get groupsMemberLimit => 'الحد الأقصى للأعضاء';

  @override
  String get groupsWhoCanPost => 'من يمكنه النشر';

  @override
  String get groupsImagesAllowed => 'السماح بالصور';

  @override
  String get groupsChatPhase2 => 'المحادثة (قادمة في المرحلة الثانية)';

  @override
  String get groupsChatUnavailable =>
      'يتم حفظ هذا الإعداد، لكن المحادثة غير متاحة بعد.';

  @override
  String get groupsRules => 'القواعد';

  @override
  String get groupsSaving => 'جارٍ الحفظ...';

  @override
  String get groupsSave => 'حفظ';

  @override
  String groupsCounter(String current, String max) {
    return '$current / $max';
  }

  @override
  String get groupsValidation =>
      'أدخل اسماً من 3 أحرف على الأقل، وفئة، وحداً للأعضاء من 1 إلى 10000.';

  @override
  String get groupsPhotoChooseError => 'تعذر اختيار الصورة. حاول مرة أخرى.';

  @override
  String get groupsPhotoSaveError => 'تعذر حفظ صورة المجموعة. حاول مرة أخرى.';

  @override
  String get groupsPhotoCreatedError =>
      'تم إنشاء المجموعة، لكن تعذر رفع الصورة. يمكنك إضافتها من إعدادات المجموعة.';

  @override
  String get groupsPhotoTypeError => 'اختر صورة بصيغة JPG أو PNG أو WebP.';

  @override
  String get groupsPhotoReadError => 'تعذرت قراءة الصورة. اخترها مرة أخرى.';

  @override
  String get groupsPhotoEmptyError => 'الصورة فارغة. اختر صورة أخرى.';

  @override
  String get groupsPhotoMismatchError =>
      'الصورة لا تطابق نوع الملف. اختر صورة JPG أو PNG أو WebP صالحة.';

  @override
  String get groupsPhotoSizeError =>
      'الصورة كبيرة جداً. اختر صورة أقل من 2 ميجابايت.';

  @override
  String get groupsPhotoInvalidError =>
      'تعذرت قراءة الصورة. اختر صورة JPG أو PNG أو WebP صالحة.';

  @override
  String get groupsBannedError =>
      'أنت محظور من هذه المجموعة. يمكن للمالك أو المشرف فقط إلغاء حظرك.';

  @override
  String get groupsFullError => 'هذه المجموعة ممتلئة.';

  @override
  String get groupsModeratorsOnlyError =>
      'يمكن للمشرفين فقط النشر في هذه المجموعة.';

  @override
  String get groupsPostingLimitError =>
      'وصلت إلى حد النشر. حاول مرة أخرى لاحقاً.';

  @override
  String get groupsCreationLimitError => 'يمكنك إنشاء 3 مجموعات كحد أقصى.';

  @override
  String get groupsUnavailableError =>
      'هذه المجموعة غير متاحة أو تحتاج إلى دعوة.';

  @override
  String communityUsername(String username) {
    return '@$username';
  }

  @override
  String get communityLikePost => 'الإعجاب بالمنشور';

  @override
  String get communityUnlikePost => 'إلغاء الإعجاب بالمنشور';

  @override
  String get communityOpenComments => 'فتح التعليقات';

  @override
  String get communityErrorSignIn => 'يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get communityErrorConnection =>
      'تعذر الاتصال. تحقق من اتصال الإنترنت.';

  @override
  String get communityErrorTimeout => 'انتهت مهلة الطلب. حاول مرة أخرى.';

  @override
  String get communityErrorEmptyPost => 'اكتب شيئاً قبل مشاركة المنشور.';

  @override
  String get communityErrorPostLength => 'يجب ألا يزيد المنشور على 5000 حرف.';

  @override
  String get communityErrorImageSize => 'اختر صورة أصغر من 8 ميجابايت.';

  @override
  String get communityErrorImageType => 'اختر صورة بصيغة JPG أو PNG أو WebP.';

  @override
  String get communityErrorDeleteOwn => 'يمكنك حذف منشوراتك فقط.';

  @override
  String get communityErrorCommentLength =>
      'يجب أن يتكون التعليق من 1 إلى 2000 حرف.';

  @override
  String get communityPostGone => 'لم يعد هذا المنشور متاحاً.';

  @override
  String get communityPostShared => 'تمت مشاركة منشورك.';

  @override
  String get communityRequestGone => 'لم يعد هذا الطلب متاحاً.';

  @override
  String get communityRequestAccepted => 'تم قبول طلب الصداقة.';

  @override
  String get communityRequestRemoved => 'تمت إزالة طلب الصداقة.';

  @override
  String get communityRequestSent => 'تم إرسال طلب الصداقة.';

  @override
  String get communityUnfollowed => 'تم إلغاء المتابعة.';

  @override
  String get communityFollowing => 'تمت المتابعة.';

  @override
  String get communityBlocked => 'تم حظر المستخدم.';

  @override
  String get communityUpdated => 'تم التحديث.';

  @override
  String get communityDeleteQuestion => 'حذف هذا المنشور؟';

  @override
  String get communityCannotUndo => 'لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get communityReportSubmitted => 'تم إرسال البلاغ.';

  @override
  String communityBlockQuestion(String username) {
    return 'حظر @$username؟';
  }

  @override
  String get communityBlockDetails =>
      'لن تظهر منشورات هذا المستخدم في مجتمعك بعد الآن.';

  @override
  String get communityDeletePost => 'حذف المنشور';

  @override
  String get communityReportPost => 'الإبلاغ عن المنشور';

  @override
  String get communityBlockUser => 'حظر المستخدم';

  @override
  String get communityImageUnavailable => 'صورة المنشور غير متاحة.';

  @override
  String get communityAcceptRequest => 'قبول الطلب';

  @override
  String get communityDeclineRequest => 'رفض الطلب';

  @override
  String get communityFollow => 'متابعة';

  @override
  String get communityUnfollow => 'إلغاء المتابعة';

  @override
  String get communitySendFriendRequest => 'إرسال طلب صداقة';

  @override
  String get communityRequestPending => 'الطلب قيد الانتظار';

  @override
  String get communityReportHint => 'أخبرنا لماذا يجب مراجعة هذا المنشور.';

  @override
  String get communitySubmit => 'إرسال';

  @override
  String get communityReportValidation => 'يرجى إدخال 3 أحرف على الأقل.';

  @override
  String get communityContinue => 'متابعة';

  @override
  String get communityClose => 'إغلاق';

  @override
  String get communityPostHint => 'شارك تحديثاً عن اللياقة أو التغذية...';

  @override
  String get communityAddPhoto => 'إضافة صورة';

  @override
  String get communityRemovePhoto => 'إزالة الصورة';

  @override
  String get communityPublic => 'عام';

  @override
  String get communitySharePost => 'مشاركة المنشور';

  @override
  String communityLikesError(String error) {
    return 'تعذر تحميل الإعجابات: $error';
  }

  @override
  String get communityNoLikes => 'لا توجد إعجابات ظاهرة.';

  @override
  String get communityLikedBy => 'أعجب به';

  @override
  String get communityComments => 'التعليقات';

  @override
  String get communityOlderComments => 'تحميل التعليقات الأقدم';

  @override
  String get communityFirstComment => 'كن أول من يعلّق.';

  @override
  String get communityLikedByAuthor => 'أعجب صاحب المنشور';

  @override
  String get communityLikeComment => 'الإعجاب بالتعليق';

  @override
  String get communityUnlikeComment => 'إلغاء الإعجاب بالتعليق';

  @override
  String get communityCommentHint => 'اكتب تعليقاً...';

  @override
  String get communitySendComment => 'إرسال التعليق';

  @override
  String get communityProfileUnavailable => 'الملف الشخصي غير متاح.';

  @override
  String get communityStreak => 'السلسلة';

  @override
  String get communityBest => 'الأفضل';

  @override
  String get communityPosts => 'المنشورات';

  @override
  String get communityFollowers => 'المتابعون';

  @override
  String communityPostCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منشور',
      many: 'منشورًا',
      few: 'منشورات',
      two: 'منشوران',
      one: 'منشور',
      zero: 'منشور',
    );
    return '$_temp0';
  }

  @override
  String communityFriendCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'صديق',
      many: 'صديقًا',
      few: 'أصدقاء',
      two: 'صديقان',
      one: 'صديق',
      zero: 'صديق',
    );
    return '$_temp0';
  }

  @override
  String communityFollowerCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'متابع',
      many: 'متابعًا',
      few: 'متابعون',
      two: 'متابعان',
      one: 'متابع',
      zero: 'متابع',
    );
    return '$_temp0';
  }

  @override
  String communityLikeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إعجاب',
      many: '$count إعجابًا',
      few: '$count إعجابات',
      two: 'إعجابان',
      one: 'إعجاب واحد',
      zero: '0 إعجاب',
    );
    return '$_temp0';
  }

  @override
  String communityCommentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تعليق',
      many: '$count تعليقًا',
      few: '$count تعليقات',
      two: 'تعليقان',
      one: 'تعليق واحد',
      zero: '0 تعليق',
    );
    return '$_temp0';
  }

  @override
  String get communityNoBadges => 'لم تحصل على شارات بعد.';

  @override
  String get communityAddFriend => 'إضافة صديق';

  @override
  String get arenaCreatePublic => 'إنشاء تحدٍ عام';

  @override
  String get arenaChallengeName => 'اسم التحدي';

  @override
  String get arenaDescription => 'الوصف (اختياري)';

  @override
  String get arenaChallengeType => 'نوع التحدي';

  @override
  String get arenaActiveDays => 'الأيام النشطة';

  @override
  String get arenaWorkoutCount => 'عدد التمارين';

  @override
  String get arenaDuration => 'المدة';

  @override
  String arenaDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      many: '$count يومًا',
      few: '$count أيام',
      two: 'يومان',
      one: 'يوم واحد',
      zero: '0 يوم',
    );
    return '$_temp0';
  }

  @override
  String arenaWorkoutsCount(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText تمرين',
      many: '$countText تمرينًا',
      few: '$countText تمارين',
      two: 'تمرينان',
      one: 'تمرين واحد',
      zero: '0 تمرين',
    );
    return '$_temp0';
  }

  @override
  String get arenaNoPrizesRule =>
      'النتائج من سجلات نشاط يدخلها المستخدمون ولم يتم التحقق منها. لا تُمنح جوائز.';

  @override
  String get arenaNoCashRule =>
      'النتائج من سجلات نشاط يدخلها المستخدمون ولم يتم التحقق منها. لا توجد جوائز نقدية أو مادية.';

  @override
  String get arenaCreate => 'إنشاء';

  @override
  String get arenaInvalidName => 'يجب أن يتكون اسم التحدي من 3 أحرف على الأقل.';

  @override
  String get arenaCreated => 'تم إنشاء التحدي العام.';

  @override
  String get arenaNeedFriend => 'أضف صديقاً قبل إنشاء تحدٍ فردي.';

  @override
  String get arenaInvitationSent => 'تم إرسال دعوة تحدي الصديق.';

  @override
  String get arenaJoined => 'انضممت إلى التحدي.';

  @override
  String get arenaAccepted => 'تم قبول التحدي.';

  @override
  String get arenaDeclined => 'تم رفض دعوة التحدي.';

  @override
  String get arenaRewardsStore => 'متجر المكافآت';

  @override
  String get arenaBadgesAchievements => 'الشارات والإنجازات';

  @override
  String get arenaSection => 'الساحة';

  @override
  String get arenaCreateChallenge => 'إنشاء تحدٍ';

  @override
  String get arenaPublicChallenge => 'تحدٍ عام';

  @override
  String get arenaChallengeFriend => 'تحدَّ صديقاً';

  @override
  String get arenaYourActivity => 'سلسلة نشاطك';

  @override
  String arenaYourStreak(String days) {
    return 'سلسلتك: $days';
  }

  @override
  String arenaLongestStreak(String days) {
    return 'أطول سلسلة: $days';
  }

  @override
  String get arenaStreakHelp =>
      'سجّل وجبة أو تمريناً مكتملاً لتحديث سلسلتك وكسب 10 نقاط خبرة و10 نقاط متجر مرة في كل يوم نشط.';

  @override
  String get arenaChallenges => 'التحديات';

  @override
  String get arenaLeaderboard => 'لوحة المتصدرين';

  @override
  String get arenaDiscover => 'اكتشف';

  @override
  String get arenaMyChallenges => 'تحدياتي';

  @override
  String get arenaFinished => 'المنتهية';

  @override
  String get arenaFriendInvitations => 'دعوات الأصدقاء';

  @override
  String arenaInvitation(String name, String metric) {
    return 'دعاك $name إلى تحدٍ فردي في $metric.';
  }

  @override
  String arenaDateRange(String start, String end) {
    return 'من $start إلى $end';
  }

  @override
  String get arenaDecline => 'رفض';

  @override
  String get arenaAccept => 'قبول';

  @override
  String get arenaNoOpen => 'لا توجد تحديات مفتوحة بعد. أنشئ تحدياً للبدء.';

  @override
  String get arenaNoChallenges => 'لا توجد تحديات لعرضها هنا بعد.';

  @override
  String get arenaOneVOne => 'فردي';

  @override
  String arenaChallengeSummary(String metric, String dates) {
    return '$metric · $dates';
  }

  @override
  String arenaParticipants(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText مشارك',
      many: '$countText مشاركًا',
      few: '$countText مشاركين',
      two: 'مشاركان',
      one: 'مشارك واحد',
      zero: '0 مشارك',
    );
    return '$_temp0';
  }

  @override
  String arenaScore(String score) {
    return 'نتيجتك: $score';
  }

  @override
  String arenaScoreRank(String score, String rank) {
    return 'نتيجتك: $score · الترتيب #$rank';
  }

  @override
  String arenaCreatedBy(String name) {
    return 'أنشأه $name';
  }

  @override
  String get arenaJoining => 'جارٍ الانضمام...';

  @override
  String get arenaJoin => 'انضم إلى التحدي';

  @override
  String get arenaNoStandings => 'لا يوجد ترتيب بعد.';

  @override
  String get arenaGlobal => 'عالمي';

  @override
  String get arenaFriends => 'الأصدقاء';

  @override
  String get arenaMyLevel => 'مستواي';

  @override
  String get arenaThisWeek => 'هذا الأسبوع';

  @override
  String get arenaThisMonth => 'هذا الشهر';

  @override
  String get arenaAllTime => 'كل الأوقات';

  @override
  String get arenaWorkouts => 'التمارين';

  @override
  String get arenaNoRanked => 'لم يُصنف أي نشاط لهذا الفلتر.';

  @override
  String arenaCurrentStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'السلسلة الحالية: $count يوم',
      many: 'السلسلة الحالية: $count يومًا',
      few: 'السلسلة الحالية: $count أيام',
      two: 'السلسلة الحالية: يومان',
      one: 'السلسلة الحالية: يوم واحد',
      zero: 'السلسلة الحالية: 0 يوم',
    );
    return '$_temp0';
  }

  @override
  String arenaLevelStreak(String level, String streak) {
    return '$level · $streak';
  }

  @override
  String get arenaCompletedWorkouts => 'التمارين المكتملة';

  @override
  String get arenaFriend => 'الصديق';

  @override
  String get arenaMetric => 'المقياس';

  @override
  String get arenaSevenDayInvite => '7 أيام · تنتهي الدعوة تلقائياً.';

  @override
  String get arenaSendInvitation => 'إرسال الدعوة';

  @override
  String get communityHeading => 'مجتمعك';

  @override
  String get communitySubtitle => 'شارك تقدمك وتواصل مع الآخرين.';

  @override
  String get communityCreatePost => 'إنشاء منشور';

  @override
  String get communityFeed => 'المنشورات';

  @override
  String get communityPeople => 'الأشخاص';

  @override
  String get communityGroups => 'المجموعات';

  @override
  String get communityFeedEmpty => 'لا توجد منشورات بعد. كن أول من يشارك!';

  @override
  String get communitySearchPeople => 'البحث عن أشخاص';

  @override
  String get communityClearSearch => 'مسح البحث';

  @override
  String get communityFriendRequests => 'طلبات الصداقة';

  @override
  String get communityFriends => 'الأصدقاء';

  @override
  String get communityDiscoverPeople => 'اكتشف أشخاصاً';

  @override
  String get communityResults => 'النتائج';

  @override
  String get communityNoPeople =>
      'لم نعثر على أشخاص. جرّب اسماً آخر أو اسم مستخدم مختلفاً.';

  @override
  String get communityTimeNow => 'الآن';

  @override
  String communityMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count دقيقة',
      many: 'منذ $count دقيقة',
      few: 'منذ $count دقائق',
      two: 'منذ دقيقتين',
      one: 'منذ دقيقة واحدة',
      zero: 'منذ 0 دقيقة',
    );
    return '$_temp0';
  }

  @override
  String communityHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count ساعة',
      many: 'منذ $count ساعة',
      few: 'منذ $count ساعات',
      two: 'منذ ساعتين',
      one: 'منذ ساعة واحدة',
      zero: 'منذ 0 ساعة',
    );
    return '$_temp0';
  }

  @override
  String communityDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count يوم',
      many: 'منذ $count يومًا',
      few: 'منذ $count أيام',
      two: 'منذ يومين',
      one: 'منذ يوم واحد',
      zero: 'منذ 0 يوم',
    );
    return '$_temp0';
  }

  @override
  String communityPostTime(String username, String time) {
    return '@$username · $time';
  }

  @override
  String get coachTitle => 'مدرب بريفيلج';

  @override
  String get coachAiBadge => 'ذكاء اصطناعي';

  @override
  String get coachNewChat => 'محادثة جديدة';

  @override
  String get coachClose => 'إغلاق المحادثة';

  @override
  String get coachInfo =>
      'قد يخطئ الذكاء الاصطناعي - ليس نصيحة طبية - اضغط للتفاصيل';

  @override
  String get coachAbout => 'عن المدرب';

  @override
  String get coachNoticeMistakes => 'المدرب قد يخطئ.';

  @override
  String get coachNoticeMedical =>
      'ليست نصيحة طبية. للمشاكل الصحية استشر طبيباً.';

  @override
  String get coachNoticeCloud =>
      'تُرسل رسائلك إلى Google Gemini للحصول على رد.';

  @override
  String get coachNoticePrivacy =>
      'لا تشارك تفاصيل شخصية أو صحية لا تريد إرسالها.';

  @override
  String get coachNoticeMemory => 'المدرب لا يتذكر الرسائل السابقة.';

  @override
  String get coachGotIt => 'فهمت';

  @override
  String get coachConsent => 'مشاركة هدف السعرات وإجمالي اليوم مع المدرب';

  @override
  String get coachWelcome => 'أهلاً! كيف أقدر أساعدك اليوم؟';

  @override
  String get coachTraining => 'أفكار للتمرين';

  @override
  String get coachProteinRecipe => 'وصفة غنية بالبروتين';

  @override
  String get coachCaloriesLeft => 'كم سعرة متبقية؟';

  @override
  String get coachSnacks => 'أفكار لوجبات خفيفة';

  @override
  String get coachResponding => 'المدرب يرد…';

  @override
  String coachRequestsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'المتبقي اليوم: $count طلب',
      many: 'المتبقي اليوم: $count طلبًا',
      few: 'المتبقي اليوم: $count طلبات',
      two: 'المتبقي اليوم: طلبان',
      one: 'المتبقي اليوم: طلب واحد',
      zero: 'المتبقي اليوم: 0 طلب',
    );
    return '$_temp0';
  }

  @override
  String get coachInputHint => 'اكتب للمدرب';

  @override
  String get coachSend => 'إرسال';

  @override
  String coachCounter(String count) {
    return '$count/2000';
  }

  @override
  String get coachPreferenceError =>
      'تعذر حفظ أو تحميل الموافقة. حاول مرة أخرى.';

  @override
  String get coachSignInError => 'سجّل الدخول بحساب لاستخدام المدرب.';

  @override
  String get coachBirthDateError =>
      'أضف تاريخ ميلادك في الملف الشخصي لاستخدام المدرب.';

  @override
  String get coachAgeError => 'المدرب الذكي للمستخدمين بعمر 18 سنة فأكثر.';

  @override
  String get coachQuotaError => 'تم الوصول إلى الحد اليومي.';

  @override
  String coachQuotaResetError(String date) {
    return 'تم الوصول إلى الحد اليومي. موعد التجديد: $date';
  }

  @override
  String get coachUnavailable => 'المدرب غير متاح حالياً.';

  @override
  String get coachLocalHelp =>
      'مساعدة محلية (ليست ذكاءً اصطناعياً): راجع السعرات والخطة الأسبوعية وسلسلة التقدم في التطبيق.';

  @override
  String coachUnavailableHelp(String error, String help) {
    return '$error\n\n$help';
  }

  @override
  String get coachTryAgain => 'حاول مرة أخرى';

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
  String recipeLogged(String name, int kcal) {
    String _temp0 = intl.Intl.pluralLogic(
      kcal,
      locale: localeName,
      other: '$kcal سعرة',
      many: '$kcal سعرة',
      few: '$kcal سعرات',
      two: 'سعرتان',
      one: 'سعرة واحدة',
      zero: '0 سعرة',
    );
    return 'تم تسجيل $name ($_temp0)';
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
  String recipeRemaining(int kcal, String protein) {
    String _temp0 = intl.Intl.pluralLogic(
      kcal,
      locale: localeName,
      other: '$kcal سعرة',
      many: '$kcal سعرة',
      few: '$kcal سعرات',
      two: 'سعرتان',
      one: 'سعرة واحدة',
      zero: '0 سعرة',
    );
    return 'المتبقي اليوم: $_temp0 · $protein جم بروتين';
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
  String recipeKcal(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount سعرة',
      many: '$amount سعرة',
      few: '$amount سعرات',
      two: 'سعرتان',
      one: 'سعرة واحدة',
      zero: '0 سعرة',
    );
    return '$_temp0';
  }

  @override
  String recipeMacro(String amount, String macro) {
    return '$amount جم $macro';
  }

  @override
  String recipeSummary(int minutes, String difficulty, String meal) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      many: '$minutes دقيقة',
      few: '$minutes دقائق',
      two: 'دقيقتان',
      one: 'دقيقة واحدة',
      zero: '0 دقيقة',
    );
    return '$_temp0 · $difficulty · $meal';
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
  String recipeOver(int kcal) {
    String _temp0 = intl.Intl.pluralLogic(
      kcal,
      locale: localeName,
      other: '$kcal سعرة',
      many: '$kcal سعرة',
      few: '$kcal سعرات',
      two: 'سعرتين',
      one: 'سعرة واحدة',
      zero: '0 سعرة',
    );
    return 'تتجاوز المتبقي بـ $_temp0';
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
    return 'تعذر تحميل وجبات المكافأة: $error';
  }

  @override
  String cravingLimitError(String error) {
    return 'يحتوي الشهر المحدد بالفعل على وجبتي مكافأة. $error';
  }

  @override
  String cravingSaveError(String error) {
    return 'تعذر الحفظ: $error';
  }

  @override
  String get cravingValidate => 'أدخل من 1 إلى 200 حرف.';

  @override
  String get cravingDeleteTitle => 'حذف وجبة المكافأة؟';

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
  String cravingUsed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'استخدمت $count من 2 هذا الشهر',
      many: 'استخدمت $count من 2 هذا الشهر',
      few: 'استخدمت $count من 2 هذا الشهر',
      two: 'استخدمت اثنتين من 2 هذا الشهر',
      one: 'استخدمت واحدة من 2 هذا الشهر',
      zero: 'استخدمت 0 من 2 هذا الشهر',
    );
    return '$_temp0';
  }

  @override
  String get cravingMonthlyLimit =>
      'بلغت الحد الشهري. عدّل أو احذف إدخالاً لإضافة آخر.';

  @override
  String cravingDay(String day) {
    return 'وجبة مكافأة ليوم $day';
  }

  @override
  String get cravingCharacters => 'من 1 إلى 200 حرف';

  @override
  String get cravingAdd => 'إضافة وجبة مكافأة';

  @override
  String get cravingEmpty => 'لم تضف أي وجبات بعد.';

  @override
  String get cravingEdit => 'تعديل';

  @override
  String get cravingEditTitle => 'تعديل وجبة المكافأة';

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
  String academyBurn(int kcal, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      kcal,
      locale: localeName,
      other: '$kcal سعرة',
      many: '$kcal سعرة',
      few: '$kcal سعرات',
      two: 'سعرتين',
      one: 'سعرة واحدة',
      zero: '0 سعرة',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      many: '$minutes دقيقة',
      few: '$minutes دقائق',
      two: 'دقيقتان',
      one: 'دقيقة واحدة',
      zero: '0 دقيقة',
    );
    return 'حوالي $_temp0 / $_temp1';
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
  String plannerWorkoutSummary(int minutes, String effort) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      many: '$minutes دقيقة',
      few: '$minutes دقائق',
      two: 'دقيقتان',
      one: 'دقيقة واحدة',
      zero: '0 دقيقة',
    );
    return 'تمرين · $_temp0 · مجهود $effort%';
  }

  @override
  String plannerSplitSummary(int minutes, String effort) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      many: '$minutes دقيقة',
      few: '$minutes دقائق',
      two: 'دقيقتان',
      one: 'دقيقة واحدة',
      zero: '0 دقيقة',
    );
    return '$_temp0 · مجهود $effort%';
  }

  @override
  String plannerWorkoutNoDuration(String effort) {
    return 'تمرين · المدة غير متاحة · مجهود $effort%';
  }

  @override
  String plannerSplitNoDuration(String effort) {
    return 'المدة غير متاحة · مجهود $effort%';
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
  String mergeMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      many: '$minutes دقيقة',
      few: '$minutes دقائق',
      two: 'دقيقتان',
      one: 'دقيقة واحدة',
      zero: '0 دقيقة',
    );
    return '$_temp0';
  }

  @override
  String mergeShortMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      many: '$minutes دقيقة',
      few: '$minutes دقائق',
      two: 'دقيقتان',
      one: 'دقيقة واحدة',
      zero: '0 دقيقة',
    );
    return '$_temp0';
  }

  @override
  String mergeNamedValue(String name, String value) {
    return '$name: $value';
  }

  @override
  String mergeCalories(int count, String calories) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$calories سعرة',
      many: '$calories سعرة',
      few: '$calories سعرات',
      two: 'سعرتان',
      one: 'سعرة واحدة',
      zero: '0 سعرة',
    );
    return '$_temp0';
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
  String burnedAmount(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount سعرة محروقة',
      many: '$amount سعرة محروقة',
      few: '$amount سعرات محروقة',
      two: 'سعرتان محروقتان',
      one: 'سعرة واحدة محروقة',
      zero: '0 سعرة محروقة',
    );
    return '$_temp0';
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
    return 'الهدف: $amount سعرة';
  }

  @override
  String get burnGoalNote =>
      'هدف الحرق اليومي • يشمل الإجمالي تمارين اللياقة والحركة.';

  @override
  String get burnRingNote => 'تستخدم كل حلقة هدف الحرق اليومي كهدف لها.';

  @override
  String totalBurn(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount سعرة',
      many: '$amount سعرة',
      few: '$amount سعرات',
      two: 'سعرتان',
      one: 'سعرة واحدة',
      zero: '0 سعرة',
    );
    return 'إجمالي الحرق ($_temp0)';
  }

  @override
  String strengthBurn(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount سعرة',
      many: '$amount سعرة',
      few: '$amount سعرات',
      two: 'سعرتان',
      one: 'سعرة واحدة',
      zero: '0 سعرة',
    );
    return 'حرق القوة ($_temp0)';
  }

  @override
  String cardioBurn(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount سعرة',
      many: '$amount سعرة',
      few: '$amount سعرات',
      two: 'سعرتان',
      one: 'سعرة واحدة',
      zero: '0 سعرة',
    );
    return 'حرق الكارديو ($_temp0)';
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
  String workoutLogs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سجل التمارين ($count تمرين)',
      many: 'سجل التمارين ($count تمرينًا)',
      few: 'سجل التمارين ($count تمارين)',
      two: 'سجل التمارين (تمرينان)',
      one: 'سجل التمارين (تمرين واحد)',
      zero: 'سجل التمارين (0 تمرين)',
    );
    return '$_temp0';
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
  String workoutSavedTitle(String name, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      many: '$minutes دقيقة',
      few: '$minutes دقائق',
      two: 'دقيقتان',
      one: 'دقيقة واحدة',
      zero: '0 دقيقة',
    );
    return '$name - $_temp0';
  }

  @override
  String get justNow => 'الآن';

  @override
  String get workoutIntensity => 'الشدة';

  @override
  String get workoutEstimateUnavailable =>
      'التقدير غير متاح — أدخل السعرات يدويًا.';

  @override
  String workoutEstimate(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount سعرة محروقة',
      many: '$amount سعرة محروقة',
      few: '$amount سعرات محروقة',
      two: 'سعرتان محروقتان',
      one: 'سعرة واحدة محروقة',
      zero: '0 سعرة محروقة',
    );
    return '≈ $_temp0';
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
  String foodGoalSummary(String goal, String estimated, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر مسجل',
      many: '$count عنصرًا مسجلًا',
      few: '$count عناصر مسجلة',
      two: 'عنصران مسجلان',
      one: 'عنصر واحد مسجل',
      zero: '0 عنصر مسجل',
    );
    return 'الهدف: $goal$estimated • $_temp0';
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
  String foodGroupTotals(int calories, String protein) {
    String _temp0 = intl.Intl.pluralLogic(
      calories,
      locale: localeName,
      other: '$calories سعرة',
      many: '$calories سعرة',
      few: '$calories سعرات',
      two: 'سعرتان',
      one: 'سعرة واحدة',
      zero: '0 سعرة',
    );
    return '$_temp0 • $protein جم بروتين';
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
  String foodCaloriesLines(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amount\nسعرة',
      many: '$amount\nسعرة',
      few: '$amount\nسعرات',
      two: 'سعرتان',
      one: 'سعرة واحدة',
      zero: '0\nسعرة',
    );
    return '$_temp0';
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
  String explorerShowing(int shown, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      shown,
      locale: localeName,
      other: 'عرض $shown عنصر من $total',
      many: 'عرض $shown عنصرًا من $total',
      few: 'عرض $shown عناصر من $total',
      two: 'عرض عنصرين من $total',
      one: 'عرض عنصر واحد من $total',
      zero: 'عرض 0 من $total',
    );
    return '$_temp0';
  }

  @override
  String get explorerEmpty => 'لم يتم العثور على أطعمة مطابقة';

  @override
  String get explorerEmptyHint => 'جرب بحثًا آخر أو أزل أحد المرشحات.';

  @override
  String get explorerDisclaimer => 'القيم الغذائية تقديرية وتقريبية.';

  @override
  String explorerPer100(int calories) {
    String _temp0 = intl.Intl.pluralLogic(
      calories,
      locale: localeName,
      other: '$calories سعرة',
      many: '$calories سعرة',
      few: '$calories سعرات',
      two: 'سعرتان',
      one: 'سعرة واحدة',
      zero: '0 سعرة',
    );
    return 'لكل 100 جم: $_temp0';
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
  String explorerLogged(String name, int calories) {
    String _temp0 = intl.Intl.pluralLogic(
      calories,
      locale: localeName,
      other: '$calories سعرة',
      many: '$calories سعرة',
      few: '$calories سعرات',
      two: 'سعرتان',
      one: 'سعرة واحدة',
      zero: '0 سعرة',
    );
    return 'تم تسجيل $name ($_temp0)';
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
  String profileAdjustment(int count, String amount, String minor) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount سعرة',
      many: '$amount سعرة',
      few: '$amount سعرات',
      two: '$amount سعرتان',
      one: '$amount سعرة',
      zero: '$amount سعرة',
    );
    return 'تعديل الهدف: $_temp0$minor';
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
  String memberHandle(String id) {
    return 'عضو $id';
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
  String progressHighest(int xp) {
    String _temp0 = intl.Intl.pluralLogic(
      xp,
      locale: localeName,
      other: '$xp نقطة خبرة',
      many: '$xp نقطة خبرة',
      few: '$xp نقاط خبرة',
      two: 'نقطتا خبرة',
      one: 'نقطة خبرة واحدة',
      zero: '0 نقطة خبرة',
    );
    return '$_temp0 · أعلى مستوى';
  }

  @override
  String progressNext(int xp, int remaining, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      xp,
      locale: localeName,
      other: '$xp نقطة خبرة',
      many: '$xp نقطة خبرة',
      few: '$xp نقاط خبرة',
      two: 'نقطتا خبرة',
      one: 'نقطة خبرة واحدة',
      zero: '0 نقطة خبرة',
    );
    String _temp1 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: 'تبقى $remaining نقطة',
      many: 'تبقت $remaining نقطة',
      few: 'تبقت $remaining نقاط',
      two: 'تبقت نقطتان',
      one: 'تبقت نقطة واحدة',
      zero: 'تبقى 0 نقطة',
    );
    return '$_temp0 · $_temp1 للوصول إلى $name';
  }

  @override
  String progressFreeze(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText رمز تجميد',
      many: '$countText رمز تجميد',
      few: '$countText رموز تجميد',
      two: 'رمزا تجميد',
      one: 'رمز تجميد واحد',
      zero: '0 رمز تجميد',
    );
    return '$_temp0';
  }

  @override
  String progressPoints(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText نقطة في المتجر',
      many: '$countText نقطة في المتجر',
      few: '$countText نقاط في المتجر',
      two: 'نقطتان في المتجر',
      one: 'نقطة واحدة في المتجر',
      zero: '0 نقطة في المتجر',
    );
    return '$_temp0';
  }

  @override
  String rewardConfirm(String name) {
    return 'استبدال $name؟';
  }

  @override
  String rewardSpend(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'استخدام $count نقطة من المتجر؟',
      many: 'استخدام $count نقطة من المتجر؟',
      few: 'استخدام $count نقاط من المتجر؟',
      two: 'استخدام نقطتين من المتجر؟',
      one: 'استخدام نقطة واحدة من المتجر؟',
      zero: 'استخدام 0 نقطة من المتجر؟',
    );
    return '$_temp0';
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
  String rewardFreezeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رمز تجميد',
      many: '$count رمز تجميد',
      few: '$count رموز تجميد',
      two: 'رمزا تجميد',
      one: 'رمز تجميد واحد',
      zero: '0 رمز تجميد',
    );
    return '$_temp0 / 3';
  }

  @override
  String get rewardInfo =>
      'عناصر رقمية فقط. تُحفظ السمات والإطارات والألقاب ضمن مكافآتك؛ تطبيقها غير متاح بعد.';

  @override
  String get rewardEmpty => 'لا توجد مكافآت متاحة حاليًا.';

  @override
  String get rewardUnlimited => 'مخزون غير محدود';

  @override
  String rewardRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'المتبقي $count',
      many: 'المتبقي $count',
      few: 'المتبقي $count',
      two: 'المتبقي اثنتان',
      one: 'المتبقي واحدة',
      zero: 'المتبقي 0',
    );
    return '$_temp0';
  }

  @override
  String rewardDetails(int cost, String tier, String stock) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '$cost نقطة',
      many: '$cost نقطة',
      few: '$cost نقاط',
      two: 'نقطتان',
      one: 'نقطة واحدة',
      zero: '0 نقطة',
    );
    return '$_temp0 · الفئة $tier · $stock';
  }

  @override
  String rewardRequires(String tier) {
    return 'يتطلب الفئة $tier';
  }

  @override
  String rewardNeedPoints(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تحتاج إلى $count نقطة إضافية',
      many: 'تحتاج إلى $count نقطة إضافية',
      few: 'تحتاج إلى $count نقاط إضافية',
      two: 'تحتاج إلى نقطتين إضافيتين',
      one: 'تحتاج إلى نقطة إضافية واحدة',
      zero: 'تحتاج إلى 0 نقطة إضافية',
    );
    return '$_temp0';
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
  String progressAchievementValue(String progress, String threshold, int xp) {
    String _temp0 = intl.Intl.pluralLogic(
      xp,
      locale: localeName,
      other: '$xp نقطة خبرة',
      many: '$xp نقطة خبرة',
      few: '$xp نقاط خبرة',
      two: 'نقطتا خبرة',
      one: 'نقطة خبرة واحدة',
      zero: '0 نقطة خبرة',
    );
    return '$progress / $threshold · $_temp0';
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
  String pathDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوم',
      many: '$days يومًا',
      few: '$days أيام',
      two: 'يومان',
      one: 'يوم واحد',
      zero: '0 يوم',
    );
    return '$_temp0';
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
  String get defaultHighProteinFuel => 'وجبة غنية بالبروتين';

  @override
  String get defaultAthleticTraining => 'تدريب رياضي';

  @override
  String get defaultQuickCalorieSnack => 'وجبة خفيفة سريعة';

  @override
  String get defaultQuickExerciseBurn => 'تمرين سريع';

  @override
  String get language => 'اللغة';

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
  String get cravingsTitle => 'وجبات المكافأة';

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
      'سيتوفر تسجيل الدخول الاجتماعي لاحقاً.';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get resetInstructions => 'أدخل بريدك الإلكتروني لطلب الرمز من بريدك.';

  @override
  String get resetChoosePassword => 'اختر كلمة مرور جديدة';

  @override
  String get resetCodeInstructions =>
      'أدخل الرمز من بريدك الإلكتروني وكلمة المرور الجديدة.';

  @override
  String get resetSendCode => 'إرسال الرمز';

  @override
  String get resetCode => 'الرمز من بريدك الإلكتروني';

  @override
  String get resetNewPassword => 'كلمة المرور الجديدة';

  @override
  String get resetUpdatePassword => 'تحديث كلمة المرور';

  @override
  String get resetResendCode => 'إرسال الرمز مرة أخرى';

  @override
  String resetResendCountdown(int seconds) {
    return 'إعادة الإرسال بعد $seconds ثانية';
  }

  @override
  String get resetNeutralMessage =>
      'إذا كان لهذا البريد حساب، فقد أرسلنا رمزاً.';

  @override
  String get resetCodeFormatError =>
      'أدخل الرمز من بريدك الإلكتروني باستخدام 6 إلى 10 أرقام.';

  @override
  String get resetInvalidCode =>
      'الرمز غير صحيح أو انتهت صلاحيته. اطلب رمزاً جديداً وحاول مرة أخرى.';

  @override
  String get resetTooManyRequests =>
      'المحاولات كثيرة. انتظر قليلاً وحاول مرة أخرى.';

  @override
  String get resetError => 'تعذر إعادة تعيين كلمة المرور. حاول مرة أخرى.';

  @override
  String get resetSuccess => 'تم تحديث كلمة المرور. يمكنك تسجيل الدخول الآن.';

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
  String get networkError =>
      'لا يوجد اتصال بالإنترنت. تحقق من اتصالك وحاول مرة أخرى.';

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
  String get goalChampionship => 'الاستعداد لبطولة طبيعية';

  @override
  String get goalMuscle => 'زيادة العضلات';

  @override
  String get goalSports => 'الجمع بين الرياضة وتمارين القوة';

  @override
  String get goalFatLoss => 'خسارة دهون الجسم';

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

  @override
  String get privacyDataTitle => 'الخصوصية والبيانات';

  @override
  String get privacyDataSubtitle => 'كيف تُحفظ بياناتك وتُستخدم في التطبيق';

  @override
  String get privacyStoreTitle => 'ما الذي نحفظه';

  @override
  String get privacyStoreBody =>
      'يُحفظ ملفك الشخصي وسجل الطعام والتمارين والمحتوى الذي تنشره في المجتمع وتقدمك في قاعدة بيانات Supabase الخاصة بالتطبيق. تبقى صورة ملفك الشخصي والمظهر على جهازك فقط.';

  @override
  String get privacyCoachTitle => 'المدرب الذكي';

  @override
  String get privacyCoachBody =>
      'تُرسل الرسائل إلى Google Gemini للحصول على رد، ولا يخزنها التطبيق. لا تُرسل أرقام السعرات إلا إذا فعّلت الموافقة. لا تشارك بيانات شخصية أو صحية لا تريد إرسالها. قد يخطئ المدرب ولا يُعد نصيحة طبية.';

  @override
  String get privacyChoicesTitle => 'خياراتك';

  @override
  String get privacyConsentTitle => 'مشاركة بيانات السعرات مع المدرب';

  @override
  String get privacyConsentSubtitle =>
      'يستخدم إعداد الموافقة نفسه الموجود في المدرب الذكي.';

  @override
  String get privacyDeletionTitle => 'حذف البيانات';

  @override
  String get privacyDeletionBody =>
      'حذف الحساب غير متاح داخل التطبيق حالياً. لطلب حذف بياناتك، تواصل مع الدعم.';

  @override
  String get privacySupport => 'التواصل مع الدعم';

  @override
  String get privacyCopyEmail => 'نسخ البريد الإلكتروني';

  @override
  String get privacyEmailCopied => 'تم نسخ بريد الدعم.';

  @override
  String get privacyEmailCopyFailed => 'تعذر نسخ بريد الدعم.';

  @override
  String get privacySignOut => 'تسجيل الخروج';
}
