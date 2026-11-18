import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/community_models.dart';
import '../models/community_post.dart';
import '../services/community_repository.dart';
import '../services/progression_repository.dart';
import '../services/groups_repository.dart';
import '../ui.dart';
import 'progression.dart';
import 'groups.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen(
      {super.key, this.repository, this.openPostId, this.openProfileId});
  final CommunityRepository? repository;
  final String? openPostId;
  final String? openProfileId;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late final _client = _repository.client;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late final CommunityRepository _repository =
      widget.repository ?? CommunityRepository(Supabase.instance.client);
  RealtimeChannel? _channel;
  Timer? _searchDebounce;
  Timer? _refreshDebounce;
  int _tab = 0;
  bool _feedLoading = true;
  bool _feedMoreLoading = false;
  bool _feedHasMore = true;
  bool _peopleLoading = true;
  bool _posting = false;
  String? _feedError;
  String? _peopleError;
  String _peopleQuery = '';
  List<CommunityPost> _posts = [];
  List<CommunityPerson> _searchResults = [];
  List<CommunityPerson> _friends = [];
  List<CommunityPerson> _requests = [];
  final Set<String> _busyPostIds = {};
  final Map<String, Future<String>> _imageUrls = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_loadFeed());
    unawaited(_loadPeople());
    _subscribe();
    if (widget.openPostId != null || widget.openProfileId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openTarget());
    }
  }

  Future<void> _openTarget() async {
    if (!mounted) return;
    try {
      if (widget.openPostId != null) {
        final post = await _repository.postById(widget.openPostId!);
        if (!mounted) return;
        if (post == null) {
          _showMessage('This post is no longer available.');
        } else {
          await _showComments(post);
        }
      } else if (widget.openProfileId != null) {
        await _showPublicProfile(widget.openProfileId!);
      }
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _refreshDebounce?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    if (_channel != null) unawaited(_client.removeChannel(_channel!));
    super.dispose();
  }

  void _subscribe() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    _channel = _client
        .channel('community-screen-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'community_posts',
          callback: (_) => _scheduleRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'community_comments',
          callback: (_) => _scheduleRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'community_likes',
          callback: (_) => _scheduleRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'friendships',
          callback: (_) => _scheduleRefresh(people: true),
        )..subscribe((status, error) {
        if (error != null) debugPrint('Community realtime error: $error');
      });
  }

  void _scheduleRefresh({bool people = false}) {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      unawaited(_loadFeed());
      if (people) unawaited(_loadPeople());
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 300 ||
        _feedLoading ||
        _feedMoreLoading ||
        !_feedHasMore) {
      return;
    }
    unawaited(_loadMoreFeed());
  }

  Future<void> _loadFeed() async {
    if (!mounted) return;
    setState(() {
      _feedLoading = _posts.isEmpty;
      _feedError = null;
    });
    try {
      final posts = await _repository.feed();
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _feedHasMore = posts.length == CommunityRepository.pageSize;
        _feedLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _feedError = error.toString();
        _feedLoading = false;
      });
    }
  }

  Future<void> _loadMoreFeed() async {
    if (_posts.isEmpty) return;
    setState(() => _feedMoreLoading = true);
    try {
      final older = await _repository.feed(before: _posts.last);
      if (!mounted) return;
      setState(() {
        _posts.addAll(older);
        _feedHasMore = older.length == CommunityRepository.pageSize;
        _feedMoreLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _feedMoreLoading = false);
      _showMessage(error.toString());
    }
  }

  Future<void> _loadPeople({String? query}) async {
    if (!mounted) return;
    final search = query ?? _peopleQuery;
    setState(() {
      _peopleLoading = true;
      _peopleError = null;
    });
    try {
      final results = await Future.wait<List<CommunityPerson>>([
        _repository.searchUsers(search),
        _repository.friends(),
        _repository.friendRequests(),
      ]);
      if (!mounted) return;
      setState(() {
        _searchResults = results[0];
        _friends = results[1];
        _requests = results[2];
        _peopleLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _peopleError = error.toString();
        _peopleLoading = false;
      });
    }
  }

  void _searchChanged(String value) {
    _searchDebounce?.cancel();
    _peopleQuery = value.trim();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) unawaited(_loadPeople(query: _peopleQuery));
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _composePost() async {
    final result = await showModalBottomSheet<(String, String, XFile?)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCard,
      builder: (_) => const _PostComposerSheet(),
    );
    if (!mounted || result == null) return;
    setState(() => _posting = true);
    try {
      await _repository.post(result.$1, result.$2, image: result.$3);
      await _loadFeed();
      _showMessage('Your post was shared.');
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _toggleLike(CommunityPost post) async {
    if (!_busyPostIds.add(post.id)) return;
    final index = _posts.indexWhere((item) => item.id == post.id);
    if (index >= 0) {
      setState(() {
        _posts[index] = CommunityPost(
          id: post.id,
          authorId: post.authorId,
          username: post.username,
          fullName: post.fullName,
          avatarUrl: post.avatarUrl,
          body: post.body,
          visibility: post.visibility,
          imagePath: post.imagePath,
          createdAt: post.createdAt,
          friendGroup: post.friendGroup,
          likeCount: post.likeCount + (post.likedByMe ? -1 : 1),
          commentCount: post.commentCount,
          likedByMe: !post.likedByMe,
        );
      });
    }
    try {
      await _repository.setLiked(post);
    } catch (error) {
      _showMessage(error.toString());
      await _loadFeed();
    } finally {
      _busyPostIds.remove(post.id);
    }
  }

  Future<void> _showComments(CommunityPost post) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCard,
      builder: (_) => _CommentsSheet(
        repository: _repository,
        post: post,
        onChanged: () => unawaited(_loadFeed()),
      ),
    );
  }

  Future<void> _showPublicProfile(String userId) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCard,
      builder: (context) => _PublicProfileSheet(
        repository: _repository,
        userId: userId,
        onChanged: () {
          unawaited(_loadPeople());
          unawaited(_loadFeed());
        },
      ),
    );
  }

  Future<void> _handlePersonAction(
      CommunityPerson person, String action) async {
    try {
      if (action == 'accept' || action == 'decline' || action == 'cancel') {
        if (person.friendshipId == null) {
          throw const CommunityException(
              'This request is no longer available.');
        }
        await _repository.respondToFriendRequest(person.friendshipId!, action);
      } else if (action == 'friend') {
        await _repository.sendFriendRequest(person.id);
      } else if (action == 'follow') {
        await _repository.setFollowing(person.id, person.followedByMe);
      } else if (action == 'block') {
        await _repository.blockUser(person.id);
      }
      await _loadPeople();
      _showMessage(switch (action) {
        'accept' => 'Friend request accepted.',
        'decline' || 'cancel' => 'Friend request removed.',
        'friend' => 'Friend request sent.',
        'follow' => person.followedByMe ? 'Unfollowed.' : 'Following.',
        'block' => 'User blocked.',
        _ => 'Updated.',
      });
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your community',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text('Share progress and connect with others.',
                        style: Theme.of(context).textTheme.bodySmall),
                  ]),
            ),
            if (_tab == 0)
              IconButton.filledTonal(
                tooltip: 'Create a post',
                onPressed: _posting ? null : _composePost,
                icon: _posting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add),
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            _tabButton('Feed', Icons.dynamic_feed_outlined, 0),
            _tabButton('People', Icons.people_outline, 1),
            _tabButton('Groups', Icons.groups_outlined, 2),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: IndexedStack(
            index: _tab,
            children: [
              _buildFeed(),
              _buildPeople(),
              _tab == 2
                  ? GroupsTab(repository: GroupsRepository(_client))
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ]);

  Widget _tabButton(String title, IconData icon, int index) {
    final selected = _tab == index;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: selected ? kGold : kMuted,
            backgroundColor: selected ? kCard2 : Colors.transparent,
          ),
          onPressed: () => setState(() => _tab = index),
          icon: Icon(icon, size: 18),
          label: Text(title),
        ),
      ),
    );
  }

  Widget _buildFeed() {
    if (_feedLoading) return const Center(child: CircularProgressIndicator());
    if (_feedError != null && _posts.isEmpty) {
      return _errorState(_feedError!, _loadFeed);
    }
    if (_posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadFeed,
        child: ListView(children: const [
          SizedBox(height: 110),
          Icon(Icons.forum_outlined, size: 42),
          SizedBox(height: 14),
          Center(child: Text('No posts yet. Be the first to share!')),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadFeed,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 18),
        itemCount: _posts.length + (_feedMoreLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return const Padding(
              padding: EdgeInsets.all(18),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _postCard(_posts[index]);
        },
      ),
    );
  }

  Widget _postCard(CommunityPost post) {
    final self = _client.auth.currentUser?.id == post.authorId;
    final title = (post.fullName?.trim().isNotEmpty ?? false)
        ? post.fullName!.trim()
        : post.username;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _avatar(post.avatarUrl, title, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: self ? null : () => _showPublicProfile(post.authorId),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                          '@${post.username} · ${_relativeTime(post.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ]),
              ),
            ),
            if (post.visibility == 'friends')
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.people_alt_outlined, size: 17),
              ),
            PopupMenuButton<String>(
              onSelected: (action) async {
                if (action == 'delete') {
                  final confirmed = await _confirm(
                      'Delete this post?', 'This cannot be undone.');
                  if (!confirmed) return;
                  try {
                    await _repository.deletePost(post);
                    if (mounted) {
                      setState(() =>
                          _posts.removeWhere((item) => item.id == post.id));
                    }
                  } catch (error) {
                    _showMessage(error.toString());
                  }
                } else if (action == 'report') {
                  final reason = await _reportReason();
                  if (reason == null) return;
                  try {
                    await _repository.reportPost(post.id, reason);
                    _showMessage('Report submitted.');
                  } catch (error) {
                    _showMessage(error.toString());
                  }
                } else if (action == 'block') {
                  final confirmed = await _confirm('Block @${post.username}?',
                      'Their posts will no longer appear in your community.');
                  if (confirmed) {
                    await _handlePersonAction(
                        CommunityPerson(
                          id: post.authorId,
                          username: post.username,
                          fullName: post.fullName,
                          avatarUrl: post.avatarUrl,
                          relationship: 'none',
                          followedByMe: false,
                        ),
                        'block');
                  }
                }
              },
              itemBuilder: (_) => [
                if (self)
                  const PopupMenuItem(
                      value: 'delete', child: Text('Delete post')),
                if (!self)
                  const PopupMenuItem(
                      value: 'report', child: Text('Report post')),
                if (!self)
                  const PopupMenuItem(
                      value: 'block', child: Text('Block user')),
              ],
              icon: const Icon(Icons.more_horiz),
            ),
          ]),
          if (post.body.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(post.body),
          ],
          if (post.imagePath != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FutureBuilder<String>(
                future: _imageUrls.putIfAbsent(post.imagePath!,
                    () => _repository.signedImageUrl(post.imagePath!)),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Container(
                      height: 160,
                      color: kCard2,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 160,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return Image.network(snapshot.data!,
                      width: double.infinity,
                      height: 240,
                      fit: BoxFit.cover, errorBuilder: (_, __, ___) {
                    Future<void>.microtask(() {
                      if (mounted) {
                        setState(() => _imageUrls.remove(post.imagePath));
                      }
                    });
                    return Container(
                      height: 160,
                      color: kCard2,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined),
                    );
                  });
                },
              ),
            ),
          ],
          const Divider(height: 24),
          Row(children: [
            TextButton.icon(
              onPressed: _busyPostIds.contains(post.id)
                  ? null
                  : () => _toggleLike(post),
              icon: Icon(
                post.likedByMe ? Icons.favorite : Icons.favorite_border,
                color: post.likedByMe ? kRed : kMuted,
                size: 20,
              ),
              label: Text('${post.likeCount}'),
            ),
            TextButton.icon(
              onPressed: () => _showComments(post),
              icon: const Icon(Icons.mode_comment_outlined, size: 19),
              label: Text('${post.commentCount}'),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildPeople() {
    final visiblePeople = _peopleQuery.isEmpty
        ? _searchResults
            .where((person) =>
                person.relationship == 'none' &&
                person.id != _client.auth.currentUser?.id &&
                !_friends.any((friend) => friend.id == person.id) &&
                !_requests.any((request) => request.id == person.id))
            .toList()
        : _searchResults;
    if (_peopleLoading && _searchResults.isEmpty && _friends.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_peopleError != null &&
        _searchResults.isEmpty &&
        _friends.isEmpty &&
        _requests.isEmpty) {
      return _errorState(_peopleError!, _loadPeople);
    }
    return RefreshIndicator(
      onRefresh: _loadPeople,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 18),
        children: [
          TextField(
            controller: _searchController,
            onChanged: _searchChanged,
            decoration: InputDecoration(
              hintText: 'Search people',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        _searchChanged('');
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          if (_peopleError != null) _inlineError(_peopleError!, _loadPeople),
          if (_requests.isNotEmpty) ...[
            _sectionTitle('Friend requests'),
            for (final request in _requests)
              _personCard(request, request: true),
          ],
          if (_friends.isNotEmpty) ...[
            _sectionTitle('Friends'),
            for (final friend in _friends) _personCard(friend, friend: true),
          ],
          _sectionTitle(
              _peopleQuery.isEmpty ? 'People to discover' : 'Results'),
          if (_peopleLoading && _searchResults.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (visiblePeople.isEmpty)
            const Panel(
              child: Text('No people found. Try a different name or username.'),
            )
          else
            for (final person in visiblePeople) _personCard(person),
        ],
      ),
    );
  }

  Widget _personCard(CommunityPerson person,
      {bool request = false, bool friend = false}) {
    final name = (person.fullName?.trim().isNotEmpty ?? false)
        ? person.fullName!.trim()
        : person.username;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          InkWell(
            onTap: () => _showPublicProfile(person.id),
            child: _avatar(person.avatarUrl, name, size: 42),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () => _showPublicProfile(person.id),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('@${person.username}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ]),
            ),
          ),
          if (request && person.requestDirection == 'incoming') ...[
            IconButton(
              tooltip: 'Accept request',
              onPressed: () => _handlePersonAction(person, 'accept'),
              icon: Icon(Icons.check_circle, color: kGreen),
            ),
            IconButton(
              tooltip: 'Decline request',
              onPressed: () => _handlePersonAction(person, 'decline'),
              icon: const Icon(Icons.cancel_outlined),
            ),
          ] else if (request)
            TextButton(
              onPressed: () => _handlePersonAction(person, 'cancel'),
              child: const Text('Cancel'),
            )
          else if (friend)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.people_alt_outlined),
            )
          else ...[
            IconButton(
              tooltip: person.followedByMe ? 'Unfollow' : 'Follow',
              onPressed: () => _handlePersonAction(person, 'follow'),
              icon: Icon(
                person.followedByMe ? Icons.person_remove : Icons.person_add,
                color: kGold,
              ),
            ),
            if (person.relationship == 'none')
              IconButton(
                tooltip: 'Send friend request',
                onPressed: () => _handlePersonAction(person, 'friend'),
                icon: const Icon(Icons.group_add_outlined),
              )
            else if (person.relationship == 'request_outgoing')
              const Tooltip(
                  message: 'Request pending',
                  child: Icon(Icons.hourglass_top, size: 20)),
          ],
        ]),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 20, 2, 10),
        child: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      );

  Widget _errorState(String message, Future<void> Function() retry) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 38),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: () => unawaited(retry()),
                icon: const Icon(Icons.refresh),
                label: const Text('Try again')),
          ]),
        ),
      );

  Widget _inlineError(String message, Future<void> Function() retry) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Material(
          color: kCard2,
          borderRadius: BorderRadius.circular(10),
          child: ListTile(
            leading: const Icon(Icons.error_outline),
            title: Text(message),
            trailing: IconButton(
              tooltip: 'Retry',
              onPressed: () => unawaited(retry()),
              icon: const Icon(Icons.refresh),
            ),
          ),
        ),
      );

  Widget _avatar(String? url, String? name, {double size = 40}) {
    final initial = name?.trim().isNotEmpty == true
        ? name!.trim().characters.first.toUpperCase()
        : '?';
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: kCard2,
      foregroundImage: url == null || url.isEmpty ? null : NetworkImage(url),
      child: Text(initial),
    );
  }

  Future<String?> _reportReason() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report post'),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          maxLength: 1000,
          decoration: const InputDecoration(
              hintText: 'Tell us why this post should be reviewed.'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Submit')),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result.length < 3) {
      _showMessage('Please provide at least 3 characters.');
      return null;
    }
    return result;
  }

  Future<bool> _confirm(String title, String detail) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(detail),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue')),
          ],
        ),
      ) ??
      false;
}

class _PostComposerSheet extends StatefulWidget {
  const _PostComposerSheet();

  @override
  State<_PostComposerSheet> createState() => _PostComposerSheetState();
}

class _PostComposerSheetState extends State<_PostComposerSheet> {
  final _textController = TextEditingController();
  XFile? _image;
  Uint8List? _imageBytes;
  String _visibility = 'public';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    final selected = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (selected == null || !mounted) return;
    final bytes = await selected.readAsBytes();
    if (!mounted) return;
    setState(() {
      _image = selected;
      _imageBytes = bytes;
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
            18, 18, 18, MediaQuery.viewInsetsOf(context).bottom + 18),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(
                  child: Text('Create a post',
                      style: Theme.of(context).textTheme.titleLarge)),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              minLines: 3,
              maxLines: 7,
              maxLength: 5000,
              decoration: const InputDecoration(
                hintText: 'Share a fitness or nutrition update...',
                alignLabelWithHint: true,
              ),
            ),
            if (_imageBytes != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(_imageBytes!,
                      height: 190, width: double.infinity, fit: BoxFit.cover),
                ),
              ),
            Row(children: [
              IconButton(
                tooltip: 'Add photo',
                onPressed: _selectImage,
                icon: const Icon(Icons.image_outlined),
              ),
              if (_image != null)
                IconButton(
                  tooltip: 'Remove photo',
                  onPressed: () => setState(() {
                    _image = null;
                    _imageBytes = null;
                  }),
                  icon: const Icon(Icons.delete_outline),
                ),
              const Spacer(),
              DropdownButton<String>(
                value: _visibility,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'public', child: Text('Public')),
                  DropdownMenuItem(value: 'friends', child: Text('Friends')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _visibility = value);
                },
              ),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(
                    context, (_textController.text, _visibility, _image)),
                icon: const Icon(Icons.send),
                label: const Text('Share post'),
              ),
            ),
          ]),
        ),
      );
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({
    required this.repository,
    required this.post,
    required this.onChanged,
  });
  final CommunityRepository repository;
  final CommunityPost post;
  final VoidCallback onChanged;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final _realtime = widget.repository.client;
  RealtimeChannel? _channel;
  List<CommunityComment> _comments = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _sending = false;
  final Set<String> _liking = {};
  String? _error;
  late final Future<String>? _postImage = widget.post.imagePath == null
      ? null
      : widget.repository.signedImageUrl(widget.post.imagePath!);

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    if (_realtime.auth.currentUser == null) return;
    _channel = _realtime
        .channel('community-comments-${widget.post.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'community_comments',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'post_id',
              value: widget.post.id),
          callback: (_) => unawaited(_load()),
        )..subscribe((status, error) {
        if (error != null) {
          debugPrint('Community comments realtime error: $error');
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    if (_channel != null) unawaited(_realtime.removeChannel(_channel!));
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final result = await widget.repository.comments(widget.post.id);
      if (!mounted) return;
      setState(() {
        _comments = result;
        _hasMore = result.length == CommunityRepository.commentPageSize;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_comments.isEmpty || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final result = await widget.repository.comments(
        widget.post.id,
        before: _comments.last,
      );
      if (!mounted) return;
      setState(() {
        _comments.addAll(result);
        _hasMore = result.length == CommunityRepository.commentPageSize;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      _message(error.toString());
    }
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await widget.repository.comment(widget.post.id, _controller.text);
      if (!mounted) return;
      _controller.clear();
      await _load();
      widget.onChanged();
    } catch (error) {
      _message(error.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleCommentLike(CommunityComment comment) async {
    if (!_liking.add(comment.id)) return;
    setState(() {});
    try {
      await widget.repository.setCommentLiked(comment.id, !comment.likedByMe);
      if (mounted) {
        setState(() {
          _comments = [
            for (final item in _comments)
              if (item.id == comment.id)
                item.withLikedByMe(!comment.likedByMe,
                    isPostAuthor:
                        widget.repository.client.auth.currentUser?.id ==
                            widget.post.authorId)
              else
                item,
          ];
        });
      }
    } catch (error) {
      _message(error.toString());
    } finally {
      _liking.remove(comment.id);
      if (mounted) setState(() {});
    }
  }

  void _showLikers(CommunityComment comment) {
    final future = widget.repository.commentLikers(comment.id);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kCard,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: 320,
          child: FutureBuilder<List<CommunityPerson>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text('Could not load likes: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.isEmpty) {
                return const Center(child: Text('No visible likes.'));
              }
              return ListView(
                children: [
                  const ListTile(title: Text('Liked by')),
                  for (final person in snapshot.data!)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: kCard2,
                        foregroundImage: person.avatarUrl == null ||
                                person.avatarUrl!.isEmpty
                            ? null
                            : NetworkImage(person.avatarUrl!),
                        child: Text(person.username.isEmpty
                            ? '?'
                            : person.username.characters.first.toUpperCase()),
                      ),
                      title: Text(person.fullName?.trim().isNotEmpty == true
                          ? person.fullName!
                          : person.username),
                      subtitle: Text('@${person.username}'),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .82,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 8, 8),
              child: Row(children: [
                Expanded(
                    child: Text('Comments',
                        style: Theme.of(context).textTheme.titleLarge)),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ]),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 140),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.post.body),
                    if (_postImage != null)
                      FutureBuilder<String>(
                        future: _postImage,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Text('Post image is unavailable.');
                          }
                          if (!snapshot.hasData) {
                            return const LinearProgressIndicator();
                          }
                          return Image.network(snapshot.data!,
                              height: 100,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  const Text('Post image is unavailable.'));
                        },
                      ),
                  ],
                ),
              ),
            ),
            if (_comments.isNotEmpty && _hasMore)
              TextButton(
                onPressed: _loadingMore ? null : _loadMore,
                child: _loadingMore
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Load older comments'),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _comments.isEmpty
                      ? Center(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(_error!, textAlign: TextAlign.center),
                          TextButton(
                              onPressed: _load, child: const Text('Try again')),
                        ]))
                      : _comments.isEmpty
                          ? const Center(
                              child: Text('Be the first to comment.'))
                          : ListView.builder(
                              controller: _scrollController,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              itemCount: _comments.length,
                              itemBuilder: (context, index) {
                                final comment = _comments[index];
                                final name =
                                    comment.fullName?.isNotEmpty == true
                                        ? comment.fullName!
                                        : comment.username;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                      backgroundColor: kCard2,
                                      child: Text(
                                          name.characters.first.toUpperCase())),
                                  title: Text(name),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(comment.body),
                                      if (comment.likedByAuthor)
                                        Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircleAvatar(
                                                radius: 8,
                                                backgroundColor: kCard2,
                                                foregroundImage: comment
                                                                .postAuthorAvatarUrl ==
                                                            null ||
                                                        comment
                                                            .postAuthorAvatarUrl!
                                                            .isEmpty
                                                    ? null
                                                    : NetworkImage(comment
                                                        .postAuthorAvatarUrl!),
                                                child: comment.postAuthorAvatarUrl ==
                                                            null ||
                                                        comment
                                                            .postAuthorAvatarUrl!
                                                            .isEmpty
                                                    ? const Icon(Icons.person,
                                                        size: 10)
                                                    : null,
                                              ),
                                              const SizedBox(width: 4),
                                              const Text('Liked by author'),
                                            ]),
                                    ],
                                  ),
                                  trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: comment.likedByMe
                                              ? 'Unlike comment'
                                              : 'Like comment',
                                          onPressed: _liking
                                                  .contains(comment.id)
                                              ? null
                                              : () =>
                                                  _toggleCommentLike(comment),
                                          icon: Icon(
                                              comment.likedByMe
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: comment.likedByMe
                                                  ? kRed
                                                  : kMuted),
                                        ),
                                        if (comment.likeCount > 0)
                                          TextButton(
                                            onPressed: () =>
                                                _showLikers(comment),
                                            child: Text('${comment.likeCount}'),
                                          ),
                                      ]),
                                );
                              },
                            ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  12, 8, 12, MediaQuery.viewInsetsOf(context).bottom + 12),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLength: 2000,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      counterText: '',
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                ),
              ]),
            ),
          ]),
        ),
      );
}

class _PublicProfileSheet extends StatefulWidget {
  const _PublicProfileSheet({
    required this.repository,
    required this.userId,
    required this.onChanged,
  });
  final CommunityRepository repository;
  final String userId;
  final VoidCallback onChanged;

  @override
  State<_PublicProfileSheet> createState() => _PublicProfileSheetState();
}

class _PublicProfileSheetState extends State<_PublicProfileSheet> {
  late final _progression =
      ProgressionRepository(client: widget.repository.client);
  late Future<CommunityPublicProfile?> _profile =
      widget.repository.publicProfile(widget.userId);

  void _refresh() {
    setState(() => _profile = widget.repository.publicProfile(widget.userId));
  }

  Future<void> _do(String action, CommunityPublicProfile profile) async {
    try {
      if (action == 'follow') {
        await widget.repository
            .setFollowing(profile.userId, profile.followedByMe);
      } else if (action == 'friend') {
        await widget.repository.sendFriendRequest(profile.userId);
      }
      _refresh();
      widget.onChanged();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FutureBuilder<CommunityPublicProfile?>(
            future: _profile,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(snapshot.error.toString()),
                  TextButton(onPressed: _refresh, child: const Text('Retry')),
                ]);
              }
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final profile = snapshot.data;
              if (profile == null) {
                return const SizedBox(
                    height: 140,
                    child: Center(child: Text('Profile is unavailable.')));
              }
              final name = profile.fullName?.isNotEmpty == true
                  ? profile.fullName!
                  : profile.username;
              final self = profile.relationship == 'self';
              return SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: kCard2,
                  foregroundImage: profile.avatarUrl == null
                      ? null
                      : NetworkImage(profile.avatarUrl!),
                  child: Text(name.characters.first.toUpperCase(),
                      style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(height: 10),
                Text(name, style: Theme.of(context).textTheme.titleLarge),
                Text('@${profile.username}',
                    style: Theme.of(context).textTheme.bodySmall),
                if (profile.levelName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(
                      avatar: const Icon(Icons.workspace_premium, size: 18),
                      label: Text(profile.levelName!),
                    ),
                  ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 22,
                  runSpacing: 12,
                  children: [
                    _stat('Streak', '${profile.currentStreak} days'),
                    _stat('Best', '${profile.longestStreak} days'),
                    _stat('Posts', '${profile.postCount}'),
                    _stat('Friends', '${profile.friendCount}'),
                    _stat('Followers', '${profile.followerCount}'),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Badges',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                LiveProgress<List<BadgeProgress>>(
                  repository: _progression,
                  load: () => _progression.publicBadges(widget.userId),
                  builder: (_, badges) => badges.isEmpty
                      ? const Text('No badges earned yet.')
                      : Wrap(
                          spacing: 6,
                          children: [
                            for (final badge in badges)
                              Chip(
                                  label: Text(badge.name),
                                  avatar: Icon(Icons.workspace_premium,
                                      size: 18, color: kGold))
                          ],
                        ),
                ),
                if (!self) ...[
                  const SizedBox(height: 18),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _do('follow', profile),
                        icon: Icon(profile.followedByMe
                            ? Icons.person_remove
                            : Icons.person_add),
                        label:
                            Text(profile.followedByMe ? 'Unfollow' : 'Follow'),
                      ),
                    ),
                    if (profile.relationship == 'none') ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _do('friend', profile),
                          icon: const Icon(Icons.group_add_outlined),
                          label: const Text('Add friend'),
                        ),
                      ),
                    ],
                  ]),
                ],
              ]));
            },
          ),
        ),
      );

  Widget _stat(String label, String value) => Column(children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ]);
}

String _relativeTime(DateTime time) {
  final difference = DateTime.now().difference(time.toLocal());
  if (difference.isNegative || difference.inMinutes < 1) return 'now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m';
  if (difference.inHours < 24) return '${difference.inHours}h';
  if (difference.inDays < 7) return '${difference.inDays}d';
  return '${time.toLocal().month}/${time.toLocal().day}/${time.toLocal().year}';
}
