import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/layout/main_content.dart';
import '../../../components/layout/sidebar_menu.dart';
import '../../../core/core.dart';
import '../../../data/app_api.dart';
import '../../../data/directory.dart';
import '../../../data/session.dart';
import '../../nav.dart';

/// Picks an image and uploads it as the signed-in user's profile photo. Returns the new
/// image URL (or null when cancelled / failed — the failure is toasted).
Future<String?> pickAndUploadProfilePhoto(BuildContext context) async {
  final f = await FilePicker.pickFile(type: FileType.image);
  if (f == null || f.path == null) return null;
  if (((await f.length()) ?? 0) > 2 * 1024 * 1024) {
    if (context.mounted) AppToast.error(context, 'Photo must be 2MB or smaller');
    return null;
  }
  final r = await AppApi.client.postMultipart(ApiEndpoints.settingsProfilePhoto, files: [await http.MultipartFile.fromPath('file', f.path!, filename: f.name)]);
  if (!r.ok) {
    if (context.mounted) AppToast.error(context, r.message);
    return null;
  }
  await AppSession.instance.refresh();
  return r.data is Map ? (r.data as Map)['imageUrl'] as String? : null;
}

/// `/module/settings` — big avatar with the multicolour ring, name, e-mail, quick links.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _name = '';
  String _email = '';
  String? _avatar;
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await AppApi.client.get(ApiEndpoints.settingsProfile);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.ok && r.data is Map) {
        final u = Map<String, dynamic>.from(r.data as Map);
        _name = userFullName(u).isEmpty ? '${u['username']}' : userFullName(u);
        _email = '${u['email'] ?? ''}';
        _avatar = u['imageUrl'] as String?;
      }
    });
  }

  Future<void> _photo() async {
    setState(() => _uploading = true);
    final url = await pickAndUploadProfilePhoto(context);
    if (!mounted) return;
    setState(() {
      _uploading = false;
      if (url != null) _avatar = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    return MainContent(
      title: 'Settings',
      backHref: '/module',
      sidebarMenu: settingsMenu,
      onRefresh: _load,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                width: 160,
                height: 160,
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(colors: [Color(0xFFEA4335), Color(0xFFFBBC05), Color(0xFF34A853), Color(0xFF4285F4), Color(0xFFEA4335)]),
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: c.background),
                  child: ClipOval(
                    child: _loading
                        ? const AppSkeleton.circle(size: 144)
                        : _avatar != null
                            ? Opacity(opacity: _uploading ? 0.5 : 1, child: Image.network(_avatar!, fit: BoxFit.cover, width: 144, height: 144, errorBuilder: (_, _, _) => _initials()))
                            : _initials(),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: Material(
                  color: c.background,
                  shape: CircleBorder(side: BorderSide(color: c.border)),
                  elevation: 2,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _uploading || _loading ? null : _photo,
                    child: SizedBox(width: 40, height: 40, child: _uploading ? const Padding(padding: EdgeInsets.all(10), child: AppSpinner(size: 18)) : Icon(LucideIcons.camera, size: 18, color: c.foreground)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(_loading ? '…' : _name, textAlign: TextAlign.center, style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(_email, style: t.bodyLarge?.copyWith(color: c.mutedForeground)),
          const SizedBox(height: 24),
          AppButton(label: 'Profile', variant: AppButtonVariant.outline, onPressed: () => AppNav.push(context, '/module/settings/profile')),
        ],
      ),
    );
  }

  Widget _initials() => Container(
        width: 144,
        height: 144,
        alignment: Alignment.center,
        color: TwColors.indigo600,
        child: Text(AppAvatar.initialsOf(_name), style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w700)),
      );
}
