import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreset {
  privilege(
    id: 'privilege',
    label: 'Privilege',
    description: 'Crimson energy with a premium gold finish',
    background: Color(0xFF0B0D12),
    primary: Color(0xFFB91C46),
    secondary: Color(0xFFF5B942),
    surface: Color(0xFF121722),
    elevatedSurface: Color(0xFF1B2230),
    outline: Color(0xFF30394A),
    text: Color(0xFFF3F5F8),
    mutedText: Color(0xFFA6B0C0),
    success: Color(0xFF32D399),
    error: Color(0xFFFB7185),
    info: Color(0xFF60A5FA),
    warmAccent: Color(0xFFFB923C),
    coolAccent: Color(0xFF22D3EE),
    violetAccent: Color(0xFFA78BFA),
  ),
  ocean(
    id: 'ocean',
    label: 'Deep Ocean',
    description: 'Midnight blue with bright, clear aqua',
    background: Color(0xFF071521),
    primary: Color(0xFF087E8B),
    secondary: Color(0xFF51D7E5),
    surface: Color(0xFF0D1E2B),
    elevatedSurface: Color(0xFF142A38),
    outline: Color(0xFF284554),
    text: Color(0xFFECF8FA),
    mutedText: Color(0xFFA0BAC6),
    success: Color(0xFF45D6A0),
    error: Color(0xFFFF7B88),
    info: Color(0xFF65AFFF),
    warmAccent: Color(0xFFFFB454),
    coolAccent: Color(0xFF58DCEB),
    violetAccent: Color(0xFFB9A6FF),
  ),
  forest(
    id: 'forest',
    label: 'Evergreen',
    description: 'Deep evergreen with a fresh mint spark',
    background: Color(0xFF081813),
    primary: Color(0xFF188653),
    secondary: Color(0xFF83E0A6),
    surface: Color(0xFF10241C),
    elevatedSurface: Color(0xFF183328),
    outline: Color(0xFF2A4A3A),
    text: Color(0xFFECF8F0),
    mutedText: Color(0xFFA4BBAA),
    success: Color(0xFF70D49A),
    error: Color(0xFFFF8181),
    info: Color(0xFF75B8FF),
    warmAccent: Color(0xFFFFB45C),
    coolAccent: Color(0xFF5ADBC0),
    violetAccent: Color(0xFFB6A0FF),
  ),
  violet(
    id: 'violet',
    label: 'Violet Edge',
    description: 'Graphite plum with a luminous violet glow',
    background: Color(0xFF110C1C),
    primary: Color(0xFF7950C8),
    secondary: Color(0xFFC6A7FF),
    surface: Color(0xFF1A1428),
    elevatedSurface: Color(0xFF261D38),
    outline: Color(0xFF3C3052),
    text: Color(0xFFF4EEFF),
    mutedText: Color(0xFFB7A9C9),
    success: Color(0xFF56D6A0),
    error: Color(0xFFFF8297),
    info: Color(0xFF79B6FF),
    warmAccent: Color(0xFFFFA96B),
    coolAccent: Color(0xFF50D5E8),
    violetAccent: Color(0xFFD0AEFF),
  );

  const AppThemePreset({
    required this.id,
    required this.label,
    required this.description,
    required this.background,
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.elevatedSurface,
    required this.outline,
    required this.text,
    required this.mutedText,
    required this.success,
    required this.error,
    required this.info,
    required this.warmAccent,
    required this.coolAccent,
    required this.violetAccent,
  });

  final String id;
  final String label;
  final String description;
  final Color background;
  final Color primary;
  final Color secondary;
  final Color surface;
  final Color elevatedSurface;
  final Color outline;
  final Color text;
  final Color mutedText;
  final Color success;
  final Color error;
  final Color info;
  final Color warmAccent;
  final Color coolAccent;
  final Color violetAccent;

  static AppThemePreset fromId(String? id) => AppThemePreset.values.firstWhere(
        (preset) => preset.id == id,
        orElse: () => AppThemePreset.privilege,
      );
}

class ThemeSettings extends ChangeNotifier {
  static const _preferenceKey = 'privilege_theme_preset';

  AppThemePreset selected = AppThemePreset.privilege;

  Future<void> restore() async {
    final preferences = await SharedPreferences.getInstance();
    selected = AppThemePreset.fromId(preferences.getString(_preferenceKey));
  }

  Future<void> select(AppThemePreset preset) async {
    if (selected == preset) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, preset.id);
    selected = preset;
    notifyListeners();
  }
}

final themeSettings = ThemeSettings();
