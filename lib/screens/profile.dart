import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../l10n_strings.dart';
import '../logic/user_profile.dart';
import '../logic/username.dart';
import '../services/account_types.dart' show AuthException;
import '../services/progression_repository.dart';
import '../state.dart';
import '../ui.dart';
import 'progression.dart';
import 'calorie_profile_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.progressionRepository});
  final ProgressionDataSource? progressionRepository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  late final _progression =
      widget.progressionRepository ?? ProgressionRepository();
  late Future<String> _subscription;
  bool _editing = false;
  bool _saved = false;
  bool _saving = false;
  Timer? _timer;
  late TextEditingController _name, _username, _weight, _height, _bio;
  late String _goal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = _progression.subscriptionTier();
    _loadForm();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reloadSubscription();
  }

  void _reloadSubscription() {
    setState(() {
      _subscription = _progression.subscriptionTier();
    });
  }

  void _loadForm() {
    final p = appState.profile;
    _name = TextEditingController(text: p.name);
    _username = TextEditingController(text: p.username);
    _weight = TextEditingController(
        text: p.hasWeight ? p.weightKg.round().toString() : '');
    _height = TextEditingController(
        text: p.hasHeight ? p.heightCm.round().toString() : '');
    _bio = TextEditingController(text: p.bio);
    _goal = p.targetGoal;
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _name.dispose();
    _username.dispose();
    _weight.dispose();
    _height.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final p = appState.profile;
    final username = _username.text.trim();
    final usernameError = validateUsername(username);
    if (username != p.username && usernameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings(context).invalidUsername)));
      return;
    }
    final w = double.tryParse(_weight.text) ?? p.weightKg;
    final h = double.tryParse(_height.text) ?? p.heightCm;
    setState(() => _saving = true);
    try {
      await appState.updateProfile(p.copyWith(
        name: _name.text.trim().isEmpty ? p.name : _name.text.trim(),
        username: username,
        weightKg: w,
        heightCm: h,
        hasWeight: double.tryParse(_weight.text) != null || p.hasWeight,
        hasHeight: double.tryParse(_height.text) != null || p.hasHeight,
        targetGoal: _goal,
        bio: _bio.text,
      ));
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error.code == 'username_taken'
                ? strings(context).usernameTaken
                : error.code == 'invalid_username'
                    ? strings(context).invalidUsername
                    : friendlyError(error.message, localizations: strings(context)))));
      }
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    setState(() {
      _editing = false;
      _saved = true;
    });
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  Widget _profileAvatar(String name, double size) {
    final encoded = appState.profilePhotoBase64;
    if (encoded == null) return initialsAvatar(name, size);
    return ClipOval(
      child: Image.memory(
        base64Decode(encoded),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => initialsAvatar(name, size),
      ),
    );
  }

  Widget _stat(IconData i, String label, String v, Color c) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: kCard2, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(i, size: 13, color: c),
            const SizedBox(width: 4),
            Flexible(
                child:
                    Text(label, style: TextStyle(fontSize: 11, color: kMuted))),
          ]),
          const SizedBox(height: 4),
          Text(v,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final p = appState.profile;
        final l = strings(context);
        String goalName(String goal) => switch (goal) {
              'Natural Championship Qualification' => l.goalChampionship,
              'Lean Muscle Mass Hypertrophy' => l.goalMuscle,
              'Sports & Strength Split Merger' => l.goalSports,
              'Metabolic Fat Loss & Calorie Deficit' => l.goalFatLoss,
              _ => goal,
            };
        String tierName(String tier) => switch (tier) {
              'Free' => l.memberFree,
              'Silver' => l.memberSilver,
              'Gold' => l.memberGold,
              _ => tier,
            };
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            FutureBuilder<String>(
              future: _subscription,
              builder: (context, snapshot) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScreenHeader(
                    l.profileTitle,
                    snapshot.connectionState != ConnectionState.done
                        ? l.membershipLoading
                        : snapshot.hasError
                            ? l.membershipUnavailable
                            : l.membershipProfile(tierName(snapshot.data!)),
                  ),
                  Wrap(
                    children: [
                      IconButton(
                        tooltip: l.settings,
                        onPressed: () =>
                            Navigator.pushNamed(context, '/settings'),
                        icon: const Icon(Icons.settings_outlined),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() {
                          if (!_editing) {
                            final profile = appState.profile;
                            _name.text = profile.name;
                            _username.text = profile.username;
                            _weight.text = profile.hasWeight
                                ? profile.weightKg.round().toString()
                                : '';
                            _height.text = profile.hasHeight
                                ? profile.heightCm.round().toString()
                                : '';
                            _bio.text = profile.bio;
                            _goal = profile.targetGoal;
                          }
                          _editing = !_editing;
                        }),
                        icon: const Icon(Icons.edit, size: 16),
                        label: Text(_editing ? l.plannerCancel : l.profileEdit),
                      ),
                    ],
                  ),
                  if (snapshot.hasError)
                    TextButton(
                      onPressed: _reloadSubscription,
                      child: Text(l.membershipRetry),
                    ),
                ],
              ),
            ),
            if (_saved) toastBanner(l.profileUpdated),
            if (_editing)
              Panel(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.profileFullName,
                          style: TextStyle(fontSize: 11, color: kMuted)),
                      const SizedBox(height: 4),
                      TextField(
                          controller: _name,
                          decoration: fieldDecoration(l.profileFullNameHint)),
                      const SizedBox(height: 10),
                      Text(l.username,
                          style: TextStyle(fontSize: 11, color: kMuted)),
                      TextField(
                          controller: _username,
                          autocorrect: false,
                          decoration: fieldDecoration(l.username)),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _weight,
                            keyboardType: TextInputType.number,
                            decoration: fieldDecoration(l.profileWeight),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _height,
                            keyboardType: TextInputType.number,
                            decoration: fieldDecoration(l.profileHeight),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Text(l.profileGoal,
                          style: TextStyle(fontSize: 11, color: kMuted)),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: goals.contains(_goal) ? _goal : null,
                        hint: Text(l.profileChooseGoal),
                        dropdownColor: kCard2,
                        items: [
                          for (final g in goals)
                            DropdownMenuItem(
                                value: g,
                                child: Text(goalName(g),
                                    style: const TextStyle(fontSize: 13)))
                        ],
                        onChanged: (v) => setState(() => _goal = v ?? _goal),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                          controller: _bio,
                          maxLines: 2,
                          decoration: fieldDecoration(l.profileBio)),
                      const SizedBox(height: 12),
                      PrimaryButton(l.profileSaveChanges,
                          icon: Icons.check, onPressed: _save),
                    ]),
              )
            else ...[
              Panel(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Stack(
                            alignment: AlignmentDirectional.bottomEnd,
                            children: [
                              _profileAvatar(
                                  p.name.isEmpty ? p.username : p.name, 72),
                              InkWell(
                                onTap: () =>
                                    Navigator.pushNamed(context, '/settings'),
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: kMaroon,
                                  child: Icon(Icons.photo_camera,
                                      size: 13, color: kCream),
                                ),
                              ),
                            ]),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800)),
                                LeftToRightValue(l.profileHandle(p.username),
                                    style:
                                        TextStyle(fontSize: 12, color: kMuted)),
                                if (appState.email.isNotEmpty)
                                  LeftToRightValue(appState.email,
                                      style: TextStyle(
                                          fontSize: 11, color: kMuted)),
                              ]),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Text(
                          p.bio.isEmpty
                              ? l.profileAddBio
                              : l.profileQuotedBio(p.bio),
                          style: TextStyle(
                              fontSize: 12,
                              color: kMuted,
                              fontStyle:
                                  Localizations.localeOf(context).languageCode ==
                                          'ar'
                                      ? FontStyle.normal
                                      : FontStyle.italic)),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = (constraints.maxWidth - 8) / 2;
                          return Wrap(spacing: 8, runSpacing: 8, children: [
                            SizedBox(
                                width: width,
                                child: _stat(
                                    Icons.monitor_weight_outlined,
                                    l.profileCurrentWeight,
                                    p.hasWeight
                                        ? l.profileKg(
                                            p.weightKg.round().toString())
                                        : l.profileNotSet,
                                    kRed)),
                            SizedBox(
                                width: width,
                                child: _stat(
                                    Icons.straighten,
                                    l.profileHeightLabel,
                                    p.hasHeight
                                        ? l.profileCm(
                                            p.heightCm.round().toString())
                                        : l.profileNotSet,
                                    kCyan)),
                            SizedBox(
                                width: width,
                                child: _stat(
                                    Icons.local_fire_department,
                                    l.profileCalorieGoal,
                                    appState.targetCalories > 0
                                        ? l.profileCalorieValue(
                                            l.mergeCalories(
                                                appState.targetCalories, fmt(appState.targetCalories)),
                                            appState.calorieTarget.isEstimate
                                                ? l.foodEstimated
                                                : '')
                                        : l.profileNotSet,
                                    kOrange)),
                          ]);
                        },
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            showCalorieProfileSheet(context, appState),
                        icon: const Icon(Icons.monitor_heart_outlined),
                        label: Text(p.birthDate == null ||
                                p.sex == null ||
                                p.activity == null ||
                                !p.hasWeight ||
                                !p.hasHeight
                            ? l.profileCompleteCalorie
                            : l.profileEditCalorie),
                      ),
                    ]),
              ),
              LevelProgressPanel(repository: _progression),
              Wrap(spacing: 8, children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/rewards'),
                  icon: const Icon(Icons.card_giftcard),
                  label: Text(l.profileRewards),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/badges'),
                  icon: const Icon(Icons.workspace_premium),
                  label: Text(l.profileBadges),
                ),
              ]),
              Panel(
                child: Row(children: [
                  Icon(Icons.flag_outlined, color: kGold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.profileActiveTarget,
                              style: TextStyle(fontSize: 11, color: kMuted)),
                          Text(
                              p.targetGoal.isEmpty
                                  ? l.profileNotSet
                                  : goalName(p.targetGoal),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                        ]),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/classified'),
                    child: Text(l.profileTrack),
                  ),
                ]),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  foregroundColor: kRed,
                  side: BorderSide(color: kRed.withAlpha(120)),
                ),
                onPressed: () async {
                  try {
                    await appState.logout();
                  } on AuthException catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(friendlyError(error.message, localizations: strings(context)))),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.logout, size: 18),
                label: Text(l.profileSignOut),
              ),
            ],
          ],
        );
      },
    );
  }
}
