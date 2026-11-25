import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n_strings.dart';
import '../services/progression_repository.dart';
import '../services/subscription_repository.dart';
import '../ui.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen(
      {super.key, this.progressionRepository, this.subscriptionRepository});
  final ProgressionDataSource? progressionRepository;
  final SubscriptionDataSource? subscriptionRepository;

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with WidgetsBindingObserver {
  late final _progression =
      widget.progressionRepository ?? ProgressionRepository();
  late final _subscriptions =
      widget.subscriptionRepository ?? SubscriptionRepository();
  late Future<String> _membership;
  late Future<List<MembershipPlan>?> _plans;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _membership = _progression.subscriptionTier();
    _plans = _loadPlans();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  /// Resolves to null when the plans cannot be loaded. The future never
  /// fails, so it cannot raise an unhandled error before the screen listens.
  Future<List<MembershipPlan>?> _loadPlans() async {
    try {
      return await _subscriptions.plans();
    } catch (_) {
      return null;
    }
  }

  void _reload() => setState(() {
        _membership = _progression.subscriptionTier();
        _plans = _loadPlans();
      });

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String _tierName(String tier, AppLocalizations l) => switch (tier) {
        'Free' => l.memberFree,
        'Silver' => l.memberSilver,
        'Gold' => l.memberGold,
        _ => tier,
      };

  String _priceText(MembershipPlan plan, AppLocalizations l) =>
      plan.priceUsd <= 0
          ? l.membershipFreePrice
          : l.membershipPrice('\$${plan.priceUsd.toStringAsFixed(2)}');

  String _perk(String tier, AppLocalizations l) => switch (tier) {
        'Silver' => l.membershipPerkSilver,
        'Gold' => l.membershipPerkGold,
        _ => l.membershipPerkFree,
      };

  Future<void> _choose(MembershipPlan plan) async {
    if (_busy) return;
    final l = strings(context);
    final name = _tierName(plan.name, l);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCard,
        title: Text(l.membershipCheckoutTitle),
        content: Text(
            l.membershipCheckoutBody('$name · ${_priceText(plan, l)}')),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l.membershipConfirm)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(() => _subscriptions.subscribe(plan.name),
        l.membershipStarted(name));
  }

  Future<void> _cancel() async {
    if (_busy) return;
    final l = strings(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCard,
        title: Text(l.membershipCancelTitle),
        content: Text(l.membershipCancelBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.membershipKeep)),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l.membershipCancel)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(_subscriptions.cancel, l.membershipCancelled);
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    final l = strings(context);
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      toast(context, success);
      _reload();
    } catch (_) {
      if (mounted) toast(context, l.membershipActionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _planCard(MembershipPlan plan, String currentTier, AppLocalizations l) {
    final rank = subscriptionTierRank(plan.name);
    final current = subscriptionTierRank(currentTier);
    final name = _tierName(plan.name, l);
    return Panel(
      borderColor: rank == current ? kGold : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            Text(_priceText(plan, l),
                style: TextStyle(color: kGold, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          Text(_perk(plan.name, l)),
          if (rank == current) ...[
            const SizedBox(height: 10),
            OutlinedButton(
                onPressed: null, child: Text(l.membershipCurrentPlanButton)),
          ] else if (rank > current) ...[
            const SizedBox(height: 10),
            FilledButton(
                onPressed: _busy ? null : () => _choose(plan),
                child: Text(l.membershipChoose(name))),
          ],
        ],
      ),
    );
  }

  Widget _plansSection(String tier, AppLocalizations l) =>
      FutureBuilder<List<MembershipPlan>?>(
        future: _plans,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SkeletonList(count: 2, itemHeight: 96);
          }
          final plans = snapshot.data;
          if (plans == null || plans.isEmpty) {
            return Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.membershipPlansUnavailable),
                  TextButton(
                      onPressed: _reload, child: Text(l.membershipRetry)),
                ],
              ),
            );
          }
          return Column(children: [
            for (final plan in plans) _planCard(plan, tier, l),
          ]);
        },
      );

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(strings(context).membershipTitle,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(strings(context).membershipComingSoon,
              style: TextStyle(color: kMuted, fontSize: 12)),
          const SizedBox(height: 12),
          FutureBuilder<String>(
            future: _membership,
            builder: (context, snapshot) {
              final l = strings(context);
              if (snapshot.connectionState != ConnectionState.done) {
                return Panel(child: Text(l.membershipLoading));
              }
              if (snapshot.hasError) {
                return Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.membershipUnavailableConnection),
                      TextButton(
                          onPressed: _reload, child: Text(l.plannerRetry)),
                    ],
                  ),
                );
              }
              final tier = snapshot.requireData;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.membershipCurrent(_tierName(tier, l)),
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        if (subscriptionTierRank(tier) > 0)
                          TextButton(
                              onPressed: _busy ? null : _cancel,
                              child: Text(l.membershipCancel)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(l.membershipPlansTitle,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  _plansSection(tier, l),
                ],
              );
            },
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
        ],
      );
}
