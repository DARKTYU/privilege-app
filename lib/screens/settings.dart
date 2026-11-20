import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../state.dart';
import '../l10n_strings.dart';
import '../language_settings.dart';
import '../theme_settings.dart';
import '../ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _choosingPhoto = false;

  Future<void> _changePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: kCard,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: kGold),
              title: Text(strings(context).choosePhotos),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: kGold),
              title: Text(strings(context).takePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ]),
        ),
      ),
    );
    if (source == null || !mounted) return;

    setState(() => _choosingPhoto = true);
    try {
      final photo = await ImagePicker().pickImage(
        source: source,
        maxWidth: 768,
        maxHeight: 768,
        imageQuality: 78,
      );
      if (photo == null) return;

      final bytes = await photo.readAsBytes();
      if (bytes.length > 900 * 1024) {
        if (mounted) toast(context, strings(context).smallerPhoto);
        return;
      }
      await appState.setProfilePhoto(bytes);
      if (mounted) toast(context, strings(context).photoUpdated);
    } on PlatformException catch (error) {
      if (mounted) {
        toast(context, error.message ?? strings(context).cameraError);
      }
    } on Exception catch (error) {
      if (mounted) toast(context, '${strings(context).savePhotoError} $error');
    } finally {
      if (mounted) setState(() => _choosingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    await appState.removeProfilePhoto();
    if (mounted) toast(context, strings(context).photoRemoved);
  }

  Widget _photoPreview() {
    final encoded = appState.profilePhotoBase64;
    return ClipOval(
      child: SizedBox(
        width: 88,
        height: 88,
        child: encoded == null
            ? initialsAvatar(
                appState.profile.name.isEmpty
                    ? appState.profile.username
                    : appState.profile.name,
                88)
            : Image.memory(
                base64Decode(encoded),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => initialsAvatar(
                    appState.profile.name.isEmpty
                        ? appState.profile.username
                        : appState.profile.name,
                    88),
              ),
      ),
    );
  }

  Widget _themeChoice(AppThemePreset preset) {
    final selected = themeSettings.selected == preset;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          try {
            await themeSettings.select(preset);
          } on Exception catch (error) {
            if (mounted) {
              toast(context, '${strings(context).saveThemeError} $error');
            }
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [preset.surface, preset.elevatedSurface],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? preset.secondary : kLine,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: preset.secondary.withAlpha(30),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : const [],
          ),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: preset.primary,
                shape: BoxShape.circle,
                border: Border.all(color: preset.secondary, width: 3),
              ),
              child: Icon(Icons.bolt_rounded, color: preset.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _themeName(preset),
                      style: TextStyle(
                        color: preset.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_themeDescription(preset),
                        style:
                            TextStyle(color: preset.mutedText, fontSize: 11)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 76,
                      height: 5,
                      child: Row(children: [
                        for (final color in [
                          preset.primary,
                          preset.secondary,
                          preset.coolAccent,
                        ])
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(right: 3),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                      ]),
                    ),
                  ]),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? preset.secondary : kMuted,
            ),
          ]),
        ),
      ),
    );
  }

  String _themeName(AppThemePreset preset) {
    final l = strings(context);
    switch (preset) {
      case AppThemePreset.privilege:
        return l.themePrivilege;
      case AppThemePreset.ocean:
        return l.themeOcean;
      case AppThemePreset.forest:
        return l.themeForest;
      case AppThemePreset.violet:
        return l.themeViolet;
    }
  }

  String _themeDescription(AppThemePreset preset) {
    final l = strings(context);
    switch (preset) {
      case AppThemePreset.privilege:
        return l.themePrivilegeDescription;
      case AppThemePreset.ocean:
        return l.themeOceanDescription;
      case AppThemePreset.forest:
        return l.themeForestDescription;
      case AppThemePreset.violet:
        return l.themeVioletDescription;
    }
  }

  Future<void> _chooseLanguage() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: kCard,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            title: const Text('English', textDirection: TextDirection.ltr),
            selected: languageSettings.selected.languageCode == 'en',
            onTap: () => Navigator.pop(context, 'en'),
          ),
          ListTile(
            title: const Text('العربية', textDirection: TextDirection.rtl),
            selected: languageSettings.selected.languageCode == 'ar',
            onTap: () => Navigator.pop(context, 'ar'),
          ),
        ]),
      ),
    );
    if (choice == null) return;
    try {
      await languageSettings.select(choice);
    } on Exception catch (error) {
      if (mounted) toast(context, '${strings(context).languageError} $error');
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appState,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            ScreenHeader(
                strings(context).settings, strings(context).settingsSubtitle),
            Panel(
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.language),
                  title: Text(strings(context).language),
                  subtitle: Text(languageSettings.selected.languageCode == 'ar'
                      ? 'العربية'
                      : 'English'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _chooseLanguage,
                ),
              ),
            ),
            sectionTitle(strings(context).profilePhoto),
            Panel(
              child: Row(children: [
                _photoPreview(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.profile.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(strings(context).photoPrivate,
                            style: TextStyle(color: kMuted, fontSize: 11)),
                        const SizedBox(height: 10),
                        Wrap(spacing: 8, runSpacing: 4, children: [
                          OutlinedButton.icon(
                            onPressed: _choosingPhoto ? null : _changePhoto,
                            icon: _choosingPhoto
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.add_a_photo_outlined,
                                    size: 16),
                            label: Text(_choosingPhoto
                                ? strings(context).opening
                                : strings(context).changePhoto),
                          ),
                          if (appState.profilePhotoBase64 != null)
                            TextButton(
                              onPressed: _choosingPhoto ? null : _removePhoto,
                              child: Text(strings(context).remove),
                            ),
                        ]),
                      ]),
                ),
              ]),
            ),
            sectionTitle(strings(context).appearance),
            Panel(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings(context).chooseTheme,
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      strings(context).savedDevice,
                      style: TextStyle(color: kMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 14),
                    for (final preset in AppThemePreset.values)
                      _themeChoice(preset),
                  ]),
            ),
          ],
        ),
      );
}
