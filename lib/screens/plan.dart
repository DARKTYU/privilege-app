import 'dart:async';

import 'package:flutter/material.dart';

import '../ui.dart';

class _DayPlan {
  _DayPlan(this.label, this.date, this.workout, this.title);
  final String label;
  final DateTime date;
  bool workout;
  String title;
}

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  late final List<_DayPlan> _week;
  late int _selected;
  double _duration = 60;
  double _intensity = 80;
  String? _toast;
  Timer? _timer;

  static const _cardNames = [
    'Push / Delts',
    'Pull / Heavy',
    'Recovery',
    'Mobility',
    'Cardio Zone 2'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final sunday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday % 7));
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    const types = [true, true, false, false, false, true, true];
    const titles = [
      'Chest & Delts',
      'Heavy Pull',
      'Active Recovery',
      'Mobility & Rest',
      'Core & Stretch',
      'Legs Hypertrophy',
      'Full Athletic'
    ];
    _week = [
      for (var i = 0; i < 7; i++)
        _DayPlan(labels[i], sunday.add(Duration(days: i)), types[i], titles[i]),
    ];
    _selected = now.weekday % 7;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle(int i) => setState(() {
        final d = _week[i];
        d.title = d.workout ? 'Rest Day' : 'Workout Day';
        d.workout = !d.workout;
      });

  void _quickAdd() {
    setState(() => _toast =
        'Added ${_duration.round()}m session (${_intensity.round()}% intensity) to Day ${_week[_selected].date.day}!');
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  Widget _stepper(String label, String value, double v, double min, double max,
      int div, ValueChanged<double> onChanged, double step) {
    return Column(children: [
      Row(children: [
        Expanded(
            child: Text(label, style: TextStyle(fontSize: 12, color: kMuted))),
        Text(value,
            style: TextStyle(color: kCream, fontWeight: FontWeight.w800)),
      ]),
      Row(children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () => onChanged((v - step).clamp(min, max).toDouble()),
        ),
        Expanded(
          child: Slider(
              value: v,
              min: min,
              max: max,
              divisions: div,
              activeColor: kMaroon,
              onChanged: onChanged),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => onChanged((v + step).clamp(min, max).toDouble()),
        ),
      ]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final sel = _week[_selected];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        ScreenHeader(
          'Plan Organiser',
          'Weekly calendar & schedule planner',
          logo: true,
          actions: [
            roundIcon(Icons.add, () {
              final i = _week.indexWhere((d) => !d.workout);
              if (i >= 0) _toggle(i);
            }, tip: 'Add Workout'),
          ],
        ),
        Row(children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _selected = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _selected == i ? kMaroon : kCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _selected == i ? kGold : kLine),
                    ),
                    child: Column(children: [
                      Text(_week[i].label,
                          style: TextStyle(
                              fontSize: 11,
                              color: _selected == i
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : kMuted)),
                      Text('${_week[i].date.day}',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _selected == i
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : kCream)),
                      const SizedBox(height: 4),
                      CircleAvatar(
                          radius: 3,
                          backgroundColor: _week[i].workout ? kGold : kLine),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.05,
          children: [
            for (var i = 0; i < 5; i++)
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _toggle(i),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _week[i].workout ? kMaroon : kCard2,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_week[i].workout ? 'Workout Days' : 'Rest Days',
                            style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withAlpha(190))),
                        const SizedBox(height: 6),
                        Icon(
                            _week[i].workout
                                ? Icons.fitness_center
                                : Icons.free_breakfast,
                            color: kCream),
                        const SizedBox(height: 6),
                        Text(_cardNames[i],
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                ),
              ),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _toggle(_selected),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kMuted),
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: kMuted),
                      SizedBox(height: 4),
                      Text('Add Split',
                          style: TextStyle(fontSize: 11, color: kMuted)),
                    ]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Panel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(
                child: Text('Daily Schedule',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              Text('Day ${sel.date.day} Settings',
                  style: TextStyle(fontSize: 12, color: kMuted)),
            ]),
            const SizedBox(height: 4),
            Text(sel.title, style: TextStyle(color: kCream, fontSize: 12)),
            const SizedBox(height: 8),
            _stepper('Session Duration', '${_duration.round()} mins', _duration,
                15, 180, 11, (v) => setState(() => _duration = v), 15),
            _stepper(
                'Target Effort / Volume',
                '${_intensity.round()}%',
                _intensity,
                30,
                100,
                14,
                (v) => setState(() => _intensity = v),
                10),
            const SizedBox(height: 4),
            PrimaryButton('Quick Add', icon: Icons.add, onPressed: _quickAdd),
            if (_toast != null) ...[
              const SizedBox(height: 10),
              toastBanner(_toast)
            ],
          ]),
        ),
      ],
    );
  }
}
