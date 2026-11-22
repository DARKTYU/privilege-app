import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n_strings.dart';
import '../coach_preferences.dart';
import '../logic/coach_safety.dart';
import '../logic/localized_dates.dart';
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
        label: strings(context).coachTitle,
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

class CoachPhoto {
  const CoachPhoto({required this.bytes, required this.mime});
  final Uint8List bytes;
  final String mime;
}

abstract class CoachImagePicker {
  Future<CoachPhoto?> pick(ImageSource source);
}

class ImagePickerCoachImagePicker implements CoachImagePicker {
  const ImagePickerCoachImagePicker();

  @override
  Future<CoachPhoto?> pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );
    if (file == null) return null;
    final mime = file.mimeType ??
        switch (file.name.toLowerCase().split('.').last) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => 'image/jpeg',
        };
    return CoachPhoto(bytes: await file.readAsBytes(), mime: mime);
  }
}

class ChatMessage {
  const ChatMessage(
      {required this.bot,
      required this.text,
      this.retry,
      this.error,
      this.photo,
      this.photoMime});
  final bool bot;
  final String text;
  final String? retry;
  final CoachException? error;
  final Uint8List? photo;
  final String? photoMime;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen(
      {super.key,
      this.client,
      this.state,
      this.refreshActivity,
      this.imagePicker});
  final CoachClient? client;
  final AppState? state;
  final Future<void> Function()? refreshActivity;
  final CoachImagePicker? imagePicker;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  List<String> get _suggestions {
    final l = strings(context);
    return [
      l.coachTraining,
      l.coachProteinRecipe,
      l.coachCaloriesLeft,
      l.coachSnacks
    ];
  }

  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  late final CoachClient _client = widget.client ?? SupabaseCoachClient();
  late final CoachImagePicker _imagePicker =
      widget.imagePicker ?? const ImagePickerCoachImagePicker();
  CoachPhoto? _selectedPhoto;
  bool _noticeAccepted = false;
  bool _lastRequestHadPhoto = false;
  late final AppState _state = widget.state ?? appState;
  bool _consent = false;
  bool _consentReady = false;
  bool _savingConsent = false;
  bool _sending = false;
  bool _preparingSend = false;
  int? _remaining;
  int _chatGeneration = 0;
  String? _account;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _account = _client.accountId;
    _state.addListener(_accountChanged);
    _input.addListener(_inputChanged);
    _restoreConsent();
    _restorePhotoNotice();
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
        _selectedPhoto = null;
      });
    }
  }

  Future<void> _restorePhotoNotice() async {
    try {
      _noticeAccepted = await loadCoachPhotoNoticeAccepted();
    } catch (_) {
      _noticeAccepted = false;
    }
  }

  Future<void> _restoreConsent() async {
    try {
      final consent = await loadCoachConsent();
      if (!mounted) return;
      setState(() {
        _consent = consent;
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
      if (!await saveCoachConsent(value)) {
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(strings(context).coachPreferenceError),
    ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    final l = strings(context);
    switch (error.code) {
      case 'authentication_required':
      case 'registered_user_required':
        return l.coachSignInError;
      case 'birth_date_required':
        return l.coachBirthDateError;
      case 'underage':
        return l.coachAgeError;
      case 'invalid_image':
      case 'invalid_image_mime':
      case 'invalid_image_data':
      case 'multiple_images':
        return l.coachPhotoNotAllowed;
      case 'image_too_large':
        return l.coachPhotoTooLarge;
      case 'photo_consent_required':
      case 'image_consent_required':
        return l.coachPhotoConsentRequired;
      case 'quota_exceeded':
        if (_lastRequestHadPhoto) return l.coachPhotoQuotaError;
        final reset = error.resetAt?.toLocal();
        if (reset == null) return l.coachQuotaError;
        final material = MaterialLocalizations.of(context);
        final date = westernDigits('${material.formatFullDate(reset)} '
            '${material.formatTimeOfDay(TimeOfDay.fromDateTime(reset), alwaysUse24HourFormat: true)}');
        return l.coachQuotaResetError(date);
      default:
        return l.coachUnavailableHelp(l.coachUnavailable, l.coachLocalHelp);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final photo = await _imagePicker.pick(source);
      if (photo == null || !mounted) return;
      if (photo.bytes.lengthInBytes > 600 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(strings(context).coachPhotoTooLarge),
        ));
        return;
      }
      if (!const {'image/jpeg', 'image/png', 'image/webp'}
          .contains(photo.mime)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(strings(context).coachPhotoNotAllowed),
        ));
        return;
      }
      setState(() => _selectedPhoto = photo);
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(strings(context).coachPhotoUnavailable),
        ));
      }
    }
  }

  Future<void> _choosePhoto() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: kCard,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(strings(context).coachTakePhoto),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(strings(context).coachChooseGallery),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source != null) await _pickPhoto(source);
  }

  Future<void> _send([String? preset, bool isRetry = false]) async {
    final text = (preset ?? _input.text).trim();
    final selectedPhoto = isRetry ? null : _selectedPhoto;
    if (_sending ||
        _preparingSend ||
        _savingConsent ||
        !_consentReady ||
        (text.isEmpty && selectedPhoto == null) ||
        text.runes.length > 2000) {
      return;
    }
    _preparingSend = true;
    if (selectedPhoto != null && !_noticeAccepted) {
      final accepted = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(strings(context).coachPhotoNoticeTitle),
              content: Text(strings(context).coachPhotoNoticeBody),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(strings(context).cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(strings(context).coachContinue),
                ),
              ],
            ),
          ) ??
          false;
      if (!accepted || !mounted) {
        _preparingSend = false;
        return;
      }
      if (!await saveCoachPhotoNoticeAccepted()) {
        _preparingSend = false;
        return;
      }
      _noticeAccepted = true;
    }
    _preparingSend = false;
    final generation = _chatGeneration;
    final account = _client.accountId;
    final shareRequested = _consent;
    _lastRequestHadPhoto = selectedPhoto != null;
    if (!isRetry) {
      _input.clear();
      _selectedPhoto = null;
    }
    setState(() {
      if (!isRetry) {
        _messages.add(ChatMessage(
          bot: false,
          text: text.isEmpty ? '[photo]' : text,
          photo: selectedPhoto?.bytes,
          photoMime: selectedPhoto?.mime,
        ));
      }
      _sending = true;
      _remaining = null;
    });
    _scrollToEnd();
    final emergency = selectedPhoto == null ? coachEmergencyReply(text) : null;
    if (emergency != null) {
      setState(() {
        _messages.add(ChatMessage(bot: true, text: emergency));
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
        if (selectedPhoto != null) 'photo_consent': true,
        if (selectedPhoto != null)
          'image': {
            'mime': selectedPhoto.mime,
            'data': base64Encode(selectedPhoto.bytes),
          },
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
        _messages.add(ChatMessage(bot: true, text: reply.text));
        _remaining = reply.remaining;
      });
    } on CoachException catch (error) {
      if (!mounted ||
          generation != _chatGeneration ||
          account != _client.accountId) {
        return;
      }
      if (error.code == 'photo_consent_required') {
        _noticeAccepted = false;
        await saveCoachPhotoNoticeAccepted(false);
      }
      final retryable = selectedPhoto == null &&
          !{
            'authentication_required',
            'registered_user_required',
            'birth_date_required',
            'underage',
            'quota_exceeded',
            'photo_consent_required',
            'image_consent_required',
            'image_too_large',
            'invalid_image',
            'invalid_image_mime',
            'invalid_image_data',
            'multiple_images',
          }.contains(error.code);
      setState(() => _messages.add(ChatMessage(
          bot: true, text: '', retry: retryable ? text : null, error: error)));
      if (error.code == 'photo_consent_required') {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final accepted = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(strings(context).coachPhotoNoticeTitle),
                  content: Text(strings(context).coachPhotoNoticeBody),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(strings(context).cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(strings(context).coachContinue),
                    ),
                  ],
                ),
              ) ?? false;
          if (accepted) {
            await saveCoachPhotoNoticeAccepted();
            if (mounted) setState(() => _noticeAccepted = true);
          }
        });
      }
    } catch (_) {
      if (!mounted ||
          generation != _chatGeneration ||
          account != _client.accountId) {
        return;
      }
      setState(() => _messages.add(ChatMessage(
            bot: true,
            text: '',
            retry: selectedPhoto == null ? text : null,
            error: const CoachException('unavailable'),
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
      _selectedPhoto = null;
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
            Expanded(child: Text(strings(context).coachAbout)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (icon, text) in [
                (
                  Icons.warning_amber_rounded,
                  strings(context).coachNoticeMistakes
                ),
                (
                  Icons.medical_services_outlined,
                  strings(context).coachNoticeMedical
                ),
                (Icons.cloud_outlined, strings(context).coachNoticeCloud),
                (Icons.lock_outline, strings(context).coachNoticePrivacy),
                (Icons.memory, strings(context).coachNoticeMemory),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 20, color: kMaroon),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(text),
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
              child: Text(strings(context).coachGotIt),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage message) {
    final text =
        message.error == null ? message.text : _errorText(message.error!);
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
                SelectableText(text,
                    textDirection: containsArabic(text)
                        ? TextDirection.rtl
                        : TextDirection.ltr),
                TextButton(
                  onPressed: _sending || _savingConsent || !_consentReady
                      ? null
                      : () => _send(message.retry, true),
                  child: Text(strings(context).coachTryAgain),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.photo != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(message.photo!,
                        width: 180, height: 120, fit: BoxFit.cover),
                  ),
                  if (text != '[photo]') const SizedBox(height: 8),
                ],
                if (text != '[photo]')
                  message.bot && text.contains('**')
                      ? SelectableText.rich(_coachText(text),
                          textDirection: containsArabic(text)
                              ? TextDirection.rtl
                              : TextDirection.ltr)
                      : SelectableText(text,
                          textDirection: containsArabic(text)
                              ? TextDirection.rtl
                              : TextDirection.ltr),
              ],
            ),
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
      padding: const EdgeInsetsDirectional.only(end: 8),
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
          Text(strings(context).coachWelcome,
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
                      alignment: AlignmentDirectional.centerStart,
                      fit: BoxFit.scaleDown,
                      child: Text(strings(context).coachTitle,
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
                  child: Text(strings(context).coachAiBadge,
                      style: const TextStyle(color: Colors.white)),
                ),
                IconButton(
                  tooltip: strings(context).coachNewChat,
                  onPressed: _newChat,
                  icon: const Icon(Icons.add_comment_outlined),
                ),
                IconButton(
                  tooltip: strings(context).coachClose,
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
                            strings(context).coachInfo,
                            style: TextStyle(color: kMuted, fontSize: 11),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(strings(context).coachConsent,
                        style: const TextStyle(fontSize: 12)),
                    value: _consent,
                    onChanged: _consentReady && !_savingConsent && !_sending
                        ? _setConsent
                        : null,
                  ),
                  if (_messages.isEmpty && !_sending) _welcome(),
                  for (final message in _messages) _bubble(message),
                  if (_sending)
                    Semantics(
                      label: strings(context).coachResponding,
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
                          strings(context).coachRequestsLeft(_remaining!),
                          style: TextStyle(color: kMuted, fontSize: 11)),
                    ),
                ],
              ),
            ),
            if (_messages.isNotEmpty)
              SizedBox(
                height: 44,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    stops: [0, 0.84, 1],
                    colors: [Colors.white, Colors.white, Colors.transparent],
                  ).createShader(bounds,
                      textDirection: Directionality.of(context)),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 32, 0),
                    children: [
                      for (final question in _suggestions)
                        _suggestion(question),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedPhoto != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Stack(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_selectedPhoto!.bytes,
                              width: 96, height: 72, fit: BoxFit.cover),
                        ),
                        PositionedDirectional(
                          top: 0,
                          end: 0,
                          child: IconButton(
                            tooltip: strings(context).coachRemovePhoto,
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                setState(() => _selectedPhoto = null),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ),
                      ]),
                    ),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    IconButton(
                      tooltip: strings(context).coachAttachPhoto,
                      onPressed: _sending ? null : _choosePhoto,
                      icon: const Icon(Icons.add),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _input,
                        maxLength: 2000,
                        inputFormatters: [
                          TextInputFormatter.withFunction(
                              (oldValue, newValue) =>
                                  newValue.text.runes.length <= 2000
                                      ? newValue
                                      : oldValue),
                        ],
                        buildCounter: (context,
                                {required currentLength,
                                required isFocused,
                                required maxLength}) =>
                            Text(strings(context).coachCounter(
                                _input.text.runes.length.toString())),
                        minLines: 1,
                        maxLines: 3,
                        onSubmitted: (_) => _send(),
                        decoration:
                            fieldDecoration(strings(context).coachInputHint)
                                .copyWith(
                                    hintMaxLines: 1,
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(24))),
                      ),
                    ),
                    const SizedBox(width: 6),
                    CircleAvatar(
                      backgroundColor: kMaroon,
                      child: IconButton(
                        tooltip: strings(context).coachSend,
                        icon: const Icon(Icons.send_rounded, size: 20),
                        color: Theme.of(context).colorScheme.onPrimary,
                        onPressed: _sending ||
                                _savingConsent ||
                                !_consentReady ||
                                (_input.text.trim().isEmpty &&
                                    _selectedPhoto == null)
                            ? null
                            : _send,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ]),
        ),
      );
}
