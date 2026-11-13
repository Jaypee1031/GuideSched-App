import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/* ------------------------------------------------------------------ */
/* Feedback helpers                                                    */
/* ------------------------------------------------------------------ */

void showSnack(BuildContext context, String message, {bool error = false}) {
  if (!context.mounted) return;
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: error ? AppColors.red : AppColors.primaryDark,
  ));
}

String errorText(Object e) => e is ApiException ? e.message : e.toString();

Future<bool> confirmDialog(BuildContext context,
    {required String title, required String message, String confirmLabel = 'Confirm', bool danger = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: danger ? FilledButton.styleFrom(backgroundColor: AppColors.red) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Runs [action] showing a snackbar for success/failure. Returns true on success.
Future<bool> runAction(BuildContext context, Future<ApiResult> Function() action, {String? successMessage}) async {
  try {
    final r = await action();
    if (context.mounted) {
      showSnack(context, successMessage ?? (r.message.isEmpty ? 'Done' : r.message));
    }
    return true;
  } catch (e) {
    if (context.mounted) showSnack(context, errorText(e), error: true);
    return false;
  }
}

/* ------------------------------------------------------------------ */
/* Layout pieces                                                       */
/* ------------------------------------------------------------------ */

class GsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  const GsCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionTitle(this.title, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryDark))),
          if (actionLabel != null) TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Green gradient hero card used at the top of dashboards.
class HeroCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? child;
  const HeroCard({super.key, required this.title, this.subtitle, this.trailing, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primaryMid, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (child != null) ...[const SizedBox(height: 14), child!],
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const StatTile({super.key, required this.label, required this.value, required this.icon, this.color = AppColors.primary, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Two-column responsive grid of widgets (stats etc.).
class TileGrid extends StatelessWidget {
  final List<Widget> children;
  final int columns;
  final double spacing;
  const TileGrid({super.key, required this.children, this.columns = 2, this.spacing = 12});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final slice = children.skip(i).take(columns).toList();
      while (slice.length < columns) {
        slice.add(const SizedBox());
      }
      rows.add(Padding(
        padding: EdgeInsets.only(bottom: spacing),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < slice.length; j++) ...[
                if (j > 0) SizedBox(width: spacing),
                Expanded(child: slice[j]),
              ],
            ],
          ),
        ),
      ));
    }
    return Column(children: rows);
  }
}

class StatusPill extends StatelessWidget {
  final String status;
  final String? label;
  const StatusPill(this.status, {super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
      child: Text(label ?? titleCase(status), style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 11.5)),
    );
  }
}

class TagChip extends StatelessWidget {
  final String text;
  final Color color;
  const TagChip(this.text, {super.key, this.color = AppColors.primaryMid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11.5)),
    );
  }
}

/// Date/time block shown at the left of appointment rows (e.g. `9:00 AM` / `Oct 21`).
class DateBlock extends StatelessWidget {
  final dynamic date;
  final dynamic time;
  const DateBlock({super.key, required this.date, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(fmtTime(time), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryDark, fontSize: 13)),
          const SizedBox(height: 2),
          Text(fmtDate(date, pattern: 'MMM d'), style: const TextStyle(color: AppColors.primaryMid, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const InfoRow(this.label, this.value, {super.key, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 118, child: Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13))),
          Expanded(
            child: Text(value.isEmpty ? '—' : value,
                style: TextStyle(fontSize: 13.5, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: AppColors.ink)),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------------------------------------------ */
/* Async states                                                        */
/* ------------------------------------------------------------------ */

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState({super.key, this.icon = Icons.inbox_outlined, required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: Icon(icon, size: 34, color: AppColors.primaryMid),
            ),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 14)),
            if (actionLabel != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 46, color: AppColors.faint),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loads data once, shows spinner/error, supports pull-to-refresh.
/// [builder] receives the data and a [reload] callback.
class AsyncView<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) builder;
  final bool scrollable; // wrap in RefreshIndicator + ListView when builder returns a non-scrollable
  const AsyncView({super.key, required this.load, required this.builder, this.scrollable = false});

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  T? _data;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload(initial: true);
  }

  Future<void> _reload({bool initial = false}) async {
    if (initial) setState(() => _loading = true);
    try {
      final d = await widget.load();
      if (!mounted) return;
      setState(() {
        _data = d;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _data == null) {
      return ErrorState(message: errorText(_error!), onRetry: () => _reload(initial: true));
    }
    final child = widget.builder(context, _data as T, () => _reload());
    if (widget.scrollable) {
      return RefreshIndicator(
        onRefresh: () => _reload(),
        child: child,
      );
    }
    return child;
  }
}

/* ------------------------------------------------------------------ */
/* Form helpers                                                        */
/* ------------------------------------------------------------------ */

class LoadingButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  const LoadingButton({super.key, required this.loading, required this.onPressed, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                Text(label),
              ],
            ),
    );
  }
}

/// Scrollable page body with consistent padding for pull-to-refresh lists.
class PageList extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  const PageList({super.key, required this.children, this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 90)});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      children: children,
    );
  }
}

/// Circle avatar with initials (no network image needed).
class InitialsAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final Color? background;
  const InitialsAvatar(this.name, {super.key, this.radius = 22, this.background});

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    final initials = parts.isEmpty ? '?' : (parts.length == 1 ? parts.first[0] : parts.first[0] + parts.last[0]).toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: background ?? AppColors.primaryLight,
      child: Text(initials, style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w800, fontSize: radius * 0.7)),
    );
  }
}
