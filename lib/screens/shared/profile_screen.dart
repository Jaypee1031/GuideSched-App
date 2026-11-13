import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../services/api_client.dart';
import '../../state/session_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _studentNoCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _pgNameCtrl = TextEditingController();
  final _pgContactCtrl = TextEditingController();
  final _pgEmailCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();

  final _curPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  int _yearLevel = 11;
  String _section = '';
  String _specialization = 'Academic Counseling';
  bool _populated = false;
  bool _savingProfile = false;
  bool _savingPassword = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _studentNoCtrl.dispose();
    _contactCtrl.dispose();
    _pgNameCtrl.dispose();
    _pgContactCtrl.dispose();
    _pgEmailCtrl.dispose();
    _deptCtrl.dispose();
    _curPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _populateFromUser(Map<String, dynamic> user, Map<String, dynamic> sectionsMap, List<String> specs) {
    if (_populated) return;
    _populated = true;
    _nameCtrl.text = str(user['name']);
    _emailCtrl.text = str(user['email']);
    _studentNoCtrl.text = str(user['student_number']);
    _contactCtrl.text = str(user['contact_number']);
    _pgNameCtrl.text = str(user['parent_guardian_name'], str(user['parent_contact_name']));
    _pgContactCtrl.text = str(user['parent_guardian_contact'], str(user['parent_contact_number']));
    _pgEmailCtrl.text = str(user['parent_guardian_email']);
    _deptCtrl.text = str(user['department'], 'Office of the Principal');

    final yl = toInt(user['year_level'], 11);
    _yearLevel = (yl >= 7 && yl <= 12) ? yl : 11;

    final userSection = str(user['section'], str(user['course']));
    final listForGrade = (sectionsMap['$_yearLevel'] as List? ?? []);
    if (listForGrade.isNotEmpty) {
      final match = listForGrade.cast<Map>().where((m) => str(m['value']) == userSection).toList();
      _section = match.isNotEmpty ? userSection : str((listForGrade.first as Map)['value']);
    } else {
      _section = userSection;
    }

    final spec = str(user['specialization'], 'Academic Counseling');
    _specialization = specs.contains(spec) ? spec : (specs.isNotEmpty ? specs.first : 'Academic Counseling');
  }

  Future<void> _saveProfile(String role, Future<void> Function() reload) async {
    setState(() => _savingProfile = true);
    try {
      final body = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'contact_number': _contactCtrl.text.trim(),
      };
      if (role == 'student') {
        body['student_number'] = _studentNoCtrl.text.trim();
        body['year_level'] = _yearLevel;
        body['section'] = _section;
        body['parent_guardian_name'] = _pgNameCtrl.text.trim();
        body['parent_guardian_contact'] = _pgContactCtrl.text.trim();
        body['parent_guardian_email'] = _pgEmailCtrl.text.trim();
      } else if (role == 'counselor') {
        body['specialization'] = _specialization;
      } else if (role == 'principal') {
        body['department'] = _deptCtrl.text.trim();
      }

      final res = await ApiClient.instance.post('profile.php', query: {'action': 'update'}, body: body);
      if (!mounted) return;
      await context.read<SessionState>().refreshUser();
      if (!mounted) return;
      showSnack(context, res.message.isEmpty ? 'Profile updated!' : res.message);
      _populated = false;
      await reload();
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    setState(() => _savingPassword = true);
    try {
      final res = await ApiClient.instance.post(
        'profile.php',
        query: {'action': 'change_password'},
        body: {
          'current_password': _curPassCtrl.text,
          'new_password': _newPassCtrl.text,
          'confirm_password': _confirmPassCtrl.text,
        },
      );
      if (!mounted) return;
      _curPassCtrl.clear();
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
      showSnack(context, res.message.isEmpty ? 'Password changed!' : res.message);
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _editServerDialog() async {
    final ctrl = TextEditingController(text: AppConfig.address);
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Server Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the XAMPP PC IP address or host (e.g. 192.168.1.10 or localhost):',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Server IP / Host',
                hintText: '192.168.106.124',
              ),
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
        showSnack(context, 'Server address updated to ${AppConfig.address}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionState>();
    final role = session.role;

    return AsyncView<Map<String, dynamic>>(
      scrollable: true,
      load: () async {
        final r = await ApiClient.instance.get('profile.php', query: {'action': 'get'});
        return r.map;
      },
      builder: (context, data, reload) {
        final user = Map<String, dynamic>.from((data['user'] ?? session.user ?? {}) as Map);
        final sectionsMap = Map<String, dynamic>.from((data['sections'] ?? {}) as Map);
        final specs = (data['specializations'] as List? ?? ['Academic Counseling']).map((e) => e.toString()).toList();
        _populateFromUser(user, sectionsMap, specs);

        final stats = Map<String, dynamic>.from((data['stats'] ?? {}) as Map);
        final gradeSections = (sectionsMap['$_yearLevel'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        return PageList(
          children: [
            HeroCard(
              title: str(user['name'], session.name),
              subtitle: role == 'student'
                  ? '${str(user['section'], str(user['course'], 'Student'))} · LRN: ${str(user['student_number'], '—')}'
                  : role == 'counselor'
                      ? '${str(user['specialization'], 'Guidance Counselor')} · ID: ${str(user['user_id'])}'
                      : '${str(user['department'], 'Office of the Principal')} · ID: ${str(user['user_id'])}',
              trailing: InitialsAvatar(str(user['name'], session.name), radius: 24, background: Colors.white),
            ),
            if (role == 'student') ...[
              const SizedBox(height: 12),
              TileGrid(
                children: [
                  StatTile(
                    label: 'Total Sessions',
                    value: '${toInt(stats['total_appointments'])}',
                    icon: Icons.calendar_month_rounded,
                  ),
                  StatTile(
                    label: 'Completed',
                    value: '${toInt(stats['completed_appointments'])}',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.teal,
                  ),
                ],
              ),
              GsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoRow('Assigned Counselor', str(data['counselor_name'], 'Ms. Grace Fontanilla'), bold: true),
                    InfoRow('Last Guidance Visit', str(data['last_visit'], 'None yet')),
                    InfoRow('Account ID', str(user['user_id'])),
                  ],
                ),
              ),
            ],
            const SectionTitle('Edit Profile Information'),
            GsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                  ),
                  const SizedBox(height: 12),
                  if (role == 'student') ...[
                    TextField(
                      controller: _studentNoCtrl,
                      decoration: const InputDecoration(labelText: 'Student Number / LRN', prefixIcon: Icon(Icons.badge_outlined)),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      key: ValueKey('yl_$_yearLevel'),
                      initialValue: _yearLevel,
                      decoration: const InputDecoration(labelText: 'Grade Level', prefixIcon: Icon(Icons.school_outlined)),
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
                        key: ValueKey('sec_${_yearLevel}_$_section'),
                        initialValue: gradeSections.any((m) => str(m['value']) == _section)
                            ? _section
                            : str(gradeSections.first['value']),
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Section & Strand', prefixIcon: Icon(Icons.class_outlined)),
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
                  ],
                  if (role == 'counselor') ...[
                    DropdownButtonFormField<String>(
                      key: ValueKey('spec_$_specialization'),
                      initialValue: specs.contains(_specialization) ? _specialization : specs.first,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Title / Specialization', prefixIcon: Icon(Icons.workspace_premium_outlined)),
                      items: [
                        for (final s in specs) DropdownMenuItem(value: s, child: Text(s)),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _specialization = v);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (role == 'principal') ...[
                    TextField(
                      controller: _deptCtrl,
                      decoration: const InputDecoration(labelText: 'Department', prefixIcon: Icon(Icons.business_outlined)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _contactCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Contact Number', prefixIcon: Icon(Icons.phone_outlined)),
                  ),
                  if (role == 'student') ...[
                    const SizedBox(height: 18),
                    const Text(
                      'Parent / Guardian Emergency Contact',
                      style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryDark, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _pgNameCtrl,
                      decoration: const InputDecoration(labelText: 'Parent / Guardian Full Name', prefixIcon: Icon(Icons.family_restroom_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pgContactCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Parent / Guardian Contact Number', prefixIcon: Icon(Icons.call_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pgEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Parent / Guardian Email (Optional)', prefixIcon: Icon(Icons.alternate_email)),
                    ),
                  ],
                  const SizedBox(height: 18),
                  LoadingButton(
                    loading: _savingProfile,
                    onPressed: () => _saveProfile(role, reload),
                    icon: Icons.save_outlined,
                    label: 'Save Profile Changes',
                  ),
                ],
              ),
            ),
            const SectionTitle('Change Password'),
            GsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _curPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Current Password', prefixIcon: Icon(Icons.lock_outline)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New Password (min 6 chars)', prefixIcon: Icon(Icons.key_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm New Password', prefixIcon: Icon(Icons.verified_user_outlined)),
                  ),
                  const SizedBox(height: 16),
                  LoadingButton(
                    loading: _savingPassword,
                    onPressed: _changePassword,
                    icon: Icons.password_rounded,
                    label: 'Update Password',
                  ),
                ],
              ),
            ),
            const SectionTitle('Connection & Session'),
            GsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InfoRow('Server Address', AppConfig.address, bold: true),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _editServerDialog,
                    icon: const Icon(Icons.dns_outlined),
                    label: const Text('Change Server IP / Host'),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.red),
                    onPressed: () async {
                      final ok = await confirmDialog(
                        context,
                        title: 'Log Out',
                        message: 'Are you sure you want to log out?',
                        confirmLabel: 'Log Out',
                        danger: true,
                      );
                      if (ok && context.mounted) {
                        await context.read<SessionState>().logout();
                      }
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Log Out of GuideSched'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
