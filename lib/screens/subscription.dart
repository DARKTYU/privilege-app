import 'package:flutter/material.dart';

import '../data.dart';
import '../logic/fitness_logic.dart';
import '../state.dart';
import '../ui.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _yearly = true;

  void _select(PlanInfo p) {
    // TODO: run the real purchase flow (in_app_purchase / RevenueCat / Stripe) before switching.
    appState.setTier(p.tier);
    toast(context, 'Plan switched to ${p.tier.label}! All features unlocked.');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Column(children: [
            tag('PRIVILEGE MEMBERSHIP', kGold),
            const SizedBox(height: 10),
            const Text('Unlock Your Peak Athletic Potential',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
                'Free plan includes generous essentials. Upgrade anytime for elite AI & show prep.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: kMuted)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              appChip(
                  'Monthly', !_yearly, () => setState(() => _yearly = false)),
              appChip('Annual · SAVE 40%', _yearly,
                  () => setState(() => _yearly = true)),
            ]),
          ]),
          const SizedBox(height: 16),
          for (final p in plans)
            Panel(
              margin: const EdgeInsets.only(bottom: 14),
              borderColor: p.popular
                  ? kGold
                  : (appState.tier == p.tier ? kGreen : kLine),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.badge != null)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: tag(p.badge!, kGold)),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Flexible(
                                        child: Text(p.name,
                                            style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w800))),
                                    if (p.popular)
                                      Padding(
                                        padding: EdgeInsets.only(left: 6),
                                        child: Icon(Icons.auto_awesome,
                                            size: 16, color: kGold),
                                      ),
                                  ]),
                                  Text(p.tagline,
                                      style: TextStyle(
                                          fontSize: 11, color: kMuted)),
                                ]),
                          ),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(_yearly ? p.yearlyPrice : p.monthlyPrice,
                                    style: TextStyle(
                                        color: kCream,
                                        fontWeight: FontWeight.w800)),
                                if (_yearly && p.tier != SubscriptionTier.free)
                                  Text('billed annually',
                                      style: TextStyle(
                                          fontSize: 10, color: kMuted)),
                              ]),
                        ]),
                    const SizedBox(height: 10),
                    for (final f in p.features)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check, size: 16, color: kGreen),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(f,
                                      style: const TextStyle(fontSize: 12))),
                            ]),
                      ),
                    const SizedBox(height: 8),
                    PrimaryButton(
                      appState.tier == p.tier
                          ? 'Active Current Plan'
                          : (p.tier == SubscriptionTier.free
                              ? 'Switch to Free'
                              : 'Upgrade to ${p.name}'),
                      icon: appState.tier == p.tier
                          ? Icons.check
                          : Icons.arrow_forward,
                      gold: p.popular,
                      onPressed:
                          appState.tier == p.tier ? null : () => _select(p),
                    ),
                  ]),
            ),
        ],
      ),
    );
  }
}
