import 'dart:async';

import 'package:flutter/material.dart';
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
      Duration(milliseconds: disabled ? 500 : 1600),
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

class _IntroScreen extends StatefulWidget {
  const _IntroScreen({super.key, required this.showProgress});
  final bool showProgress;

  @override
  State<_IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<_IntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0B0D12),
        body: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final logoProgress = Curves.easeOutCubic
                  .transform((_controller.value / 0.6).clamp(0.0, 1.0));
              final taglineProgress = CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.6, 1, curve: Curves.easeOut),
              ).value;
              return Column(mainAxisSize: MainAxisSize.min, children: [
                Opacity(
                  opacity: logoProgress,
                  child: Transform.scale(
                    scale: 0.88 + (0.12 * logoProgress),
                    child: DecoratedBox(
                      decoration: BoxDecoration(boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFB91C46).withAlpha(35),
                          blurRadius: 40,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: const Color(0xFFF5B942).withAlpha(18),
                          blurRadius: 56,
                          spreadRadius: 6,
                        ),
                      ]),
                      child: const PrivilegeLogo(width: 190),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Opacity(
                  opacity: taglineProgress,
                  child: Text(
                    strings(context).splashSlogan,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFF3F5F8),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                    ),
                  ),
                ),
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
              ]);
            },
          ),
        ),
      );
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
