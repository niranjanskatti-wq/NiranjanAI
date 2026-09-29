import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/tokens.dart';
import '../data/database.dart';
import '../data/enums.dart';
import '../data/models.dart';

/// Round photo, or initials on a warm gradient.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({super.key, required this.person, this.size = 40, this.ring = false});

  final Person? person;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final p = person;
    final path = p?.photoPath;
    final hasPhoto = path != null && File(path).existsSync();
    final g = avatarGradients[(p?.name.hashCode ?? 0).abs() % avatarGradients.length];
    Widget inner = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasPhoto ? null : LinearGradient(colors: g, begin: Alignment.topLeft, end: Alignment.bottomRight),
        image: hasPhoto ? DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover) : null,
      ),
      alignment: Alignment.center,
      child: hasPhoto
          ? null
          : Text(
              p?.initials ?? '?',
              style: TextStyle(
                fontFamily: serif,
                fontFamilyFallback: fontFallback,
                fontWeight: FontWeight.w600,
                fontSize: size * 0.42,
                color: c.onGold,
              ),
            ),
    );
    if (!ring) return inner;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.gold, width: 1.5)),
      child: inner,
    );
  }
}

/// Avatar for an event: person photo, overlapping pair for couples, or a
/// coloured category icon for non-person events.
class EventAvatar extends StatelessWidget {
  const EventAvatar({super.key, required this.entry, this.size = 40, this.ring = false});

  final EventEntry entry;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    if (entry.kind == EventKind.other || entry.people.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: groupColor(entry.type.group),
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Icon(entry.type.icon, color: Colors.white, size: size * 0.5),
      );
    }
    if (entry.kind == EventKind.couple && entry.people.length > 1) {
      final s = size * 0.72;
      return SizedBox(
        width: size,
        height: size,
        child: Stack(children: [
          Positioned(left: 0, top: 0, child: PersonAvatar(person: entry.people[0], size: s)),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(color: context.c.bg, shape: BoxShape.circle),
              child: PersonAvatar(person: entry.people[1], size: s - 3),
            ),
          ),
        ]),
      );
    }
    return PersonAvatar(person: entry.primary, size: size, ring: ring);
  }
}

/// Read-only or tappable 1–5 star rating.
class Stars extends StatelessWidget {
  const Stars({super.key, required this.value, this.size = 12, this.onChanged});

  final int value;
  final double size;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          onChanged == null
              ? Icon(Icons.star_rounded, size: size, color: i <= value ? c.gold : c.line)
              : IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: '$i star${i == 1 ? '' : 's'}',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onChanged!(i);
                  },
                  icon: Icon(Icons.star_rounded, size: size, color: i <= value ? c.gold : c.line),
                ),
      ],
    );
  }
}

/// Small gold pill, e.g. "Turning 60!" with an optional sparkle.
class Badge2 extends StatelessWidget {
  const Badge2(this.label, {super.key, this.sparkle = false});

  final String label;
  final bool sparkle;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: c.gold, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (sparkle) ...[Icon(Icons.auto_awesome, size: 12, color: c.onGold), const SizedBox(width: 4)],
        Text(label,
            style: TextStyle(
                fontFamily: sans, fontSize: 11, fontWeight: FontWeight.w700, color: c.onGold, letterSpacing: 0.3)),
      ]),
    );
  }
}

/// Uppercase section label.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Row(children: [
          Expanded(child: Text(text.toUpperCase(), style: context.text.labelSmall)),
          ?trailing,
        ]),
      );
}

/// Friendly empty state with one clear next action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title, message;
  final String? actionLabel, secondaryLabel;
  final VoidCallback? onAction, onSecondary;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 40, color: c.goldText),
          const SizedBox(height: 12),
          Text(title, style: context.text.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(message,
              style: context.text.bodyMedium?.copyWith(color: c.muted), textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 20),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
          if (secondaryLabel != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Card with a small uppercase heading.
class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.title, required this.children, this.trailing});

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(child: Text(title.toUpperCase(), style: context.text.labelSmall)),
                ?trailing,
              ]),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      );
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
}

Future<bool> confirm(BuildContext context,
    {required String title, required String message, required String action, bool danger = false}) async {
  final c = context.c;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: danger ? TextButton.styleFrom(foregroundColor: c.alert) : null,
          child: Text(action),
        ),
      ],
    ),
  );
  return ok ?? false;
}
