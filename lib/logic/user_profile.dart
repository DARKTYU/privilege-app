import 'fitness_logic.dart';
import 'calorie_target.dart';

/// Port of src/types/user.ts
class UserProfile {
  const UserProfile({
    required this.name,
    required this.username,
    required this.weightKg,
    required this.heightCm,
    required this.targetGoal,
    required this.experienceLevel,
    required this.bio,
    required this.avatarUrl,
    required this.bodyFatPercent,
    required this.muscleMassKg,
    required this.naturalVerified,
    required this.dailyCalorieTarget,
    required this.onboardingCompleted,
    required this.subscriptionTier,
    required this.subscriptionRenewalDate,
    this.birthDate,
    this.sex,
    this.activity,
    this.nutritionGoal,
    this.hasWeight = true,
    this.hasHeight = true,
    this.hasSavedTarget = true,
  });

  final String name, username, targetGoal, experienceLevel, bio, avatarUrl;
  final String subscriptionRenewalDate;
  final double weightKg, heightCm;
  final int bodyFatPercent, muscleMassKg, dailyCalorieTarget;
  final bool naturalVerified, onboardingCompleted;
  final DateTime? birthDate;
  final TargetSex? sex;
  final TargetActivity? activity;
  final NutritionGoal? nutritionGoal;
  final bool hasWeight, hasHeight, hasSavedTarget;
  final SubscriptionTier subscriptionTier;

  UserProfile copyWith({
    String? name,
    String? username,
    double? weightKg,
    double? heightCm,
    String? targetGoal,
    String? bio,
    int? dailyCalorieTarget,
    bool? onboardingCompleted,
    SubscriptionTier? subscriptionTier,
    DateTime? birthDate,
    TargetSex? sex,
    TargetActivity? activity,
    NutritionGoal? nutritionGoal,
    bool? hasWeight,
    bool? hasHeight,
    bool? hasSavedTarget,
  }) =>
      UserProfile(
        name: name ?? this.name,
        username: username ?? this.username,
        weightKg: weightKg ?? this.weightKg,
        heightCm: heightCm ?? this.heightCm,
        targetGoal: targetGoal ?? this.targetGoal,
        experienceLevel: experienceLevel,
        bio: bio ?? this.bio,
        avatarUrl: avatarUrl,
        bodyFatPercent: bodyFatPercent,
        muscleMassKg: muscleMassKg,
        naturalVerified: naturalVerified,
        dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
        onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
        subscriptionTier: subscriptionTier ?? this.subscriptionTier,
        subscriptionRenewalDate: subscriptionRenewalDate,
        birthDate: birthDate ?? this.birthDate,
        sex: sex ?? this.sex,
        activity: activity ?? this.activity,
        nutritionGoal: nutritionGoal ?? this.nutritionGoal,
        hasWeight: hasWeight ?? this.hasWeight,
        hasHeight: hasHeight ?? this.hasHeight,
        hasSavedTarget: hasSavedTarget ?? this.hasSavedTarget,
      );
}

const defaultUserProfile = UserProfile(
  name: 'Alex Johnson',
  username: 'Alex_Athlete',
  weightKg: 78,
  heightCm: 182,
  targetGoal: 'Natural Championship Qualification',
  experienceLevel: 'Natural Athlete',
  bio:
      'Competitive natural physique athlete focused on strength splits and basketball crossover conditioning.',
  avatarUrl:
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=256&h=256&fit=crop&crop=faces',
  bodyFatPercent: 11,
  muscleMassKg: 42,
  naturalVerified: true,
  dailyCalorieTarget: 2600,
  onboardingCompleted: true,
  subscriptionTier: SubscriptionTier.pro,
  subscriptionRenewalDate: 'Nov 17, 2026',
);

const goals = <String>[
  'Natural Championship Qualification',
  'Lean Muscle Mass Hypertrophy',
  'Sports & Strength Split Merger',
  'Metabolic Fat Loss & Calorie Deficit',
];
