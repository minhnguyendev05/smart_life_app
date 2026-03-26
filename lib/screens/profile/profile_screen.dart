import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin người dùng')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(provider.profile.fullName),
              subtitle: Text(provider.profile.email),
              trailing: Text(provider.profile.role.name.toUpperCase()),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              value: provider.biometricEnabled,
              onChanged: (_) => provider.toggleBiometric(),
              title: const Text('Biometric Lock theo module'),
              subtitle: const Text('Bật/Tắt bảo mật vân tay, FaceID'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Họ tên'),
                  ),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: provider.loading
                              ? null
                              : () async {
                                  await provider.signInWithEmailPassword(
                                    email: _emailCtrl.text.trim(),
                                    password: _passwordCtrl.text,
                                  );
                                },
                          child: const Text('Đăng nhập Email'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: provider.loading
                              ? null
                              : () async {
                                  await provider.signInWithGoogle();
                                },
                          icon: const Icon(Icons.login),
                          label: const Text('Google'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: provider.loading
                              ? null
                              : () async {
                                  await provider.signUpWithEmailPassword(
                                    email: _emailCtrl.text.trim(),
                                    password: _passwordCtrl.text,
                                    fullName: _nameCtrl.text.trim(),
                                  );
                                },
                          child: const Text('Đăng ký'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: provider.loading
                ? null
                : () async {
                    await provider.signOut();
                    if (!mounted) return;
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
