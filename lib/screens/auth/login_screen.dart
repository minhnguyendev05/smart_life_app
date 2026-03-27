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
  bool _loginPasswordVisible = false;
  bool _registerPasswordVisible = false;

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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primaryContainer.withOpacity(0.55),
              scheme.surfaceContainerLowest,
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _LoginBackgroundPainter(
                  arcColor: scheme.outlineVariant.withOpacity(0.35),
                  cloudColor: scheme.surfaceContainerHighest.withOpacity(0.55),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Card(
                      elevation: 10,
                      shadowColor: scheme.shadow.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.35)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.login_rounded,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Sign in with email',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              FirebaseCoreService.isReady
                                  ? 'Đăng nhập để vào hệ thống quản lý học tập và tài chính của bạn.'
                                  : 'Firebase chưa sẵn sàng. Vui lòng kiểm tra cấu hình để đăng nhập.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _buildLoginTab(context, auth),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(child: Divider(color: scheme.outlineVariant)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    'Hoặc đăng nhập với',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: scheme.outlineVariant)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: auth.loading ? null : () => _signInWithGoogle(context),
                                    child: const Icon(Icons.g_mobiledata_rounded),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: auth.loading ? null : () => _showRegisterBottomSheet(context),
                              child: const Text('Chưa có tài khoản? Đăng ký'),
                            ),
                            if (auth.authError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  auth.authError!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: scheme.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginTab(BuildContext context, AuthProvider auth) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _loginEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: 'Email',
            prefixIcon: const Icon(Icons.mail_outline_rounded),
            filled: true,
            fillColor: scheme.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _loginPasswordCtrl,
          obscureText: !_loginPasswordVisible,
          onSubmitted: (_) => _signInWithEmail(context),
          decoration: InputDecoration(
            hintText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() => _loginPasswordVisible = !_loginPasswordVisible);
              },
              icon: Icon(
                _loginPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: scheme.onSurfaceVariant,
              ),
            ),
            filled: true,
            fillColor: scheme.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: auth.loading
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng quên mật khẩu sẽ có sớm.')),
                    );
                  },
            style: TextButton.styleFrom(
              foregroundColor: scheme.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: theme.textTheme.bodyMedium,
            ),
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.inverseSurface,
              foregroundColor: scheme.onInverseSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: auth.loading ? null : () => _signInWithEmail(context),
            child: Text(auth.loading ? 'Đang xử lý...' : 'Get Started'),
          ),
        ),
      ],
    );
  }

  Future<void> _showRegisterBottomSheet(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final scheme = Theme.of(context).colorScheme;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            4,
            16,
            MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _registerNameCtrl,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Họ tên',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  filled: true,
                  fillColor: scheme.surfaceContainerLow,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _registerEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                  filled: true,
                  fillColor: scheme.surfaceContainerLow,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _registerPasswordCtrl,
                obscureText: !_registerPasswordVisible,
                onSubmitted: (_) => _signUpWithEmail(context),
                decoration: InputDecoration(
                  labelText: 'Mật khẩu (tối thiểu 6 ký tự)',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(
                        () => _registerPasswordVisible = !_registerPasswordVisible,
                      );
                    },
                    icon: Icon(
                      _registerPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  filled: true,
                  fillColor: scheme.surfaceContainerLow,
                ),
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
          ),
        );
      },
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

class _LoginBackgroundPainter extends CustomPainter {
  _LoginBackgroundPainter({
    required this.arcColor,
    required this.cloudColor,
  });

  final Color arcColor;
  final Color cloudColor;

  @override
  void paint(Canvas canvas, Size size) {
    final arcPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height * 0.92);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * 0.9),
      3.6,
      1.4,
      false,
      arcPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * 0.65),
      3.7,
      1.2,
      false,
      arcPaint,
    );

    final cloudPaint = Paint()..color = cloudColor;
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.88), size.width * 0.2, cloudPaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.95), size.width * 0.3, cloudPaint);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.9), size.width * 0.22, cloudPaint);
  }

  @override
  bool shouldRepaint(covariant _LoginBackgroundPainter oldDelegate) {
    return oldDelegate.arcColor != arcColor || oldDelegate.cloudColor != cloudColor;
  }
}
