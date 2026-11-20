import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/coach_safety.dart';
import '../services/coach_client.dart';
import '../state.dart';
import '../ui.dart';

Future<void> showCoachSheet(BuildContext context,
    {CoachClient? client,
    AppState? state,
    Future<void> Function()? refreshActivity}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => LayoutBuilder(builder: (context, constraints) {
      final keyboard = MediaQuery.viewInsetsOf(context).bottom;
      final height = (constraints.maxHeight - keyboard)
          .clamp(0.0, constraints.maxHeight * 0.92);
      return Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: SizedBox(
          height: height,
          child: ThemeAwareBuilder(
            builder: () => ChatScreen(
                client: client, state: state, refreshActivity: refreshActivity),
          ),
        ),
      );
    }),
  );
}

class _CoachAvatar extends StatelessWidget {
  const _CoachAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Privilege Coach',
        image: true,
        child: Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.15),
          decoration: BoxDecoration(
            color: kCard,
            shape: BoxShape.circle,
            border: Border.all(color: kMaroon),
          ),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            excludeFromSemantics: true,
          ),
        ),
      );
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.client, this.state, this.refreshActivity});
  final CoachClient? client;
  final AppState? state;
  final Future<void> Function()? refreshActivity;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _consentKey = 'coach_share_calorie_context';
  static const _noticeRows = <(IconData, String, String)>[
    (
      Icons.warning_amber_rounded,
      'The coach can make mistakes.',
      'المدرب قد يخطئ.'
    ),
    (
      Icons.medical_services_outlined,
      'Not medical advice. For health problems, ask a doctor.',
      'ليست نصيحة طبية. للمشاكل الصحية استشر طبيباً.'
    ),
    (
      Icons.cloud_outlined,
      'Messages are sent to Google Gemini to get a reply.',
      'تُرسل رسائلك إلى Google Gemini للحصول على رد.'
    ),
    (
      Icons.lock_outline,
      'Do not share personal or health details you do not want sent.',
      'لا تشارك تفاصيل شخصية أو صحية لا تريد إرسالها.'
    ),
    (
      Icons.memory,
      'The coach does not remember earlier messages.',
      'المدرب لا يتذكر الرسائل السابقة.'
    ),
  ];
  static const _fallback = 'Local help (not AI): ask about your calories, '
      'weekly plan or streak in the app.\n'
      'مساعدة محلية (ليست ذكاءً اصطناعياً): راجع السعرات والخطة الأسبوعية وسلسلة التقدم في التطبيق.';
  static const _suggestions = [
    'Training ideas',
    'High-protein recipe',
    'Calories left?',
    'Snack ideas',
  ];

  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<({bool bot, String text, String? retry})> _messages = [];
  late final CoachClient _client = widget.client ?? SupabaseCoachClient();
  late final AppState _state = widget.state ?? appState;
  bool _consent = false;
  bool _consentReady = false;
  bool _savingConsent = false;
  bool _sending = false;
  int? _remaining;
  int _chatGeneration = 0;
  String? _account;

  @override
  void initState() {
    super.initState();
    _account = _client.accountId;
    _state.addListener(_accountChanged);
    _input.addListener(_inputChanged);
    _restoreConsent();
  }

  void _inputChanged() {
    if (mounted) setState(() {});
  }

  void _accountChanged() {
    final current = _client.accountId;
    if (_account != current) {
      _account = current;
      _chatGeneration++;
      setState(() {
        _messages.clear();
        _remaining = null;
        _input.clear();
      });
    }
  }

  Future<void> _restoreConsent() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _consent = preferences.getBool(_consentKey) ?? false;
        _consentReady = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _consentReady = true);
      _showPreferenceError();
    }
  }

  Future<void> _setConsent(bool value) async {
    if (_savingConsent) return;
    setState(() => _savingConsent = true);
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!await preferences.setBool(_consentKey, value)) {
        throw StateError('Preference could not be saved');
      }
      if (mounted) setState(() => _consent = value);
    } catch (_) {
      if (mounted) _showPreferenceError();
    } finally {
      if (mounted) setState(() => _savingConsent = false);
    }
  }

  void _showPreferenceError() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text(
          'Could not save or load consent. Please try again.\nتعذر حفظ أو تحميل الموافقة. حاول مرة أخرى.'),
    ));
  }

  @override
  void dispose() {
    _state.removeListener(_accountChanged);
    _input.removeListener(_inputChanged);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  String _errorText(CoachException error) {
    switch (error.code) {
      case 'authentication_required':
      case 'registered_user_required':
        return 'Sign in with an account to use the coach.\nسجّل الدخول بحساب لاستخدام المدرب.';
      case 'birth_date_required':
        return 'Add your birth date in Profile to use the coach.\nأضف تاريخ ميلادك في الملف الشخصي لاستخدام المدرب.';
      case 'underage':
        return 'The AI coach is for users 18 and over.\nالمدرب الذكي للمستخدمين بعمر 18 سنة فأكثر.';
      case 'quota_exceeded':
        final reset = error.resetAt?.toLocal();
        final date = reset == null
            ? ''
            : ' ${MaterialLocalizations.of(context).formatFullDate(reset)} '
                '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(reset), alwaysUse24HourFormat: true)}';
        return 'Daily limit reached.${reset == null ? '' : ' Resets:$date'}\n'
            'تم الوصول إلى الحد اليومي.${reset == null ? '' : ' موعد التجديد:$date'}';
      default:
        return 'The coach is unavailable right now.\nالمدرب غير متاح حالياً.\n\n$_fallback';
    }
  }

  Future<void> _send([String? preset, bool isRetry = false]) async {
    final text = (preset ?? _input.text).trim();
    if (_sending ||
        _savingConsent ||
        !_consentReady ||
        text.isEmpty ||
        text.runes.length > 2000) {
      return;
    }
    final generation = _chatGeneration;
    final account = _client.accountId;
    final shareRequested = _consent;
    if (!isRetry) _input.clear();
    setState(() {
      if (!isRetry) _messages.add((bot: false, text: text, retry: null));
      _sending = true;
      _remaining = null;
    });
    _scrollToEnd();
    final emergency = coachEmergencyReply(text);
    if (emergency != null) {
      setState(() {
        _messages.add((bot: true, text: emergency, retry: null));
        _sending = false;
      });
      _scrollToEnd();
      return;
    }
    try {
      if (account == null) {
        throw const CoachException('authentication_required');
      }
      if (shareRequested) {
        await (widget.refreshActivity?.call() ?? _state.loadActivity());
        if (!mounted ||
            generation != _chatGeneration ||
            account != _client.accountId) {
          return;
        }
      }
      final share = shareRequested && _consent;
      if (share &&
          (!_state.loggedIn ||
              _state.activityLoading ||
              _state.activityError != null ||
              _state.targetCalories <= 0)) {
        throw const CoachException('unavailable');
      }
      final totals = _state.totals;
      final reply = await _client.send({
        'message': text,
        'consent': share,
        if (share)
          'context': {
            'calorie_target': _state.targetCalories,
            'calories_consumed': totals.totalMealCalories,
            'calories_burned': totals.totalBurnedCalories,
          },
      });
      if (!mounted ||
          generation != _chatGeneration ||
          account != _client.accountId) {
        return;
      }
      setState(() {
        _messages.add((bot: true, text: reply.text, retry: null));
        _remaining = reply.remaining;
      });
    } on CoachException catch (error) {
      if (!mounted ||
          generation != _chatGeneration ||
          account != _client.accountId) {
        return;
      }
      final retryable = !{
        'authentication_required',
        'registered_user_required',
        'birth_date_required',
        'underage',
        'quota_exceeded',
      }.contains(error.code);
      setState(() => _messages.add((
            bot: true,
            text: _errorText(error),
            retry: retryable ? text : null
          )));
    } catch (_) {
      if (!mounted ||
          generation != _chatGeneration ||
          account != _client.accountId) {
        return;
      }
      setState(() => _messages.add((
            bot: true,
            text: _errorText(const CoachException('unavailable')),
            retry: text
          )));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToEnd();
      }
    }
  }

  void _newChat() {
    _chatGeneration++;
    setState(() {
      _messages.clear();
      _remaining = null;
      _input.clear();
    });
  }

  TextSpan _coachText(String text) {
    final spans = <TextSpan>[];
    var position = 0;
    var bold = false;
    while (true) {
      final next = text.indexOf('**', position);
      if (next == -1) {
        spans.add(TextSpan(
            text: text.substring(position),
            style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null));
        break;
      }
      spans.add(TextSpan(
          text: text.substring(position, next),
          style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null));
      bold = !bold;
      position = next + 2;
    }
    return TextSpan(children: spans);
  }

  void _showNotice() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: kMaroon),
        ),
        title: Row(
          children: [
            const _CoachAvatar(size: 44),
            const SizedBox(width: 12),
            const Expanded(child: Text('About the coach / عن المدرب')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (icon, english, arabic) in _noticeRows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 20, color: kMaroon),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(english,
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.left),
                            const SizedBox(height: 4),
                            Text(arabic,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.right),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kMaroon,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it / فهمت'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(({bool bot, String text, String? retry}) message) {
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 290),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: message.bot ? kCard2 : kMaroon,
        borderRadius: BorderRadius.circular(16),
        border: message.bot ? Border.all(color: kMaroon) : null,
      ),
      child: message.retry != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(message.text,
                    textDirection: containsArabic(message.text)
                        ? TextDirection.rtl
                        : TextDirection.ltr),
                TextButton(
                  onPressed: _sending || _savingConsent || !_consentReady
                      ? null
                      : () => _send(message.retry, true),
                  child: const Text('Try again / حاول مرة أخرى'),
                ),
              ],
            )
          : message.bot && message.text.contains('**')
              ? SelectableText.rich(_coachText(message.text),
                  textDirection: containsArabic(message.text)
                      ? TextDirection.rtl
                      : TextDirection.ltr)
              : SelectableText(message.text,
                  textDirection: containsArabic(message.text)
                      ? TextDirection.rtl
                      : TextDirection.ltr),
    );
    return Align(
      alignment: message.bot ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: message.bot
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                const _CoachAvatar(size: 32),
                const SizedBox(width: 8),
                Flexible(child: bubble),
              ])
            : bubble,
      ),
    );
  }

  Widget _suggestion(String question, {bool card = false}) {
    final enabled = !_sending && _consentReady && !_savingConsent;
    if (card) {
      return OutlinedButton(
        onPressed: enabled ? () => _send(question) : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: kCard2,
          foregroundColor: kCream,
          side: BorderSide(color: kMaroon),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(question, textAlign: TextAlign.center),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(question, style: const TextStyle(fontSize: 12)),
        backgroundColor: kCard2,
        side: BorderSide(color: kMaroon),
        onPressed: enabled ? () => _send(question) : null,
      ),
    );
  }

  Widget _welcome() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(children: [
          const _CoachAvatar(size: 88),
          const SizedBox(height: 12),
          Text('Hi! How can I help today?\nأهلاً! كيف أقدر أساعدك اليوم؟',
              textAlign: TextAlign.center,
              style: TextStyle(color: kCream, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final width = (constraints.maxWidth - 8) / 2;
            return Wrap(spacing: 8, runSpacing: 8, children: [
              for (final question in _suggestions)
                SizedBox(
                    width: width, child: _suggestion(question, card: true)),
            ]);
          }),
        ]),
      );

  @override
  Widget build(BuildContext context) => Material(
        color: kBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: kMuted, borderRadius: BorderRadius.circular(4)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                const _CoachAvatar(size: 44),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: Text('Privilege Coach\nمدرب بريفيلج',
                          style: TextStyle(
                              color: kCream,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: kMaroon, borderRadius: BorderRadius.circular(6)),
                  child:
                      const Text('AI', style: TextStyle(color: Colors.white)),
                ),
                IconButton(
                  tooltip: 'New chat / محادثة جديدة',
                  onPressed: _newChat,
                  icon: const Icon(Icons.add_comment_outlined),
                ),
                IconButton(
                  tooltip: 'Close chat / إغلاق المحادثة',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ]),
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  InkWell(
                    onTap: _showNotice,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        Icon(Icons.info_outline, size: 16, color: kMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'AI can make mistakes - not medical advice - tap for details\n'
                            'قد يخطئ الذكاء الاصطناعي - ليس نصيحة طبية - اضغط للتفاصيل',
                            style: TextStyle(color: kMuted, fontSize: 11),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text(
                        'Share my calorie target and today’s totals with the coach\nمشاركة هدف السعرات وإجمالي اليوم مع المدرب',
                        style: TextStyle(fontSize: 12)),
                    value: _consent,
                    onChanged: _consentReady && !_savingConsent && !_sending
                        ? _setConsent
                        : null,
                  ),
                  if (_messages.isEmpty && !_sending) _welcome(),
                  for (final message in _messages) _bubble(message),
                  if (_sending)
                    Semantics(
                      label: 'Coach is responding… / المدرب يرد…',
                      child: ExcludeSemantics(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                                color: kCard2,
                                border: Border.all(color: kMaroon),
                                borderRadius: BorderRadius.circular(16)),
                            child: Text('•••',
                                style: TextStyle(color: kCream, fontSize: 20)),
                          ),
                        ),
                      ),
                    ),
                  if (_remaining != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                          'Requests left today: $_remaining\nالمتبقي اليوم: $_remaining',
                          style: TextStyle(color: kMuted, fontSize: 11)),
                    ),
                ],
              ),
            ),
            if (_messages.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final question in _suggestions) _suggestion(question),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    maxLength: 2000,
                    inputFormatters: [
                      TextInputFormatter.withFunction((oldValue, newValue) =>
                          newValue.text.runes.length <= 2000
                              ? newValue
                              : oldValue),
                    ],
                    buildCounter: (context,
                            {required currentLength,
                            required isFocused,
                            required maxLength}) =>
                        Text('${_input.text.runes.length}/2000'),
                    minLines: 1,
                    maxLines: 3,
                    onSubmitted: (_) => _send(),
                    decoration:
                        fieldDecoration('Message the coach / اكتب للمدرب')
                            .copyWith(
                                hintMaxLines: 1,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24))),
                  ),
                ),
                const SizedBox(width: 6),
                CircleAvatar(
                  backgroundColor: kMaroon,
                  child: IconButton(
                    tooltip: 'Send / إرسال',
                    icon: const Icon(Icons.send_rounded, size: 20),
                    color: Theme.of(context).colorScheme.onPrimary,
                    onPressed: _sending ||
                            _savingConsent ||
                            !_consentReady ||
                            _input.text.trim().isEmpty
                        ? null
                        : _send,
                  ),
                ),
              ]),
            ),
          ]),
        ),
      );
}
