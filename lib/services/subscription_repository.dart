import 'package:supabase_flutter/supabase_flutter.dart';

import 'session_recovery.dart';

/// One row of the shared `subscription_plans` catalogue.
class MembershipPlan {
  const MembershipPlan({required this.name, required this.priceUsd});
  final String name;
  final double priceUsd;
}

abstract interface class SubscriptionDataSource {
  /// Plans ordered by price, cheapest first.
  Future<List<MembershipPlan>> plans();

  /// Starts a 30-day membership. Demo checkout: no real payment is taken.
  Future<void> subscribe(String plan);

  /// Cancels the active membership; the account returns to Free at once.
  Future<void> cancel();
}

class SubscriptionRepository implements SubscriptionDataSource {
  SubscriptionRepository({SupabaseClient? client}) : _providedClient = client;
  final SupabaseClient? _providedClient;
  SupabaseClient get client => _providedClient ?? Supabase.instance.client;
  Future<T> _request<T>(Future<T> Function() action) =>
      SessionRecovery.forClient(client).request(action);

  @override
  Future<List<MembershipPlan>> plans() async {
    final rows = await _request(() => client
        .from('subscription_plans')
        .select('name,price_usd')
        .order('price_usd', ascending: true));
    return [
      for (final row in rows)
        if (row['name'] is String)
          MembershipPlan(
            name: row['name'] as String,
            priceUsd: double.tryParse('${row['price_usd']}') ?? 0,
          ),
    ];
  }

  @override
  Future<void> subscribe(String plan) async {
    await _request(() => client.rpc('subscribe_demo', params: {'p_plan': plan}));
  }

  @override
  Future<void> cancel() async {
    await _request(() => client.rpc('cancel_subscription'));
  }
}
