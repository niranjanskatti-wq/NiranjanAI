import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/tokens.dart';
import '../core/util/format.dart';

// ------------------------------------------------------------------ surfaces

/// Top bar for pages outside the tab shell: back pops, or goes to [fallback] when opened directly.
PreferredSizeWidget backBar(BuildContext context, {String? title, String fallback = '/'}) => AppBar(
      title: title == null ? null : Text(title),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Back',
        onPressed: () => context.canPop() ? context.pop() : context.go(fallback),
      ),
    );

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding, this.onTap, this.borderColor, this.color});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final content = Padding(padding: padding ?? EdgeInsets.all(context.density.pad), child: child);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? p.card,
        borderRadius: BorderRadius.circular(radiusCard),
        border: Border.all(color: borderColor ?? p.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: p.isDark ? 0.25 : 0.04), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      // A transparent Material so ink ripples from list tiles and buttons inside the card are visible.
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(radiusCard),
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

class CardHeader extends StatelessWidget {
  const CardHeader({super.key, required this.title, this.subtitle, this.icon, this.action});
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        if (icon != null) ...[Icon(icon, size: 17, color: p.muted), const SizedBox(width: 10)],
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(subtitle!, style: TextStyle(color: p.muted, fontSize: 13))),
          ]),
        ),
        ?action,
      ]),
    );
  }
}

/// Large page title with optional subtitle and trailing action.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.action, this.overline});
  final String title;
  final String? subtitle, overline;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (overline != null) Text(overline!, style: TextStyle(color: p.muted, fontSize: 14, fontWeight: FontWeight.w500)),
            if (overline != null) const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 30, height: 1.1)),
            if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(subtitle!, style: TextStyle(color: p.muted, fontSize: 14))),
          ]),
        ),
        ?action,
      ]),
    );
  }
}

/// Scrollable page body with consistent padding and max width.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.maxWidth = 720, this.bottomPadding = 32, this.controller});
  final List<Widget> children;
  final double maxWidth, bottomPadding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        controller: controller,
        padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPadding + MediaQuery.paddingOf(context).bottom),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical spacing that follows the density setting.
class Gap extends StatelessWidget {
  const Gap({super.key, this.size});
  final double? size;
  @override
  Widget build(BuildContext context) => SizedBox(height: size ?? context.density.gap, width: size ?? context.density.gap);
}

// ------------------------------------------------------------------ buttons

/// Subtle press feedback (scale down while pressed).
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.onLongPress, this.scale = 0.97});
  final Widget child;
  final VoidCallback? onTap, onLongPress;
  final double scale;
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      onLongPress: widget.onLongPress,
      child: AnimatedScale(scale: _down ? widget.scale : 1, duration: const Duration(milliseconds: 110), curve: Curves.easeOut, child: widget.child),
    );
  }
}

enum BtnKind { primary, secondary, ghost, danger, dangerGhost, subtle }

class Btn extends StatelessWidget {
  const Btn(this.label, {super.key, this.onPressed, this.icon, this.kind = BtnKind.secondary, this.expand = false, this.large = false, this.small = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final BtnKind kind;
  final bool expand, large, small;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final (bg, fg, border) = switch (kind) {
      BtnKind.primary => (p.accent, p.onAccent, Colors.transparent),
      BtnKind.secondary => (p.card2, p.fg, p.border),
      BtnKind.ghost => (Colors.transparent, p.fg, Colors.transparent),
      BtnKind.danger => (p.danger, Colors.white, Colors.transparent),
      BtnKind.dangerGhost => (Colors.transparent, p.danger, Colors.transparent),
      BtnKind.subtle => (p.accentSoft, p.accent, Colors.transparent),
    };
    final h = large ? 54.0 : small ? 34.0 : 44.0;
    final disabled = onPressed == null;
    final child = AnimatedOpacity(
      opacity: disabled ? 0.45 : 1,
      duration: const Duration(milliseconds: 150),
      child: Container(
        height: h,
        padding: EdgeInsets.symmetric(horizontal: small ? 12 : large ? 22 : 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radiusButton),
          border: Border.all(color: border),
          boxShadow: kind == BtnKind.primary && !disabled ? [BoxShadow(color: p.accent.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6), spreadRadius: -6)] : null,
        ),
        child: Row(mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[Icon(icon, size: small ? 15 : 18, color: fg), const SizedBox(width: 8)],
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: large ? 16 : small ? 13 : 14.5)),
          ),
        ]),
      ),
    );
    return Semantics(button: true, enabled: !disabled, label: label, child: Pressable(onTap: onPressed, child: child));
  }
}

class IconBtn extends StatelessWidget {
  const IconBtn(this.icon, {super.key, this.onPressed, this.tooltip, this.color, this.filled = false, this.size = 40});
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final w = Pressable(
      onTap: onPressed,
      scale: 0.9,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: filled ? p.accentSoft : Colors.transparent, shape: BoxShape.circle),
        child: Icon(icon, size: size * 0.48, color: color ?? (filled ? p.accent : p.muted)),
      ),
    );
    return Semantics(button: true, label: tooltip, child: tooltip == null ? w : Tooltip(message: tooltip!, child: w));
  }
}

// ------------------------------------------------------------------ chips, tags

class PillChip extends StatelessWidget {
  const PillChip({super.key, required this.label, this.active = false, this.onTap, this.leading, this.height = 34});
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final Widget? leading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Pressable(
      onTap: onTap,
      scale: 0.95,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: active ? p.accentSoft : p.card2.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? p.accent.withValues(alpha: 0.5) : p.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: active ? p.accent : p.muted, fontWeight: FontWeight.w500, fontSize: 13, fontFeatures: tabular)),
          ),
        ]),
      ),
    );
  }
}

class Dot extends StatelessWidget {
  const Dot(this.color, {super.key, this.size = 8});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class TagPill extends StatelessWidget {
  const TagPill(this.label, this.color, {super.key});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Dot(color, size: 6),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color.lerp(color, p.fg, 0.25))),
      ]),
    );
  }
}

/// iOS-style segmented control with a sliding highlight.
class Segmented<T> extends StatelessWidget {
  const Segmented({super.key, required this.value, required this.options, required this.onChanged, this.small = false});
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: p.card2.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(radiusButton), border: Border.all(color: p.border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final (v, label) in options)
            Pressable(
              onTap: () => onChanged(v),
              scale: 0.96,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(horizontal: small ? 10 : 14, vertical: small ? 5 : 7),
                decoration: BoxDecoration(
                  color: v == value ? p.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: v == value ? p.border : Colors.transparent),
                  boxShadow: v == value ? [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 1))] : null,
                ),
                child: Text(label,
                    style: TextStyle(
                      fontSize: small ? 12 : 13,
                      fontWeight: FontWeight.w500,
                      color: v == value ? p.fg : p.muted,
                      fontFeatures: tabular,
                    )),
              ),
            ),
        ]),
      ),
    );
  }
}

class ProgressLine extends StatelessWidget {
  const ProgressLine({super.key, required this.value, this.color, this.height = 6});
  final double value;
  final Color? color;
  final double height;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: height,
        child: Stack(children: [
          Container(color: p.border.withValues(alpha: 0.8)),
          LayoutBuilder(
            builder: (c, cons) => TweenAnimationBuilder<double>(
              tween: Tween(end: value.clamp(0, 1)),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (c, v, _) => Container(width: cons.maxWidth * v, color: color ?? p.accent),
            ),
          ),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------------ settings rows

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.title, required this.children, this.action, this.description});
  final String title;
  final String? description;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title.toUpperCase(), style: TextStyle(color: p.muted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                if (description != null) Padding(padding: const EdgeInsets.only(top: 3), child: Text(description!, style: TextStyle(color: p.muted, fontSize: 13))),
              ]),
            ),
            ?action,
          ]),
        ),
        AppCard(
          padding: EdgeInsets.symmetric(horizontal: context.density.pad),
          child: Column(children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1) Divider(color: p.border.withValues(alpha: 0.7)),
            ],
          ]),
        ),
      ]),
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({super.key, required this.label, this.description, this.trailing, this.below, this.onTap});
  final String label;
  final String? description;
  final Widget? trailing;
  final Widget? below;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500)),
              if (description != null) Padding(padding: const EdgeInsets.only(top: 3), child: Text(description!, style: TextStyle(color: p.muted, fontSize: 13, height: 1.35))),
            ]),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            // Shrink wide controls rather than overflow on narrow phones.
            Flexible(child: Align(alignment: Alignment.centerRight, child: FittedBox(fit: BoxFit.scaleDown, child: trailing!))),
          ],
        ]),
        if (below != null) Padding(padding: const EdgeInsets.only(top: 12), child: below!),
      ]),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}

class SwitchRow extends StatelessWidget {
  const SwitchRow({super.key, required this.label, this.description, required this.value, required this.onChanged});
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) => SettingsRow(
        label: label,
        description: description,
        trailing: Switch(value: value, onChanged: onChanged),
        onTap: onChanged == null ? null : () => onChanged!(!value),
      );
}

/// A tappable time value that opens the time picker.
class TimeButton extends StatelessWidget {
  const TimeButton({super.key, required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Pressable(
      onTap: () async {
        final m = timeToMinutes(value);
        final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60));
        if (t != null) onChanged(minutesToTime(t.hour * 60 + t.minute));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: p.card2.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10), border: Border.all(color: p.border)),
        child: Text(formatClock(value), style: const TextStyle(fontWeight: FontWeight.w500, fontFeatures: tabular)),
      ),
    );
  }
}

class NumStepper extends StatelessWidget {
  const NumStepper({super.key, required this.value, required this.min, required this.max, required this.onChanged, this.suffix, this.step = 1});
  final int value, min, max, step;
  final ValueChanged<int> onChanged;
  final String? suffix;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconBtn(Icons.remove_rounded, size: 34, onPressed: value - step >= min ? () => onChanged(value - step) : null, tooltip: 'Decrease'),
      ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 36),
        child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, fontFeatures: tabular)),
      ),
      IconBtn(Icons.add_rounded, size: 34, onPressed: value + step <= max ? () => onChanged(value + step) : null, tooltip: 'Increase'),
      if (suffix != null) Padding(padding: const EdgeInsets.only(left: 2), child: Text(suffix!, style: TextStyle(color: p.muted, fontSize: 13))),
    ]);
  }
}

// ------------------------------------------------------------------ states

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.icon, required this.title, this.description, this.action});
  final IconData? icon;
  final String title;
  final String? description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(children: [
        if (icon != null)
          Container(
            width: 46,
            height: 46,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: p.card2, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: p.muted, size: 22),
          ),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
        if (description != null)
          Padding(padding: const EdgeInsets.only(top: 6), child: Text(description!, textAlign: TextAlign.center, style: TextStyle(color: p.muted, fontSize: 13.5, height: 1.4))),
        if (action != null) Padding(padding: const EdgeInsets.only(top: 16), child: action!),
      ]),
    );
  }
}

class LoadingBlock extends StatelessWidget {
  const LoadingBlock({super.key, this.height = 80});
  final double height;
  @override
  Widget build(BuildContext context) => Container(
        height: height,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: context.pal.card2, borderRadius: BorderRadius.circular(radiusCard)),
      );
}

class ErrorBlock extends StatelessWidget {
  const ErrorBlock(this.error, {super.key});
  final Object error;
  @override
  Widget build(BuildContext context) => AppCard(
        child: EmptyState(icon: Icons.error_outline_rounded, title: 'Something went wrong', description: '$error'),
      );
}

// ------------------------------------------------------------------ sheets, dialogs, toasts

Future<T?> showAppSheet<T>(BuildContext context, {required String title, String? description, required WidgetBuilder builder, List<Widget> Function(BuildContext)? actions}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) {
      final p = ctx.pal;
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.9),
              decoration: BoxDecoration(color: p.card.withValues(alpha: 0.9), border: Border(top: BorderSide(color: p.border))),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Center(child: Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 4, decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(2)))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 6),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: Theme.of(ctx).textTheme.titleLarge),
                    if (description != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(description, style: TextStyle(color: p.muted, fontSize: 14))),
                  ]),
                ),
                Flexible(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(22, 8, 22, 16), child: builder(ctx))),
                if (actions != null)
                  Container(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(ctx).bottom),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: p.border))),
                    child: Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: actions(ctx)),
                  )
                else
                  SizedBox(height: MediaQuery.paddingOf(ctx).bottom),
              ]),
            ),
          ),
        ),
      );
    },
  );
}

Future<bool> confirm(BuildContext context, {required String title, String? description, String confirmLabel = 'Confirm', bool danger = false, String? typeToConfirm}) async {
  final controller = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (ctx) {
      final p = ctx.pal;
      return StatefulBuilder(builder: (ctx, setState) {
        final blocked = typeToConfirm != null && controller.text.trim().toUpperCase() != typeToConfirm.toUpperCase();
        return AlertDialog(
          title: Text(title, style: Theme.of(ctx).textTheme.titleLarge),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (description != null) Text(description, style: TextStyle(color: p.muted, height: 1.4)),
            if (typeToConfirm != null) ...[
              const SizedBox(height: 14),
              Text.rich(TextSpan(children: [
                TextSpan(text: 'Type ', style: TextStyle(color: p.muted)),
                TextSpan(text: typeToConfirm, style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: ' to confirm.', style: TextStyle(color: p.muted)),
              ])),
              const SizedBox(height: 8),
              TextField(controller: controller, autofocus: true, onChanged: (_) => setState(() {})),
            ],
          ]),
          actions: [
            Btn('Cancel', kind: BtnKind.ghost, onPressed: () => Navigator.pop(ctx, false)),
            Btn(confirmLabel, kind: danger ? BtnKind.danger : BtnKind.primary, onPressed: blocked ? null : () => Navigator.pop(ctx, true)),
          ],
        );
      });
    },
  );
  return ok ?? false;
}

void toast(BuildContext context, String message, {bool error = false, String? actionLabel, VoidCallback? onAction}) {
  final p = context.pal;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? Icons.warning_amber_rounded : Icons.check_circle_rounded, size: 18, color: error ? p.warning : p.success),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ]),
      duration: const Duration(milliseconds: 2600),
      action: actionLabel == null ? null : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
    ));
}

Color colorFromHex(String hex) => parseHex(hex);
