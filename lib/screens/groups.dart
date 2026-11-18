import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/groups_repository.dart';
import '../services/community_repository.dart';
import '../models/community_models.dart';
import '../widgets/post_image.dart';

class GroupsTab extends StatefulWidget {
  const GroupsTab({super.key, this.repository});
  final GroupsRepository? repository;
  @override
  State<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> with WidgetsBindingObserver {
  late final repo =
      widget.repository ?? GroupsRepository(Supabase.instance.client);
  late Future<
          (List<Group>, List<Map<String, dynamic>>, List<Map<String, dynamic>>)>
      future;
  String query = '', category = 'All';
  bool mine = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) reload();
  }

  void reload() {
    setState(() {
      future = load();
    });
  }

  Future<(List<Group>, List<Map<String, dynamic>>, List<Map<String, dynamic>>)>
      load() async => (
            await repo.groups(),
            await repo.myMemberships(),
            await repo.invitations()
          );

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.hasError) return _error(snapshot.error!, reload);
            return const Center(child: CircularProgressIndicator());
          }
          final (groups, memberships, invitations) = snapshot.data!;
          final categories = groups
              .map((g) => g.category)
              .where((c) => c != 'All')
              .toSet()
              .toList()
            ..sort();
          final ids = memberships.map((m) => m['group_id']).toSet();
          final pendingIds = memberships
              .where((m) => m['status'] == 'pending')
              .map((m) => m['group_id'])
              .toSet();
          final inviteIds =
              invitations.map((m) => m['group_id'] as String).toSet();
          final filtered = groups
              .where((g) =>
                  (!mine || ids.contains(g.id)) &&
                  (category == 'All' || g.category == category) &&
                  ('${g.name} ${g.description}'
                      .toLowerCase()
                      .contains(query.toLowerCase())))
              .toList();
          return RefreshIndicator(
            onRefresh: () async {
              reload();
              await future;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(children: [
                  Expanded(
                      child: TextButton(
                          onPressed: () => setState(() => mine = false),
                          child: const Text('Discover'))),
                  Expanded(
                      child: TextButton(
                          onPressed: () => setState(() => mine = true),
                          child: const Text('My groups'))),
                  IconButton(
                      tooltip: 'Create group',
                      onPressed: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                                builder: (_) =>
                                    GroupSettingsPage(repository: repo)));
                        if (mounted) reload();
                      },
                      icon: const Icon(Icons.add_circle_outline)),
                ]),
                TextField(
                    decoration: const InputDecoration(
                        labelText: 'Search groups',
                        prefixIcon: Icon(Icons.search)),
                    onChanged: (value) => setState(() => query = value)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                    initialValue:
                        categories.contains(category) ? category : 'All',
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: ['All', ...categories]
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => category = value ?? 'All')),
                if (mine && inviteIds.isNotEmpty) ...[
                  const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text('Invitations')),
                  for (final id in inviteIds)
                    Card(
                        child: ListTile(
                      leading: const Icon(Icons.mail_outline),
                      title: const Text('Group invitation'),
                      subtitle: const Text('Open to accept'),
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                                builder: (_) => GroupPage(
                                    repository: repo,
                                    groupId: id,
                                    invited: true)));
                        if (mounted) reload();
                      },
                    )),
                ],
                if (filtered.isEmpty && (!mine || inviteIds.isEmpty))
                  const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('No groups found.')))
                else
                  for (final group in filtered)
                    Card(
                        child: ListTile(
                      leading: _avatar(group.avatar),
                      title: Text(group.name),
                      subtitle: Text('${group.category} · ${group.visibility}'
                          '${pendingIds.contains(group.id) ? ' · Request pending' : ''}'),
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                                builder: (_) => GroupPage(
                                    repository: repo,
                                    groupId: group.id,
                                    invited: inviteIds.contains(group.id))));
                        if (mounted) reload();
                      },
                    )),
              ],
            ),
          );
        },
      );
}

Widget _avatar(String? url) => CircleAvatar(
      foregroundImage: url == null || url.isEmpty ? null : NetworkImage(url),
      child: const Icon(Icons.groups_outlined),
    );

String _profileName(Map<String, dynamic>? profile) {
  final name = (profile?['full_name'] as String?)?.trim();
  final username = (profile?['username'] as String?)?.trim();
  return name?.isNotEmpty == true
      ? name!
      : username?.isNotEmpty == true
          ? username!
          : 'Member';
}

Widget _personAvatar(Map<String, dynamic>? profile) {
  final name = _profileName(profile);
  final url = profile?['avatar_url'] as String?;
  return CircleAvatar(
    foregroundImage: url == null || url.isEmpty ? null : NetworkImage(url),
    onForegroundImageError: url == null || url.isEmpty
        ? null
        : (error, stack) => debugPrint('Could not load profile avatar: $error'),
    child: Text(name.characters.first.toUpperCase()),
  );
}

String _profileUsername(Map<String, dynamic>? profile) {
  final username = (profile?['username'] as String?)?.trim();
  return username == null || username.isEmpty ? '' : '@$username';
}

Widget _error(Object error, VoidCallback retry) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(groupError(error), textAlign: TextAlign.center),
      TextButton(onPressed: retry, child: const Text('Try again')),
    ]));

class GroupSettingsPage extends StatefulWidget {
  const GroupSettingsPage({super.key, required this.repository, this.group});
  final GroupsRepository repository;
  final Group? group;
  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage> {
  late final name = TextEditingController(text: widget.group?.name ?? '');
  late final description =
      TextEditingController(text: widget.group?.description ?? '');
  late final category =
      TextEditingController(text: widget.group?.category ?? '');
  late final limit =
      TextEditingController(text: '${widget.group?.limit ?? 100}');
  late final rules = TextEditingController(text: widget.group?.rules ?? '');
  late final avatar = TextEditingController(text: widget.group?.avatar ?? '');
  late String visibility = widget.group?.visibility ?? 'public';
  late String joinMode = widget.group?.joinMode ?? 'open';
  late String posting = widget.group?.posting ?? 'everyone';
  late bool images = widget.group?.images ?? false;
  late bool chat = widget.group?.chat ?? false;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    category.dispose();
    limit.dispose();
    rules.dispose();
    avatar.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final size = int.tryParse(limit.text);
    if (name.text.trim().length < 3 ||
        category.text.trim().isEmpty ||
        size == null ||
        size < 1 ||
        size > 10000) {
      setState(() => error =
          'Enter a name of at least 3 characters, a category, and a member limit from 1 to 10000.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final params = <String, dynamic>{
        'p_name': name.text.trim(),
        'p_description': description.text.trim(),
        'p_category': category.text.trim(),
        'p_visibility': visibility,
        'p_join_mode': joinMode,
        'p_member_limit': size,
        'p_rules': rules.text.trim(),
        'p_avatar_url': avatar.text.trim().isEmpty ? null : avatar.text.trim(),
        'p_who_can_post': posting,
        'p_images_allowed': images,
        'p_chat_enabled': chat,
      };
      if (widget.group != null) params['p_group'] = widget.group!.id;
      await widget.repository.rpc(
          widget.group == null ? 'group_create' : 'group_update_settings',
          params);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = groupError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget dropdown(String label, String value, Map<String, String> options,
          ValueChanged<String> change) =>
      DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(labelText: label),
          items: options.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: busy
              ? null
              : (v) {
                  if (v != null) setState(() => change(v));
                });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title:
                Text(widget.group == null ? 'Create group' : 'Group settings')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
              maxLength: 80),
          TextField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLength: 2000),
          TextField(
              controller: category,
              decoration: const InputDecoration(labelText: 'Category'),
              maxLength: 60),
          dropdown(
              'Visibility',
              visibility,
              {'public': 'Public', 'private': 'Private'},
              (v) => visibility = v),
          const SizedBox(height: 12),
          dropdown(
              'Join mode',
              joinMode,
              {
                'open': 'Open',
                'approval': 'Approval needed',
                'invite_only': 'Invite only'
              },
              (v) => joinMode = v),
          if (visibility == 'private')
            const Text('Private groups require an invitation.'),
          const SizedBox(height: 12),
          TextField(
              controller: limit,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Member limit')),
          const SizedBox(height: 12),
          dropdown(
              'Who can post',
              posting,
              {'everyone': 'Everyone', 'moderators': 'Moderators'},
              (v) => posting = v),
          SwitchListTile(
              title: const Text('Images allowed'),
              value: images,
              onChanged: busy ? null : (v) => setState(() => images = v)),
          SwitchListTile(
              title: const Text('Chat (coming in phase 2)'),
              subtitle: const Text(
                  'This setting is saved, but chat is not available yet.'),
              value: chat,
              onChanged: busy ? null : (v) => setState(() => chat = v)),
          TextField(
              controller: rules,
              maxLines: 3,
              maxLength: 5000,
              decoration: const InputDecoration(labelText: 'Rules')),
          TextField(
              controller: avatar,
              decoration: const InputDecoration(labelText: 'Avatar image URL')),
          if (error != null)
            Padding(
                padding: const EdgeInsets.all(8),
                child: Text(error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error))),
          const SizedBox(height: 12),
          ElevatedButton(
              onPressed: busy ? null : save,
              child: Text(busy ? 'Saving...' : 'Save')),
        ]),
      );
}

class GroupPage extends StatefulWidget {
  const GroupPage(
      {super.key,
      required this.repository,
      required this.groupId,
      this.invited = false});
  final GroupsRepository repository;
  final String groupId;
  final bool invited;
  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> with WidgetsBindingObserver {
  late Future<
          (Group?, List<Map<String, dynamic>>, List<Map<String, dynamic>>, int)>
      future;
  bool busy = false;
  late bool invited = widget.invited;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) reload();
  }

  void reload() {
    setState(() {
      future = load();
    });
  }

  Future<(Group?, List<Map<String, dynamic>>, List<Map<String, dynamic>>, int)>
      load() async {
    final group = await widget.repository.group(widget.groupId);
    if (group == null) {
      return (null, <Map<String, dynamic>>[], <Map<String, dynamic>>[], 0);
    }
    final members = await widget.repository.members(group.id);
    final mine = members
        .where((m) =>
            m['user_id'] == widget.repository.userId && m['status'] == 'active')
        .isNotEmpty;
    return (
      group,
      members,
      mine ? await widget.repository.posts(group.id) : <Map<String, dynamic>>[],
      await widget.repository.count(group.id)
    );
  }

  Future<bool> action(Future<dynamic> Function() call) async {
    setState(() => busy = true);
    try {
      await call();
      if (mounted) reload();
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(groupError(e))));
      }

      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> changeMembership(bool leave) async {
    final success = await action(() => widget.repository.rpc(
        leave ? 'group_leave' : 'group_join', {'p_group': widget.groupId}));
    if (success && !leave && mounted) {
      setState(() => invited = false);
    }
  }

  Future<void> report({String? post, String? user}) async {
    final reason = await _prompt(context, 'Report', 'Reason');
    if (!mounted || reason == null) return;
    final success = await action(() => widget.repository.rpc('group_report', {
          'p_group': widget.groupId,
          'p_reason': reason,
          'p_post': post,
          'p_user': user,
        }));
    if (mounted && success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Report submitted.')));
    }
  }

  Future<void> manageMember(String userId, String operation) async {
    if (operation == 'remove' || operation == 'ban') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(operation == 'ban' ? 'Ban member?' : 'Remove member?'),
          content: Text(operation == 'ban'
              ? 'This bans the member until you unban them. Their posts and comments in this group are hidden and they cannot join again.'
              : 'This removes the member and hides their posts and comments in this group. They can join again.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(operation == 'ban' ? 'Ban' : 'Remove')),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    await action(() => widget.repository.rpc('group_manage_member', {
          'p_group': widget.groupId,
          'p_user': userId,
          'p_action': operation,
        }));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Group')),
        body: FutureBuilder(
          future: future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              if (snapshot.hasError) return _error(snapshot.error!, reload);
              return const Center(child: CircularProgressIndicator());
            }
            final (group, members, posts, count) = snapshot.data!;
            if (group == null) {
              return RefreshIndicator(
                onRefresh: () async {
                  reload();
                  await future;
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 100),
                    const Center(child: Text(
                        'This group is unavailable. Private groups require an invitation.')),
                    if (invited)
                      TextButton(
                          onPressed: busy ? null : () => changeMembership(false),
                          child: const Text('Accept invitation')),
                  ],
                ),
              );
            }
            final myRows = members
                .where((m) => m['user_id'] == widget.repository.userId)
                .toList();
            final status = myRows.isEmpty ? null : myRows.first['status'];
            final role = myRows.isEmpty ? null : myRows.first['role'];
            final active = status == 'active';
            final moderator = active && (role == 'owner' || role == 'moderator');
            final visibleMembers = members
                .where((member) =>
                    member['status'] == 'active' ||
                    (moderator && member['status'] == 'pending'))
                .toList();
            final canPost =
                active && (group.posting == 'everyone' || moderator);
            return RefreshIndicator(
                onRefresh: () async {
                  reload();
                  await future;
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(children: [
                      _avatar(group.avatar),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(group.name,
                                style: Theme.of(context).textTheme.titleLarge),
                            Text('${group.category} · $count members'),
                          ])),
                      PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'report') {
                              await report();
                              return;
                            }
                            if (v == 'settings') {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                      builder: (_) => GroupSettingsPage(
                                          repository: widget.repository,
                                          group: group)));
                              if (mounted) reload();
                              return;
                            }
                            if (v == 'invite') {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                      builder: (_) => _InvitePage(
                                          repository: widget.repository,
                                          groupId: group.id)));
                              if (mounted) reload();
                              return;
                            }
                            if (v == 'banned') {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                      builder: (_) => _BannedMembersPage(
                                            repository: widget.repository,
                                            groupId: group.id,
                                            onChanged: () {
                                              if (mounted) reload();
                                            },
                                          )));
                              if (mounted) reload();
                            }
                          },
                          itemBuilder: (_) => [
                                if (role == 'owner')
                                  const PopupMenuItem(
                                      value: 'settings',
                                      child: Text('Settings')),
                                if (moderator)
                                  const PopupMenuItem(
                                      value: 'invite',
                                      child: Text('Invite people')),
                                if (moderator)
                                  const PopupMenuItem(
                                      value: 'banned',
                                      child: Text('Banned members')),
                                if (role != 'owner')
                                  const PopupMenuItem(
                                      value: 'report',
                                      child: Text('Report group')),
                              ]),
                    ]),
                    const SizedBox(height: 8),
                    Text(group.description),
                    if (group.rules.isNotEmpty) Text('Rules: ${group.rules}'),
                    if (role != 'owner')
                      TextButton(
                        onPressed: busy ||
                                (!active &&
                                    status != 'pending' &&
                                    group.joinMode == 'invite_only' &&
                                    !invited)
                            ? null
                            : () =>
                                changeMembership(active || status == 'pending'),
                        child: Text(active
                            ? 'Leave group'
                            : status == 'pending'
                                ? 'Cancel request'
                                : invited
                                    ? 'Accept invitation'
                                    : group.joinMode == 'approval'
                                        ? 'Request to join'
                                        : group.joinMode == 'invite_only'
                                            ? 'Invitation required'
                                            : 'Join'),
                      ),
                    if (!active)
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(status == 'pending'
                              ? 'Request pending'
                              : 'Join to see posts and members.'))
                    else ...[
                      const Divider(),
                      Row(children: [
                        Expanded(
                            child: Text('Posts',
                                style:
                                    Theme.of(context).textTheme.titleMedium)),
                        if (canPost)
                          TextButton(
                              onPressed: busy
                                  ? null
                                  : () async {
                                      final post = await _composeGroupPost(
                                          context, group.images);
                                      if (post != null && mounted) {
                                        await action(() => widget.repository
                                            .createPost(
                                                group.id, post.$1, post.$2));
                                      }
                                    },
                              child: const Text('Create post')),
                      ]),
                      if (!canPost) const Text('Only moderators can post.'),
                      if (posts.isEmpty) const Text('No posts yet.'),
                      for (final post in posts)
                        _GroupPost(
                            key: ValueKey(post['id']),
                            repository: widget.repository,
                            post: post,
                            moderator: moderator,
                            onRefresh: reload,
                            onReport: () => report(post: post['id'] as String)),
                      const Divider(),
                      Text('Members',
                          style: Theme.of(context).textTheme.titleMedium),
                      if (visibleMembers.isEmpty)
                        const Text('No members found.'),
                      for (final member in visibleMembers
                          .where((m) => m['status'] == 'active'))
                        _MemberTile(
                            repository: widget.repository,
                            member: member,
                            allowModeration: moderator &&
                                member['user_id'] != widget.repository.userId &&
                                member['role'] != 'owner' &&
                                (role == 'owner' ||
                                    member['role'] != 'moderator'),
                            owner: role == 'owner',
                            onAction: (operation) => manageMember(
                                member['user_id'] as String, operation),
                            onReport: member['user_id'] ==
                                    widget.repository.userId
                                ? null
                                : () =>
                                    report(user: member['user_id'] as String)),
                      if (moderator &&
                          visibleMembers
                              .any((m) => m['status'] == 'pending')) ...[
                        Text('Join requests',
                            style: Theme.of(context).textTheme.titleMedium),
                        for (final member in visibleMembers
                            .where((m) => m['status'] == 'pending'))
                          _MemberTile(
                            repository: widget.repository,
                            member: member,
                            allowModeration: true,
                            owner: role == 'owner',
                            onAction: (operation) => manageMember(
                                member['user_id'] as String, operation),
                            onReport: null,
                          ),
                      ],
                    ],
                  ],
                ));
          },
        ),
      );
}

class _BannedMembersPage extends StatefulWidget {
  const _BannedMembersPage(
      {required this.repository,
      required this.groupId,
      required this.onChanged});
  final GroupsRepository repository;
  final String groupId;
  final VoidCallback onChanged;
  @override
  State<_BannedMembersPage> createState() => _BannedMembersPageState();
}

class _BannedMembersPageState extends State<_BannedMembersPage> {
  late Future<List<Map<String, dynamic>>> future;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() {
    setState(() {
      future = widget.repository.bannedMembers(widget.groupId);
    });
  }

  Future<void> unban(Map<String, dynamic> member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unban member?'),
        content: const Text(
            'They can join again. Previously hidden posts and comments will remain hidden.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Unban')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      await widget.repository.rpc('group_unban', {
        'p_group': widget.groupId,
        'p_user': member['user_id'],
      });
      widget.onChanged();
      if (mounted) reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(groupError(error))));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Banned members')),
        body: FutureBuilder(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) return _error(snapshot.error!, reload);
            final members = snapshot.requireData;
            if (members.isEmpty) {
              return const Center(child: Text('No banned members.'));
            }
            return ListView(children: [
              for (final member in members)
                ListTile(
                  leading: _personAvatar(member),
                  title: Text(_profileName(member)),
                  subtitle: Text([
                    if (_profileUsername(member).isNotEmpty)
                      _profileUsername(member),
                    if (member['banned_at'] != null &&
                        DateTime.tryParse(member['banned_at'] as String) !=
                            null)
                      'Banned ${MaterialLocalizations.of(context).formatFullDate(DateTime.parse(member['banned_at'] as String).toLocal())}',
                    if ((member['banned_by_full_name'] as String?)
                            ?.trim()
                            .isNotEmpty ==
                        true)
                      'By ${(member['banned_by_full_name'] as String).trim()}'
                    else if ((member['banned_by_username'] as String?)
                            ?.trim()
                            .isNotEmpty ==
                        true)
                      'By @${(member['banned_by_username'] as String).trim()}',
                  ].join(' · ')),
                  trailing: TextButton(
                      onPressed: busy ? null : () => unban(member),
                      child: const Text('Unban')),
                ),
            ]);
          },
        ),
      );
}

class _InvitePage extends StatefulWidget {
  const _InvitePage({required this.repository, required this.groupId});
  final GroupsRepository repository;
  final String groupId;
  @override
  State<_InvitePage> createState() => _InvitePageState();
}

class _InvitePageState extends State<_InvitePage> {
  late final community = CommunityRepository(widget.repository.client);
  final search = TextEditingController();
  Future<List<CommunityPerson>>? future;
  bool busy = false;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void find() => setState(() {
        future = community.searchUsers(search.text);
      });
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Invite people')),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(
                    child: TextField(
                        controller: search,
                        decoration:
                            const InputDecoration(labelText: 'Search users'),
                        onSubmitted: (_) => find())),
                IconButton(
                    onPressed: find,
                    tooltip: 'Search',
                    icon: const Icon(Icons.search)),
              ])),
          Expanded(
              child: future == null
                  ? const Center(child: Text('Search for someone to invite.'))
                  : FutureBuilder(
                      future: future,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          if (snapshot.hasError) {
                            return _error(snapshot.error!, find);
                          }
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.data!.isEmpty) {
                          return const Center(child: Text('No people found.'));
                        }
                        return ListView(children: [
                          for (final person in snapshot.data!)
                            ListTile(
                              leading: _avatar(person.avatarUrl),
                              title: Text(person.fullName?.isNotEmpty == true
                                  ? person.fullName!
                                  : person.username),
                              subtitle: Text('@${person.username}'),
                              trailing: TextButton(
                                  onPressed: busy
                                      ? null
                                      : () async {
                                          setState(() => busy = true);
                                          try {
                                            await widget.repository.rpc(
                                                'group_invite', {
                                              'p_group': widget.groupId,
                                              'p_user': person.id
                                            });
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                      content: Text(
                                                          'Invitation sent.')));
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content:
                                                          Text(groupError(e))));
                                            }
                                          } finally {
                                            if (mounted) {
                                              setState(() => busy = false);
                                            }
                                          }
                                        },
                                  child: const Text('Invite')),
                            ),
                        ]);
                      })),
        ]),
      );
}

Future<String?> _prompt(
    BuildContext context, String title, String label) async {
  var value = '';
  return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
            title: Text(title),
            content: TextField(
                autofocus: true,
                maxLines: 3,
                onChanged: (text) => value = text,
                decoration: InputDecoration(labelText: label)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () {
                    if (value.trim().isNotEmpty) {
                      Navigator.pop(context, value.trim());
                    }
                  },
                  child: const Text('Submit'))
            ],
          ));
}

Future<(String, XFile?)?> _composeGroupPost(BuildContext context, bool images) {
  var body = '';
  XFile? image;
  return showDialog<(String, XFile?)>(
    context: context,
    builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
              title: const Text('Create post'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    autofocus: true,
                    maxLines: 3,
                    maxLength: 5000,
                    decoration:
                        const InputDecoration(labelText: 'Write a post'),
                    onChanged: (value) => body = value),
                if (images)
                  TextButton.icon(
                      icon: const Icon(Icons.image_outlined),
                      label: Text(image == null ? 'Add image' : image!.name),
                      onPressed: () async {
                        try {
                          final selected = await ImagePicker()
                              .pickImage(source: ImageSource.gallery);
                          if (context.mounted && selected != null) {
                            update(() => image = selected);
                          }
                        } catch (error) {
                          debugPrint('Could not choose group image: $error');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Could not choose the image. Please try again.')));
                          }
                        }
                      }),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () {
                      if (body.trim().isNotEmpty) {
                        Navigator.pop(context, (body.trim(), image));
                      }
                    },
                    child: const Text('Share')),
              ],
            )),
  );
}

class _MemberTile extends StatelessWidget {
  const _MemberTile(
      {required this.repository,
      required this.member,
      required this.allowModeration,
      required this.owner,
      required this.onAction,
      required this.onReport});
  final GroupsRepository repository;
  final Map<String, dynamic> member;
  final bool allowModeration;
  final bool owner;
  final ValueChanged<String> onAction;
  final VoidCallback? onReport;
  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: repository.profile(member['user_id'] as String),
      builder: (context, snapshot) {
        final p = snapshot.data;
        return ListTile(
          leading: _personAvatar(p),
          title:
              Text(snapshot.hasError ? 'Profile unavailable' : _profileName(p)),
          subtitle: Text([
            if (_profileUsername(p).isNotEmpty) _profileUsername(p),
            '${member['role']} · ${member['status']}',
          ].join(' · ')),
          trailing: allowModeration || onReport != null
              ? PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'report') {
                      onReport?.call();
                    } else {
                      onAction(v);
                    }
                  },
                  itemBuilder: (_) => [
                        if (allowModeration && member['status'] == 'pending')
                          const PopupMenuItem(
                              value: 'approve', child: Text('Approve request')),
                        if (allowModeration &&
                            owner &&
                            member['status'] == 'active')
                          PopupMenuItem(
                              value: member['role'] == 'moderator'
                                  ? 'demote'
                                  : 'promote',
                              child: Text(member['role'] == 'moderator'
                                  ? 'Remove moderator role'
                                  : 'Make moderator')),
                        if (allowModeration)
                          const PopupMenuItem(
                              value: 'remove', child: Text('Remove')),
                        if (allowModeration)
                          const PopupMenuItem(value: 'ban', child: Text('Ban')),
                        if (onReport != null)
                          const PopupMenuItem(
                              value: 'report', child: Text('Report member')),
                      ])
              : null,
        );
      });
}

class _GroupPost extends StatefulWidget {
  const _GroupPost(
      {super.key,
      required this.repository,
      required this.post,
      required this.moderator,
      required this.onRefresh,
      required this.onReport});
  final GroupsRepository repository;
  final Map<String, dynamic> post;
  final bool moderator;
  final VoidCallback onRefresh, onReport;
  @override
  State<_GroupPost> createState() => _GroupPostState();
}

class _GroupPostState extends State<_GroupPost> {
  late Future<List<Map<String, dynamic>>> likes;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    likes = widget.repository.likes(widget.post['id'] as String);
  }

  @override
  Widget build(BuildContext context) => Card(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FutureBuilder(
            future:
                widget.repository.profile(widget.post['author_id'] as String),
            builder: (context, snapshot) => ListTile(
                  leading: _personAvatar(snapshot.data),
                  title: Text(snapshot.hasError
                      ? 'Profile unavailable'
                      : _profileName(snapshot.data)),
                  subtitle: _profileUsername(snapshot.data).isEmpty
                      ? null
                      : Text(_profileUsername(snapshot.data)),
                  trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'report') {
                          widget.onReport();
                          return;
                        }
                        try {
                          await widget.repository.rpc('group_delete_post',
                              {'p_post': widget.post['id']});
                          widget.onRefresh();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(groupError(e))));
                          }
                        }
                      },
                      itemBuilder: (_) => [
                            if (widget.moderator ||
                                widget.post['author_id'] ==
                                    widget.repository.userId)
                              const PopupMenuItem(
                                  value: 'delete', child: Text('Delete post')),
                            if (widget.post['author_id'] !=
                                widget.repository.userId)
                              const PopupMenuItem(
                                  value: 'report', child: Text('Report post')),
                          ]),
                )),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(widget.post['body'] as String)),
        if (widget.post['image_path'] != null)
          FutureBuilder(
              future: widget.repository
                  .imageUrl(widget.post['image_path'] as String),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return TextButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Image unavailable. Retry'));
                }
                if (!snapshot.hasData) return const LinearProgressIndicator();
                return PostImage(
                    image: NetworkImage(snapshot.data!),
                    onRetry: () => setState(() {}));
              }),
        FutureBuilder(
            future: likes,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return TextButton(
                    onPressed: () => setState(load),
                    child: const Text('Could not load likes. Retry'));
              }
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final liked = snapshot.data!
                  .any((l) => l['user_id'] == widget.repository.userId);
              return Row(children: [
                TextButton.icon(
                    onPressed: busy
                        ? null
                        : () async {
                            setState(() => busy = true);
                            try {
                              await widget.repository.rpc(
                                  'group_set_post_like', {
                                'p_post': widget.post['id'],
                                'p_liked': !liked
                              });
                              if (mounted) setState(load);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(groupError(e))));
                              }
                            } finally {
                              if (mounted) setState(() => busy = false);
                            }
                          },
                    icon: Icon(liked ? Icons.favorite : Icons.favorite_border),
                    label: Text('${snapshot.data!.length}')),
                TextButton(
                    onPressed: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                              builder: (_) => _CommentsPage(
                                  repository: widget.repository,
                                  postId: widget.post['id'] as String)));
                      if (mounted) widget.onRefresh();
                    },
                    child: const Text('Comments')),
              ]);
            }),
      ]));
}

class _CommentsPage extends StatefulWidget {
  const _CommentsPage({required this.repository, required this.postId});
  final GroupsRepository repository;
  final String postId;
  @override
  State<_CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<_CommentsPage> {
  late Future<List<Map<String, dynamic>>> future;
  final controller = TextEditingController();
  bool busy = false;
  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() {
    setState(() {
      future = widget.repository.comments(widget.postId);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Comments')),
        body: Column(children: [
          Expanded(
              child: FutureBuilder(
                  future: future,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      if (snapshot.hasError) {
                        return _error(snapshot.error!, reload);
                      }
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.data!.isEmpty) {
                      return const Center(child: Text('No comments yet.'));
                    }
                    return ListView(children: [
                      for (final comment in snapshot.data!)
                        ListTile(
                          title: Text(comment['body'] as String),
                          subtitle: FutureBuilder(
                              future: widget.repository
                                  .profile(comment['author_id'] as String),
                              builder: (_, profile) => Text(profile.hasError
                                  ? 'Profile unavailable'
                                  : profile.data?['username'] as String? ??
                                      'Member')),
                        ),
                    ]);
                  })),
          Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(
                    child: TextField(
                        controller: controller,
                        decoration:
                            const InputDecoration(labelText: 'Comment'))),
                IconButton(
                    tooltip: 'Send comment',
                    onPressed: busy
                        ? null
                        : () async {
                            final body = controller.text.trim();
                            if (body.isEmpty) return;
                            setState(() => busy = true);
                            try {
                              await widget.repository.rpc(
                                  'group_create_comment',
                                  {'p_post': widget.postId, 'p_body': body});
                              controller.clear();
                              if (mounted) reload();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(groupError(e))));
                              }
                            } finally {
                              if (mounted) setState(() => busy = false);
                            }
                          },
                    icon: const Icon(Icons.send)),
              ])),
        ]),
      );
}
