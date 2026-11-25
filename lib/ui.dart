import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme_settings.dart';
import 'l10n_strings.dart';

Color get kBg => themeSettings.selected.background;
Color get kCard => themeSettings.selected.surface;
Color get kCard2 => themeSettings.selected.elevatedSurface;
Color get kLine => themeSettings.selected.outline;
Color get kMaroon => themeSettings.selected.primary;
Color get kGold => themeSettings.selected.secondary;
Color get kCream => themeSettings.selected.text;
Color get kMuted => themeSettings.selected.mutedText;
Color get kGreen => themeSettings.selected.success;
Color get kRed => themeSettings.selected.error;
Color get kSmallTextAccent => themeSettings.selected.smallTextAccent;
Color get kBlue => themeSettings.selected.info;
Color get kOrange => themeSettings.selected.warmAccent;
Color get kCyan => themeSettings.selected.coolAccent;
Color get kPurple => themeSettings.selected.violetAccent;

enum CaloriesResultKind { food, workout }

class CaloriesLogResult {
  const CaloriesLogResult(this.kind, this.calories);
  final CaloriesResultKind kind;
  final int calories;
}

final caloriesLogEvents = ValueNotifier<CaloriesLogResult?>(null);

void notifyCaloriesLog(CaloriesResultKind kind, int calories) {
  caloriesLogEvents.value = CaloriesLogResult(kind, calories);
}

ThemeData buildTheme([AppThemePreset preset = AppThemePreset.privilege]) {
  const brightness = Brightness.dark;
  final textColor = preset.text;
  final mutedColor = preset.mutedText;
  final outlineColor = preset.outline;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: preset.primary,
    onPrimary: Colors.white,
    secondary: preset.secondary,
    onSecondary: Colors.black,
    error: preset.error,
    onError: Colors.white,
    surface: preset.surface,
    onSurface: textColor,
    outline: outlineColor,
  );
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: preset.background,
    colorScheme: scheme,
    textTheme: TextTheme(
      headlineSmall: TextStyle(
        color: textColor,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      titleMedium: TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      bodyLarge: TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        color: mutedColor,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: preset.background,
      foregroundColor: textColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: shape,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        side: BorderSide(color: outlineColor),
        shape: shape,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: preset.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(color: mutedColor),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: outlineColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: preset.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: preset.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: preset.error, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      color: preset.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: outlineColor),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: outlineColor,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PrivilegePageTransitionsBuilder(),
        TargetPlatform.iOS: PrivilegePageTransitionsBuilder(),
        TargetPlatform.macOS: PrivilegePageTransitionsBuilder(),
        TargetPlatform.windows: PrivilegePageTransitionsBuilder(),
        TargetPlatform.linux: PrivilegePageTransitionsBuilder(),
        TargetPlatform.fuchsia: PrivilegePageTransitionsBuilder(),
      },
    ),
  );
}

/// Locale-independent display formatting with Western digits.
String fmt(num n) {
  final sign = n < 0 ? '-' : '';
  final rounded = n.toDouble().abs();
  final fixed = rounded == rounded.roundToDouble()
      ? rounded.toInt().toString()
      : rounded.toStringAsFixed(1);
  final parts = fixed.split('.');
  final whole = parts.first;
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(',');
    buffer.write(whole[i]);
  }
  return '$sign$buffer${parts.length == 2 ? '.${parts[1]}' : ''}';
}

/// The Privilege logo (burger dumbbell).
class PrivilegeLogo extends StatelessWidget {
  const PrivilegeLogo({super.key, this.width = 220});
  final double width;

  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/images/logo.png', width: width, fit: BoxFit.contain);
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.only(bottom: 10),
    this.borderColor,
  });
  final Widget child;
  final EdgeInsets padding, margin;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor ?? kLine),
        ),
        child: child,
      );
}

class PrivilegePageTransitionsBuilder extends PageTransitionsBuilder {
  const PrivilegePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(rtl ? -0.04 : 0.04, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class AnimatedNumberText extends StatefulWidget {
  const AnimatedNumberText(this.value,
      {super.key,
      this.formatter,
      this.labelBuilder,
      this.style,
      this.textAlign});
  final num value;
  final String Function(num)? formatter;
  final String Function(int)? labelBuilder;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  State<AnimatedNumberText> createState() => _AnimatedNumberTextState();
}

class _AnimatedNumberTextState extends State<AnimatedNumberText> {
  double _from = 0;

  @override
  void didUpdateWidget(AnimatedNumberText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _from = oldWidget.value.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.value),
      tween: Tween(begin: disabled ? widget.value.toDouble() : _from,
          end: widget.value.toDouble()),
      duration: disabled ? Duration.zero : const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, current, _) {
        final text = widget.labelBuilder?.call(current.round()) ??
            widget.formatter?.call(current) ??
            fmt(current);
        return Text(text, style: widget.style, textAlign: widget.textAlign);
      },
    );
  }
}

class PressFeedback extends StatefulWidget {
  const PressFeedback({super.key, required this.child, this.haptic = false});
  final Widget child;
  final bool haptic;

  @override
  State<PressFeedback> createState() => _PressFeedbackState();
}

class _PressFeedbackState extends State<PressFeedback> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
    if (value && widget.haptic) HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.disableAnimationsOf(context);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed && !disabled ? 0.97 : 1,
        duration: disabled ? Duration.zero : const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(this.label,
      {super.key,
      required this.onPressed,
      this.icon,
      this.gold = false,
      this.expand = true,
      this.haptic = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool gold, expand, haptic;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = ElevatedButton.styleFrom(
      backgroundColor: gold ? colors.secondary : colors.primary,
      foregroundColor: gold ? colors.onSecondary : colors.onPrimary,
      minimumSize: expand ? const Size.fromHeight(46) : const Size(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
    final button = icon == null
        ? ElevatedButton(
            style: style, onPressed: onPressed, child: Text(label))
        : ElevatedButton.icon(
            style: style,
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
          );
    return PressFeedback(haptic: haptic && onPressed != null, child: button);
  }
}

InputDecoration fieldDecoration(String hint,
        {Widget? suffix, IconData? icon, String? error}) =>
    InputDecoration(
      hintText: hint,
      errorText: error,
      errorMaxLines: 2,
      filled: true,
      fillColor: kCard2,
      suffixIcon: suffix,
      prefixIcon: icon == null ? null : Icon(icon, size: 20, color: kMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
}

Widget sectionTitle(String t) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        t.toUpperCase(),
        style: TextStyle(
            color: kGold,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2),
      ),
    );

Widget appChip(String label, bool on, VoidCallback onTap) => ChoiceChip(
      label: Text(label),
      selected: on,
      onSelected: (_) => onTap(),
      selectedColor: kMaroon,
      backgroundColor: kCard2,
      showCheckmark: false,
      side: BorderSide.none,
      labelStyle: TextStyle(color: on ? kCream : kMuted, fontSize: 12),
    );

Widget roundIcon(IconData icon, VoidCallback onTap,
        {String? tip, Color? color}) =>
    IconButton(
      tooltip: tip,
      style: IconButton.styleFrom(backgroundColor: kCard2),
      icon: Icon(icon, size: 20, color: color ?? kCream),
      onPressed: onTap,
    );

/// Green confirmation strip (the little "✓ Added ..." banners in the React app).
Widget toastBanner(String? msg) => msg == null
    ? const SizedBox.shrink()
    : Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kCard2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kGreen.withAlpha(120)),
        ),
        child: Row(children: [
          Icon(Icons.check, color: kGreen, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: const TextStyle(fontSize: 12))),
        ]),
      );

String ltrValue(String value) => '\u2066$value\u2069';

String friendlyUsername(BuildContext context, String username) {
  final match = RegExp(r'^user_(.+)$').firstMatch(username.trim());
  final id = match?.group(1);
  if (id != null && id.length >= 12) {
    return strings(context).memberHandle(id.substring(0, 4));
  }
  return username.trim();
}

String friendlyHandle(BuildContext context, String username) {
  final display = friendlyUsername(context, username);
  return display == username.trim()
      ? strings(context).communityUsername(display)
      : display;
}

class AccountHandle extends StatelessWidget {
  const AccountHandle(this.username,
      {super.key, this.style, this.maxLines, this.overflow});

  final String username;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) => LeftToRightValue(
        friendlyHandle(context, username),
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
}

class LeftToRightValue extends StatelessWidget {
  const LeftToRightValue(this.text,
      {super.key, this.style, this.maxLines, this.overflow, this.textAlign});

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Text(text,
            style: style,
            maxLines: maxLines,
            overflow: overflow,
            textAlign: textAlign),
      );
}

Widget imagePlaceholder(BuildContext context,
        {required double height,
        double? width,
        BorderRadius? radius,
        IconData icon = Icons.image_outlined}) =>
    Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(colors: [
          Theme.of(context).colorScheme.surfaceContainerHighest,
          Theme.of(context).colorScheme.surface,
        ]),
      ),
      alignment: Alignment.center,
      child:
          Icon(icon, size: 40, color: Theme.of(context).colorScheme.onSurface),
    );

Widget tag(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );

class ThemeAwareBuilder extends StatelessWidget {
  const ThemeAwareBuilder({super.key, required this.builder});

  final Widget Function() builder;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: themeSettings,
        builder: (_, __) => builder(),
      );
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader(this.title, this.subtitle,
      {super.key, this.actions = const [], this.logo = false});
  final String title, subtitle;
  final List<Widget> actions;
  final bool logo;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          if (logo) ...[
            const PrivilegeLogo(width: 52),
            const SizedBox(width: 12)
          ],
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 21, fontWeight: FontWeight.w800)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: kMuted)),
            ]),
          ),
          ...actions,
        ]),
      );
}

/// Full-screen page with a back arrow (used for screens opened from the shortcut strip).
class AppPage extends StatelessWidget {
  const AppPage({super.key, required this.title, required this.builder});
  final String title;
  final Widget Function() builder;

  @override
  Widget build(BuildContext context) => ThemeAwareBuilder(
        builder: () => Scaffold(
          appBar: AppBar(
            backgroundColor: kBg,
            surfaceTintColor: Colors.transparent,
            foregroundColor: kCream,
            title: Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          body: SafeArea(child: builder()),
        ),
      );
}

class TabbedPage extends StatelessWidget {
  const TabbedPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.labels,
    required this.children,
    this.controller,
    this.confirmation,
  });
  final String title, subtitle;
  final List<String> labels;
  final List<Widget> children;
  final TabController? controller;
  final Widget? confirmation;

  @override
  Widget build(BuildContext context) {
    final page = Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ScreenHeader(title, subtitle),
          ),
          if (confirmation != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                child: confirmation,
              ),
            ),
          TabBar(
            controller: controller,
            tabs: [for (final l in labels) Tab(text: l)],
            indicatorColor: kGold,
            labelColor: kGold,
            unselectedLabelColor: kMuted,
            dividerColor: Colors.transparent,
          ),
          Expanded(
              child: TabBarView(controller: controller, children: children)),
        ]);
    return controller == null
        ? DefaultTabController(length: labels.length, child: page)
        : page;
  }
}

/// Shows an upgrade message and returns false when the current tier cannot use [feature].
Widget initialsAvatar(String name, double size) {
  final words = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
  final initials =
      words.take(2).map((s) => s.characters.first.toUpperCase()).join();
  return CircleAvatar(
    radius: size / 2,
    backgroundColor: kCard2,
    child: initials.isEmpty
        ? Icon(Icons.person, color: kMuted, size: size * 0.6)
        : Text(initials,
            style: TextStyle(color: kCream, fontSize: size * 0.32)),
  );
}

/// A grey rounded placeholder with a soft shimmer, shown while data loads.
/// The shimmer is static when the system asks for reduced animations.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, this.width, this.height = 16, this.radius = 12});
  final double? width;
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = kCard2;
    final highlight = Color.alphaBlend(kCream.withAlpha(22), kCard2);
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final center = -1.3 + 2.6 * _controller.value;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              gradient: LinearGradient(
                begin: AlignmentDirectional(center - 0.6, 0),
                end: AlignmentDirectional(center + 0.6, 0),
                colors: [base, highlight, base],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A short list of card-shaped placeholders. It never overflows its parent,
/// so it is safe inside small sheets and inside scrolling lists.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4, this.itemHeight = 84});
  final int count;
  final double itemHeight;

  @override
  Widget build(BuildContext context) => ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: count,
        itemBuilder: (context, _) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: itemHeight,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kLine),
            ),
            child: Row(children: [
              SkeletonBox(
                  width: itemHeight - 24, height: itemHeight - 24, radius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(height: 14),
                      SizedBox(height: 10),
                      SkeletonBox(width: 120, height: 12),
                    ]),
              ),
            ]),
          ),
        ),
      );
}

/// A friendly "nothing here yet" message with an icon and an optional button.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.disableAnimationsOf(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: disabled ? 1 : 0, end: 1),
          duration: disabled ? Duration.zero : const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
                offset: Offset(0, 10 * (1 - value)), child: child),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kCard2,
                border: Border.all(color: kLine),
              ),
              child: Icon(icon, size: 32, color: kGold),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: kMuted)),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ]),
        ),
      ),
    );
  }
}
