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

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: _SplashContent(),
      );
}

class _SplashContent extends StatefulWidget {
  const _SplashContent();

  @override
  State<_SplashContent> createState() => _SplashContentState();
}

class _SplashContentState extends State<_SplashContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.15),
            radius: 0.9,
            colors: [kCard2, kBg],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final progress = Curves.easeOutCubic.transform(_controller.value);
              return Opacity(
                opacity: progress,
                child: Transform.translate(
                  offset: Offset(0, 18 * (1 - progress)),
                  child: Transform.scale(
                    scale: 0.88 + 0.12 * progress,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const PrivilegeLogo(width: 190),
                      const SizedBox(height: 18),
                      Text(
                        'EAT WELL. STAY WELL.',
                        style: TextStyle(
                          color: kCream,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.4,
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: 120,
                        child: LinearProgressIndicator(
                          value: _controller.value,
                          minHeight: 2,
                          backgroundColor: kLine,
                          color: kGold,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      );
}

class PrivilegeApp extends StatelessWidget {
  const PrivilegeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([themeSettings, languageSettings]),
      builder: (context, _) => ListenableBuilder(
          listenable: appState,
          builder: (context, _) => MaterialApp(
                key: ValueKey(appState.loggedIn),
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
                  '/rewards': (_) => _protected(AppPage(
                        title: 'Rewards Store',
                        builder: () => const RewardsStoreScreen(),
                      )),
                  '/badges': (_) => _protected(AppPage(
                        title: 'Badges & Achievements',
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
                  builder: () => ListenableBuilder(
                    listenable: appState,
                    builder: (_, __) {
                      final Widget screen;
                      final String stage;
                      if (appState.restoring) {
                        screen = _Splash();
                        stage = 'splash';
                      } else if (!appState.loggedIn) {
                        screen = LoginScreen();
                        stage = 'login';
                      } else if (!appState.onboardingDone) {
                        screen = OnboardingScreen();
                        stage = 'onboarding';
                      } else {
                        screen = HomeShell();
                        stage = 'home';
                      }
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 650),
                        reverseDuration: const Duration(milliseconds: 350),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final slide = Tween<Offset>(
                            begin: const Offset(0, 0.035),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                              parent: animation, curve: Curves.easeOutCubic));
                          return FadeTransition(
                            opacity: animation,
                            child:
                                SlideTransition(position: slide, child: child),
                          );
                        },
                        child:
                            KeyedSubtree(key: ValueKey(stage), child: screen),
                      );
                    },
                  ),
                ),
              )),
    );
  }

  Widget _protected(Widget page) {
    if (appState.restoring) return const _Splash();
    if (!appState.loggedIn) return const LoginScreen();
    if (!appState.onboardingDone) return const OnboardingScreen();
    return page;
  }
}
