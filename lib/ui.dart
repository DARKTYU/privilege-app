import 'package:flutter/material.dart';

import 'theme_settings.dart';

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
Color get kBlue => themeSettings.selected.info;
Color get kOrange => themeSettings.selected.warmAccent;
Color get kCyan => themeSettings.selected.coolAccent;
Color get kPurple => themeSettings.selected.violetAccent;

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
  );
}

/// 1,234 style number formatting (JS toLocaleString equivalent).
String fmt(num n) {
  final s = n.round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return (n < 0 ? '-' : '') + b.toString();
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

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(this.label,
      {super.key,
      required this.onPressed,
      this.icon,
      this.gold = false,
      this.expand = true});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool gold, expand;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = ElevatedButton.styleFrom(
      backgroundColor: gold ? colors.secondary : colors.primary,
      foregroundColor: gold ? colors.onSecondary : colors.onPrimary,
      minimumSize: expand ? const Size.fromHeight(46) : const Size(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
    if (icon == null) {
      return ElevatedButton(
          style: style, onPressed: onPressed, child: Text(label));
    }
    return ElevatedButton.icon(
      style: style,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
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

Widget netImage(String url,
    {double? width,
    double? height,
    BorderRadius? radius,
    IconData icon = Icons.image_outlined}) {
  final fallback = Container(
    width: width,
    height: height,
    color: kCard2,
    alignment: Alignment.center,
    child: Icon(icon, color: kMuted),
  );
  return ClipRRect(
    borderRadius: radius ?? BorderRadius.zero,
    child: Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
      loadingBuilder: (_, child, p) => p == null ? child : fallback,
    ),
  );
}

Widget avatar(String url, double size) => ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: kCard2,
            child: Icon(Icons.person, color: kMuted, size: size * 0.6),
          ),
        ),
      ),
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
  });
  final String title, subtitle;
  final List<String> labels;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: labels.length,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ScreenHeader(title, subtitle),
          ),
          TabBar(
            tabs: [for (final l in labels) Tab(text: l)],
            indicatorColor: kGold,
            labelColor: kGold,
            unselectedLabelColor: kMuted,
            dividerColor: Colors.transparent,
          ),
          Expanded(child: TabBarView(children: children)),
        ]),
      );
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
