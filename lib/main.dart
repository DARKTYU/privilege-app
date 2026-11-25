import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/settings.dart';
import 'screens/academy.dart';
import 'screens/arena.dart';
import 'screens/champion.dart';
import 'screens/cheats.dart';
import 'screens/community.dart';
import 'screens/home_shell.dart';
import 'screens/login.dart';
import 'screens/onboarding.dart';
import 'screens/progression.dart';
import 'screens/recipes.dart';
import 'screens/subscription.dart';
import 'state.dart';
import 'supabase_config.dart';
import 'theme_settings.dart';
import 'language_settings.dart';
import 'l10n/app_localizations.dart';
import 'l10n_strings.dart';
import 'ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  await themeSettings.restore();
  await languageSettings.restore();
  appState
      .restoreSession(); // checks the saved login (if any) before choosing the first screen
  runApp(const PrivilegeApp());
}

class _AppStartup extends StatefulWidget {
  const _AppStartup({required this.state, this.loginBuilder, this.homeBuilder});
  final AppState state;
  final WidgetBuilder? loginBuilder, homeBuilder;

  @override
  State<_AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<_AppStartup> {
  Timer? _minimumTimer;
  Timer? _slowRestoreTimer;
  bool _minimumElapsed = false;
  bool _slowRestore = false;
  bool _done = false;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_sessionChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    final disabled = MediaQuery.disableAnimationsOf(context);
    _minimumTimer = Timer(
      Duration(milliseconds: disabled ? 500 : _introMilliseconds),
      () => setState(() {
        _minimumElapsed = true;
        _finishIfReady();
      }),
    );
    _slowRestoreTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted && widget.state.restoring) {
        setState(() => _slowRestore = true);
      }
    });
  }

  void _sessionChanged() {
    if (!mounted) return;
    setState(() => _finishIfReady());
  }

  void _finishIfReady() {
    if (!_done && _minimumElapsed && !widget.state.restoring) {
      _done = true;
      _slowRestoreTimer?.cancel();
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(_sessionChanged);
    _minimumTimer?.cancel();
    _slowRestoreTimer?.cancel();
    super.dispose();
  }

  Widget _destination() {
    if (!widget.state.loggedIn) {
      return widget.loginBuilder?.call(context) ?? const LoginScreen();
    }
    if (!widget.state.onboardingDone) return const OnboardingScreen();
    return widget.homeBuilder?.call(context) ?? HomeShell();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: Duration(
            milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 300),
        child: _done
            ? KeyedSubtree(
                key: const ValueKey('destination'), child: _destination())
            : _IntroScreen(
                key: const ValueKey('intro'), showProgress: _slowRestore),
      );
}

/// Length of the intro animation. The screen stays at least this long on a
/// cold start; a slow session restore keeps the finished intro on screen.
const int _introMilliseconds = 1800;

class _IntroScreen extends StatefulWidget {
  const _IntroScreen({super.key, required this.showProgress});
  final bool showProgress;

  @override
  State<_IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<_IntroScreen>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF0B0D12);
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _introMilliseconds),
  );
  bool _hapticDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1;
      } else {
        _controller.addListener(_hapticWhenSettled);
        _controller.forward();
      }
    });
  }

  // One light tap when the logo has settled (halfway through the intro).
  void _hapticWhenSettled() {
    if (_hapticDone || _controller.value < 0.5) return;
    _hapticDone = true;
    HapticFeedback.lightImpact().catchError((_) {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _window(double t, double from, double to, [Curve curve = Curves.linear]) =>
      curve.transform(((t - from) / (to - from)).clamp(0.0, 1.0));

  Widget _logo(double t) {
    final fade = _window(t, 0.05, 0.5, Curves.easeOutCubic);
    final sweep = _window(t, 0.42, 0.82, Curves.easeInOut);
    return Opacity(
      opacity: fade,
      child: Transform.scale(
        scale: 0.9 + (0.1 * fade),
        child: ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(-2 + 4 * sweep, -0.4),
            end: Alignment(-1 + 4 * sweep, 0.4),
            colors: const [
              Color(0x00FFFFFF),
              Color(0x73FFFFFF),
              Color(0x00FFFFFF),
            ],
          ).createShader(rect),
          child: const PrivilegeLogo(width: 190),
        ),
      ),
    );
  }

  Widget _tagline(double t) {
    final text = strings(context).splashSlogan;
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    const wordLength = 0.2;
    final step = words.length > 1 ? (0.45 - wordLength) / (words.length - 1) : 0.0;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      children: [
        for (var i = 0; i < words.length; i++)
          Builder(builder: (context) {
            final start = 0.55 + step * i;
            final p = _window(t, start, start + wordLength, Curves.easeOut);
            return Opacity(
              opacity: p,
              child: Transform.translate(
                offset: Offset(0, 6 * (1 - p)),
                child: Text(
                  words[i],
                  style: TextStyle(
                    color: const Color(0xFFF3F5F8),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    // Letter spacing would break Arabic letter joining.
                    letterSpacing: isArabic ? 0 : 1.8,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _bg,
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return Stack(fit: StackFit.expand, children: [
              CustomPaint(painter: _EmberPainter(t)),
              Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: -70,
                        right: -70,
                        top: -70,
                        bottom: -70,
                        child: CustomPaint(painter: _GlowPainter(t)),
                      ),
                      _logo(t),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _tagline(t),
                  SizedBox(height: widget.showProgress ? 24 : 0),
                  if (widget.showProgress)
                    const SizedBox(
                      width: 96,
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        backgroundColor: Color(0xFF30394A),
                        color: Color(0xFFF5B942),
                      ),
                    ),
                ]),
              ),
            ]);
          },
        ),
      );
}

/// Soft glow behind the logo plus one thin ring that expands and fades.
class _GlowPainter extends CustomPainter {
  const _GlowPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final grow = Curves.easeOutCubic.transform((t / 0.55).clamp(0.0, 1.0));
    final scale = 0.55 + 0.45 * grow;
    final glow = Rect.fromCenter(
        center: center, width: size.width * scale, height: size.height * scale);
    canvas.drawOval(
        glow,
        Paint()
          ..color = const Color(0xFFB91C46).withAlpha((70 * grow).round())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36));
    canvas.drawOval(
        glow.deflate(size.shortestSide * 0.1),
        Paint()
          ..color = const Color(0xFFF5B942).withAlpha((30 * grow).round())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 44));
    final ringT = Curves.easeOut.transform((t / 0.75).clamp(0.0, 1.0));
    final ring = Rect.fromCenter(
        center: center,
        width: size.width * (0.5 + 0.5 * ringT),
        height: size.height * (0.5 + 0.5 * ringT));
    canvas.drawOval(
        ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFFF5B942)
              .withAlpha((130 * (1 - ringT)).round().clamp(0, 255)));
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.t != t;
}

/// A few small embers that float up from behind the logo and fade out.
class _EmberPainter extends CustomPainter {
  const _EmberPainter(this.t);
  final double t;

  static const _xs = [
    -0.9, -0.55, -0.3, -0.1, 0.12, 0.3, 0.52, 0.8, -0.7, 0.0, 0.65, -0.2
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final spread = math.min(size.width, 320.0) / 2;
    for (var i = 0; i < _xs.length; i++) {
      final delay = (i * 0.06) % 0.5;
      final local = ((t - 0.1 - delay) / 0.55).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final x = cx + _xs[i] * spread + math.sin(local * math.pi * 2 + i) * 8;
      final y = cy + 50 - local * 170;
      final alpha = (math.sin(local * math.pi) * 200).round().clamp(0, 255);
      final color =
          i.isEven ? const Color(0xFFF5B942) : const Color(0xFFE0476D);
      canvas.drawCircle(
          Offset(x, y),
          1.5 + (i % 3) * 0.7,
          Paint()
            ..color = color.withAlpha(alpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
    }
  }

  @override
  bool shouldRepaint(_EmberPainter old) => old.t != t;
}

class PrivilegeApp extends StatelessWidget {
  const PrivilegeApp({super.key, this.loginBuilder, this.homeBuilder});
  final WidgetBuilder? loginBuilder, homeBuilder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([themeSettings, languageSettings]),
      builder: (context, _) => ListenableBuilder(
          listenable: appState,
          builder: (context, _) => MaterialApp(
                initialRoute: '/',
                title: 'Privilege',
                debugShowCheckedModeBanner: false,
                theme: buildTheme(themeSettings.selected),
                locale: languageSettings.selected,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: const [Locale('en'), Locale('ar')],
                routes: {
                  '/community': (context) => _protected(AppPage(
                        title: strings(context).community,
                        builder: () => const CommunityScreen(),
                      )),
                  '/recipes': (context) => _protected(AppPage(
                        title: strings(context).recipes,
                        builder: () => RecipesScreen(),
                      )),
                  '/arena': (context) => _protected(AppPage(
                        title: strings(context).arena,
                        builder: () => ArenaScreen(),
                      )),
                  '/rewards': (context) => _protected(AppPage(
                        title: strings(context).arenaRewardsStore,
                        builder: () => const RewardsStoreScreen(),
                      )),
                  '/badges': (context) => _protected(AppPage(
                        title: strings(context).arenaBadgesAchievements,
                        builder: () => const BadgesAchievementsScreen(),
                      )),
                  '/cheats': (context) => _protected(AppPage(
                        title: strings(context).cravingsTitle,
                        builder: () => CheatsScreen(),
                      )),
                  '/classified': (context) => _protected(AppPage(
                        title: strings(context).classified,
                        builder: () => ChampionScreen(),
                      )),
                  '/academy': (context) => _protected(AppPage(
                        title: strings(context).academyTitle,
                        builder: () => AcademyScreen(),
                      )),
                  '/plans': (context) => _protected(AppPage(
                        title: strings(context).vipPlans,
                        builder: () => SubscriptionScreen(),
                      )),
                  '/settings': (context) => _protected(AppPage(
                        title: strings(context).settings,
                        builder: () => SettingsScreen(),
                      )),
                },
                home: ThemeAwareBuilder(
                  builder: () => _AppStartup(
                    state: appState,
                    loginBuilder: loginBuilder,
                    homeBuilder: homeBuilder,
                  ),
                ),
              )),
    );
  }

  Widget _protected(Widget page) {
    if (appState.restoring) return const SizedBox.shrink();
    if (!appState.loggedIn) return const LoginScreen();
    if (!appState.onboardingDone) return const OnboardingScreen();
    return page;
  }
}
