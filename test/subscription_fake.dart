import 'package:privilege/services/subscription_repository.dart';

class FakeSubscriptions implements SubscriptionDataSource {
  List<MembershipPlan> planList = const [
    MembershipPlan(name: 'Free', priceUsd: 0),
    MembershipPlan(name: 'Silver', priceUsd: 9.99),
    MembershipPlan(name: 'Gold', priceUsd: 14.99),
  ];
  Object? plansError;
  Object? actionError;
  final List<String> subscribed = [];
  int cancels = 0;

  /// Lets a test change what the progression fake reports after an action.
  void Function(String tier)? onTierChange;

  @override
  Future<List<MembershipPlan>> plans() async {
    if (plansError != null) throw plansError!;
    return planList;
  }

  @override
  Future<void> subscribe(String plan) async {
    if (actionError != null) throw actionError!;
    subscribed.add(plan);
    onTierChange?.call(plan);
  }

  @override
  Future<void> cancel() async {
    if (actionError != null) throw actionError!;
    cancels++;
    onTierChange?.call('Free');
  }
}
