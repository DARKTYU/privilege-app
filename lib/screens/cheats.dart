import 'dart:async';

import 'package:flutter/material.dart';

import '../logic/fitness_logic.dart';
import '../ui.dart';

class CheatsScreen extends StatefulWidget {
  const CheatsScreen({super.key});

  @override
  State<CheatsScreen> createState() => _CheatsScreenState();
}

class _CheatsScreenState extends State<CheatsScreen> {
  static const _allowedDays = [8, 20];
  static const _dayNotes = {8: 'Post-Legs Re-feed', 20: 'Tournament Prep Fuel'};
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  final _input = TextEditingController();
  final List<String> _list = [
    'Double Bacon Wagyu Burger (Day 8)',
    'Wood-fired Truffle Pizza (Day 20)',
  ];
  int _selected = 8;
  String? _note;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _add() {
    final v = _input.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _list.insert(0, '$v (Day $_selected)');
      _note = 'Scheduled "$v" on Day $_selected!';
      _input.clear();
    });
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _note = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final lead = DateTime(now.year, now.month, 1).weekday - 1;
    final count = DateTime(now.year, now.month + 1, 0).day;
    final over = _list.length > 2;
    final selAllowed = isDayAllowedForCheat(_selected, _allowedDays);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Expanded(
            child: Text('${_months[now.month - 1]} ${now.year}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          tag('2 Allowed / Month', kGold),
        ]),
        const SizedBox(height: 12),
        Panel(
          child: GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              for (final l in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Center(
                    child:
                        Text(l, style: TextStyle(color: kMuted, fontSize: 12))),
              for (var i = 0; i < lead; i++) const SizedBox(),
              for (var d = 1; d <= count; d++)
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _selected = d),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _selected == d ? kMaroon : kCard2,
                      borderRadius: BorderRadius.circular(10),
                      border: isDayAllowedForCheat(d, _allowedDays)
                          ? Border.all(color: kGold, width: 2)
                          : null,
                    ),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$d',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: _selected == d
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : kMuted)),
                          if (isDayAllowedForCheat(d, _allowedDays))
                            Icon(Icons.auto_awesome, size: 10, color: kGold),
                        ]),
                  ),
                ),
            ],
          ),
        ),
        if (selAllowed)
          Panel(
            borderColor: kGold.withAlpha(110),
            child: Row(children: [
              Icon(Icons.auto_awesome, size: 16, color: kGold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Day $_selected: Cheat Meal Allowed · ${_dayNotes[_selected]}',
                    style: const TextStyle(fontSize: 12)),
              ),
            ]),
          ),
        sectionTitle('Cheat Meal Stats'),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _input,
              onSubmitted: (_) => _add(),
              decoration: fieldDecoration('Add craving for Day $_selected...'),
            ),
          ),
          const SizedBox(width: 8),
          roundIcon(Icons.add, _add, tip: 'Add Cheat Meal'),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: Text('Cheat meal total:',
                  style: TextStyle(fontSize: 12, color: kMuted))),
          Text('${_list.length} scheduled / 2 budgeted',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: over ? kRed : kGreen)),
        ]),
        const SizedBox(height: 10),
        toastBanner(_note),
        for (var i = 0; i < _list.length; i++)
          Panel(
            padding: EdgeInsets.zero,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              dense: true,
              leading: Icon(Icons.cake, color: kGold),
              title: Text(_list[i], style: const TextStyle(fontSize: 13)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: () => setState(() => _list.removeAt(i)),
              ),
            ),
          ),
      ],
    );
  }
}
