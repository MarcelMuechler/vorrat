import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Stock/batch status ('ok' | 'expiring_soon' | 'expired', as returned by the
/// backend) -> the color used for it everywhere: the status dot, and the
/// swipe/delete backgrounds that share the same red/orange/green meaning.
/// Was duplicated between stock_overview_screen.dart and
/// product_batches_screen.dart before centralizing here (#141).
Color statusColor(String status) {
  switch (status) {
    case 'expired':
      return Colors.red;
    case 'expiring_soon':
      return Colors.orange;
    default:
      return Colors.green;
  }
}

/// Localized human word for [status] -- used as the a11y label/tooltip on
/// the status dot, since its color alone isn't conveyed to screen readers.
String statusLabel(AppLocalizations l10n, String status) {
  switch (status) {
    case 'expired':
      return l10n.statusExpired;
    case 'expiring_soon':
      return l10n.statusExpiringSoon;
    default:
      return l10n.statusOk;
  }
}

/// The small colored circle used in every stock/batch list row to show
/// status at a glance. Wrapped in [Tooltip] + [Semantics] so the status is
/// also reachable by screen readers and long-press/hover, not color alone.
Widget statusDot(BuildContext context, String status) {
  final label = statusLabel(AppLocalizations.of(context)!, status);
  return Tooltip(
    message: label,
    child: Semantics(
      label: label,
      child: CircleAvatar(backgroundColor: statusColor(status), radius: 6),
    ),
  );
}
