import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n_strings.dart';
import '../logic/localized_dates.dart';
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
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = DialogRoute<(String, String, String, int)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(strings(context).arenaCreatePublic),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: titleController,
                maxLength: 80,
                decoration: InputDecoration(
                    labelText: strings(context).arenaChallengeName),
              ),
              TextField(
                controller: descriptionController,
                maxLength: 500,
                maxLines: 2,
                decoration: InputDecoration(
                    labelText: strings(context).arenaDescription),
              ),
              DropdownButtonFormField<String>(
                initialValue: type,
                isExpanded: true,
                decoration: InputDecoration(
                    labelText: strings(context).arenaChallengeType),
                items: [
                  DropdownMenuItem(
                      value: 'streak',
                      child: Text(strings(context).arenaActiveDays)),
                  DropdownMenuItem(
                      value: 'workout_count',
                      child: Text(strings(context).arenaWorkoutCount)),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => type = value);
                },
              ),
              DropdownButtonFormField<int>(
                initialValue: duration,
                isExpanded: true,
                decoration:
                    InputDecoration(labelText: strings(context).arenaDuration),
                items: [
                  for (final days in [7, 14, 30])
                    DropdownMenuItem(
                        value: days,
                        child: Text(strings(context).arenaDays(days))),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => duration = value);
                },
              ),
              const SizedBox(height: 8),
              Text(
                strings(context).arenaNoPrizesRule,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(strings(context).plannerCancel)),
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
              child: Text(strings(context).arenaCreate),
            ),
          ],
        ),
      ),
    );
    final form = await navigator.push(route);
    await route.completed;
    titleController.dispose();
    descriptionController.dispose();
    if (!mounted || form == null) return;
    if (form.$1.length < 3) {
      _message(strings(context).arenaInvalidName);
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
      if (mounted) _message(strings(context).arenaCreated);
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
        _message(strings(context).arenaNeedFriend);
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
      if (mounted) _message(strings(context).arenaInvitationSent);
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
      if (mounted) _message(strings(context).arenaJoined);
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
      if (mounted) {
        _message(action == 'accept'
            ? strings(context).arenaAccepted
            : strings(context).arenaDeclined);
      }
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
              label: Text(strings(context).arenaRewardsStore),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/badges'),
              icon: const Icon(Icons.workspace_premium),
              label: Text(strings(context).arenaBadgesAchievements),
            ),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: sectionTitle(strings(context).arenaSection)),
            if (_section == 'challenges')
              PopupMenuButton<String>(
                tooltip: strings(context).arenaCreateChallenge,
                onSelected: (value) {
                  if (value == 'public') unawaited(_createPublicChallenge());
                  if (value == 'friend') unawaited(_createFriendChallenge());
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                      value: 'public',
                      child: Text(strings(context).arenaPublicChallenge)),
                  PopupMenuItem(
                      value: 'friend',
                      child: Text(strings(context).arenaChallengeFriend)),
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
            strings(context).arenaNoCashRule,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: kMuted),
          ),
        ],
      );

  Widget _activityStreak() {
    final state = appState;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      sectionTitle(strings(context).arenaYourActivity),
      Panel(
        child: Column(children: [
          if (state.activityError != null) ...[
            Text(state.activityError!, textAlign: TextAlign.center),
            TextButton.icon(
              onPressed: state.loadActivity,
              icon: const Icon(Icons.refresh),
              label: Text(strings(context).plannerRetry),
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
                  Text(
                      strings(context).arenaYourStreak(
                          strings(context).arenaDays(state.streak)),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(
                      strings(context).arenaLongestStreak(
                          strings(context).arenaDays(state.longestStreak)),
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
            strings(context).arenaStreakHelp,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: kMuted),
          ),
        ]),
      ),
    ]);
  }

  Widget _sectionSelector() => SegmentedButton<String>(
        segments: [
          ButtonSegment(
              value: 'challenges',
              label: Text(strings(context).arenaChallenges),
              icon: const Icon(Icons.sports_martial_arts)),
          ButtonSegment(
              value: 'leaderboard',
              label: Text(strings(context).arenaLeaderboard),
              icon: const Icon(Icons.leaderboard_outlined)),
        ],
        selected: {_section},
        onSelectionChanged: (selection) =>
            setState(() => _section = selection.first),
      );

  Widget _challengeScopeSelector() => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SegmentedButton<String>(
          segments: [
            ButtonSegment(
                value: 'open', label: Text(strings(context).arenaDiscover)),
            ButtonSegment(
                value: 'mine', label: Text(strings(context).arenaMyChallenges)),
            ButtonSegment(
                value: 'finished', label: Text(strings(context).arenaFinished)),
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
      sectionTitle(strings(context).arenaFriendInvitations),
      for (final invite in _invitations)
        Panel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(invite.title,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              strings(context).arenaInvitation(
                  invite.inviterFullName ?? invite.inviterUsername,
                  _metricLabel(invite.type)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
                strings(context).arenaDateRange(
                    _dateLabel(invite.startDate), _dateLabel(invite.endDate)),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busyIds.contains(invite.id)
                      ? null
                      : () => _respond(invite, 'decline'),
                  child: Text(strings(context).arenaDecline),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _busyIds.contains(invite.id)
                      ? null
                      : () => _respond(invite, 'accept'),
                  child: Text(strings(context).arenaAccept),
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
              ? strings(context).arenaNoOpen
              : strings(context).arenaNoChallenges),
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
                  Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(strings(context).arenaOneVOne)),
                Icon(Icons.expand_more,
                    color: _expanded.contains(challenge.id) ? kGold : kMuted),
              ]),
              if (challenge.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(challenge.description),
              ],
              const SizedBox(height: 5),
              Text(
                strings(context).arenaChallengeSummary(
                    _metricLabel(challenge.type),
                    strings(context).arenaDateRange(
                        _dateLabel(challenge.startDate),
                        _dateLabel(challenge.endDate))),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 5),
              Wrap(spacing: 16, runSpacing: 4, children: [
                Text(
                    strings(context).arenaParticipants(
                        challenge.participantCount.toString()),
                    style: Theme.of(context).textTheme.bodySmall),
                if (challenge.joined)
                  Text(
                    challenge.myRank == null
                        ? strings(context).arenaScore(
                            _scoreLabel(challenge.type, challenge.myScore))
                        : strings(context).arenaScoreRank(
                            _scoreLabel(challenge.type, challenge.myScore),
                            challenge.myRank.toString()),
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  Text(strings(context).arenaCreatedBy(title),
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
                        ? strings(context).arenaJoining
                        : strings(context).arenaJoin),
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
          return Padding(
            padding: const EdgeInsets.all(14),
            child: Text(strings(context).arenaNoStandings),
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
                child: Text(row.rank?.toString() ?? '-'),
              ),
              title: Text(row.fullName?.isNotEmpty == true
                  ? row.fullName!
                  : '@${row.username}'),
              trailing: Text(_scoreLabel(challenge.type, row.score)),
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
          label: {
            'global': strings(context).arenaGlobal,
            'friends': strings(context).arenaFriends,
            'level': strings(context).arenaMyLevel,
          }[_leaderboardScope]!,
          options: {
            strings(context).arenaGlobal: 'global',
            strings(context).arenaFriends: 'friends',
            strings(context).arenaMyLevel: 'level',
          },
          onSelected: (value) {
            setState(() => _leaderboardScope = value);
            unawaited(_loadLeaderboard());
          },
        ),
        _filterChip(
          label: {
            'weekly': strings(context).arenaThisWeek,
            'monthly': strings(context).arenaThisMonth,
            'all_time': strings(context).arenaAllTime,
          }[_leaderboardPeriod]!,
          options: {
            strings(context).arenaThisWeek: 'weekly',
            strings(context).arenaThisMonth: 'monthly',
            strings(context).arenaAllTime: 'all_time',
          },
          onSelected: (value) {
            setState(() => _leaderboardPeriod = value);
            unawaited(_loadLeaderboard());
          },
        ),
        _filterChip(
          label: _leaderboardMetric == 'streak'
              ? strings(context).arenaActiveDays
              : strings(context).arenaWorkouts,
          options: {
            strings(context).arenaActiveDays: 'streak',
            strings(context).arenaWorkouts: 'workout_count'
          },
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
        Panel(child: Text(strings(context).arenaNoRanked))
      else
        Card(
          child: Column(children: [
            for (final row in _leaderboard)
              ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: row.isMe ? kGold : kCard2,
                  child: Text(row.place.toString()),
                ),
                title: Text(row.fullName?.isNotEmpty == true
                    ? row.fullName!
                    : '@${row.username}'),
                subtitle: Text(row.levelName == null
                    ? strings(context)
                        .arenaCurrentStreak(row.currentStreak.toString())
                    : strings(context).arenaLevelStreak(
                        localizedLevelName(context, row.levelName!),
                        strings(context)
                            .arenaCurrentStreak(row.currentStreak.toString()))),
                trailing: Text(
                  _scoreLabel(_leaderboardMetric, row.score),
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
            label: Text(strings(context).plannerRetry),
          ),
        ]),
      );

  String _metricLabel(String type) => type == 'workout_count'
      ? strings(context).arenaCompletedWorkouts
      : strings(context).arenaActiveDays;

  String _scoreLabel(String type, num? score) {
    final value = (score ?? 0).toStringAsFixed(0);
    return type == 'workout_count'
        ? strings(context).arenaWorkoutsCount(value)
        : strings(context).arenaDays(int.parse(value));
  }

  String _dateLabel(DateTime date) {
    return westernDigits(
        MaterialLocalizations.of(context).formatMediumDate(date));
  }
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
        title: Text(strings(context).arenaChallengeFriend),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: _title,
              maxLength: 80,
              decoration: InputDecoration(
                  labelText: strings(context).arenaChallengeName),
            ),
            DropdownButtonFormField<String>(
              initialValue: _friendId,
              isExpanded: true,
              decoration:
                  InputDecoration(labelText: strings(context).arenaFriend),
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
              isExpanded: true,
              decoration:
                  InputDecoration(labelText: strings(context).arenaMetric),
              items: [
                DropdownMenuItem(
                    value: 'streak',
                    child: Text(strings(context).arenaActiveDays)),
                DropdownMenuItem(
                    value: 'workout_count',
                    child: Text(strings(context).arenaWorkoutCount)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 8),
            Text(strings(context).arenaSevenDayInvite,
                style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings(context).plannerCancel)),
          FilledButton(
            onPressed: () {
              if (_title.text.trim().length < 3) return;
              Navigator.pop(context, (_friendId, _title.text.trim(), _type));
            },
            child: Text(strings(context).arenaSendInvitation),
          ),
        ],
      );
}
