import 'package:flutter/material.dart';

import '../ui.dart';
import '../l10n_strings.dart';
import '../services/progression_repository.dart';
import '../services/coach_client.dart';
import '../state.dart';
import 'alerts.dart';
import 'calories.dart';
import 'chat.dart';
import 'plan.dart';
import 'profile.dart';
import 'splits.dart';

class HomeShell extends StatefulWidget {
  const HomeShell(
      {super.key,
      this.alertBell,
      this.progressionRepository,
      this.plannerState,
      this.coachClient});
  final Widget? alertBell;
  final ProgressionDataSource? progressionRepository;
  final AppState? plannerState;
  final CoachClient? coachClient;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with WidgetsBindingObserver {
  int _i = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Shortcut strip from the React app's bottom navigation.
  List<(String, IconData, String)> get _shortcuts {
    final l = strings(context);
    return [
      (l.community, Icons.people_alt_outlined, '/community'),
      (l.recipes, Icons.menu_book, '/recipes'),
      (l.arena, Icons.emoji_events, '/arena'),
      (l.cheatMeals, Icons.no_food, '/cheats'),
      (l.classified, Icons.workspace_premium, '/classified'),
      (l.academy, Icons.explore, '/academy'),
      (l.vipPlans, Icons.diamond, '/plans'),
    ];
  }

  Widget _nav(int i, IconData icon, String label) {
    final on = _i == i;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _i = i),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: on ? kGold : kMuted),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  maxLines: 1,
                  style: TextStyle(fontSize: 11, color: on ? kGold : kMuted)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _shortcutList({required bool caloriesTab}) => SizedBox(
        height: caloriesTab ? 52 : 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: caloriesTab
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 2)
              : const EdgeInsets.symmetric(horizontal: 12),
          children: [
            for (final s in _shortcuts)
              Padding(
                padding: EdgeInsetsDirectional.only(
                    end: 8, bottom: caloriesTab ? 2 : 6),
                child: ActionChip(
                  avatar: Icon(s.$2, size: 16, color: kGold),
                  label: Text(s.$1, style: const TextStyle(fontSize: 12)),
                  backgroundColor: kCard2,
                  side: BorderSide.none,
                  onPressed: () => Navigator.pushNamed(context, s.$3),
                ),
              ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return ThemeAwareBuilder(
      builder: () => Scaffold(
        body: SafeArea(
          child: Column(children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: widget.alertBell ?? const AlertBell(),
            ),
            Expanded(
              child: IndexedStack(
                index: _i,
                children: [
                  PlanScreen(state: widget.plannerState),
                  SplitsScreen(
                      state: widget.plannerState,
                      active: _i == 1,
                      onManageSplits: () => setState(() => _i = 0)),
                  const CaloriesSection(),
                  ProfileScreen(
                      progressionRepository: widget.progressionRepository),
                ],
              ),
            ),
            keyboardOpen
                ? const SizedBox.shrink()
                : SizedBox(
                    height: 80,
                    child: Column(children: [
                      _shortcutList(caloriesTab: true),
                      const SizedBox(height: 28),
                    ]),
                  ),
          ]),
        ),
        floatingActionButton: keyboardOpen
            ? null
            : FloatingActionButton(
                backgroundColor: kMaroon,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: const CircleBorder(),
                tooltip: strings(context).botTooltip,
                onPressed: () =>
                    showCoachSheet(context, client: widget.coachClient),
                child: const Icon(Icons.smart_toy_rounded),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          color: kCard,
          surfaceTintColor: Colors.transparent,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: Row(children: [
            Expanded(child: _nav(0, Icons.home_rounded, strings(context).home)),
            Expanded(child: _nav(1, Icons.shuffle, strings(context).splits)),
            const SizedBox(width: 48),
            Expanded(
                child: _nav(
                    2, Icons.local_fire_department, strings(context).calories)),
            Expanded(child: _nav(3, Icons.person, strings(context).profile)),
          ]),
        ),
      ),
    );
  }
}
