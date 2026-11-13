import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_client.dart';
import '../../state/session_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _studentNoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _pgNameCtrl = TextEditingController();
  final _pgContactCtrl = TextEditingController();
  final _pgEmailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  int _yearLevel = 11;
  String _section = '';
  bool _privacyConsent = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _studentNoCtrl.dispose();
    _emailCtrl.dispose();
    _contactCtrl.dispose();
    _pgNameCtrl.dispose();
    _pgContactCtrl.dispose();
    _pgEmailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_privacyConsent) {
      showSnack(context, 'Please agree to the Data Privacy Consent before registering.', error: true);
      return;
    }
    setState(() => _submitting = true);
    try {
      final msg = await context.read<SessionState>().register({
        'name': _nameCtrl.text.trim(),
        'student_number': _studentNoCtrl.text.trim(),
        'year_level': _yearLevel,
        'section': _section,
        'email': _emailCtrl.text.trim(),
        'contact_number': _contactCtrl.text.trim(),
        'parent_guardian_name': _pgNameCtrl.text.trim(),
        'parent_guardian_contact': _pgContactCtrl.text.trim(),
        'parent_guardian_email': _pgEmailCtrl.text.trim(),
        'password': _passCtrl.text,
        'confirm_password': _confirmPassCtrl.text,
        'privacy_consent': _privacyConsent,
      });
      if (!mounted) return;
      showSnack(context, msg.isEmpty ? 'Registration successful! You can now log in.' : msg);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Registration'),
      ),
      body: AsyncView<Map<String, dynamic>>(
        load: () async {
          final r = await ApiClient.instance.get('auth.php', query: {'action': 'sections'});
          return r.map;
        },
        builder: (context, data, _) {
          final sectionsMap = Map<String, dynamic>.from((data['sections'] ?? {}) as Map);
          final gradeSections = (sectionsMap['$_yearLevel'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          if (_section.isEmpty && gradeSections.isNotEmpty) {
            _section = str(gradeSections.first['value']);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const HeroCard(
                      title: 'Create Student Account',
                      subtitle: 'Cagasat High School Guidance Portal · Grades 7 to 12',
                    ),
                    const SectionTitle('Student Details'),
                    GsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Full Name *',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _studentNoCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Student Number / LRN *',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            key: ValueKey('reg_yl_$_yearLevel'),
                            initialValue: _yearLevel,
                            decoration: const InputDecoration(
                              labelText: 'Grade Level *',
                              prefixIcon: Icon(Icons.school_outlined),
                            ),
                            items: [
                              for (final g in [7, 8, 9, 10, 11, 12])
                                DropdownMenuItem(value: g, child: Text('Grade $g')),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() {
                                _yearLevel = v;
                                final list = (sectionsMap['$_yearLevel'] as List? ?? []);
                                _section = list.isNotEmpty ? str((list.first as Map)['value']) : '';
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          if (gradeSections.isNotEmpty)
                            DropdownButtonFormField<String>(
                              key: ValueKey('reg_sec_${_yearLevel}_$_section'),
                              initialValue: gradeSections.any((m) => str(m['value']) == _section)
                                  ? _section
                                  : str(gradeSections.first['value']),
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Section & Track/Strand *',
                                prefixIcon: Icon(Icons.class_outlined),
                              ),
                              items: [
                                for (final s in gradeSections)
                                  DropdownMenuItem(
                                    value: str(s['value']),
                                    child: Text(str(s['label']), overflow: TextOverflow.ellipsis),
                                  ),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _section = v);
                              },
                            ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address *',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _contactCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Student Contact Number',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SectionTitle('Parent / Guardian Emergency Contact'),
                    GsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _pgNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Parent / Guardian Full Name *',
                              prefixIcon: Icon(Icons.family_restroom_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _pgContactCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Parent / Guardian Contact Number *',
                              prefixIcon: Icon(Icons.call_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _pgEmailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Parent / Guardian Email (Optional)',
                              prefixIcon: Icon(Icons.alternate_email),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SectionTitle('Account Security & Privacy Consent'),
                    GsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _passCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password (min 6 characters) *',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _confirmPassCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirm Password *',
                              prefixIcon: Icon(Icons.verified_user_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _privacyConsent,
                            onChanged: (v) => setState(() => _privacyConsent = v ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                            title: const Text(
                              'I agree to the Data Privacy Act of 2012 (RA 10173) terms and authorize the Cagasat High School Guidance Office to process my information for guidance counseling services.',
                              style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                            ),
                          ),
                          const SizedBox(height: 12),
                          LoadingButton(
                            loading: _submitting,
                            onPressed: _submit,
                            icon: Icons.check_circle_outline,
                            label: 'Register Student Account',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
