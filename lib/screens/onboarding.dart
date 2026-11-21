import 'package:flutter/material.dart';

import '../logic/user_profile.dart';
import '../logic/calorie_target.dart';
import '../logic/username.dart';
import '../l10n_strings.dart';
import '../services/account_types.dart';
import '../state.dart';
import '../ui.dart';
import '../widgets/auth_language_toggle.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _weight;
  late final TextEditingController _height;
  String? _goal;
  bool _lbs = false;
  bool _saving = false;
  String? _error;

  String _translatedError(String value) {
    final l = strings(context);
    switch (value) {
      case 'Username must be 3 to 20 letters, numbers or underscores.':
        return l.invalidUsername;
      case 'Enter your name (up to 60 characters).':
        return l.invalidName;
      case 'Enter both your weight and height.':
        return l.missingMeasurements;
      case 'Weight must be 35-250 kg and height 120-230 cm.':
        return l.invalidMeasurements;
      case 'Choose a primary target goal.':
        return l.chooseGoal;
      case 'That username is already taken.':
        return l.usernameTaken;
      case 'Please log in again.':
        return l.sessionExpired;
      case 'Could not connect. Check your internet connection and try again.':
        return l.networkError;
      default:
        return friendlyError(value, localizations: l);
    }
  }

  String _goalLabel(String value) {
    final l = strings(context);
    switch (goals.indexOf(value)) {
      case 0:
        return l.goalChampionship;
      case 1:
        return l.goalMuscle;
      case 2:
        return l.goalSports;
      case 3:
        return l.goalFatLoss;
      default:
        return value;
    }
  }

  @override
  void initState() {
    super.initState();
    final p = appState.profile;
    _name = TextEditingController(text: p.name);
    _username = TextEditingController();
    _weight = TextEditingController();
    _height = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  double? get _weightKg {
    final w = double.tryParse(_weight.text.trim());
    if (w == null) return null;
    return _lbs ? w * 0.453592 : w;
  }

  double? get _heightCm => double.tryParse(_height.text.trim());

  int? get _recommended {
    final weightKg = _weightKg, heightCm = _heightCm, goal = _goal;
    if (weightKg == null ||
        heightCm == null ||
        goal == null ||
        weightKg < 35 ||
        weightKg > 250 ||
        heightCm < 120 ||
        heightCm > 230) {
      return null;
    }
    return CalorieTarget.calculate(
      today: DateTime.now(),
      weightKg: weightKg.roundToDouble(),
      heightCm: heightCm.roundToDouble(),
      goal: nutritionGoalFromTraining(goal),
      legacyTrainingGoal: goal,
    ).target;
  }

  void _toggleUnit() {
    final w = double.tryParse(_weight.text);
    setState(() {
      if (w != null) {
        _weight.text = (_lbs ? w * 0.453592 : w / 0.453592).round().toString();
      }
      _lbs = !_lbs;
    });
  }

  Future<void> _submit() async {
    final kg = _weightKg,
        cm = _heightCm,
        goal = _goal,
        recommended = _recommended;
    final name = _name.text.trim();
    final username = _username.text.trim();
    final usernameError = validateUsername(username);
    if (usernameError != null) {
      setState(() => _error = usernameError);
      return;
    }
    if (name.isEmpty || name.length > 60) {
      setState(() => _error = 'Enter your name (up to 60 characters).');
      return;
    }
    if (kg == null || cm == null) {
      setState(() => _error = 'Enter both your weight and height.');
      return;
    }
    if (kg < 35 || kg > 250 || cm < 120 || cm > 230) {
      setState(
          () => _error = 'Weight must be 35-250 kg and height 120-230 cm.');
      return;
    }
    if (goal == null || !goals.contains(goal) || recommended == null) {
      setState(() => _error = 'Choose a primary target goal.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await appState.completeOnboarding(appState.profile.copyWith(
        name: name,
        username: username,
        weightKg: kg.roundToDouble(),
        heightCm: cm.roundToDouble(),
        targetGoal: goal,
        dailyCalorieTarget: recommended,
        onboardingCompleted: true,
      ));
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _label(String t, IconData i, Color c) => Padding(
        padding: const EdgeInsetsDirectional.only(start: 4, bottom: 6),
        child: Row(children: [
          Icon(i, size: 14, color: c),
          const SizedBox(width: 6),
          Text(t,
              style: TextStyle(
                  fontSize: 12, color: kMuted, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _measurementHeading({
    required String label,
    required IconData icon,
    required Color color,
    required String unit,
    VoidCallback? onUnitTap,
  }) =>
      SizedBox(
        height: 28,
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: kMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onUnitTap,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 42),
                  height: 24,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: kLine),
                  ),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: onUnitTap == null ? kMuted : kGold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const Padding(
            padding: EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: AuthLanguageToggle(),
            ),
          ),
          Expanded(
              child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: PrivilegeLogo(width: 150)),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(strings(context).setupTitle,
                            style: TextStyle(
                                color: kCream,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2)),
                      ),
                      Center(
                        child: Text(strings(context).setupSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: kMuted, fontSize: 12)),
                      ),
                      const SizedBox(height: 18),
                      _label(strings(context).fullName, Icons.person_outline,
                          kGold),
                      TextField(
                          controller: _name,
                          decoration:
                              fieldDecoration(strings(context).exampleName)),
                      const SizedBox(height: 14),
                      _label(strings(context).username, Icons.alternate_email,
                          kGold),
                      TextField(
                          controller: _username,
                          maxLength: 20,
                          autocorrect: false,
                          decoration:
                              fieldDecoration(strings(context).usernameHint)),
                      const SizedBox(height: 14),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _measurementHeading(
                                      label: strings(context).weight,
                                      icon: Icons.monitor_weight_outlined,
                                      color: kRed,
                                      unit: _lbs ? 'LBS' : 'KG',
                                      onUnitTap: _toggleUnit,
                                    ),
                                    TextField(
                                      controller: _weight,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      onChanged: (_) => setState(() {}),
                                      decoration:
                                          fieldDecoration(_lbs ? '172' : '78'),
                                    ),
                                  ]),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _measurementHeading(
                                      label: strings(context).height,
                                      icon: Icons.straighten,
                                      color: kCyan,
                                      unit: 'CM',
                                    ),
                                    TextField(
                                      controller: _height,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      onChanged: (_) => setState(() {}),
                                      decoration: fieldDecoration('182'),
                                    ),
                                  ]),
                            ),
                          ]),
                      const SizedBox(height: 14),
                      _label(strings(context).primaryGoal, Icons.flag_outlined,
                          kGold),
                      for (final g in goals)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setState(() => _goal = g),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: _goal == g ? kMaroon : kCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _goal == g ? kMaroon : kLine),
                              ),
                              child: Row(children: [
                                Expanded(
                                  child: Text(_goalLabel(g),
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _goal == g
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary
                                              : kMuted)),
                                ),
                                if (_goal == g)
                                  Icon(Icons.circle, size: 10, color: kGold),
                              ]),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Panel(
                        borderColor: kGold.withAlpha(90),
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          Icon(Icons.auto_awesome, size: 16, color: kGold),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(strings(context).estimatedTarget,
                                style: TextStyle(fontSize: 12, color: kMuted)),
                          ),
                          Flexible(
                            child: Text(
                              _recommended == null
                                  ? strings(context).enterDetails
                                  : '${fmt(_recommended!)} ${strings(context).kcalPerDay}',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                  color: kCream, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ]),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(_translatedError(_error!),
                              style: TextStyle(color: kSmallTextAccent, fontSize: 12)),
                        ),
                      PrimaryButton(
                        _saving
                            ? strings(context).saving
                            : strings(context).completeSetup,
                        icon: Icons.arrow_forward,
                        onPressed: _saving ? null : _submit,
                      ),
                    ]),
              ),
            ),
          )),
        ]),
      ),
    );
  }
}
