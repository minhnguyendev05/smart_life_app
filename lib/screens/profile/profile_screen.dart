import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) {
      return;
    }
    final provider = context.read<AuthProvider>();
    _nameCtrl.text = provider.currentUser.displayName;
    _seeded = true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthProvider>();

    if (!provider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thông tin người dùng')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_circle_outlined, size: 56),
                const SizedBox(height: 12),
                const Text(
                  'Bạn chưa đăng nhập',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vui lòng đăng nhập ở màn hình xác thực để xem hồ sơ.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true)
                        .popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Về màn hình đăng nhập'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin người dùng')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: provider.currentUser.avatarUrl?.isNotEmpty == true
                        ? ClipOval(
                            key: const ValueKey('avatar-image'),
                            child: CachedNetworkImage(
                              imageUrl: provider.currentUser.avatarUrl!,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) {
                                return const CircleAvatar(
                                  radius: 26,
                                  child: Icon(Icons.person_outline),
                                );
                              },
                            ),
                          )
                        : const CircleAvatar(
                            key: ValueKey('avatar-placeholder'),
                            radius: 26,
                            child: Icon(Icons.person_outline),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.currentUser.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(provider.currentUser.email),
                        Text(
                          'userId: ${provider.userId}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(provider.profile.role.name.toUpperCase()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hồ sơ ứng dụng',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Tên hiển thị'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: provider.loading
                              ? null
                              : () async {
                                  await provider.updateProfileInfo(
                                    displayName: _nameCtrl.text,
                                  );
                                },
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Cập nhật hồ sơ'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: provider.loading
                              ? null
                              : () async {
                                  final picked = await FilePicker.platform.pickFiles(
                                    type: FileType.image,
                                    withData: true,
                                  );
                                  if (picked == null || picked.files.isEmpty) {
                                    return;
                                  }
                                  if (!context.mounted) {
                                    return;
                                  }
                                  final file = picked.files.first;
                                  final bytes = file.bytes;
                                  if (bytes == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Không đọc được dữ liệu ảnh. Hãy chọn ảnh nhỏ hơn hoặc thử ảnh khác.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  await provider.uploadAvatarAndSave(
                                    bytes: bytes,
                                    filename: file.name,
                                    preferredDisplayName: _nameCtrl.text,
                                  );
                                },
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('Upload avatar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              value: provider.biometricEnabled,
              onChanged: (_) => provider.toggleBiometric(),
              title: const Text('Khóa sinh trắc học'),
              subtitle: const Text('Bật/Tắt bảo mật vân tay, FaceID'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await provider.verifyBiometricForSensitiveAction();
              },
              icon: const Icon(Icons.fingerprint),
              label: const Text('Thử xác thực sinh trắc học'),
            ),
          ),
          if (provider.authError != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                provider.authError!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          if (provider.loading)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(),
            ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: provider.loading
                ? null
                : () async {
                    final navigator = Navigator.of(
                      context,
                      rootNavigator: true,
                    );
                    await provider.signOut();
                    if (!context.mounted) return;
                    Navigator.of(context, rootNavigator: true)
                        .popUntil((route) => route.isFirst);
                  },
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
