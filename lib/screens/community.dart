import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n_strings.dart';
import '../progression_content.dart';
import '../models/community_models.dart';
import '../models/community_post.dart';
import '../services/community_repository.dart';
import '../services/storage_image.dart';
import '../services/progression_repository.dart';
import '../services/groups_repository.dart';
import '../ui.dart';
import '../widgets/post_image.dart';
import 'progression.dart';
import 'groups.dart';

String _communityError(BuildContext context, Object error) {
  if (error is! CommunityException) {
    return friendlyError(error, localizations: strings(context));
  }
  final l = strings(context);
  return switch (error.message) {
    'Please sign in again.' => l.communityErrorSignIn,
    'Could not connect. Check your internet connection.' =>
      l.communityErrorConnection,
    'The request timed out. Please try again.' => l.communityErrorTimeout,
    'Write something before sharing your post.' => l.communityErrorEmptyPost,
    'Posts must be 5000 characters or fewer.' => l.communityErrorPostLength,
    'Choose an image smaller than 8 MB.' => l.communityErrorImageSize,
    'Choose a JPG, PNG, or WebP image.' => l.communityErrorImageType,
    'You can only delete your own post.' => l.communityErrorDeleteOwn,
    'Comments must be 1–2000 characters.' => l.communityErrorCommentLength,
    _ => friendlyError(error, localizations: l),
  };
}

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
  Object? _feedError;
  Object? _peopleError;
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
          _showMessage(strings(context).communityPostGone);
        } else {
          await _showComments(post);
        }
      } else if (widget.openProfileId != null) {
        await _showPublicProfile(widget.openProfileId!);
      }
    } catch (error) {
      if (mounted) _showMessage(_communityError(context, error));
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
        _feedError = error;
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
      if (mounted) _showMessage(_communityError(context, error));
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
        _peopleError = error;
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
      if (mounted) _showMessage(strings(context).communityPostShared);
    } catch (error) {
      if (mounted) _showMessage(_communityError(context, error));
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
      if (mounted) _showMessage(_communityError(context, error));
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
          _showMessage(strings(context).communityRequestGone);
          return;
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
      if (!mounted) return;
      _showMessage(switch (action) {
        'accept' => strings(context).communityRequestAccepted,
        'decline' || 'cancel' => strings(context).communityRequestRemoved,
        'friend' => strings(context).communityRequestSent,
        'follow' => person.followedByMe
            ? strings(context).communityUnfollowed
            : strings(context).communityFollowing,
        'block' => strings(context).communityBlocked,
        _ => strings(context).communityUpdated,
      });
    } catch (error) {
      if (mounted) _showMessage(_communityError(context, error));
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
                    Text(strings(context).communityHeading,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(strings(context).communitySubtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ]),
            ),
            if (_tab == 0)
              IconButton.filledTonal(
                tooltip: strings(context).communityCreatePost,
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
            _tabButton(
                strings(context).communityFeed, Icons.dynamic_feed_outlined, 0),
            _tabButton(
                strings(context).communityPeople, Icons.people_outline, 1),
            _tabButton(
                strings(context).communityGroups, Icons.groups_outlined, 2),
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
      return _errorState(_communityError(context, _feedError!), _loadFeed);
    }
    if (_posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadFeed,
        child: ListView(children: [
          const SizedBox(height: 110),
          const Icon(Icons.forum_outlined, size: 42),
          const SizedBox(height: 14),
          Center(child: Text(strings(context).communityFeedEmpty)),
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
                      LeftToRightValue(
                          strings(context).communityPostTime(post.username,
                              _relativeTime(context, post.createdAt)),
                          style: Theme.of(context).textTheme.bodySmall),
                    ]),
              ),
            ),
            if (post.visibility == 'friends')
              const Padding(
                padding: EdgeInsetsDirectional.only(end: 4),
                child: Icon(Icons.people_alt_outlined, size: 17),
              ),
            PopupMenuButton<String>(
              onSelected: (action) async {
                if (action == 'delete') {
                  final confirmed = await _confirm(
                      strings(context).communityDeleteQuestion,
                      strings(context).communityCannotUndo);
                  if (!confirmed) return;
                  try {
                    await _repository.deletePost(post);
                    if (mounted) {
                      setState(() =>
                          _posts.removeWhere((item) => item.id == post.id));
                    }
                  } catch (error) {
                    if (mounted) _showMessage(_communityError(context, error));
                  }
                } else if (action == 'report') {
                  final reason = await _reportReason();
                  if (reason == null) return;
                  try {
                    await _repository.reportPost(post.id, reason);
                    if (mounted) {
                      _showMessage(strings(context).communityReportSubmitted);
                    }
                  } catch (error) {
                    if (mounted) _showMessage(_communityError(context, error));
                  }
                } else if (action == 'block') {
                  final confirmed = await _confirm(
                      strings(context).communityBlockQuestion(post.username),
                      strings(context).communityBlockDetails);
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
                  PopupMenuItem(
                      value: 'delete',
                      child: Text(strings(context).communityDeletePost)),
                if (!self)
                  PopupMenuItem(
                      value: 'report',
                      child: Text(strings(context).communityReportPost)),
                if (!self)
                  PopupMenuItem(
                      value: 'block',
                      child: Text(strings(context).communityBlockUser)),
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
                  final image = storageImage(snapshot.data);
                  if (image == null) {
                    return Text(strings(context).communityImageUnavailable);
                  }
                  return PostImage(
                    image: image,
                    onRetry: () => setState(() {
                      _imageUrls.remove(post.imagePath);
                    }),
                  );
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
              label: Semantics(
                label: post.likedByMe
                    ? strings(context).communityUnlikePost
                    : strings(context).communityLikePost,
                value: strings(context).communityLikeCount(post.likeCount),
                child: Text(strings(context).communityLikeCount(post.likeCount)),
              ),
            ),
            TextButton.icon(
              onPressed: () => _showComments(post),
              icon: const Icon(Icons.mode_comment_outlined, size: 19),
              label: Semantics(
                label: strings(context).communityOpenComments,
                value: strings(context).communityCommentCount(post.commentCount),
                child: Text(strings(context).communityCommentCount(post.commentCount)),
              ),
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
      return _errorState(_communityError(context, _peopleError!), _loadPeople);
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
              hintText: strings(context).communitySearchPeople,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: strings(context).communityClearSearch,
                      onPressed: () {
                        _searchController.clear();
                        _searchChanged('');
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          if (_peopleError != null)
            _inlineError(_communityError(context, _peopleError!), _loadPeople),
          if (_requests.isNotEmpty) ...[
            _sectionTitle(strings(context).communityFriendRequests),
            for (final request in _requests)
              _personCard(request, request: true),
          ],
          if (_friends.isNotEmpty) ...[
            _sectionTitle(strings(context).communityFriends),
            for (final friend in _friends) _personCard(friend, friend: true),
          ],
          _sectionTitle(_peopleQuery.isEmpty
              ? strings(context).communityDiscoverPeople
              : strings(context).communityResults),
          if (_peopleLoading && _searchResults.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (visiblePeople.isEmpty)
            Panel(
              child: Text(strings(context).communityNoPeople),
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
                    LeftToRightValue(strings(context).communityUsername(person.username),
                        style: Theme.of(context).textTheme.bodySmall),
                  ]),
            ),
          ),
          if (request && person.requestDirection == 'incoming') ...[
            IconButton(
              tooltip: strings(context).communityAcceptRequest,
              onPressed: () => _handlePersonAction(person, 'accept'),
              icon: Icon(Icons.check_circle, color: kGreen),
            ),
            IconButton(
              tooltip: strings(context).communityDeclineRequest,
              onPressed: () => _handlePersonAction(person, 'decline'),
              icon: const Icon(Icons.cancel_outlined),
            ),
          ] else if (request)
            TextButton(
              onPressed: () => _handlePersonAction(person, 'cancel'),
              child: Text(strings(context).plannerCancel),
            )
          else if (friend)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.people_alt_outlined),
            )
          else ...[
            IconButton(
              tooltip: person.followedByMe
                  ? strings(context).communityUnfollow
                  : strings(context).communityFollow,
              onPressed: () => _handlePersonAction(person, 'follow'),
              icon: Icon(
                person.followedByMe ? Icons.person_remove : Icons.person_add,
                color: kGold,
              ),
            ),
            if (person.relationship == 'none')
              IconButton(
                tooltip: strings(context).communitySendFriendRequest,
                onPressed: () => _handlePersonAction(person, 'friend'),
                icon: const Icon(Icons.group_add_outlined),
              )
            else if (person.relationship == 'request_outgoing')
              Tooltip(
                  message: strings(context).communityRequestPending,
                  child: const Icon(Icons.hourglass_top, size: 20)),
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
                label: Text(strings(context).coachTryAgain)),
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
              tooltip: strings(context).plannerRetry,
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
      foregroundImage: storageImage(url),
      child: Text(initial),
    );
  }

  Future<String?> _reportReason() async {
    final controller = TextEditingController();
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = DialogRoute<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings(context).communityReportPost),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          maxLength: 1000,
          decoration:
              InputDecoration(hintText: strings(context).communityReportHint),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings(context).plannerCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(strings(context).communitySubmit)),
        ],
      ),
    );
    final result = await navigator.push(route);
    await route.completed;
    controller.dispose();
    if (result != null && result.length < 3) {
      if (mounted) _showMessage(strings(context).communityReportValidation);
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
                child: Text(strings(context).plannerCancel)),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(strings(context).communityContinue)),
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
                  child: Text(strings(context).communityCreatePost,
                      style: Theme.of(context).textTheme.titleLarge)),
              IconButton(
                tooltip: strings(context).communityClose,
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
              decoration: InputDecoration(
                hintText: strings(context).communityPostHint,
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
                tooltip: strings(context).communityAddPhoto,
                onPressed: _selectImage,
                icon: const Icon(Icons.image_outlined),
              ),
              if (_image != null)
                IconButton(
                  tooltip: strings(context).communityRemovePhoto,
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
                items: [
                  DropdownMenuItem(
                      value: 'public',
                      child: Text(strings(context).communityPublic)),
                  DropdownMenuItem(
                      value: 'friends',
                      child: Text(strings(context).communityFriends)),
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
                label: Text(strings(context).communitySharePost),
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
  Object? _error;
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
        _error = error;
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
      if (mounted) _message(_communityError(context, error));
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
      if (mounted) _message(_communityError(context, error));
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
      if (mounted) _message(_communityError(context, error));
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
                    child: Text(strings(context).communityLikesError(
                        _communityError(context, snapshot.error!))));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.isEmpty) {
                return Center(child: Text(strings(context).communityNoLikes));
              }
              return ListView(
                children: [
                  ListTile(title: Text(strings(context).communityLikedBy)),
                  for (final person in snapshot.data!)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: kCard2,
                        foregroundImage: storageImage(person.avatarUrl),
                        child: Text(person.username.isEmpty
                            ? '?'
                            : person.username.characters.first.toUpperCase()),
                      ),
                      title: Text(person.fullName?.trim().isNotEmpty == true
                          ? person.fullName!
                          : person.username),
                      subtitle: LeftToRightValue(
                          strings(context).communityUsername(person.username)),
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
                    child: Text(strings(context).communityComments,
                        style: Theme.of(context).textTheme.titleLarge)),
                IconButton(
                    tooltip: strings(context).communityClose,
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
                            return Text(
                                strings(context).communityImageUnavailable);
                          }
                          if (!snapshot.hasData) {
                            return const LinearProgressIndicator();
                          }
                          final image = storageImage(snapshot.data);
                          if (image == null) {
                            return Text(
                                strings(context).communityImageUnavailable);
                          }
                          return PostImage(image: image, maxHeight: 100);
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
                    : Text(strings(context).communityOlderComments),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _comments.isEmpty
                      ? Center(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(_communityError(context, _error!),
                              textAlign: TextAlign.center),
                          TextButton(
                              onPressed: _load,
                              child: Text(strings(context).coachTryAgain)),
                        ]))
                      : _comments.isEmpty
                          ? Center(
                              child:
                                  Text(strings(context).communityFirstComment))
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
                                                foregroundImage: storageImage(
                                                    comment
                                                        .postAuthorAvatarUrl),
                                                child: storageImage(comment
                                                            .postAuthorAvatarUrl) ==
                                                        null
                                                    ? const Icon(Icons.person,
                                                        size: 10)
                                                    : null,
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(strings(context)
                                                    .communityLikedByAuthor),
                                              ),
                                            ]),
                                    ],
                                  ),
                                  trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: comment.likedByMe
                                              ? strings(context)
                                                  .communityUnlikeComment
                                              : strings(context)
                                                  .communityLikeComment,
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
                                            child: Text(strings(context)
                                                .communityLikeCount(comment.likeCount)),
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
                    decoration: InputDecoration(
                      hintText: strings(context).communityCommentHint,
                      counterText: '',
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: strings(context).communitySendComment,
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
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_communityError(context, error))));
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
                  Text(_communityError(context, snapshot.error!)),
                  TextButton(
                      onPressed: _refresh,
                      child: Text(strings(context).plannerRetry)),
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
                return SizedBox(
                    height: 140,
                    child: Center(
                        child: Text(
                            strings(context).communityProfileUnavailable)));
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
                  foregroundImage: storageImage(profile.avatarUrl),
                  child: Text(name.characters.first.toUpperCase(),
                      style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(height: 10),
                Text(name, style: Theme.of(context).textTheme.titleLarge),
                LeftToRightValue(strings(context).communityUsername(profile.username),
                    style: Theme.of(context).textTheme.bodySmall),
                if (profile.levelName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(
                      avatar: const Icon(Icons.workspace_premium, size: 18),
                      label:
                          Text(localizedLevelName(context, profile.levelName!)),
                    ),
                  ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 22,
                  runSpacing: 12,
                  children: [
                    _stat(strings(context).communityStreak,
                        strings(context).arenaDays(profile.currentStreak)),
                    _stat(strings(context).communityBest,
                        strings(context).arenaDays(profile.longestStreak)),
                    _stat(strings(context).communityPostCountLabel(profile.postCount),
                        profile.postCount.toString()),
                    _stat(strings(context).communityFriendCountLabel(profile.friendCount),
                        profile.friendCount.toString()),
                    _stat(strings(context).communityFollowerCountLabel(profile.followerCount),
                        profile.followerCount.toString()),
                  ],
                ),
                const SizedBox(height: 12),
                Text(strings(context).progressBadges,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                LiveProgress<List<BadgeProgress>>(
                  repository: _progression,
                  load: () => _progression.publicBadges(widget.userId),
                  builder: (_, badges) => badges.isEmpty
                      ? Text(strings(context).communityNoBadges)
                      : Wrap(
                          spacing: 6,
                          children: [
                            for (final badge in badges)
                              Chip(
                                  label: Text(localizedProgressionContent(
                                      badgeTranslations, badge.code,
                                      name: badge.name,
                                      description: badge.description,
                                      arabic: Localizations.localeOf(context).languageCode == 'ar').name),
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
                        label: Text(profile.followedByMe
                            ? strings(context).communityUnfollow
                            : strings(context).communityFollow),
                      ),
                    ),
                    if (profile.relationship == 'none') ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _do('friend', profile),
                          icon: const Icon(Icons.group_add_outlined),
                          label: Text(strings(context).communityAddFriend),
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

String _relativeTime(BuildContext context, DateTime time) {
  final difference = DateTime.now().difference(time.toLocal());
  final l = strings(context);
  if (difference.isNegative || difference.inMinutes < 1) {
    return l.communityTimeNow;
  }
  if (difference.inMinutes < 60) {
    return l.communityMinutesAgo(difference.inMinutes);
  }
  if (difference.inHours < 24) return l.communityHoursAgo(difference.inHours);
  if (difference.inDays < 7) return l.communityDaysAgo(difference.inDays);
  final format = DateFormat.yMMMd(Localizations.localeOf(context).languageCode)
    ..useNativeDigits = false;
  return format.format(time.toLocal());
}
