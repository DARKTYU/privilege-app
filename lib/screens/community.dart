import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/community_post.dart';
import '../services/community_repository.dart';
import '../ui.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late final CommunityRepository _repository;
  final _text = TextEditingController();
  final _scroll = ScrollController();
  List<CommunityPost> _posts = [];
  bool _loading = true, _loadingMore = false, _hasMore = true, _busy = false;
  String? _error;
  String _visibility = 'public';
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _repository = CommunityRepository(Supabase.instance.client);
    _refresh();
  }

  @override
  void dispose() {
    _generation++;
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _error = null;
    });
    try {
      final posts = await _repository.feed();
      if (!mounted || generation != _generation) return;
      setState(() {
        _posts = posts;
        _hasMore = posts.length == CommunityRepository.pageSize;
      });
    } on CommunityException catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _more() async {
    if (_loadingMore || !_hasMore || _posts.isEmpty) return;
    final generation = _generation;
    setState(() => _loadingMore = true);
    try {
      final posts = await _repository.feed(before: _posts.last);
      if (!mounted || generation != _generation) return;
      final known = _posts.map((post) => post.id).toSet();
      setState(() {
        _posts.addAll(posts.where((post) => known.add(post.id)));
        _hasMore = posts.length == CommunityRepository.pageSize;
      });
    } on CommunityException catch (error) {
      if (mounted && generation == _generation) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Future<void> _publish() async {
    final value = _text.text.trim();
    if (value.isEmpty || value.length > 5000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write a post of 1–5000 characters.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await _repository.post(value, _visibility);
      if (!mounted) return;
      _text.clear();
      await _refresh();
    } on CommunityException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _like(CommunityPost post) async {
    setState(() => _busy = true);
    try {
      await _repository.setLiked(post);
      await _refresh();
    } on CommunityException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
        controller: _scroll,
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _text,
            maxLength: 5000,
            maxLines: 3,
            decoration: fieldDecoration('Share something with the community'),
          ),
          Row(children: [
            DropdownButton<String>(
              value: _visibility,
              items: const [
                DropdownMenuItem(value: 'public', child: Text('Public')),
                DropdownMenuItem(value: 'friends', child: Text('Friends')),
              ],
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _visibility = value!),
            ),
            const Spacer(),
            TextButton(
                onPressed: _busy ? null : _publish, child: const Text('Post')),
          ]),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Column(children: [
              Text('Could not load the feed: $_error'),
              TextButton(onPressed: _refresh, child: const Text('Retry')),
            ])
          else if (_posts.isEmpty)
            const Center(child: Text('No posts yet.'))
          else ...[
            for (final post in _posts)
              Panel(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          post.fullName?.isNotEmpty == true
                              ? post.fullName!
                              : post.username,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('@${post.username} · ${post.visibility}',
                          style: TextStyle(color: kMuted)),
                      const SizedBox(height: 8),
                      Text(post.body),
                      Row(children: [
                        IconButton(
                          onPressed: _busy ? null : () => _like(post),
                          icon: Icon(post.likedByMe
                              ? Icons.favorite
                              : Icons.favorite_border),
                        ),
                        Text('${post.likeCount}'),
                        const SizedBox(width: 16),
                        Text('${post.commentCount} comments'),
                      ]),
                    ]),
              ),
            if (_hasMore)
              TextButton(
                onPressed: _loadingMore ? null : _more,
                child: Text(_loadingMore ? 'Loading…' : 'Load more'),
              ),
          ],
        ],
      );
}
