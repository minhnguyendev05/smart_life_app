import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/firebase_core_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _loginEmailCtrl = TextEditingController();
  final TextEditingController _loginPasswordCtrl = TextEditingController();
  final TextEditingController _registerNameCtrl = TextEditingController();
  final TextEditingController _registerEmailCtrl = TextEditingController();
  final TextEditingController _registerPasswordCtrl = TextEditingController();

  @override
  void dispose() {
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _registerNameCtrl.dispose();
    _registerEmailCtrl.dispose();
    _registerPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFEAF6FF), Color(0xFFF8FBFF)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  margin: const EdgeInsets.all(18),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          'SmartLife',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          FirebaseCoreService.isReady
                              ? 'Đăng nhập để vào hệ thống quản lý học tập và tài chính.'
                              : 'Firebase chưa sẵn sàng. Vui lòng kiểm tra cấu hình để đăng nhập.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        const TabBar(
                          tabs: [
                            Tab(text: 'Đăng nhập'),
                            Tab(text: 'Đăng ký'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 290,
                          child: TabBarView(
                            children: [
                              _buildLoginTab(context, auth),
                              _buildRegisterTab(context, auth),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: auth.loading ? null : () => _signInWithGoogle(context),
                            icon: const Icon(Icons.login),
                            label: const Text('Đăng nhập bằng Google'),
                          ),
                        ),
                        if (auth.authError != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            auth.authError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab(BuildContext context, AuthProvider auth) {
    return Column(
      children: [
        TextField(
          controller: _loginEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _loginPasswordCtrl,
          obscureText: true,
          onSubmitted: (_) => _signInWithEmail(context),
          decoration: const InputDecoration(labelText: 'Mật khẩu'),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: auth.loading ? null : () => _signInWithEmail(context),
            child: Text(auth.loading ? 'Đang xử lý...' : 'Đăng nhập'),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterTab(BuildContext context, AuthProvider auth) {
    return Column(
      children: [
        TextField(
          controller: _registerNameCtrl,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Họ tên'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _registerEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _registerPasswordCtrl,
          obscureText: true,
          onSubmitted: (_) => _signUpWithEmail(context),
          decoration: const InputDecoration(labelText: 'Mật khẩu (tối thiểu 6 ký tự)'),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: auth.loading ? null : () => _signUpWithEmail(context),
            child: Text(auth.loading ? 'Đang xử lý...' : 'Tạo tài khoản'),
          ),
        ),
      ],
    );
  }

  Future<void> _signInWithEmail(BuildContext context) async {
    final email = _loginEmailCtrl.text.trim();
    final password = _loginPasswordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ email và mật khẩu.')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithEmailPassword(
      email: email,
      password: password,
    );
    if (!ok && context.mounted && auth.authError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.authError!)),
      );
    }
  }

  Future<void> _signUpWithEmail(BuildContext context) async {
    final fullName = _registerNameCtrl.text.trim();
    final email = _registerEmailCtrl.text.trim();
    final password = _registerPasswordCtrl.text;
    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập họ tên, email và mật khẩu.')),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu cần tối thiểu 6 ký tự.')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.signUpWithEmailPassword(
      email: email,
      password: password,
      fullName: fullName,
    );
    if (!ok && context.mounted && auth.authError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.authError!)),
      );
    }
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (!ok && context.mounted && auth.authError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.authError!)),
      );
    }
  }
}
