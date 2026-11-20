import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/coach_safety.dart';
import '../services/coach_client.dart';
import '../state.dart';
import '../ui.dart';

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
  static const _noticeEnglish =
      'The coach can make mistakes and is not medical advice. '
      'Messages are sent to Google Gemini for a reply. Do not share personal or '
      'health details you do not want sent. The coach does not remember earlier messages.';
  static const _noticeArabic =
      'قد يخطئ المدرب ولا يقدم نصيحة طبية. تُرسل الرسائل إلى Google Gemini للحصول على رد. '
      'لا تشارك تفاصيل شخصية أو صحية لا تريد إرسالها. المدرب لا يتذكر الرسائل السابقة.';
  static const _fallback = 'Local help (not AI): ask about your calories, '
      'weekly plan or streak in the app.\n'
      'مساعدة محلية (ليست ذكاءً اصطناعياً): راجع السعرات والخطة الأسبوعية وسلسلة التقدم في التطبيق.';

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

  Widget _bubble(({bool bot, String text, String? retry}) message,
      {bool notice = false}) {
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 290),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: message.bot ? kCard2 : kMaroon,
        borderRadius: BorderRadius.circular(16),
      ),
      child: notice
          ? const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SelectableText(_noticeEnglish,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left),
                SizedBox(height: 8),
                SelectableText(_noticeArabic,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right),
              ],
            )
          : message.retry != null
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
                CircleAvatar(
                    radius: 14,
                    backgroundColor: kMaroon,
                    child:
                        Icon(Icons.smart_toy_rounded, size: 16, color: kCream)),
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
          foregroundColor: kCream,
          title: const Text('Privilege Bot'),
          actions: [
            IconButton(
              tooltip: 'New chat / محادثة جديدة',
              onPressed: _newChat,
              icon: const Icon(Icons.add_comment_outlined),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(children: [
            SwitchListTile(
              dense: true,
              title: const Text(
                  'Share my calorie target and today’s totals with the coach\nمشاركة هدف السعرات وإجمالي اليوم مع المدرب',
                  style: TextStyle(fontSize: 13)),
              value: _consent,
              onChanged: _consentReady && !_savingConsent && !_sending
                  ? _setConsent
                  : null,
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                children: [
                  _bubble((bot: true, text: '', retry: null), notice: true),
                  for (final message in _messages) _bubble(message),
                  if (_sending)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Coach is responding… / المدرب يرد…'),
                    ),
                  if (_remaining != null)
                    Text(
                        'Requests left today: $_remaining\nالمتبقي اليوم: $_remaining',
                        style: TextStyle(color: kMuted)),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final question in const [
                    'Training ideas',
                    'High-protein recipe',
                    'Calories left?'
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(question,
                            style: const TextStyle(fontSize: 12)),
                        backgroundColor: kCard2,
                        side: BorderSide.none,
                        onPressed: _sending || !_consentReady || _savingConsent
                            ? null
                            : () => _send(question),
                      ),
                    ),
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
                        fieldDecoration('Message the coach / اكتب للمدرب'),
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
