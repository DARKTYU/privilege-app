import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../state.dart';
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
              title: const Text('Choose from photos'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: kGold),
              title: const Text('Take a photo'),
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
        if (mounted) toast(context, 'Choose a smaller photo (under 900 KB).');
        return;
      }
      await appState.setProfilePhoto(bytes);
      if (mounted) toast(context, 'Profile photo updated.');
    } on PlatformException catch (error) {
      if (mounted) {
        toast(context,
            error.message ?? 'Could not open the camera or photo library.');
      }
    } on Exception catch (error) {
      if (mounted) toast(context, 'Could not save your profile photo: $error');
    } finally {
      if (mounted) setState(() => _choosingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    await appState.removeProfilePhoto();
    if (mounted) toast(context, 'Profile photo removed.');
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
            if (mounted) toast(context, 'Could not save your theme: $error');
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
                      preset.label,
                      style: TextStyle(
                        color: preset.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(preset.description,
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

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appState,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const ScreenHeader('Settings', 'Make Privilege feel like yours'),
            sectionTitle('Profile photo'),
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
                        Text('Stored privately on this device',
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
                            label: Text(
                                _choosingPhoto ? 'Opening…' : 'Change photo'),
                          ),
                          if (appState.profilePhotoBase64 != null)
                            TextButton(
                              onPressed: _choosingPhoto ? null : _removePhoto,
                              child: const Text('Remove'),
                            ),
                        ]),
                      ]),
                ),
              ]),
            ),
            sectionTitle('App appearance'),
            Panel(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a color theme',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Your selection is saved on this device.',
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
