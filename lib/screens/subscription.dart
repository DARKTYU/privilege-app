import 'package:flutter/material.dart';

import '../l10n_strings.dart';
import '../services/progression_repository.dart';
import '../ui.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key, this.progressionRepository});
  final ProgressionDataSource? progressionRepository;

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with WidgetsBindingObserver {
  late final _progression =
      widget.progressionRepository ?? ProgressionRepository();
  late Future<String> _membership;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _membership = _progression.subscriptionTier();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  void _reload() => setState(() {
        _membership = _progression.subscriptionTier();
      });

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(strings(context).membershipTitle,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Panel(
            child: FutureBuilder<String>(
              future: _membership,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Text(strings(context).membershipLoading);
                }
                if (snapshot.hasError) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(strings(context).membershipUnavailableConnection),
                      TextButton(
                          onPressed: _reload,
                          child: Text(strings(context).plannerRetry)),
                    ],
                  );
                }
                final l = strings(context);
                final tier = switch (snapshot.requireData) {
                  'Free' => l.memberFree,
                  'Silver' => l.memberSilver,
                  'Gold' => l.memberGold,
                  _ => snapshot.requireData,
                };
                return Text(l.membershipCurrent(tier),
                    style: const TextStyle(fontWeight: FontWeight.w800));
              },
            ),
          ),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings(context).membershipBenefits,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                for (final benefit in [
                  strings(context).membershipFood,
                  strings(context).membershipCommunity,
                  strings(context).membershipAcademy,
                  strings(context).membershipRewards,
                  strings(context).membershipSplits,
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(strings(context).membershipBenefit(benefit)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(strings(context).membershipComingSoon),
        ],
      );
}
