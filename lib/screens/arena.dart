import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/arena_models.dart';
import '../models/community_models.dart';
import '../services/arena_repository.dart';
import '../services/progression_repository.dart';
import '../state.dart';
import '../ui.dart';
import 'progression.dart';

class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key, this.repository, this.progressionRepository});
  final ArenaDataSource? repository;
  final ProgressionDataSource? progressionRepository;

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  late final ProgressionDataSource _progression =
      widget.progressionRepository ?? ProgressionRepository();
  late final ArenaDataSource _repository =
      widget.repository ?? ArenaRepository();
  SupabaseClient? _realtimeClient;
  RealtimeChannel? _channel;
  Timer? _refreshTimer;
  String _section = 'challenges';
  String _challengeScope = 'open';
  String _leaderboardScope = 'global';
  String _leaderboardPeriod = 'weekly';
  String _leaderboardMetric = 'streak';
  bool _challengesLoading = true;
  bool _invitationsLoading = true;
  bool _leaderboardLoading = true;
  bool _creating = false;
  String? _challengeError;
  String? _invitationError;
  String? _leaderboardError;
  List<ArenaChallenge> _challenges = [];
  List<ArenaInvitation> _invitations = [];
  List<ArenaLeaderboardEntry> _leaderboard = [];
  final Set<String> _busyIds = {};
  final Set<String> _expanded = {};
  final Map<String, Future<List<ArenaStanding>>> _standings = {};

  @override
  void initState() {
    super.initState();
    unawaited(_loadChallenges());
    unawaited(_loadInvitations());
    unawaited(_loadLeaderboard());
    _subscribe();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    if (_channel != null && _realtimeClient != null) {
      unawaited(_realtimeClient!.removeChannel(_channel!));
    }
    super.dispose();
  }

  void _subscribe() {
    if (widget.repository != null) return;
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;
      _realtimeClient = client;
      _channel = client
          .channel('arena-$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'challenges',
            callback: (_) => _scheduleRefresh(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'challenge_participants',
            callback: (_) => _scheduleRefresh(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'challenge_invitations',
            callback: (_) => _scheduleRefresh(),
          )..subscribe((status, error) {
          if (error != null) debugPrint('Arena realtime error: $error');
        });
    } on AuthException catch (error) {
      debugPrint('Arena realtime unavailable: ${error.message}');
    }
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      unawaited(_refreshAll());
    });
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadChallenges(),
      _loadInvitations(),
      _loadLeaderboard(),
    ]);
  }

  Future<void> _loadChallenges() async {
    if (!mounted) return;
    setState(() {
      _challengesLoading = true;
      _challengeError = null;
    });
    try {
      final rows = await _repository.challenges(_challengeScope);
      if (!mounted) return;
      setState(() {
        _challenges = rows;
        _challengesLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _challengeError = error.toString();
        _challengesLoading = false;
      });
    }
  }

  Future<void> _loadInvitations() async {
    if (!mounted) return;
    setState(() {
      _invitationsLoading = true;
      _invitationError = null;
    });
    try {
      final rows = await _repository.invitations();
      if (!mounted) return;
      setState(() {
        _invitations = rows;
        _invitationsLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _invitationError = error.toString();
        _invitationsLoading = false;
      });
    }
  }

  Future<void> _loadLeaderboard() async {
    if (!mounted) return;
    setState(() {
      _leaderboardLoading = true;
      _leaderboardError = null;
    });
    try {
      final rows = await _repository.leaderboard(
        scope: _leaderboardScope,
        period: _leaderboardPeriod,
        metric: _leaderboardMetric,
      );
      if (!mounted) return;
      setState(() {
        _leaderboard = rows;
        _leaderboardLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _leaderboardError = error.toString();
        _leaderboardLoading = false;
      });
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _createPublicChallenge() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String type = 'streak';
    int duration = 7;
    final form = await showDialog<(String, String, String, int)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create a public challenge'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: titleController,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Challenge name'),
              ),
              TextField(
                controller: descriptionController,
                maxLength: 500,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Description (optional)'),
              ),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Challenge type'),
                items: const [
                  DropdownMenuItem(value: 'streak', child: Text('Active days')),
                  DropdownMenuItem(
                      value: 'workout_count', child: Text('Workout count')),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => type = value);
                },
              ),
              DropdownButtonFormField<int>(
                initialValue: duration,
                decoration: const InputDecoration(labelText: 'Duration'),
                items: const [
                  DropdownMenuItem(value: 7, child: Text('7 days')),
                  DropdownMenuItem(value: 14, child: Text('14 days')),
                  DropdownMenuItem(value: 30, child: Text('30 days')),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => duration = value);
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Scores use self-reported activity logs and are unverified. No prizes are awarded.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                (
                  titleController.text.trim(),
                  descriptionController.text.trim(),
                  type,
                  duration
                ),
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
    descriptionController.dispose();
    if (form == null) return;
    if (form.$1.length < 3) {
      _message('Challenge name must be at least 3 characters.');
      return;
    }

    setState(() => _creating = true);
    try {
      final start = _today();
      await _repository.createPublicChallenge(
        title: form.$1,
        description: form.$2,
        type: form.$3,
        startDate: start,
        endDate: start.add(Duration(days: form.$4 - 1)),
      );
      _message('Public challenge created.');
      await _loadChallenges();
    } catch (error) {
      _message(error.toString());
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _createFriendChallenge() async {
    setState(() => _creating = true);
    try {
      final friends = await _repository.friends();
      if (!mounted) return;
      if (friends.isEmpty) {
        _message('Add a friend before creating a 1v1 challenge.');
        return;
      }
      final details = await showDialog<(String, String, String)>(
        context: context,
        builder: (context) => _FriendChallengeDialog(friends: friends),
      );
      if (details == null) return;
      final start = _today();
      await _repository.createFriendChallenge(
        friendId: details.$1,
        title: details.$2,
        type: details.$3,
        startDate: start,
        endDate: start.add(const Duration(days: 6)),
      );
      _message('Friend challenge invitation sent.');
      await _loadInvitations();
      setState(() => _challengeScope = 'mine');
      await _loadChallenges();
    } catch (error) {
      _message(error.toString());
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _join(ArenaChallenge challenge) async {
    if (!_busyIds.add(challenge.id)) return;
    setState(() {});
    try {
      await _repository.joinChallenge(challenge.id);
      _message('You joined the challenge.');
      await _loadChallenges();
    } catch (error) {
      _message(error.toString());
    } finally {
      _busyIds.remove(challenge.id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _respond(ArenaInvitation invitation, String action) async {
    if (!_busyIds.add(invitation.id)) return;
    setState(() {});
    try {
      await _repository.respondToInvitation(invitation.id, action);
      _message(action == 'accept'
          ? 'Challenge accepted.'
          : 'Challenge invitation declined.');
      await Future.wait([_loadInvitations(), _loadChallenges()]);
    } catch (error) {
      _message(error.toString());
    } finally {
      _busyIds.remove(invitation.id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _toggleStandings(ArenaChallenge challenge) async {
    setState(() {
      if (!_expanded.add(challenge.id)) {
        _expanded.remove(challenge.id);
      } else {
        _standings[challenge.id] = _repository.standings(challenge.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _activityStreak(),
          LevelProgressPanel(repository: _progression),
          Wrap(spacing: 8, children: [
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/rewards'),
              icon: const Icon(Icons.card_giftcard),
              label: const Text('Rewards Store'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/badges'),
              icon: const Icon(Icons.workspace_premium),
              label: const Text('Badges & Achievements'),
            ),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: sectionTitle('Arena')),
            if (_section == 'challenges')
              PopupMenuButton<String>(
                tooltip: 'Create challenge',
                onSelected: (value) {
                  if (value == 'public') unawaited(_createPublicChallenge());
                  if (value == 'friend') unawaited(_createFriendChallenge());
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: 'public', child: Text('Public challenge')),
                  PopupMenuItem(
                      value: 'friend', child: Text('Challenge a friend')),
                ],
                child: _creating
                    ? const SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.add_circle_outline, color: kGold, size: 28),
              ),
          ]),
          _sectionSelector(),
          const SizedBox(height: 8),
          if (_section == 'challenges') ...[
            _invitationsSection(),
            _challengeScopeSelector(),
            _challengesSection(),
          ] else
            _leaderboardSection(),
          const SizedBox(height: 12),
          Text(
            'Scores use self-reported activity logs and are unverified. There are no cash or real-world prizes.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: kMuted),
          ),
        ],
      );

  Widget _activityStreak() {
    final state = appState;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      sectionTitle('Your activity streak'),
      Panel(
        child: Column(children: [
          if (state.activityError != null) ...[
            Text(state.activityError!, textAlign: TextAlign.center),
            TextButton.icon(
              onPressed: state.loadActivity,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            const SizedBox(height: 8),
          ],
          if (state.activityLoading && state.activityError == null)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(),
            ),
          Row(children: [
            Icon(Icons.local_fire_department, color: kGold, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your streak: ${state.streak} ${_dayUnit(state.streak)}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(
                      'Longest streak: ${state.longestStreak} ${_dayUnit(state.longestStreak)}',
                      style: TextStyle(fontSize: 12, color: kMuted)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 8),
          FreezeTokenCount(repository: _progression),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.stars, color: kGold, size: 22),
            const SizedBox(width: 8),
            StorePointsCount(repository: _progression),
          ]),
          const SizedBox(height: 10),
          Text(
            'Log a meal or completed workout to update your streak and earn 10 XP plus 10 store points once per active day.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: kMuted),
          ),
        ]),
      ),
    ]);
  }

  Widget _sectionSelector() => SegmentedButton<String>(
        segments: const [
          ButtonSegment(
              value: 'challenges',
              label: Text('Challenges'),
              icon: Icon(Icons.sports_martial_arts)),
          ButtonSegment(
              value: 'leaderboard',
              label: Text('Leaderboard'),
              icon: Icon(Icons.leaderboard_outlined)),
        ],
        selected: {_section},
        onSelectionChanged: (selection) =>
            setState(() => _section = selection.first),
      );

  Widget _challengeScopeSelector() => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'open', label: Text('Discover')),
            ButtonSegment(value: 'mine', label: Text('My challenges')),
            ButtonSegment(value: 'finished', label: Text('Finished')),
          ],
          selected: {_challengeScope},
          onSelectionChanged: (selection) {
            setState(() => _challengeScope = selection.first);
            unawaited(_loadChallenges());
          },
        ),
      );

  Widget _invitationsSection() {
    if (_invitationsLoading && _invitations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(18),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_invitationError != null && _invitations.isEmpty) {
      return _errorPanel(_invitationError!, _loadInvitations);
    }
    if (_invitations.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      sectionTitle('Friend invitations'),
      for (final invite in _invitations)
        Panel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(invite.title,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              '${invite.inviterFullName ?? invite.inviterUsername} invited you to a ${_metricLabel(invite.type)} 1v1.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
                '${_dateLabel(invite.startDate)} – ${_dateLabel(invite.endDate)}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busyIds.contains(invite.id)
                      ? null
                      : () => _respond(invite, 'decline'),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _busyIds.contains(invite.id)
                      ? null
                      : () => _respond(invite, 'accept'),
                  child: const Text('Accept'),
                ),
              ),
            ]),
          ]),
        ),
    ]);
  }

  Widget _challengesSection() {
    if (_challengesLoading) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_challengeError != null && _challenges.isEmpty) {
      return _errorPanel(_challengeError!, _loadChallenges);
    }
    if (_challenges.isEmpty) {
      return Panel(
        child: Column(children: [
          const Icon(Icons.emoji_events_outlined, size: 34),
          const SizedBox(height: 8),
          Text(_challengeScope == 'open'
              ? 'No open challenges yet. Create one to get started.'
              : 'No challenges to show here yet.'),
        ]),
      );
    }
    return Column(children: [
      for (final challenge in _challenges) _challengeCard(challenge),
    ]);
  }

  Widget _challengeCard(ArenaChallenge challenge) {
    final title = challenge.creatorFullName?.isNotEmpty == true
        ? challenge.creatorFullName!
        : challenge.creatorUsername;
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Column(children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _toggleStandings(challenge),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(
                  challenge.type == 'streak'
                      ? Icons.local_fire_department
                      : Icons.fitness_center,
                  color: kGold,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(challenge.title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                if (challenge.isOneVOne)
                  const Chip(
                      visualDensity: VisualDensity.compact, label: Text('1v1')),
                Icon(Icons.expand_more,
                    color: _expanded.contains(challenge.id) ? kGold : kMuted),
              ]),
              if (challenge.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(challenge.description),
              ],
              const SizedBox(height: 5),
              Text(
                '${_metricLabel(challenge.type)} · ${_dateLabel(challenge.startDate)} – ${_dateLabel(challenge.endDate)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 5),
              Wrap(spacing: 16, runSpacing: 4, children: [
                Text('${challenge.participantCount} participants',
                    style: Theme.of(context).textTheme.bodySmall),
                if (challenge.joined)
                  Text(
                    'Your score: ${_score(challenge.myScore)} ${_unit(challenge.type, challenge.myScore)}${challenge.myRank == null ? '' : ' · #${challenge.myRank}'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  Text('Created by $title',
                      style: Theme.of(context).textTheme.bodySmall),
              ]),
              if (_challengeScope == 'open' && !challenge.joined) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busyIds.contains(challenge.id)
                        ? null
                        : () => _join(challenge),
                    child: Text(_busyIds.contains(challenge.id)
                        ? 'Joining...'
                        : 'Join challenge'),
                  ),
                ),
              ],
            ]),
          ),
        ),
        if (_expanded.contains(challenge.id)) _standingsPanel(challenge),
      ]),
    );
  }

  Widget _standingsPanel(ArenaChallenge challenge) {
    final future = _standings[challenge.id];
    if (future == null) return const SizedBox.shrink();
    return FutureBuilder<List<ArenaStanding>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(14),
            child: Text(snapshot.error.toString()),
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(18),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(14),
            child: Text('No standings yet.'),
          );
        }
        return Column(children: [
          const Divider(height: 1),
          for (final row in snapshot.data!)
            ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: row.isMe ? kGold : kCard2,
                child: Text('${row.rank ?? '-'}'),
              ),
              title: Text(row.fullName?.isNotEmpty == true
                  ? row.fullName!
                  : '@${row.username}'),
              trailing: Text(
                  '${_score(row.score)} ${_unit(challenge.type, row.score)}'),
            ),
        ]);
      },
    );
  }

  Widget _leaderboardSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 4, children: [
        _filterChip(
          label: const {
            'global': 'Global',
            'friends': 'Friends',
            'level': 'My level',
          }[_leaderboardScope]!,
          options: const {
            'Global': 'global',
            'Friends': 'friends',
            'My level': 'level',
          },
          onSelected: (value) {
            setState(() => _leaderboardScope = value);
            unawaited(_loadLeaderboard());
          },
        ),
        _filterChip(
          label: const {
            'weekly': 'This week',
            'monthly': 'This month',
            'all_time': 'All time',
          }[_leaderboardPeriod]!,
          options: const {
            'This week': 'weekly',
            'This month': 'monthly',
            'All time': 'all_time',
          },
          onSelected: (value) {
            setState(() => _leaderboardPeriod = value);
            unawaited(_loadLeaderboard());
          },
        ),
        _filterChip(
          label: _leaderboardMetric == 'streak' ? 'Active days' : 'Workouts',
          options: const {'Active days': 'streak', 'Workouts': 'workout_count'},
          onSelected: (value) {
            setState(() => _leaderboardMetric = value);
            unawaited(_loadLeaderboard());
          },
        ),
      ]),
      const SizedBox(height: 8),
      if (_leaderboardLoading)
        const Padding(
          padding: EdgeInsets.all(28),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_leaderboardError != null && _leaderboard.isEmpty)
        _errorPanel(_leaderboardError!, _loadLeaderboard)
      else if (_leaderboard.isEmpty)
        const Panel(child: Text('No activity has been ranked for this filter.'))
      else
        Card(
          child: Column(children: [
            for (final row in _leaderboard)
              ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: row.isMe ? kGold : kCard2,
                  child: Text('${row.place}'),
                ),
                title: Text(row.fullName?.isNotEmpty == true
                    ? row.fullName!
                    : '@${row.username}'),
                subtitle: Text([
                  if (row.levelName != null) row.levelName!,
                  'Current streak: ${row.currentStreak}',
                ].join(' · ')),
                trailing: Text(
                  '${row.score} ${_unit(_leaderboardMetric, row.score)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ]),
        ),
    ]);
  }

  Widget _filterChip({
    required String label,
    required Map<String, String> options,
    required ValueChanged<String> onSelected,
  }) =>
      PopupMenuButton<String>(
        onSelected: onSelected,
        itemBuilder: (_) => [
          for (final entry in options.entries)
            PopupMenuItem(value: entry.value, child: Text(entry.key)),
        ],
        child: Chip(
          avatar: const Icon(Icons.tune, size: 16),
          label: Text(label),
        ),
      );

  Widget _errorPanel(String message, Future<void> Function() retry) => Panel(
        child: Column(children: [
          Text(message, textAlign: TextAlign.center),
          TextButton.icon(
            onPressed: () => unawaited(retry()),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ]),
      );

  String _metricLabel(String type) =>
      type == 'workout_count' ? 'Completed workouts' : 'Active days';

  String _unit(String type, num? score) =>
      type == 'workout_count' ? 'workouts' : _dayUnit(score);

  String _dayUnit(num? score) => _score(score) == '1' ? 'day' : 'days';

  String _score(num? score) => (score ?? 0).toStringAsFixed(0);

  String _dateLabel(DateTime date) => '${date.month}/${date.day}/${date.year}';
}

class _FriendChallengeDialog extends StatefulWidget {
  const _FriendChallengeDialog({required this.friends});
  final List<CommunityPerson> friends;

  @override
  State<_FriendChallengeDialog> createState() => _FriendChallengeDialogState();
}

class _FriendChallengeDialogState extends State<_FriendChallengeDialog> {
  late String _friendId = widget.friends.first.id;
  String _type = 'streak';
  final _title = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Challenge a friend'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: _title,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Challenge name'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _friendId,
              decoration: const InputDecoration(labelText: 'Friend'),
              items: [
                for (final friend in widget.friends)
                  DropdownMenuItem(
                    value: friend.id,
                    child: Text(friend.fullName?.isNotEmpty == true
                        ? friend.fullName!
                        : '@${friend.username}'),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _friendId = value);
              },
            ),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Metric'),
              items: const [
                DropdownMenuItem(value: 'streak', child: Text('Active days')),
                DropdownMenuItem(
                    value: 'workout_count', child: Text('Workout count')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 8),
            Text('Seven days · Invitation expires automatically.',
                style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (_title.text.trim().length < 3) return;
              Navigator.pop(context, (_friendId, _title.text.trim(), _type));
            },
            child: const Text('Send invitation'),
          ),
        ],
      );
}
