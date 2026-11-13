import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../services/api_client.dart';
import '../../state/session_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      showSnack(context, 'Please enter your email and password.', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<SessionState>().login(email, pass);
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openServerSettings() async {
    final ctrl = TextEditingController(text: AppConfig.address);
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Server Connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the XAMPP PC IP address on your Wi-Fi (e.g. 192.168.106.124) or localhost:',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Server IP / Host',
                hintText: '192.168.106.124',
                prefixIcon: Icon(Icons.dns_outlined),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'API URL:\n${AppConfig.apiBaseUrl}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.faint),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (saved != null && mounted) {
      await AppConfig.saveAddress(saved);
      if (mounted) {
        setState(() {});
        showSnack(context, 'Server set to ${AppConfig.address}');
      }
    }
  }

  Future<void> _openForgotSheet() async {
    final ctrl = TextEditingController(text: _emailCtrl.text.trim());
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        var sending = false;
        return StatefulBuilder(
          builder: (ctx, setModalState) => Padding(
            padding: EdgeInsets.fromLTRB(20, 22, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Forgot Password?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                const SizedBox(height: 6),
                const Text(
                  'Enter your registered email address or visit the Cagasat High School Guidance Office to reset your account password.',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                ),
                const SizedBox(height: 16),
                LoadingButton(
                  loading: sending,
                  label: 'Request Password Reset',
                  icon: Icons.send_outlined,
                  onPressed: () async {
                    setModalState(() => sending = true);
                    try {
                      final r = await ApiClient.instance.post('auth.php', query: {'action': 'forgot'}, body: {'email': ctrl.text.trim()});
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) showSnack(context, r.message);
                    } catch (e) {
                      if (mounted) showSnack(context, errorText(e), error: true);
                    } finally {
                      if (ctx.mounted) setModalState(() => sending = false);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAnonymousFeedbackSheet() async {
    final tokenCtrl = TextEditingController();
    final commentsCtrl = TextEditingController();
    var rating = 5;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        var sending = false;
        return StatefulBuilder(
          builder: (ctx, setModalState) => Padding(
            padding: EdgeInsets.fromLTRB(20, 22, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Anonymous Session Feedback',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                        ),
                      ),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const Text(
                    'Have a feedback token from your completed counseling session? Submit your anonymous rating below.',
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: tokenCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Session Feedback Token',
                      hintText: 'Paste token from counselor...',
                      prefixIcon: Icon(Icons.vpn_key_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Overall Rating (1–5 Stars)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 1; i <= 5; i++)
                        IconButton(
                          iconSize: 34,
                          onPressed: () => setModalState(() => rating = i),
                          icon: Icon(
                            i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: AppColors.amber,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: commentsCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Comments (Optional)',
                      hintText: 'What went well? What could be better?',
                    ),
                  ),
                  const SizedBox(height: 16),
                  LoadingButton(
                    loading: sending,
                    label: 'Submit Anonymously',
                    icon: Icons.lock_outline,
                    onPressed: () async {
                      setModalState(() => sending = true);
                      try {
                        final r = await ApiClient.instance.post(
                          'auth.php',
                          query: {'action': 'anonymous_feedback'},
                          body: {
                            'token': tokenCtrl.text.trim(),
                            'rating': rating,
                            'comments': commentsCtrl.text.trim(),
                          },
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) showSnack(context, r.message);
                      } catch (e) {
                        if (mounted) showSnack(context, errorText(e), error: true);
                      } finally {
                        if (ctx.mounted) setModalState(() => sending = false);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _openServerSettings,
                      icon: const Icon(Icons.dns_outlined, size: 17),
                      label: Text('Server: ${AppConfig.address}', style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.primaryMid, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'GS',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'GuideSched',
                                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                                  ),
                                  Text(
                                    'Cagasat High School Guidance Office',
                                    style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Student, Counselor & Principal Guidance Appointment Portal',
                          style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  GsCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Sign In to Your Account',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Enter your school email and password to continue.',
                          style: TextStyle(fontSize: 13, color: AppColors.muted),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          onSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _openForgotSheet,
                            child: const Text('Forgot Password?'),
                          ),
                        ),
                        const SizedBox(height: 4),
                        LoadingButton(
                          loading: _loading,
                          onPressed: _submit,
                          icon: Icons.login_rounded,
                          label: 'Sign In',
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          icon: const Icon(Icons.person_add_alt_1_outlined),
                          label: const Text('Create Student Account'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _openAnonymousFeedbackSheet,
                    icon: const Icon(Icons.rate_review_outlined, size: 18),
                    label: const Text('Have a Session Token? Submit Anonymous Feedback'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
