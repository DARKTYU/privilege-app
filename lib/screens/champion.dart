import 'package:flutter/material.dart';

import '../logic/fitness_logic.dart';
import '../state.dart';
import '../ui.dart';

/// "Classified Level": Natural Athlete Competition / Show qualification tracker.
class ChampionScreen extends StatefulWidget {
  const ChampionScreen({super.key});

  @override
  State<ChampionScreen> createState() => _ChampionScreenState();
}

class _ChampionScreenState extends State<ChampionScreen> {
  bool _natural = true;
  int _bodyFat = 11;
  int _muscle = 42;
  bool _posing = false;
  bool _registered = false;

  Widget _row(String label, String badge, bool ok, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kCard2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ok ? kGreen.withAlpha(120) : kLine),
            ),
            child: Row(children: [
              Icon(ok ? Icons.check_box : Icons.check_box_outline_blank,
                  color: ok ? kGreen : kMuted),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600))),
              tag(badge, ok ? kGreen : kMuted),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final q = calculateQualificationScore(QualificationMetrics(
      naturalVerified: _natural,
      bodyFatPercent: _bodyFat,
      muscleMassKg: _muscle,
      mandatoryPosingRoutine: _posing,
    ));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Natural Athlete Competition/Show',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        Text('Qualification Tracker!',
            style: TextStyle(color: kMuted, fontSize: 12)),
        const SizedBox(height: 12),
        Panel(
          borderColor: kGold.withAlpha(110),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Classified Level:',
                          style: TextStyle(fontSize: 12, color: kMuted)),
                      Text(q.levelName,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: kCream)),
                    ]),
              ),
              CircleAvatar(
                radius: 30,
                backgroundColor: kMaroon,
                child: Text('${q.scorePercent}%',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: Text('Championship Qualification',
                      style: TextStyle(fontWeight: FontWeight.w700))),
              Text('Road to Natural Championship',
                  style: TextStyle(fontSize: 10, color: kMuted)),
            ]),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: q.scorePercent / 100,
              minHeight: 10,
              color: kGold,
              backgroundColor: kCard2,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                  q.eligible
                      ? 'Eligible to register'
                      : 'Not yet eligible (80% + natural status needed)',
                  style: TextStyle(
                      fontSize: 11, color: q.eligible ? kGreen : kMuted)),
            ),
          ]),
        ),
        sectionTitle('Qualification Metrics'),
        _row('100% Natural Status Verified', 'WADA Tested', _natural,
            () => setState(() => _natural = !_natural)),
        _row('Optimal Body Fat', '$_bodyFat%', _bodyFat <= 12 && _bodyFat >= 8,
            () => setState(() => _bodyFat = _bodyFat == 11 ? 13 : 11)),
        _row('Optimal Muscle Mass', '${_muscle}kg', _muscle >= 40,
            () => setState(() => _muscle = _muscle == 42 ? 40 : 42)),
        _row('Mandatory Posing Routine', _posing ? 'Registered' : 'Pending',
            _posing, () => setState(() => _posing = !_posing)),
        const SizedBox(height: 4),
        for (final n in q.statusNotes)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Icon(Icons.check, size: 14, color: kGold),
              const SizedBox(width: 6),
              Expanded(
                  child:
                      Text(n, style: TextStyle(fontSize: 12, color: kMuted))),
            ]),
          ),
        const SizedBox(height: 12),
        PrimaryButton(
          _registered
              ? 'Registered for Championship!'
              : 'Register for Natural Championship / Show',
          icon: Icons.auto_awesome,
          onPressed: () {
            if (!requireTier(context, appState.can(Feature.contestPrep),
                'Championship registration')) return;
            setState(() => _registered = true);
          },
        ),
        if (_registered) ...[
          const SizedBox(height: 10),
          toastBanner('Contest Pass Issued: Division ${q.levelName} #88'),
        ],
      ],
    );
  }
}
