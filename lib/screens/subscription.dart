import 'package:flutter/material.dart';

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
          const Text('Privilege membership',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Panel(
            child: FutureBuilder<String>(
              future: _membership,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Text('Loading membership...');
                }
                if (snapshot.hasError) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                          'Membership unavailable. Check your connection.'),
                      TextButton(
                          onPressed: _reload, child: const Text('Retry')),
                    ],
                  );
                }
                return Text('Current membership: ${snapshot.requireData}',
                    style: const TextStyle(fontWeight: FontWeight.w800));
              },
            ),
          ),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available in the app',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                for (final benefit in [
                  'Food and workout logging',
                  'Community and streak tracking',
                  'Academy exercise guides',
                  'Rewards and achievements',
                  'Create and save custom splits',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• $benefit'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Coming soon. Payments are not available yet.'),
        ],
      );
}
