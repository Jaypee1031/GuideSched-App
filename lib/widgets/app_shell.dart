import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../state/session_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'common.dart';

class NavDestination {
  final String title;
  final String? section;
  final IconData icon;
  final Widget Function(BuildContext context) builder;
  final bool showInBottomBar;

  const NavDestination({
    required this.title,
    required this.icon,
    required this.builder,
    this.section,
    this.showInBottomBar = false,
  });
}

class RoleShell extends StatefulWidget {
  final String portalLabel;
  final List<NavDestination> destinations;
  final int? notificationsIndex;
  final int? profileIndex;

  const RoleShell({
    super.key,
    required this.portalLabel,
    required this.destinations,
    this.notificationsIndex,
    this.profileIndex,
  });

  /// Switches the active destination of the nearest [RoleShell] by index.
  static void switchTo(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_RoleShellState>();
    state?.selectIndex(index);
  }

  /// Switches the active destination of the nearest [RoleShell] by matching [title] (case-insensitive substring).
  static void openByTitle(BuildContext context, String title) {
    final state = context.findAncestorStateOfType<_RoleShellState>();
    if (state == null) return;
    final needle = title.toLowerCase();
    final idx = state.widget.destinations.indexWhere((d) => d.title.toLowerCase().contains(needle));
    if (idx >= 0) {
      state.selectIndex(idx);
    }
  }

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  int _index = 0;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnread();
  }

  Future<void> _fetchUnread() async {
    try {
      final res = await ApiClient.instance.get('notifications.php', query: {'action': 'list'});
      if (!mounted) return;
      setState(() {
        _unreadCount = toInt(res.map['unread_count']);
      });
    } catch (_) {
      // Ignore badge errors silently
    }
  }

  void selectIndex(int i) {
    if (i < 0 || i >= widget.destinations.length) return;
    setState(() => _index = i);
    _fetchUnread();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionState>();
    final current = widget.destinations[_index];

    final bottomIndices = <int>[];
    for (var i = 0; i < widget.destinations.length; i++) {
      if (widget.destinations[i].showInBottomBar) {
        bottomIndices.add(i);
      }
    }
    final activeBottomPos = bottomIndices.indexOf(_index);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(current.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            Text(
              'GuideSched · ${widget.portalLabel}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          if (widget.notificationsIndex != null)
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => selectIndex(widget.notificationsIndex!),
              icon: Badge(
                isLabelVisible: _unreadCount > 0,
                label: Text(_unreadCount > 99 ? '99+' : '$_unreadCount'),
                backgroundColor: AppColors.red,
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
          if (widget.profileIndex != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => selectIndex(widget.profileIndex!),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: InitialsAvatar(session.name, radius: 16),
                ),
              ),
            ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primaryMid, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        session.initials,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.portalLabel.toUpperCase()} · Cagasat HS',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  children: _buildDrawerItems(context),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.red),
                title: const Text('Log Out', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
                onTap: () async {
                  Navigator.pop(context);
                  final ok = await confirmDialog(
                    context,
                    title: 'Log Out',
                    message: 'Are you sure you want to log out of GuideSched?',
                    confirmLabel: 'Log Out',
                    danger: true,
                  );
                  if (ok && context.mounted) {
                    await context.read<SessionState>().logout();
                  }
                },
              ),
            ],
          ),
        ),
      ),
      body: KeyedSubtree(
        key: ValueKey('dest_$_index'),
        child: current.builder(context),
      ),
      bottomNavigationBar: bottomIndices.length >= 2
          ? NavigationBar(
              backgroundColor: Colors.white,
              indicatorColor: AppColors.primaryLight,
              selectedIndex: activeBottomPos >= 0 ? activeBottomPos : 0,
              onDestinationSelected: (pos) => selectIndex(bottomIndices[pos]),
              destinations: [
                for (final idx in bottomIndices)
                  NavigationDestination(
                    icon: idx == widget.notificationsIndex && _unreadCount > 0
                        ? Badge(
                            label: Text('$_unreadCount'),
                            backgroundColor: AppColors.red,
                            child: Icon(widget.destinations[idx].icon),
                          )
                        : Icon(widget.destinations[idx].icon),
                    label: widget.destinations[idx].title,
                  ),
              ],
            )
          : null,
    );
  }

  List<Widget> _buildDrawerItems(BuildContext context) {
    final items = <Widget>[];
    String? lastSection;
    for (var i = 0; i < widget.destinations.length; i++) {
      final d = widget.destinations[i];
      if (d.section != null && d.section != lastSection) {
        lastSection = d.section;
        items.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
            child: Text(
              d.section!.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.faint, letterSpacing: 0.8),
            ),
          ),
        );
      }
      final selected = i == _index;
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: ListTile(
            dense: true,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            selected: selected,
            selectedTileColor: AppColors.primaryLight,
            selectedColor: AppColors.primaryDark,
            leading: Icon(d.icon, color: selected ? AppColors.primaryDark : AppColors.muted, size: 21),
            title: Text(
              d.title,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppColors.primaryDark : AppColors.ink,
                fontSize: 14,
              ),
            ),
            trailing: (i == widget.notificationsIndex && _unreadCount > 0)
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(12)),
                    child: Text('$_unreadCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  )
                : null,
            onTap: () {
              Navigator.pop(context);
              selectIndex(i);
            },
          ),
        ),
      );
    }
    return items;
  }
}
