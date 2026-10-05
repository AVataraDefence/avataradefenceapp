import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/layout/main_content.dart';
import '../../../../components/layout/sidebar_menu.dart';
import '../../../../core/core.dart';
import '../../../../data/app_api.dart';
import '../../../../data/session.dart';
import '../page.dart' show pickAndUploadProfilePhoto;

/// `/module/settings/profile` (web `settings/profile/page.tsx`).
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _first = TextEditingController();
  final _middle = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _username = TextEditingController();
  String? _avatar;
  String _error = '';
  String _success = '';
  bool _loading = true;
  bool _saving = false;
  bool _photoBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_first, _middle, _last, _email, _phone, _username]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(Map u) {
    _first.text = '${u['firstName'] ?? ''}';
    _middle.text = '${u['middleName'] ?? ''}';
    _last.text = '${u['lastName'] ?? ''}';
    _email.text = '${u['email'] ?? ''}';
    _phone.text = '${u['phoneNo'] ?? ''}';
    _username.text = '${u['username'] ?? ''}';
    _avatar = u['imageUrl'] as String?;
  }

  Future<void> _load() async {
    final r = await AppApi.client.get(ApiEndpoints.settingsProfile);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.ok && r.data is Map) {
        _fill(r.data as Map);
      } else {
        _error = r.message;
      }
    });
  }

  Future<void> _save() async {
    setState(() {
      _error = '';
      _success = '';
    });
    if (_first.text.trim().isEmpty) return setState(() => _error = 'First name is required');
    if (_last.text.trim().isEmpty) return setState(() => _error = 'Last name is required');
    if (_email.text.trim().isEmpty) return setState(() => _error = 'Email is required');
    setState(() => _saving = true);
    final r = await AppApi.client.put(ApiEndpoints.settingsProfile, body: {
      'firstName': _first.text.trim(),
      'middleName': _middle.text.trim(),
      'lastName': _last.text.trim(),
      'email': _email.text.trim(),
      'phoneNo': _phone.text.trim(),
    });
    if (!mounted) return;
    if (r.ok && r.data is Map) {
      _fill(r.data as Map);
      await AppSession.instance.refresh();
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (r.ok) {
        _success = 'Profile updated successfully';
      } else {
        _error = r.message;
      }
    });
  }

  Future<void> _changePhoto() async {
    setState(() => _photoBusy = true);
    final url = await pickAndUploadProfilePhoto(context);
    if (!mounted) return;
    setState(() {
      _photoBusy = false;
      if (url != null) _avatar = url;
    });
  }

  Future<void> _removePhoto() async {
    setState(() => _photoBusy = true);
    final r = await AppApi.client.delete(ApiEndpoints.settingsProfilePhoto);
    if (!mounted) return;
    if (r.ok) {
      await AppSession.instance.refresh();
      if (!mounted) return;
    } else {
      AppToast.error(context, r.message);
    }
    setState(() {
      _photoBusy = false;
      if (r.ok) _avatar = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final name = '${_first.text} ${_last.text}'.trim();
    return MainContent(
      title: 'Settings',
      backHref: '/module',
      sidebarMenu: settingsMenu,
      onRefresh: _load,
      child: _loading
          ? const Padding(padding: EdgeInsets.symmetric(vertical: 80), child: Center(child: AppSpinner(size: 24)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Profile', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('Update your personal profile information.', style: t.bodyMedium?.copyWith(color: c.mutedForeground)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_error.isNotEmpty) ...[AppAlert(title: _error, variant: AppAlertVariant.destructive), const SizedBox(height: 16)],
                if (_success.isNotEmpty) ...[AppAlert(title: _success, variant: AppAlertVariant.success), const SizedBox(height: 16)],
                AppCard(
                  title: 'Profile Photo',
                  description: 'JPG, PNG or GIF. Max size 2MB.',
                  headerDivider: true,
                  child: Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Opacity(opacity: _photoBusy ? 0.5 : 1, child: AppAvatar(name: name, imageUrl: _avatar, color: TwColors.indigo600, size: AppAvatarSize.lg)),
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle, border: Border.all(color: c.background, width: 2)),
                              child: Icon(LucideIcons.camera, size: 12, color: c.primaryForeground),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                            Text(_email.text, style: t.bodySmall),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 16,
                              children: [
                                GestureDetector(
                                  onTap: _photoBusy ? null : _changePhoto,
                                  child: Text(_photoBusy ? 'Working…' : (_avatar != null ? 'Change photo' : 'Upload new photo'), style: t.bodySmall?.copyWith(color: c.primary)),
                                ),
                                if (_avatar != null)
                                  GestureDetector(onTap: _photoBusy ? null : _removePhoto, child: Text('Remove', style: t.bodySmall?.copyWith(color: c.destructive))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  title: 'Personal Information',
                  description: 'Update your name and contact details.',
                  headerDivider: true,
                  child: Column(
                    children: [
                      AppInput(controller: _first, label: 'First Name', hint: 'First name', onChanged: (_) => setState(() {})),
                      const SizedBox(height: 16),
                      AppInput(controller: _middle, label: 'Middle Name', hint: 'Middle name'),
                      const SizedBox(height: 16),
                      AppInput(controller: _last, label: 'Last Name', hint: 'Last name', onChanged: (_) => setState(() {})),
                      const SizedBox(height: 16),
                      AppInput(controller: _email, label: 'Email Address', hint: 'Email', keyboardType: TextInputType.emailAddress, onChanged: (_) => setState(() {})),
                      const SizedBox(height: 16),
                      AppInput(controller: _phone, label: 'Phone Number', hint: '+91 00000 00000', keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                      AppInput(controller: _username, label: 'Username', enabled: false),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Align(alignment: Alignment.centerRight, child: AppButton(label: _saving ? 'Saving...' : 'Save Changes', loading: _saving, onPressed: _saving ? null : _save)),
              ],
            ),
    );
  }
}
