import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/community_models.dart';
import '../services/community_repository.dart';
import '../ui.dart';
import 'community.dart';

final alertsChanged = ValueNotifier<int>(0);
void refreshAlerts() => alertsChanged.value++;

class AlertBell extends StatefulWidget {
  const AlertBell({super.key, this.repository});
  final CommunityRepository? repository;
  @override
  State<AlertBell> createState() => _AlertBellState();
}

class _AlertBellState extends State<AlertBell> {
  late final _repository =
      widget.repository ?? CommunityRepository(Supabase.instance.client);
  RealtimeChannel? _channel;
  int? _count;
  bool _failed = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    alertsChanged.addListener(_load);
    unawaited(_load());
    final userId = _repository.client.auth.currentUser?.id;
    if (userId != null) {
      _channel = _repository.client.channel('alert-bell-$userId')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'community_notifications',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'recipient_id',
              value: userId),
          callback: (_) => refreshAlerts(),
        )
        ..subscribe((status, error) {
          if (error != null) {
            debugPrint('Alerts realtime error: $error');
            if (mounted) setState(() => _failed = true);
          } else if (status == RealtimeSubscribeStatus.subscribed) {
            unawaited(_load());
          }
        });
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    try {
      final count = await _repository.unreadCount();
      if (mounted && request == _request) {
        setState(() {
          _count = count;
          _failed = false;
        });
      }
    } catch (error) {
      debugPrint('Unread alerts failed: $error');
      if (mounted && request == _request) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    alertsChanged.removeListener(_load);
    if (_channel != null) {
      unawaited(_repository.client.removeChannel(_channel!));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: _failed ? 'Alerts (updates unavailable)' : 'Alerts',
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => AlertsPage(repository: _repository)));
          if (mounted) unawaited(_load());
        },
        icon: Badge(
          isLabelVisible: _count != null && _count! > 0,
          label:
              Text(_count != null && _count! > 99 ? '99+' : '${_count ?? 0}'),
          child: const Icon(Icons.notifications_none),
        ),
      );
}

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key, required this.repository, this.openTarget});
  final CommunityRepository repository;
  final Future<void> Function(BuildContext, CommunityNotification)? openTarget;
  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  List<CommunityNotification> _items = [];
  bool _loading = true;
  String? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    alertsChanged.addListener(_reload);
    unawaited(_load());
  }

  void _reload() => unawaited(_load());

  @override
  void dispose() {
    alertsChanged.removeListener(_reload);
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    try {
      final items = await widget.repository.notifications();
      if (!mounted || request != _request) return;
      setState(() {
        _items = items;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _open(CommunityNotification item) async {
    try {
      if (!item.isRead) {
        await widget.repository.markNotificationRead(item.id);
        refreshAlerts();
      }
      if (!mounted) return;
      if (widget.openTarget != null) {
        await widget.openTarget!(context, item);
      } else {
        await openAlertTarget(context, item, widget.repository);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Alerts'), actions: [
          IconButton(
            tooltip: 'Notification settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => NotificationSettingsPage(
                        repository: widget.repository))),
          )
        ]),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _items.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(onPressed: _load, child: const Text('Try again'))
                  ]))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      children: [
                        if (_items.any((item) => !item.isRead))
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () async {
                                try {
                                  await widget.repository
                                      .markAllNotificationsRead();
                                  refreshAlerts();
                                } catch (error) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(error.toString())));
                                  }
                                }
                              },
                              child: const Text('Mark all as read'),
                            ),
                          ),
                        if (_error != null) Text(_error!),
                        if (_items.isEmpty)
                          const Padding(
                              padding: EdgeInsets.only(top: 80),
                              child:
                                  Center(child: Text('You are all caught up.')))
                        else
                          for (final item in _items)
                            Card(
                                child: ListTile(
                              onTap: () => _open(item),
                              leading: Badge(
                                isLabelVisible: !item.isRead,
                                child: CircleAvatar(
                                  backgroundColor: kCard2,
                                  foregroundImage: item.avatarUrl == null ||
                                          item.avatarUrl!.isEmpty
                                      ? null
                                      : NetworkImage(item.avatarUrl!),
                                  child: Text(
                                      (item.fullName?.trim().isNotEmpty == true
                                              ? item.fullName!.trim()
                                              : item.username
                                                          ?.trim()
                                                          .isNotEmpty ==
                                                      true
                                                  ? item.username!.trim()
                                                  : 'P')
                                          .characters
                                          .first
                                          .toUpperCase()),
                                ),
                              ),
                              title: Text(item.message),
                              subtitle: Text(MaterialLocalizations.of(context)
                                  .formatMediumDate(item.createdAt.toLocal())),
                              trailing: const Icon(Icons.chevron_right),
                            )),
                      ],
                    ),
                  ),
      );
}

Future<void> openAlertTarget(BuildContext context, CommunityNotification item,
    CommunityRepository repository) async {
  if (item.postId != null ||
      item.actorId != null &&
          {'friend_request', 'friend_accepted', 'follow'}.contains(item.type)) {
    await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => AppPage(
            title: 'Community',
            builder: () => CommunityScreen(
              repository: repository,
              openPostId: item.postId,
              openProfileId: item.postId == null ? item.actorId : null,
            ),
          ),
        ));
    return;
  }
  final route = switch (item.type) {
    'challenge_invite' || 'challenge_result' || 'level_up' => '/arena',
    'badge_earned' || 'achievement_earned' => '/badges',
    'reward_redeemed' => '/rewards',
    _ => null,
  };
  if (route != null) {
    await Navigator.pushNamed(context, route);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This alert has no destination.')));
  }
}

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key, required this.repository});
  final CommunityRepository repository;
  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  Map<String, bool>? _settings;
  String? _error;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final settings = await widget.repository.notificationSettings();
      if (mounted) {
        setState(() {
          _settings = settings;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _change(String key, bool value) async {
    final next = {..._settings!, key: value};
    setState(() => _saving = true);
    try {
      await widget.repository.saveNotificationSettings(next);
      if (mounted) setState(() => _settings = next);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Notification settings')),
        body: _settings == null
            ? _error == null
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!),
                    TextButton(onPressed: _load, child: const Text('Try again'))
                  ]))
            : ListView(children: [
                for (final entry in const {
                  'likes_enabled': 'Likes',
                  'comments_enabled': 'Comments',
                  'friend_posts_enabled': 'Friend posts',
                  'friend_requests_enabled':
                      'Friend requests, acceptances and follows',
                }.entries)
                  SwitchListTile(
                    title: Text(entry.value),
                    value: _settings![entry.key]!,
                    onChanged:
                        _saving ? null : (value) => _change(entry.key, value),
                  )
              ]),
      );
}
