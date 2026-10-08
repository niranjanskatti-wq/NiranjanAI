import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/constants.dart';
import '../../data/models.dart';
import '../../services/reminder_engine.dart';
import '../screens/item_detail_screen.dart';
import '../screens/location_detail_screen.dart';
import '../screens/reminders_screen.dart';
import 'common.dart';

/// One line in an item's movement history.
class MovementTile extends StatelessWidget {
  const MovementTile(this.m, {super.key, this.showItem = false});
  final Movement m;
  final bool showItem;

  static String describe(BuildContext context, Movement m) {
    final s = context.s;
    String where(int? loc, String? name, String? status) =>
        loc != null ? (name ?? '?') : s.status(status ?? '');
    switch (m.action) {
      case 'create':
        return s.t('move.created', {'to': where(m.toLocationId, m.toName, m.toStatus)});
      case 'deposit':
        return s.t('move.deposit', {'to': m.toName ?? ''});
      case 'withdraw':
        return s.t('move.withdraw', {'from': m.fromName ?? '', 'to': where(m.toLocationId, m.toName, m.toStatus)});
      case 'close':
        return s.t('move.close', {'from': m.fromName ?? '', 'to': m.toName ?? ''});
      default:
        if (m.toLocationId == null) return s.t('move.status', {'status': s.status(m.toStatus)});
        return s.t('move.moved', {'from': where(m.fromLocationId, m.fromName, m.fromStatus), 'to': m.toName ?? ''});
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (m.action) {
      'deposit' => (Icons.login, GV.gold),
      'withdraw' => (Icons.logout, const Color(0xFF4FC3F7)),
      'create' => (Icons.add_circle_outline, GV.ok),
      'close' => (Icons.lock_outline, GV.muted),
      _ => (Icons.swap_horiz, statusColor(m.toStatus)),
    };
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color)),
      title: Text(showItem ? '${m.itemName} · ${m.itemSerial}' : describe(context, m)),
      subtitle: Text([
        if (showItem) describe(context, m),
        Fmt.dateTime(m.at),
        if (m.note != null && m.action != 'create') m.note!,
      ].join('\n')),
      isThreeLine: showItem,
      onTap: showItem
          ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: m.itemId)))
          : null,
    );
  }
}

class DueTile extends StatelessWidget {
  const DueTile(this.d, {super.key, this.trailing, this.onTap});
  final DueItem d;
  final Widget? trailing;
  final VoidCallback? onTap;

  static (IconData, String) look(BuildContext context, DueKind k) => switch (k) {
        DueKind.rent => (Icons.receipt_long_outlined, context.t('rem.rent')),
        DueKind.notReturned => (Icons.assignment_return_outlined, context.t('rem.notReturned')),
        DueKind.plannedVisit => (Icons.event_available_outlined, context.t('rem.planned')),
        DueKind.custom => (Icons.alarm, context.t('rem.custom')),
        DueKind.keep => (Icons.login, context.t('rem.kind.keep')),
        DueKind.take => (Icons.logout, context.t('rem.kind.take')),
        DueKind.holiday => (Icons.beach_access_outlined, context.t('rem.holiday')),
      };

  @override
  Widget build(BuildContext context) {
    final overdue = d.isOverdue(DateTime.now());
    final (icon, label) = look(context, d.kind);
    final color = overdue ? GV.danger : (d.kind == DueKind.holiday ? const Color(0xFFEF9A9A) : GV.gold);
    final title = d.kind == DueKind.holiday
        ? context.t('hol.closedDays', {'n': d.days}) + (d.title.isEmpty ? '' : ' · ${d.title}')
        : d.title;
    final when = d.kind == DueKind.holiday
        ? (d.subtitle ?? Fmt.date(d.date))
        : (d.notifyAt.hour != 0 || d.notifyAt.minute != 0) && d.reminderId != null
            ? Fmt.dateTime(d.notifyAt)
            : Fmt.date(d.date);
    final extra = switch (d.kind) {
      DueKind.notReturned => context.t('rem.outSince', {'date': d.subtitle}),
      DueKind.holiday => context.t('hol.alertOn', {'date': Fmt.dateTime(d.notifyAt)}),
      DueKind.plannedVisit => null,
      _ => d.subtitle,
    };
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(d.alarm ? Icons.alarm_on : icon, color: color),
      ),
      title: Text(title),
      subtitle: Text('$label · $when${overdue ? ' · ${context.t('rem.overdue')}' : ''}${extra == null ? '' : '\n$extra'}'),
      isThreeLine: extra != null,
      trailing: trailing,
      onTap: onTap ??
          () {
            final Widget page = switch (d.kind) {
              DueKind.rent => LocationDetailScreen(locationId: d.locationId!),
              DueKind.notReturned => ItemDetailScreen(itemId: d.itemId!),
              _ => const RemindersScreen(),
            };
            Navigator.push(context, MaterialPageRoute(builder: (_) => page));
          },
    );
  }
}

class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.item, required this.photo, required this.locations, this.onTap, this.selected, this.index = 0});
  final Item item;
  final String? photo;
  final Map<int, Location> locations;
  final VoidCallback? onTap;
  final bool? selected;
  final int index;

  @override
  Widget build(BuildContext context) {
    final loc = item.locationId == null ? null : locations[item.locationId];
    final parent = loc?.parentId == null ? null : locations[loc!.parentId];
    final where = loc == null
        ? (item.statusNote ?? '')
        : (parent == null ? loc.name : '${parent.name} › ${loc.name}');
    final w = item.netWt ?? item.grossWt;
    return FadeIn(
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GoldCard(
          padding: const EdgeInsets.all(12),
          accent: selected == true ? GV.gold : null,
          onTap: onTap ?? () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id!))),
          child: Row(children: [
            Hero(tag: 'item-photo-${item.id}', child: PhotoThumb(photo, size: 72)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(item.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.w700)),
                  ),
                  if (item.needsDetails) const Icon(Icons.edit_note, color: GV.goldLight, size: 20),
                ]),
                const SizedBox(height: 3),
                Text(
                  [
                    item.serial,
                    context.s.opt(item.category),
                    if (item.purity != null && item.purity != '—') item.purity!,
                    if (w != null) Fmt.grams(w),
                    if (item.pieces > 1) context.t('dash.pcs', {'n': item.pieces}),
                  ].join(' · '),
                  style: const TextStyle(color: GV.muted, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  StatusChip(item.status),
                  const SizedBox(width: 8),
                  if (loc != null) ...[Dot(Color(loc.color), size: 9), const SizedBox(width: 5)],
                  Expanded(child: Text(where, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, color: GV.text))),
                ]),
              ]),
            ),
            if (selected != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(selected! ? Icons.check_circle : Icons.radio_button_unchecked, color: selected! ? GV.gold : GV.muted, size: 30),
              ),
          ]),
        ),
      ),
    );
  }
}

bool isActiveStatus(String s) => Opt.activeStatuses.contains(s);
