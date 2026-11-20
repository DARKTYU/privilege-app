import 'fitness_logic.dart';

enum WorkoutIntensity { light, moderate, vigorous }

enum WorkoutActivity {
  strength('Strength training', '🏋️', BurnType.strength),
  walking('Walking', '🚶', BurnType.cardio),
  running('Running', '🏃', BurnType.cardio),
  cycling('Cycling', '🚴', BurnType.cardio),
  swimming('Swimming', '🏊', BurnType.cardio),
  football('Football', '⚽', BurnType.cardio),
  basketball('Basketball', '🏀', BurnType.cardio),
  tennis('Tennis', '🎾', BurnType.cardio),
  circuit('HIIT or circuit', '⚡', BurnType.cardio),
  martialArts('Boxing or martial arts', '🥊', BurnType.cardio),
  yoga('Yoga or stretching', '🧘', BurnType.cardio),
  jumpRope('Jump rope', '🪢', BurnType.cardio),
  other('Other', '🏃', BurnType.cardio);

  const WorkoutActivity(this.label, this.icon, this.type);
  final String label, icon;
  final BurnType type;
}

// Approximate values based on the Compendium of Physical Activities.
const workoutMetValues = <WorkoutActivity, List<double>>{
  WorkoutActivity.strength: [3.5, 5.0, 6.0],
  WorkoutActivity.walking: [2.8, 3.8, 5.0],
  WorkoutActivity.running: [7.0, 9.8, 11.5],
  WorkoutActivity.cycling: [4.0, 6.8, 10.0],
  WorkoutActivity.swimming: [5.8, 7.0, 9.8],
  WorkoutActivity.football: [7.0, 8.5, 10.0],
  WorkoutActivity.basketball: [4.5, 6.5, 8.0],
  WorkoutActivity.tennis: [6.0, 7.3, 8.0],
  WorkoutActivity.circuit: [6.0, 8.0, 10.0],
  WorkoutActivity.martialArts: [5.5, 7.8, 10.3],
  WorkoutActivity.yoga: [2.0, 2.5, 3.3],
  WorkoutActivity.jumpRope: [8.8, 11.8, 12.3],
};

int? estimateWorkoutCalories(WorkoutActivity activity,
    WorkoutIntensity intensity, double? weightKg, int? minutes) {
  final met = workoutMetValues[activity];
  if (met == null ||
      weightKg == null ||
      !weightKg.isFinite ||
      weightKg <= 0 ||
      minutes == null ||
      minutes < 1 ||
      minutes > 600) {
    return null;
  }
  return (met[intensity.index] * weightKg * minutes / 60).round();
}
