import 'package:flutter/material.dart';

import '../data.dart';
import '../l10n_strings.dart';
import '../ui.dart';

class AcademyScreen extends StatefulWidget {
  const AcademyScreen({super.key});

  @override
  State<AcademyScreen> createState() => _AcademyScreenState();
}

class _AcademyScreenState extends State<AcademyScreen> {
  String _category = 'all';
  String _query = '';

  String _burnRate(BuildContext context, String value) {
    final l = strings(context);
    if (value == 'Lifetime Knowledge') return l.academyLifetime;
    final match = RegExp(r'^(\d+) kcal / (\d+) mins$').firstMatch(value);
    return match == null ? value : l.academyBurn(int.parse(match[1]!), int.parse(match[2]!));
  }

  IconData _guideIcon(ExerciseGuide guide) {
    if (guide.id == 'basketball') return Icons.sports_basketball;
    if (guide.id == 'boxing') return Icons.sports_mma;
    if (guide.category == 'gym') return Icons.fitness_center;
    return Icons.directions_run;
  }

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
                  icon: _guideIcon(g)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        g.localizedTitle(
                            Localizations.localeOf(ctx).languageCode == 'ar'),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(g.localizedSubCategory(
                        Localizations.localeOf(ctx).languageCode == 'ar')),
                  ])),
            ]),
            const SizedBox(height: 12),
            Text(strings(ctx).academyDisclaimer),
            sectionTitle(strings(ctx).academyCues),
            for (final c in g.localizedCues(
                Localizations.localeOf(ctx).languageCode == 'ar'))
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
            sectionTitle(strings(ctx).academyMistakes),
            for (final m in g.localizedMistakes(
                Localizations.localeOf(ctx).languageCode == 'ar'))
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
            PrimaryButton(strings(ctx).academyMastered,
                onPressed: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = strings(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final tabs = [
      ('all', l.academyAllGuides),
      ('gym', l.academyGymLifts),
      ('sport', l.academySportMechanics),
      ('foundation', l.academyStarterRules),
    ];
    final q = _query.toLowerCase();
    final filtered = guides.where((g) {
      final cat = _category == 'all' || g.category == _category;
      final match = g.title.toLowerCase().contains(q) ||
          g.subCategory.toLowerCase().contains(q) ||
          g.muscles.any((m) => m.toLowerCase().contains(q)) ||
          g.titleAr.toLowerCase().contains(q) ||
          g.subCategoryAr.toLowerCase().contains(q) ||
          g.musclesAr.any((m) => m.toLowerCase().contains(q));
      return cat && match;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l.academySubtitle, style: TextStyle(color: kMuted, fontSize: 12)),
        const SizedBox(height: 12),
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: fieldDecoration(l.academySearch, icon: Icons.search),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final t in tabs)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: appChip(t.$2, _category == t.$1,
                    () => setState(() => _category = t.$1)),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
                child: Text(l.academyEmpty, style: TextStyle(color: kMuted))),
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
                                icon: _guideIcon(g)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        g
                                            .localizedSubCategory(arabic)
                                            .toUpperCase(),
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: kGold,
                                            fontWeight: FontWeight.w800)),
                                    Text(g.localizedTitle(arabic),
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800)),
                                    Text(g.localizedDifficulty(arabic),
                                        style: TextStyle(
                                            color: kMuted, fontSize: 11)),
                                    const SizedBox(height: 4),
                                    Text(
                                        l.academyMuscles(g
                                            .localizedMuscles(arabic)
                                            .join(', ')),
                                        style: TextStyle(
                                            fontSize: 12, color: kMuted)),
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      Icon(Icons.local_fire_department,
                                          size: 14, color: kOrange),
                                      const SizedBox(width: 4),
                                      Expanded(
                                          child: Text(
                                              _burnRate(context, g.burnRate),
                                              style: const TextStyle(
                                                  fontSize: 12))),
                                      Text(l.academyLearn,
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
