import 'package:flutter/material.dart';

import '../data.dart';
import '../ui.dart';

class AcademyScreen extends StatefulWidget {
  const AcademyScreen({super.key});

  @override
  State<AcademyScreen> createState() => _AcademyScreenState();
}

class _AcademyScreenState extends State<AcademyScreen> {
  String _category = 'all';
  String _query = '';

  static const _tabs = [
    ('all', 'All Guides'),
    ('gym', 'Gym Lifts'),
    ('sport', 'Sport Mechanics'),
    ('foundation', 'Starter Rules'),
  ];

  void _open(ExerciseGuide g) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              imagePlaceholder(context,
                  width: 56,
                  height: 56,
                  radius: BorderRadius.circular(12),
                  icon: Icons.fitness_center),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(g.title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(g.subCategory),
                  ])),
            ]),
            const SizedBox(height: 12),
            const Text(
                'General information, not professional advice. Check with a qualified coach or doctor.'),
            sectionTitle('Key Execution Cues'),
            for (final c in g.cues)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: CircleAvatar(radius: 3, backgroundColor: kGreen),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(c, style: const TextStyle(fontSize: 13))),
                    ]),
              ),
            sectionTitle('Common Mistakes to Avoid'),
            for (final m in g.mistakes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: CircleAvatar(radius: 3, backgroundColor: kRed),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(m, style: const TextStyle(fontSize: 13))),
                    ]),
              ),
            const SizedBox(height: 8),
            PrimaryButton('Mastered Cue', onPressed: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final filtered = guides.where((g) {
      final cat = _category == 'all' || g.category == _category;
      final match = g.title.toLowerCase().contains(q) ||
          g.subCategory.toLowerCase().contains(q) ||
          g.muscles.any((m) => m.toLowerCase().contains(q));
      return cat && match;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
            'Biomechanical masterclasses for gym lifts, sports conditioning & fitness foundations.',
            style: TextStyle(color: kMuted, fontSize: 12)),
        const SizedBox(height: 12),
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: fieldDecoration(
              'Search bench, squats, basketball, nutrition...',
              icon: Icons.search),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final t in _tabs)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: appChip(t.$2, _category == t.$1,
                    () => setState(() => _category = t.$1)),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Padding(
            padding: EdgeInsets.all(24),
            child: Center(
                child: Text('No guides match your search.',
                    style: TextStyle(color: kMuted))),
          ),
        for (final g in filtered)
          InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _open(g),
              child: Panel(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            imagePlaceholder(context,
                                width: 56,
                                height: 56,
                                radius: BorderRadius.circular(12),
                                icon: Icons.fitness_center),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(g.subCategory.toUpperCase(),
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: kGold,
                                            fontWeight: FontWeight.w800)),
                                    Text(g.title,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800)),
                                    Text(g.difficulty,
                                        style: TextStyle(
                                            color: kMuted, fontSize: 11)),
                                    const SizedBox(height: 4),
                                    Text('Muscles: ${g.muscles.join(', ')}',
                                        style: TextStyle(
                                            fontSize: 12, color: kMuted)),
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      Icon(Icons.local_fire_department,
                                          size: 14, color: kOrange),
                                      const SizedBox(width: 4),
                                      Expanded(
                                          child: Text(g.burnRate,
                                              style: const TextStyle(
                                                  fontSize: 12))),
                                      Text('Learn ',
                                          style: TextStyle(
                                              fontSize: 12, color: kGold)),
                                      Icon(Icons.chevron_right,
                                          size: 16, color: kGold),
                                    ]),
                                  ]),
                            ),
                          ]),
                    ]),
              )),
      ],
    );
  }
}
