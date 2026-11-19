import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(usernameError)));
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
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

  Widget _profileAvatar(String fallbackUrl, double size) {
    final encoded = appState.profilePhotoBase64;
    if (encoded == null) return avatar(fallbackUrl, size);
    return ClipOval(
      child: Image.memory(
        base64Decode(encoded),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CircleAvatar(
          radius: size / 2,
          backgroundColor: kCard2,
          child: Icon(Icons.person, color: kMuted, size: size * 0.6),
        ),
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
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            FutureBuilder<String>(
              future: _subscription,
              builder: (context, snapshot) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScreenHeader(
                    'Athlete Profile',
                    snapshot.connectionState != ConnectionState.done
                        ? 'Loading membership...'
                        : snapshot.hasError
                            ? 'Membership unavailable'
                            : 'Privilege ${snapshot.data} Member',
                    actions: [
                      IconButton(
                        tooltip: 'Settings',
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
                        label: Text(_editing ? 'Cancel' : 'Edit Profile'),
                      ),
                    ],
                  ),
                  if (snapshot.hasError)
                    TextButton(
                      onPressed: _reloadSubscription,
                      child: const Text('Retry membership'),
                    ),
                ],
              ),
            ),
            if (_saved) toastBanner('Profile successfully updated!'),
            if (_editing)
              Panel(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Full Name',
                          style: TextStyle(fontSize: 11, color: kMuted)),
                      const SizedBox(height: 4),
                      TextField(
                          controller: _name,
                          decoration: fieldDecoration('Full name')),
                      const SizedBox(height: 10),
                      Text('Username',
                          style: TextStyle(fontSize: 11, color: kMuted)),
                      TextField(
                          controller: _username,
                          autocorrect: false,
                          decoration: fieldDecoration('Username')),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _weight,
                            keyboardType: TextInputType.number,
                            decoration: fieldDecoration('Weight (kg)'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _height,
                            keyboardType: TextInputType.number,
                            decoration: fieldDecoration('Height (cm)'),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Text('Target Goal',
                          style: TextStyle(fontSize: 11, color: kMuted)),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: goals.contains(_goal) ? _goal : null,
                        hint: const Text('Choose a target goal'),
                        dropdownColor: kCard2,
                        items: [
                          for (final g in goals)
                            DropdownMenuItem(
                                value: g,
                                child: Text(g,
                                    style: const TextStyle(fontSize: 13)))
                        ],
                        onChanged: (v) => setState(() => _goal = v ?? _goal),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                          controller: _bio,
                          maxLines: 2,
                          decoration: fieldDecoration('Athlete bio')),
                      const SizedBox(height: 12),
                      PrimaryButton('Save Changes',
                          icon: Icons.check, onPressed: _save),
                    ]),
              )
            else ...[
              Panel(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Stack(alignment: Alignment.bottomRight, children: [
                          _profileAvatar(p.avatarUrl, 72),
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
                                Text('@${p.username}',
                                    style:
                                        TextStyle(fontSize: 12, color: kMuted)),
                                if (appState.email.isNotEmpty)
                                  Text(appState.email,
                                      style: TextStyle(
                                          fontSize: 11, color: kMuted)),
                              ]),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Text('“${p.bio}”',
                          style: TextStyle(
                              fontSize: 12,
                              color: kMuted,
                              fontStyle: FontStyle.italic)),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.2,
                        children: [
                          _stat(
                              Icons.monitor_weight_outlined,
                              'Current Weight',
                              p.hasWeight
                                  ? '${p.weightKg.round()} kg'
                                  : 'Not set',
                              kRed),
                          _stat(
                              Icons.straighten,
                              'Height',
                              p.hasHeight
                                  ? '${p.heightCm.round()} cm'
                                  : 'Not set',
                              kCyan),
                          _stat(
                              Icons.local_fire_department,
                              'Calorie Goal',
                              appState.targetCalories > 0
                                  ? '${fmt(appState.targetCalories)} kcal${appState.calorieTarget.isEstimate ? ' • Estimated' : ''}'
                                  : 'Not set',
                              kOrange),
                          _stat(Icons.workspace_premium, 'Body Fat %',
                              '${p.bodyFatPercent}%', kGold),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            showCalorieProfileSheet(context, appState),
                        icon: const Icon(Icons.monitor_heart_outlined),
                        label: const Text('Complete your calorie profile'),
                      ),
                    ]),
              ),
              LevelProgressPanel(repository: _progression),
              Wrap(spacing: 8, children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/rewards'),
                  icon: const Icon(Icons.card_giftcard),
                  label: const Text('Rewards Store'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/badges'),
                  icon: const Icon(Icons.workspace_premium),
                  label: const Text('Badges & Achievements'),
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
                          Text('Active Target:',
                              style: TextStyle(fontSize: 11, color: kMuted)),
                          Text(p.targetGoal.isEmpty ? 'Not set' : p.targetGoal,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                        ]),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/classified'),
                    child: const Text('Track →'),
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
                        SnackBar(content: Text(error.message)),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sign Out of Privilege'),
              ),
            ],
          ],
        );
      },
    );
  }
}
