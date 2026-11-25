import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n_strings.dart';
import '../logic/localized_dates.dart';
import '../models/community_models.dart';
import '../services/community_repository.dart';
import '../services/groups_repository.dart';
import '../services/storage_image.dart';
import '../ui.dart';
import 'community.dart';
import 'groups.dart';

final alertsChanged = ValueNotifier<int>(0);
void refreshAlerts() => alertsChanged.value++;

String _alertMessage(BuildContext context, CommunityNotification item) {
  final l = strings(context);
  final name = item.fullName?.trim().isNotEmpty == true
      ? item.fullName!
      : item.username?.trim().isNotEmpty == true
          ? '@${item.username!}'
          : l.alertSomeone;
  return switch (item.type) {
    'friend_request' => l.alertFriendRequest(name),
    'friend_accepted' => l.alertFriendAccepted(name),
    'post_comment' => item.commentBody?.trim().isNotEmpty == true
        ? l.alertCommentBody(name, item.commentBody!)
        : l.alertComment(name),
    'post_like' => l.alertPostLike(name),
    'comment_like' => l.alertCommentLike(name),
    'follow' => l.alertFollow(name),
    'friend_post' => l.alertFriendPost(name),
    'challenge_invite' => l.alertChallengeInvite(name),
    'challenge_result' => l.alertChallengeResult,
    'badge_earned' => l.alertBadge,
    'achievement_earned' => l.alertAchievement,
    'level_up' => l.alertLevel,
    'reward_redeemed' => l.alertReward,
    'group_join_request' => l.alertGroupRequest(name),
    'group_request_approved' => l.alertGroupApproved(name),
    'group_removed' => l.alertGroupRemoved(name),
    'group_banned' => l.alertGroupBanned(name),
    'group_invited' => l.alertGroupInvited(name),
    _ => l.alertUnknown,
  };
}

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
        tooltip: _failed
            ? strings(context).alertsUnavailable
            : strings(context).alertsTitle,
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
        _error = friendlyError(error, localizations: strings(context));
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
            .showSnackBar(SnackBar(content: Text(friendlyError(error, localizations: strings(context)))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(strings(context).alertsTitle), actions: [
          IconButton(
            tooltip: strings(context).notificationSettings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => NotificationSettingsPage(
                        repository: widget.repository))),
          )
        ]),
        body: _loading
            ? const SkeletonList(count: 5, itemHeight: 72)
            : _error != null && _items.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(
                        onPressed: _load,
                        child: Text(strings(context).alertsTryAgain))
                  ]))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      children: [
                        if (_items.any((item) => !item.isRead))
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
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
                                            content: Text(friendlyError(error, localizations: strings(context)))));
                                  }
                                }
                              },
                              child: Text(strings(context).alertsMarkRead),
                            ),
                          ),
                        if (_error != null) Text(_error!),
                        if (_items.isEmpty)
                          Padding(
                              padding: const EdgeInsets.only(top: 48),
                              child: EmptyState(
                                  icon: Icons.notifications_none_rounded,
                                  title: strings(context).alertsEmpty))
                        else
                          for (final item in _items)
                            Card(
                                child: ListTile(
                              onTap: () => _open(item),
                              leading: Badge(
                                isLabelVisible: !item.isRead,
                                child: CircleAvatar(
                                  backgroundColor: kCard2,
                                  foregroundImage: storageImage(item.avatarUrl),
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
                              title: Text(_alertMessage(context, item)),
                              subtitle: Text(westernDigits(
                                  MaterialLocalizations.of(context)
                                      .formatMediumDate(
                                          item.createdAt.toLocal()))),
                              trailing: const Icon(Icons.chevron_right),
                            )),
                      ],
                    ),
                  ),
      );
}

Future<void> openAlertTarget(BuildContext context, CommunityNotification item,
    CommunityRepository repository,
    {GroupsRepository? groupsRepository}) async {
  if (item.type.startsWith('group_')) {
    final groups = groupsRepository ?? GroupsRepository(repository.client);
    final id = await groups.notificationTarget(item.id);
    if (!context.mounted) return;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings(context).alertsGroupMissing)));
      return;
    }
    await Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => GroupPage(
                repository: groups,
                groupId: id,
                invited: item.type == 'group_invited')));
    return;
  }
  if (item.postId != null ||
      item.actorId != null &&
          {'friend_request', 'friend_accepted', 'follow'}.contains(item.type)) {
    await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => AppPage(
            title: strings(context).community,
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
        SnackBar(content: Text(strings(context).alertsNoDestination)));
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
      if (mounted) setState(() => _error = friendlyError(error, localizations: strings(context)));
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
            .showSnackBar(SnackBar(content: Text(friendlyError(error, localizations: strings(context)))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(strings(context).notificationSettings)),
        body: _settings == null
            ? _error == null
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!),
                    TextButton(
                        onPressed: _load,
                        child: Text(strings(context).alertsTryAgain))
                  ]))
            : ListView(children: [
                for (final entry in {
                  'likes_enabled': strings(context).alertsLikes,
                  'comments_enabled': strings(context).alertsComments,
                  'friend_posts_enabled': strings(context).alertsFriendPosts,
                  'friend_requests_enabled':
                      strings(context).alertsFriendRequests,
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
