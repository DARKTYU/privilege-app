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
    required this.dailyCalorieTarget,
    required this.onboardingCompleted,
    this.birthDate,
    this.sex,
    this.activity,
    this.nutritionGoal,
    this.hasWeight = true,
    this.hasHeight = true,
    this.hasSavedTarget = true,
  });

  final String name, username, targetGoal, experienceLevel, bio;
  final double weightKg, heightCm;
  final int dailyCalorieTarget;
  final bool onboardingCompleted;
  final DateTime? birthDate;
  final TargetSex? sex;
  final TargetActivity? activity;
  final NutritionGoal? nutritionGoal;
  final bool hasWeight, hasHeight, hasSavedTarget;

  UserProfile copyWith({
    String? name,
    String? username,
    double? weightKg,
    double? heightCm,
    String? targetGoal,
    String? bio,
    int? dailyCalorieTarget,
    bool? onboardingCompleted,
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
        dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
        onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
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
  name: '',
  username: '',
  weightKg: 78,
  heightCm: 182,
  targetGoal: '',
  experienceLevel: '',
  bio: '',
  dailyCalorieTarget: 2600,
  onboardingCompleted: true,
);

const goals = <String>[
  'Natural Championship Qualification',
  'Lean Muscle Mass Hypertrophy',
  'Sports & Strength Split Merger',
  'Metabolic Fat Loss & Calorie Deficit',
];
