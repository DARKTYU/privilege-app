import 'package:flutter/material.dart';

import '../ui.dart';

class CheatsScreen extends StatefulWidget {
  const CheatsScreen({super.key});

  @override
  State<CheatsScreen> createState() => _CheatsScreenState();
}

class _CheatsScreenState extends State<CheatsScreen> {
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
  final List<String> _list = [];
  int _selected = DateTime.now().day;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _add() {
    final v = _input.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _list.insert(0, '$v (Day $_selected)');
      _input.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final lead = DateTime(now.year, now.month, 1).weekday - 1;
    final count = DateTime(now.year, now.month + 1, 0).day;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Expanded(
            child: Text('${_months[now.month - 1]} ${now.year}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 12),
        const Text('Not saved yet'),
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
                        ]),
                  ),
                ),
            ],
          ),
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
          Text('${_list.length} on this screen',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: kMuted)),
        ]),
        const SizedBox(height: 10),
        if (_list.isEmpty) const Text('No meals added yet.'),
        for (var i = 0; i < _list.length; i++)
          Panel(
            padding: EdgeInsets.zero,
            margin: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
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
          ),
      ],
    );
  }
}
