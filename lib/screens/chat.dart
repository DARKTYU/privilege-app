import 'package:flutter/material.dart';

import '../ui.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<({bool bot, String text})> _messages = [
    (
      bot: true,
      text: 'AI chat, photo analysis and voice features are coming soon.'
    ),
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty) return;
    _input.clear();
    setState(() {
      _messages.add((bot: false, text: text));
      _messages.add((
        bot: true,
        text: 'AI chat is coming soon. Your message was not sent.',
      ));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Widget _bubble(({bool bot, String text}) message) {
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 290),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: message.bot ? kCard2 : kMaroon,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message.text),
    );
    return Align(
      alignment: message.bot ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: message.bot
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: kMaroon,
                  child: Icon(Icons.smart_toy_rounded, size: 16, color: kCream),
                ),
                const SizedBox(width: 8),
                Flexible(child: bubble),
              ])
            : bubble,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: kBg,
          surfaceTintColor: Colors.transparent,
          foregroundColor: kCream,
          titleSpacing: 0,
          title: Row(children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: kMaroon,
              child: Icon(Icons.smart_toy_rounded, size: 18, color: kCream),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Privilege Bot',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Row(children: [
                CircleAvatar(radius: 3, backgroundColor: kGold),
                const SizedBox(width: 4),
                Text('Coming soon',
                    style: TextStyle(fontSize: 10, color: kMuted)),
              ]),
            ]),
          ]),
        ),
        body: SafeArea(
          child: Column(children: [
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                children: [for (final message in _messages) _bubble(message)],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text('Quick:',
                          style: TextStyle(fontSize: 11, color: kMuted)),
                    ),
                  ),
                  for (final question in const [
                    'Merge my workouts',
                    'Plan my week',
                    'High-protein recipe',
                    'Calories left?',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(question,
                            style: const TextStyle(fontSize: 12)),
                        backgroundColor: kCard2,
                        side: BorderSide.none,
                        onPressed: () => _send(question),
                      ),
                    ),
                  for (final label in const ['Meal Scan', 'Squat Form Check'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: const Icon(Icons.photo_camera, size: 14),
                        label:
                            Text(label, style: const TextStyle(fontSize: 12)),
                        backgroundColor: kCard2,
                        side: BorderSide.none,
                        onPressed: () =>
                            toast(context, 'Photo analysis is coming soon.'),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.photo_camera_outlined),
                  tooltip: 'Photo analysis coming soon',
                  onPressed: () =>
                      toast(context, 'Photo analysis is coming soon.'),
                ),
                IconButton(
                  icon: const Icon(Icons.mic),
                  tooltip: 'Voice check-ins coming soon',
                  onPressed: () =>
                      toast(context, 'Voice check-ins are coming soon.'),
                ),
                Expanded(
                  child: TextField(
                    controller: _input,
                    onSubmitted: (_) => _send(),
                    decoration: fieldDecoration('AI chat coming soon'),
                  ),
                ),
                const SizedBox(width: 6),
                CircleAvatar(
                  backgroundColor: kMaroon,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, size: 20),
                    color: Theme.of(context).colorScheme.onPrimary,
                    onPressed: () => _send(),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      );
}
