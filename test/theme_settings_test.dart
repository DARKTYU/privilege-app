import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:privilege/theme_settings.dart';
import 'package:privilege/ui.dart';

double _contrastRatio(Color foreground, Color background) {
  final luminances = [
    foreground.computeLuminance(),
    background.computeLuminance(),
  ]..sort((a, b) => b.compareTo(a));
  return (luminances[0] + 0.05) / (luminances[1] + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Privilege is the fallback while saved preset ids remain supported', () {
    expect(AppThemePreset.fromId(null), AppThemePreset.privilege);
    for (final preset in AppThemePreset.values) {
      expect(AppThemePreset.fromId(preset.id), preset);
    }
  });

  test('dark theme presets have accessible text and button contrast', () {
    for (final preset in AppThemePreset.values) {
      final theme = buildTheme(preset);
      final scheme = theme.colorScheme;

      expect(theme.brightness, Brightness.dark, reason: preset.label);
      expect(scheme.primary, preset.primary, reason: preset.label);
      expect(
        _contrastRatio(scheme.onPrimary, scheme.primary),
        greaterThanOrEqualTo(4.5),
        reason: '${preset.label} primary button',
      );
      expect(
        _contrastRatio(scheme.onSecondary, scheme.secondary),
        greaterThanOrEqualTo(4.5),
        reason: '${preset.label} secondary button',
      );
      expect(
        _contrastRatio(preset.text, preset.surface),
        greaterThanOrEqualTo(4.5),
        reason: '${preset.label} main text',
      );
      expect(
        _contrastRatio(preset.mutedText, preset.surface),
        greaterThanOrEqualTo(4.5),
        reason: '${preset.label} supporting text',
      );
    }
  });

  testWidgets('theme-aware content rebuilds immediately after selection',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    themeSettings.selected = AppThemePreset.privilege;

    await tester.pumpWidget(
      MaterialApp(
        home: ThemeAwareBuilder(
          builder: () => Text(themeSettings.selected.label),
        ),
      ),
    );
    expect(find.text('Privilege'), findsOneWidget);

    await themeSettings.select(AppThemePreset.ocean);
    await tester.pump();
    expect(find.text('Deep Ocean'), findsOneWidget);

    await themeSettings.select(AppThemePreset.privilege);
  });
}
