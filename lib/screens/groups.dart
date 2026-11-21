import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n_strings.dart';
import '../services/groups_repository.dart';
import '../services/community_repository.dart';
import '../services/storage_image.dart';
import '../models/community_models.dart';
import '../ui.dart';
import '../widgets/post_image.dart';

const groupCategories = [
  'Weight loss',
  'Muscle building',
  'Running & cardio',
  'Yoga & mobility',
  'Nutrition',
  'Beginners',
  'General fitness',
  'Other',
];

class GroupAvatar extends StatefulWidget {
  const GroupAvatar(
      {super.key,
      required this.id,
      required this.name,
      this.url,
      this.path,
      this.repository,
      this.preview});
  final String id;
  final String name;
  final String? url;
  final String? path;
  final GroupsRepository? repository;
  final Uint8List? preview;

  @override
  State<GroupAvatar> createState() => _GroupAvatarState();
}

class _GroupAvatarState extends State<GroupAvatar> {
  Future<String>? signedUrl;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(GroupAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path ||
        oldWidget.repository != widget.repository) {
      load();
    }
  }

  void load() {
    timer?.cancel();
    signedUrl = widget.path == null || widget.repository == null
        ? null
        : widget.repository!.signedAvatarUrl(widget.path!);
    if (signedUrl != null) {
      timer = Timer(const Duration(minutes: 9), () {
        if (mounted) setState(load);
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const palette = [
      Color(0xFF3D6B70),
      Color(0xFF5B5982),
      Color(0xFF795B70),
      Color(0xFF796344),
      Color(0xFF476B58),
      Color(0xFF526782),
    ];
    var hash = 0;
    for (final unit in widget.id.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    final words = widget.name.trim().split(RegExp(r'\s+'));
    final initials = words.first.isEmpty
        ? '?'
        : '${words.first.characters.first}${words.length > 1 ? words.last.characters.first : ''}'
            .toUpperCase();
    return FutureBuilder<String>(
      future: signedUrl,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Could not sign group photo: ${snapshot.error}');
        }
        final url = widget.path == null ? widget.url : snapshot.data;
        ImageProvider? image;
        if (widget.preview != null) {
          image = MemoryImage(widget.preview!);
        } else {
          image = storageImage(url);
        }
        return CircleAvatar(
          backgroundColor: palette[hash % palette.length],
          foregroundColor: Colors.white,
          foregroundImage: image,
          onForegroundImageError: image == null
              ? null
              : (error, stack) =>
                  debugPrint('Could not load group avatar: $error'),
          child: Text(initials,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}

String _groupCategory(BuildContext context, String value) {
  final l = strings(context);
  return switch (value) {
    'Weight loss' => l.groupsWeightLoss,
    'Muscle building' => l.groupsMuscleBuilding,
    'Running & cardio' => l.groupsRunning,
    'Yoga & mobility' => l.groupsYoga,
    'Nutrition' => l.groupsNutrition,
    'Beginners' => l.groupsBeginners,
    'General fitness' => l.groupsFitness,
    'Other' => l.groupsOther,
    'All' => l.groupsAll,
    _ => value,
  };
}

String _groupVisibility(BuildContext context, String value) {
  final l = strings(context);
  return switch (value) {
    'public' => l.groupsPublic,
    'private' => l.groupsPrivate,
    _ => value,
  };
}

String _localizedGroupError(BuildContext context, Object error) {
  final l = strings(context);
  final message = groupError(error);
  return switch (message) {
    'Please sign in again.' => l.communityErrorSignIn,
    'Could not connect. Check your internet connection.' =>
      l.communityErrorConnection,
    'The request timed out. Please try again.' => l.communityErrorTimeout,
    'Choose a JPG, PNG or WebP photo.' => l.groupsPhotoTypeError,
    'Could not read the photo. Please choose it again.' =>
      l.groupsPhotoReadError,
    'The photo is empty. Choose another photo.' => l.groupsPhotoEmptyError,
    'The photo does not match its file type. Choose a valid JPG, PNG or WebP image.' =>
      l.groupsPhotoMismatchError,
    'The photo is too large. Choose one under 2 MB.' => l.groupsPhotoSizeError,
    'Could not read the photo. Choose a valid JPG, PNG or WebP image.' =>
      l.groupsPhotoInvalidError,
    'Choose a JPG, PNG or WebP image smaller than 8 MB.' =>
      l.groupImageTypeSizeError,
    'Could not read the image. Please choose it again.' =>
      l.groupImageReadError,
    'Could not upload the image. Please try again.' => l.groupImageUploadError,
    'You are banned from this group. Only the group owner or a moderator can unban you.' =>
      l.groupsBannedError,
    'This group is full.' => l.groupsFullError,
    'Only moderators can post in this group.' => l.groupsModeratorsOnlyError,
    'Posting limit reached. Please try again later.' =>
      l.groupsPostingLimitError,
    'You can create up to 3 groups.' => l.groupsCreationLimitError,
    'This group is unavailable or requires an invitation.' =>
      l.groupsUnavailableError,
    _ => friendlyError(error, localizations: l),
  };
}

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
                  (category == 'All' ||
                      g.category == category ||
                      (category == 'Other' &&
                          !groupCategories.contains(g.category))) &&
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
                      child: _tab(strings(context).groupsDiscover, !mine,
                          () => setState(() => mine = false))),
                  Expanded(
                      child: _tab(strings(context).groupsMine, mine,
                          () => setState(() => mine = true))),
                  IconButton(
                      tooltip: strings(context).groupsCreate,
                      onPressed: () async {
                        final message = await Navigator.push<String>(
                            context,
                            MaterialPageRoute<String>(
                                builder: (_) =>
                                    GroupSettingsPage(repository: repo)));
                        if (mounted) {
                          reload();
                          if (message != null && context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(message)));
                          }
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline)),
                ]),
                TextField(
                    decoration: InputDecoration(
                        labelText: strings(context).groupsSearch,
                        prefixIcon: const Icon(Icons.search)),
                    onChanged: (value) => setState(() => query = value)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: category,
                    decoration: InputDecoration(
                        labelText: strings(context).groupsCategory),
                    items: ['All', ...groupCategories]
                        .map((c) => DropdownMenuItem(
                            value: c, child: Text(_groupCategory(context, c))))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => category = value ?? 'All')),
                if (mine && inviteIds.isNotEmpty) ...[
                  Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(strings(context).groupsInvitations)),
                  for (final id in inviteIds)
                    Card(
                        child: ListTile(
                      leading: groups.where((g) => g.id == id).isEmpty
                          ? const Icon(Icons.mail_outline)
                          : GroupAvatar(
                              id: id,
                              name: groups.firstWhere((g) => g.id == id).name,
                              url: groups.firstWhere((g) => g.id == id).avatar,
                              path: groups
                                  .firstWhere((g) => g.id == id)
                                  .avatarPath,
                              repository: repo),
                      title: Text(groups.where((g) => g.id == id).isEmpty
                          ? strings(context).groupsInvitation
                          : groups.firstWhere((g) => g.id == id).name),
                      subtitle: Text(strings(context).groupsOpenToAccept),
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
                  Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(child: Text(strings(context).groupsNone)))
                else
                  for (final group in filtered)
                    Card(
                        child: ListTile(
                      leading: GroupAvatar(
                          id: group.id,
                          name: group.name,
                          url: group.avatar,
                          path: group.avatarPath,
                          repository: repo),
                      title: Text(group.name),
                      subtitle: Text(pendingIds.contains(group.id)
                          ? strings(context).groupsPendingSummary(
                              strings(context).groupsSummary(
                                  _groupCategory(context, group.category),
                                  _groupVisibility(context, group.visibility)))
                          : strings(context).groupsSummary(
                              _groupCategory(context, group.category),
                              _groupVisibility(context, group.visibility))),
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

  Widget _tab(String label, bool selected, VoidCallback onPressed) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: selected ? colors.primary : Colors.transparent,
                  width: 2)),
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
              foregroundColor: selected
                  ? colors.primary
                  : colors.onSurface.withValues(alpha: 0.6)),
          child: Text(label),
        ),
      ),
    );
  }
}

String _profileName(BuildContext context, Map<String, dynamic>? profile) {
  final name = (profile?['full_name'] as String?)?.trim();
  final username = (profile?['username'] as String?)?.trim();
  return name?.isNotEmpty == true
      ? name!
      : username?.isNotEmpty == true
          ? friendlyUsername(context, username!)
          : strings(context).groupsMember;
}

Widget _personAvatar(BuildContext context, Map<String, dynamic>? profile) {
  final name = _profileName(context, profile);
  final url = profile?['avatar_url'] as String?;
  final image = storageImage(url);
  return CircleAvatar(
    foregroundImage: image,
    onForegroundImageError: image == null
        ? null
        : (error, stack) => debugPrint('Could not load profile avatar: $error'),
    child: Text(name.characters.first.toUpperCase()),
  );
}

String _profileUsername(Map<String, dynamic>? profile) {
  final username = (profile?['username'] as String?)?.trim();
  return username == null || username.isEmpty ? '' : '@$username';
}

Widget _error(Object error, VoidCallback retry) => Builder(
    builder: (context) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_localizedGroupError(context, error),
              textAlign: TextAlign.center),
          TextButton(
              onPressed: retry, child: Text(strings(context).groupsRetry)),
        ])));

class GroupSettingsPage extends StatefulWidget {
  const GroupSettingsPage(
      {super.key, required this.repository, this.group, this.pickPhoto});
  final GroupsRepository repository;
  final Group? group;
  final Future<XFile?> Function()? pickPhoto;
  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage> {
  late final name = TextEditingController(text: widget.group?.name ?? '');
  late final description =
      TextEditingController(text: widget.group?.description ?? '');
  late String category = widget.group?.category ?? 'General fitness';
  late final limit =
      TextEditingController(text: '${widget.group?.limit ?? 100}');
  late final rules = TextEditingController(text: widget.group?.rules ?? '');
  late String visibility = widget.group?.visibility ?? 'public';
  late String joinMode = widget.group?.joinMode ?? 'open';
  late String posting = widget.group?.posting ?? 'everyone';
  late bool images = widget.group?.images ?? false;
  late bool chat = widget.group?.chat ?? false;
  bool busy = false;
  bool choosingPhoto = false;
  String Function(BuildContext)? error;
  GroupAvatarImage? photo;
  bool removePhoto = false;

  Future<void> choosePhoto() async {
    setState(() => choosingPhoto = true);
    try {
      final selected = await (widget.pickPhoto?.call() ??
          ImagePicker().pickImage(
              source: ImageSource.gallery,
              maxWidth: 1024,
              maxHeight: 1024,
              imageQuality: 85));
      if (selected == null) return;
      final prepared = await widget.repository.prepareAvatar(selected);
      if (mounted) {
        setState(() {
          photo = prepared;
          removePhoto = false;
          error = null;
        });
      }
    } catch (e, stack) {
      debugPrint('Could not choose group photo: $e\n$stack');
      if (mounted) {
        final message = e is GroupException
            ? _localizedGroupError(context, e)
            : strings(context).groupsPhotoChooseError;
        setState(() => error = e is GroupException
            ? (context) => _localizedGroupError(context, e)
            : (context) => strings(context).groupsPhotoChooseError);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => choosingPhoto = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    limit.dispose();
    rules.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final size = int.tryParse(limit.text);
    if (name.text.trim().length < 3 ||
        category.trim().isEmpty ||
        size == null ||
        size < 1 ||
        size > 10000) {
      setState(() => error = (context) => strings(context).groupsValidation);
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
        'p_category': category.trim(),
        'p_visibility': visibility,
        'p_join_mode': joinMode,
        'p_member_limit': size,
        'p_rules': rules.text.trim(),
        'p_avatar_url': widget.group?.avatar,
        'p_who_can_post': posting,
        'p_images_allowed': images,
        'p_chat_enabled': chat,
      };
      if (widget.group != null) params['p_group'] = widget.group!.id;
      final result = await widget.repository.rpc(
          widget.group == null ? 'group_create' : 'group_update_settings',
          params);
      if (widget.group == null && photo != null) {
        try {
          if (result is! String || result.isEmpty) {
            throw StateError('Group creation returned no ID');
          }
          await widget.repository.setAvatar(result, photo, null);
        } catch (e, stack) {
          debugPrint('Group created but photo upload failed: $e\n$stack');
          if (mounted) {
            Navigator.pop(context, strings(context).groupsPhotoCreatedError);
          }
          return;
        }
      } else if (widget.group != null && (photo != null || removePhoto)) {
        try {
          await widget.repository
              .setAvatar(widget.group!.id, photo, widget.group!.avatarPath);
        } catch (e, stack) {
          debugPrint('Group photo update failed: $e\n$stack');
          if (mounted) {
            setState(() =>
                error = (context) => strings(context).groupsPhotoSaveError);
          }
          return;
        }
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => error = (context) => _localizedGroupError(context, e));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget dropdown(String label, String value, Map<String, String> options,
          ValueChanged<String> change) =>
      DropdownButtonFormField<String>(
          isExpanded: true,
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
            title: Text(widget.group == null
                ? strings(context).groupsCreate
                : strings(context).groupsSettings)),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          if (widget.group == null ||
              widget.group!.ownerId == widget.repository.userId) ...[
            GroupAvatar(
              id: widget.group?.id ?? '',
              name: name.text,
              url: removePhoto ? null : widget.group?.avatar,
              path: removePhoto ? null : widget.group?.avatarPath,
              repository: widget.repository,
              preview: photo?.bytes,
            ),
            Row(children: [
              TextButton(
                  onPressed: busy || choosingPhoto ? null : choosePhoto,
                  child: Text(strings(context).groupsChoosePhoto)),
              if (photo != null ||
                  (!removePhoto && widget.group?.avatarPath != null))
                TextButton(
                    onPressed: busy || choosingPhoto
                        ? null
                        : () => setState(() {
                              photo = null;
                              removePhoto = true;
                            }),
                    child: Text(strings(context).groupsRemovePhoto)),
            ]),
          ],
          TextField(
              controller: name,
              onChanged: (_) => setState(() {}),
              decoration:
                  InputDecoration(labelText: strings(context).groupsName),
              maxLength: 80,
              buildCounter: _counter),
          TextField(
              controller: description,
              decoration: InputDecoration(
                  labelText: strings(context).groupsDescription),
              maxLength: 2000,
              buildCounter: _counter),
          dropdown(
              strings(context).groupsCategory,
              category,
              {
                for (final value in groupCategories)
                  value: _groupCategory(context, value),
                if (!groupCategories.contains(category)) category: category,
              },
              (v) => category = v),
          const SizedBox(height: 12),
          dropdown(
              strings(context).groupsVisibility,
              visibility,
              {
                'public': strings(context).groupsPublic,
                'private': strings(context).groupsPrivate
              },
              (v) => visibility = v),
          const SizedBox(height: 12),
          dropdown(
              strings(context).groupsJoinMode,
              joinMode,
              {
                'open': strings(context).groupsOpen,
                'approval': strings(context).groupsApproval,
                'invite_only': strings(context).groupsInviteOnly
              },
              (v) => joinMode = v),
          if (visibility == 'private')
            Text(strings(context).groupsPrivateInvitation),
          const SizedBox(height: 12),
          TextField(
              controller: limit,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: strings(context).groupsMemberLimit)),
          const SizedBox(height: 12),
          dropdown(
              strings(context).groupsWhoCanPost,
              posting,
              {
                'everyone': strings(context).groupsEveryone,
                'moderators': strings(context).groupsModerators
              },
              (v) => posting = v),
          SwitchListTile(
              title: Text(strings(context).groupsImagesAllowed),
              value: images,
              onChanged: busy ? null : (v) => setState(() => images = v)),
          SwitchListTile(
              title: Text(strings(context).groupsChatPhase2),
              subtitle: Text(strings(context).groupsChatUnavailable),
              value: chat,
              onChanged: busy ? null : (v) => setState(() => chat = v)),
          TextField(
              controller: rules,
              maxLines: 3,
              maxLength: 5000,
              decoration:
                  InputDecoration(labelText: strings(context).groupsRules),
              buildCounter: _counter),
          if (error != null)
            Padding(
                padding: const EdgeInsets.all(8),
                child: Text(error!(context),
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error))),
          const SizedBox(height: 12),
          ElevatedButton(
              onPressed: busy || choosingPhoto ? null : save,
              child: Text(busy
                  ? strings(context).groupsSaving
                  : strings(context).groupsSave)),
        ]),
      );

  Widget _counter(BuildContext context,
          {required int currentLength,
          required bool isFocused,
          required int? maxLength}) =>
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Text(
            strings(context).groupsCounter('$currentLength', '$maxLength'),
            style: Theme.of(context).textTheme.bodySmall),
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
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_localizedGroupError(context, e))));
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
    final reason = await _prompt(
        context, strings(context).groupReport, strings(context).groupReason);
    if (!mounted || reason == null) return;
    final success = await action(() => widget.repository.rpc('group_report', {
          'p_group': widget.groupId,
          'p_reason': reason,
          'p_post': post,
          'p_user': user,
        }));
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings(context).communityReportSubmitted)));
    }
  }

  Future<void> manageMember(String userId, String operation) async {
    if (operation == 'remove' || operation == 'ban') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(operation == 'ban'
              ? strings(context).groupBanQuestion
              : strings(context).groupRemoveQuestion),
          content: Text(operation == 'ban'
              ? strings(context).groupBanDetails
              : strings(context).groupRemoveDetails),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(strings(context).groupCancel)),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(operation == 'ban'
                    ? strings(context).groupBan
                    : strings(context).groupRemove)),
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
        appBar: AppBar(title: Text(strings(context).groupTitle)),
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
                    Center(
                        child:
                            Text(strings(context).groupUnavailableInvitation)),
                    if (invited)
                      TextButton(
                          onPressed:
                              busy ? null : () => changeMembership(false),
                          child: Text(strings(context).groupAcceptInvitation)),
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
            final moderator =
                active && (role == 'owner' || role == 'moderator');
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
                      GroupAvatar(
                          id: group.id,
                          name: group.name,
                          url: group.avatar,
                          path: group.avatarPath,
                          repository: widget.repository),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(group.name,
                                style: Theme.of(context).textTheme.titleLarge),
                            Text(strings(context).groupHeaderDetails(
                                _groupCategory(context, group.category),
                                strings(context).groupsMemberCount(count))),
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
                                          group: group)));
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
                                  PopupMenuItem(
                                      value: 'settings',
                                      child: Text(
                                          strings(context).groupMenuSettings)),
                                if (moderator)
                                  PopupMenuItem(
                                      value: 'invite',
                                      child: Text(
                                          strings(context).groupInvitePeople)),
                                if (moderator)
                                  PopupMenuItem(
                                      value: 'banned',
                                      child: Text(
                                          strings(context).groupBannedMembers)),
                                if (role != 'owner')
                                  PopupMenuItem(
                                      value: 'report',
                                      child: Text(
                                          strings(context).groupReportGroup)),
                              ]),
                    ]),
                    const SizedBox(height: 8),
                    Text(group.description),
                    if (group.rules.isNotEmpty)
                      Text(strings(context).groupRulesValue(group.rules)),
                    if (role != 'owner')
                      Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton(
                            onPressed: busy ||
                                    (!active &&
                                        status != 'pending' &&
                                        group.joinMode == 'invite_only' &&
                                        !invited)
                                ? null
                                : () => changeMembership(
                                    active || status == 'pending'),
                            child: Text(active
                                ? strings(context).groupLeave
                                : status == 'pending'
                                    ? strings(context).groupCancelRequest
                                    : invited
                                        ? strings(context).groupAcceptInvitation
                                        : group.joinMode == 'approval'
                                            ? strings(context).groupRequestJoin
                                            : group.joinMode == 'invite_only'
                                                ? strings(context)
                                                    .groupInvitationRequired
                                                : strings(context).groupJoin),
                          )),
                    if (!active)
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(status == 'pending'
                              ? strings(context).communityRequestPending
                              : strings(context).groupJoinToSee))
                    else ...[
                      const Divider(),
                      Row(children: [
                        Expanded(
                            child: Text(strings(context).groupPosts,
                                style:
                                    Theme.of(context).textTheme.titleMedium)),
                        if (canPost)
                          FilledButton(
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
                              child: Text(strings(context).groupCreatePost)),
                      ]),
                      if (!canPost) Text(strings(context).groupModeratorsPost),
                      if (posts.isEmpty) Text(strings(context).groupNoPosts),
                      for (final post in posts)
                        _GroupPost(
                            key: ValueKey(post['id']),
                            repository: widget.repository,
                            post: post,
                            moderator: moderator,
                            onRefresh: reload,
                            onReport: () => report(post: post['id'] as String)),
                      const Divider(),
                      Text(strings(context).groupMembers,
                          style: Theme.of(context).textTheme.titleMedium),
                      if (visibleMembers.isEmpty)
                        Text(strings(context).groupNoMembers),
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
                        Text(strings(context).groupJoinRequests,
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
        title: Text(strings(context).groupUnbanQuestion),
        content: Text(strings(context).groupUnbanDetails),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(strings(context).groupCancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(strings(context).groupUnban)),
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
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_localizedGroupError(context, error))));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(strings(context).groupBannedMembers)),
        body: FutureBuilder(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) return _error(snapshot.error!, reload);
            final members = snapshot.requireData;
            if (members.isEmpty) {
              return Center(child: Text(strings(context).groupNoBanned));
            }
            return ListView(children: [
              for (final member in members)
                ListTile(
                  leading: _personAvatar(context, member),
                  title: Text(_profileName(context, member)),
                  subtitle: Text([
                    if (_profileUsername(member).isNotEmpty)
                      ltrValue(friendlyHandle(context,
                          (member['username'] as String).trim())),
                    if (member['banned_at'] != null &&
                        DateTime.tryParse(member['banned_at'] as String) !=
                            null)
                      strings(context).groupBannedDate((DateFormat.yMMMMEEEEd(
                              Localizations.localeOf(context).languageCode)
                            ..useNativeDigits = false)
                          .format(DateTime.parse(member['banned_at'] as String)
                              .toLocal())),
                    if ((member['banned_by_full_name'] as String?)
                            ?.trim()
                            .isNotEmpty ==
                        true)
                      strings(context).groupBannedBy(
                          (member['banned_by_full_name'] as String).trim())
                    else if ((member['banned_by_username'] as String?)
                            ?.trim()
                            .isNotEmpty ==
                        true)
                      strings(context).groupBannedBy(ltrValue(friendlyHandle(
                          context,
                          (member['banned_by_username'] as String).trim()))),
                  ].join(' · ')),
                  trailing: TextButton(
                      onPressed: busy ? null : () => unban(member),
                      child: Text(strings(context).groupUnban)),
                ),
            ]);
          },
        ),
      );
}

class _InvitePage extends StatefulWidget {
  const _InvitePage({required this.repository, required this.group});
  final GroupsRepository repository;
  final Group group;
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
        appBar: AppBar(title: Text(strings(context).groupInvitePeople)),
        body: Column(children: [
          ListTile(
            leading: GroupAvatar(
                id: widget.group.id,
                name: widget.group.name,
                url: widget.group.avatar,
                path: widget.group.avatarPath,
                repository: widget.repository),
            title: Text(widget.group.name),
          ),
          Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(
                    child: TextField(
                        controller: search,
                        decoration: InputDecoration(
                            labelText: strings(context).groupSearchUsers),
                        onSubmitted: (_) => find())),
                IconButton(
                    onPressed: find,
                    tooltip: strings(context).groupSearch,
                    icon: const Icon(Icons.search)),
              ])),
          Expanded(
              child: future == null
                  ? Center(child: Text(strings(context).groupSearchInvite))
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
                          return Center(
                              child: Text(strings(context).groupNoPeople));
                        }
                        return ListView(children: [
                          for (final person in snapshot.data!)
                            ListTile(
                              leading: _personAvatar(context, {
                                'full_name': person.fullName,
                                'username': person.username,
                                'avatar_url': person.avatarUrl,
                              }),
                              title: Text(person.fullName?.isNotEmpty == true
                                  ? person.fullName!
                                  : friendlyUsername(context, person.username)),
                              subtitle: AccountHandle(person.username),
                              trailing: TextButton(
                                  onPressed: busy
                                      ? null
                                      : () async {
                                          setState(() => busy = true);
                                          try {
                                            await widget.repository.rpc(
                                                'group_invite', {
                                              'p_group': widget.group.id,
                                              'p_user': person.id
                                            });
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(strings(
                                                              context)
                                                          .groupInvitationSent)));
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(
                                                          _localizedGroupError(
                                                              context, e))));
                                            }
                                          } finally {
                                            if (mounted) {
                                              setState(() => busy = false);
                                            }
                                          }
                                        },
                                  child: Text(strings(context).groupInvite)),
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
                  child: Text(strings(context).groupCancel)),
              TextButton(
                  onPressed: () {
                    if (value.trim().isNotEmpty) {
                      Navigator.pop(context, value.trim());
                    }
                  },
                  child: Text(strings(context).communitySubmit))
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
              title: Text(strings(context).groupCreatePost),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    autofocus: true,
                    maxLines: 3,
                    maxLength: 5000,
                    decoration: InputDecoration(
                        labelText: strings(context).groupWritePost),
                    onChanged: (value) => body = value),
                if (images)
                  TextButton.icon(
                      icon: const Icon(Icons.image_outlined),
                      label: Text(image == null
                          ? strings(context).groupAddImage
                          : image!.name),
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
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    strings(context).groupImageChooseError)));
                          }
                        }
                      }),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(strings(context).groupCancel)),
                TextButton(
                    onPressed: () {
                      if (body.trim().isNotEmpty) {
                        Navigator.pop(context, (body.trim(), image));
                      }
                    },
                    child: Text(strings(context).groupShare)),
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
          leading: _personAvatar(context, p),
          title: Row(children: [
            Flexible(
                child: Text(
              snapshot.hasError
                  ? strings(context).groupProfileUnavailable
                  : _profileName(context, p),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
            if (member['role'] == 'owner' || member['role'] == 'moderator') ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                    member['role'] == 'owner'
                        ? strings(context).groupOwner
                        : strings(context).groupModerator,
                    style: Theme.of(context).textTheme.labelSmall),
              ),
            ],
          ]),
          subtitle: _profileUsername(p).isEmpty
              ? null
              : AccountHandle(
                  (p?['username'] as String?) ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.65)),
                ),
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
                          PopupMenuItem(
                              value: 'approve',
                              child:
                                  Text(strings(context).groupApproveRequest)),
                        if (allowModeration &&
                            owner &&
                            member['status'] == 'active')
                          PopupMenuItem(
                              value: member['role'] == 'moderator'
                                  ? 'demote'
                                  : 'promote',
                              child: Text(member['role'] == 'moderator'
                                  ? strings(context).groupRemoveModerator
                                  : strings(context).groupMakeModerator)),
                        if (allowModeration)
                          PopupMenuItem(
                              value: 'remove',
                              child: Text(strings(context).groupRemove)),
                        if (allowModeration)
                          PopupMenuItem(
                              value: 'ban',
                              child: Text(strings(context).groupBan)),
                        if (onReport != null)
                          PopupMenuItem(
                              value: 'report',
                              child: Text(strings(context).groupReportMember)),
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
                  leading: _personAvatar(context, snapshot.data),
                  title: Text(snapshot.hasError
                      ? strings(context).groupProfileUnavailable
                      : _profileName(context, snapshot.data)),
                  subtitle: _profileUsername(snapshot.data).isEmpty
                      ? null
                      : AccountHandle(
                          (snapshot.data?['username'] as String?) ?? ''),
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
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content:
                                    Text(_localizedGroupError(context, e))));
                          }
                        }
                      },
                      itemBuilder: (_) => [
                            if (widget.moderator ||
                                widget.post['author_id'] ==
                                    widget.repository.userId)
                              PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                      strings(context).communityDeletePost)),
                            if (widget.post['author_id'] !=
                                widget.repository.userId)
                              PopupMenuItem(
                                  value: 'report',
                                  child: Text(
                                      strings(context).communityReportPost)),
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
                      child: Text(strings(context).groupImageRetry));
                }
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final image = storageImage(snapshot.data);
                if (image == null) {
                  return Text(strings(context).groupImageUnavailable);
                }
                return PostImage(image: image, onRetry: () => setState(() {}));
              }),
        FutureBuilder(
            future: likes,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return TextButton(
                    onPressed: () => setState(load),
                    child: Text(strings(context).groupLikesRetry));
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
                                    SnackBar(
                                        content: Text(
                                            _localizedGroupError(context, e))));
                              }
                            } finally {
                              if (mounted) setState(() => busy = false);
                            }
                          },
                    icon: Icon(liked ? Icons.favorite : Icons.favorite_border,
                        semanticLabel: liked
                            ? strings(context).communityUnlikePost
                            : strings(context).communityLikePost),
                    label: Text(strings(context)
                        .communityLikeCount(snapshot.data!.length))),
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
                    child: Text(strings(context).communityComments)),
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
        appBar: AppBar(title: Text(strings(context).communityComments)),
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
                      return Center(
                          child: Text(strings(context).groupNoComments));
                    }
                    return ListView(children: [
                      for (final comment in snapshot.data!)
                        ListTile(
                          title: Text(comment['body'] as String),
                          subtitle: FutureBuilder(
                              future: widget.repository
                                  .profile(comment['author_id'] as String),
                              builder: (context, profile) => Text(
                                  profile.hasError
                                      ? strings(context).groupProfileUnavailable
                                      : profile.data?['username'] as String? ??
                                          strings(context).groupsMember)),
                        ),
                    ]);
                  })),
          Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(
                    child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                            labelText: strings(context).groupComment))),
                IconButton(
                    tooltip: strings(context).groupSendComment,
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
                                    SnackBar(
                                        content: Text(
                                            _localizedGroupError(context, e))));
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
