import 'package:flutter/material.dart';

import '../ui.dart';
import 'calories.dart';
import 'plan.dart';
import 'profile.dart';
import 'splits.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _i = 0;

  // Shortcut strip from the React app's bottom navigation.
  static const _shortcuts = <(String, IconData, String)>[
    ('Community', Icons.people_alt_outlined, '/community'),
    ('Recipes', Icons.menu_book, '/recipes'),
    ('Streak Arena', Icons.emoji_events, '/arena'),
    ('Cheat Meals', Icons.no_food, '/cheats'),
    ('Classified Level', Icons.workspace_premium, '/classified'),
    ('Academy', Icons.explore, '/academy'),
    ('VIP Plans', Icons.diamond, '/plans'),
  ];

  Widget _nav(int i, IconData icon, String label) {
    final on = _i == i;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _i = i),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: on ? kGold : kMuted),
          Text(label,
              style: TextStyle(fontSize: 11, color: on ? kGold : kMuted)),
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
                padding: EdgeInsets.only(right: 8, bottom: caloriesTab ? 2 : 6),
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
    return ThemeAwareBuilder(
      builder: () => Scaffold(
        body: SafeArea(
          child: Column(children: [
            Expanded(
              child: IndexedStack(
                index: _i,
                children: [
                  PlanScreen(),
                  SplitsScreen(),
                  CaloriesSection(),
                  ProfileScreen(),
                ],
              ),
            ),
            SizedBox(
              height: _i == 2 ? 80 : 44,
              child: _i == 2
                  ? Column(children: [
                      _shortcutList(caloriesTab: true),
                      const SizedBox(height: 28),
                    ])
                  : _shortcutList(caloriesTab: false),
            ),
          ]),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: kMaroon,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: const CircleBorder(),
          tooltip: 'AI Privilege Bot',
          onPressed: () => Navigator.pushNamed(context, '/chat'),
          child: const Icon(Icons.smart_toy_rounded),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          color: kCard,
          surfaceTintColor: Colors.transparent,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _nav(0, Icons.home_rounded, 'Home'),
            _nav(1, Icons.shuffle, 'Splits'),
            const SizedBox(width: 48),
            _nav(2, Icons.local_fire_department, 'Calories'),
            _nav(3, Icons.person, 'Profile'),
          ]),
        ),
      ),
    );
  }
}
