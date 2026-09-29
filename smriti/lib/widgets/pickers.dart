import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/theme/tokens.dart';
import '../core/util/format.dart';
import '../core/util/phone.dart';
import '../data/enums.dart';
import '../features/contacts/contacts_helper.dart';

/// A day and month with an optional year.
class DateParts {
  const DateParts(this.day, this.month, [this.year]);

  final int day, month;
  final int? year;
}

/// Wheel picker for day, month and (optionally) year.
Future<DateParts?> pickDate(
  BuildContext context, {
  DateParts? initial,
  bool yearRequired = false,
  bool allowYear = true,
  String title = 'Pick a date',
}) {
  final now = DateTime.now();
  final minYear = 1900, maxYear = now.year + 15;
  var day = initial?.day ?? now.day;
  var month = initial?.month ?? now.month;
  int? year = initial?.year ?? (yearRequired ? now.year : null);
  // Year list: index 0 is "Not sure" when optional.
  final years = [for (var y = maxYear; y >= minYear; y--) y];
  final yearOffset = yearRequired ? 0 : 1;
  int yearIndex() => year == null ? 0 : years.indexOf(year!) + yearOffset;

  return showModalBottomSheet<DateParts>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) {
      final c = ctx.c;
      final style = TextStyle(fontFamily: sans, fontSize: 19, color: c.text, fontWeight: FontWeight.w600);
      return StatefulBuilder(
        builder: (ctx, setState) {
          final maxDay = month == 2 ? 29 : daysInMonthOf(month);
          if (day > maxDay) day = maxDay;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: ctx.text.headlineMedium),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 190,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: CupertinoPicker(
                            itemExtent: 38,
                            scrollController: FixedExtentScrollController(initialItem: day - 1),
                            onSelectedItemChanged: (i) => setState(() => day = i + 1),
                            children: [for (var d = 1; d <= 31; d++) Center(child: Text('$d', style: style))],
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: CupertinoPicker(
                            itemExtent: 38,
                            scrollController: FixedExtentScrollController(initialItem: month - 1),
                            onSelectedItemChanged: (i) => setState(() => month = i + 1),
                            children: [for (final m in monthNames) Center(child: Text(m, style: style))],
                          ),
                        ),
                        if (allowYear)
                          Expanded(
                            flex: 3,
                            child: CupertinoPicker(
                              itemExtent: 38,
                              scrollController: FixedExtentScrollController(initialItem: yearIndex()),
                              onSelectedItemChanged: (i) => setState(
                                  () => year = (!yearRequired && i == 0) ? null : years[i - yearOffset]),
                              children: [
                                if (!yearRequired)
                                  Center(child: Text('Year?', style: style.copyWith(color: c.muted))),
                                for (final y in years) Center(child: Text('$y', style: style)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (day > maxDay || (month == 2 && day == 29 && year != null && !_leap(year!)))
                    Text('That date does not exist.', style: TextStyle(color: c.alert)),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: (month == 2 && day == 29 && year != null && !_leap(year!))
                        ? null
                        : () => Navigator.pop(ctx, DateParts(day, month, allowYear ? year : null)),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

bool _leap(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

int daysInMonthOf(int month) => const [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1];

/// Grid of relationship choices.
Future<Relationship?> pickRelationship(BuildContext context, Relationship? current) =>
    showModalBottomSheet<Relationship>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Relationship', style: ctx.text.headlineMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in Relationship.choices)
                    ChoiceChip(
                      label: Text(r.label),
                      selected: r == current,
                      showCheckmark: false,
                      labelStyle: ctx.text.titleSmall?.copyWith(color: r == current ? ctx.c.bg : ctx.c.text),
                      onSelected: (_) => Navigator.pop(ctx, r),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

/// Searchable list of time zones with their current offset.
Future<String?> pickTimeZone(BuildContext context, String? current) => showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (ctx) => _TimeZoneSheet(current: current),
    );

class _TimeZoneSheet extends StatefulWidget {
  const _TimeZoneSheet({this.current});

  final String? current;

  @override
  State<_TimeZoneSheet> createState() => _TimeZoneSheetState();
}

class _TimeZoneSheetState extends State<_TimeZoneSheet> {
  static const popular = [
    'Asia/Kolkata', 'Asia/Dubai', 'Asia/Singapore', 'Europe/London', 'America/New_York',
    'America/Chicago', 'America/Los_Angeles', 'America/Toronto', 'Australia/Sydney', 'Asia/Tokyo',
    'Europe/Berlin', 'Asia/Riyadh', 'Asia/Qatar', 'Pacific/Auckland',
  ];
  String _q = '';

  String _offset(String name) {
    try {
      final off = tz.TZDateTime.now(tz.getLocation(name)).timeZoneOffset;
      final sign = off.isNegative ? '−' : '+';
      final m = off.inMinutes.abs();
      return 'GMT$sign${m ~/ 60}${m % 60 == 0 ? '' : ':${(m % 60).toString().padLeft(2, '0')}'}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = tz.timeZoneDatabase.locations.keys.where((k) => k.contains('/')).toList()..sort();
    final list = _q.isEmpty
        ? popular
        : all.where((z) => z.toLowerCase().replaceAll('_', ' ').contains(_q.toLowerCase())).toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: false,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search a city, e.g. London'),
                onChanged: (v) => setState(() => _q = v.trim()),
              ),
            ),
            ListTile(
              title: const Text('Same as mine'),
              trailing: widget.current == null ? Icon(Icons.check, color: context.c.goldText) : null,
              onTap: () => Navigator.pop(context, ''),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) => ListTile(
                  title: Text(list[i].split('/').last.replaceAll('_', ' ')),
                  subtitle: Text('${list[i]}  ·  ${_offset(list[i])}'),
                  trailing: list[i] == widget.current ? Icon(Icons.check, color: context.c.goldText) : null,
                  onTap: () => Navigator.pop(context, list[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lets the user pick which contact number to call and which is on WhatsApp.
Future<(String, String?)?> chooseNumbers(
  BuildContext context,
  List<ContactNumber> numbers, {
  String? currentCall,
  String? currentWhatsapp,
}) {
  var call = numbers.any((n) => n.number == currentCall) ? currentCall! : numbers.first.number;
  var wa = numbers.any((n) => n.number == currentWhatsapp) ? currentWhatsapp! : call;
  return showModalBottomSheet<(String, String?)>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        Widget group(String title, String value, ValueChanged<String> set) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Text(title.toUpperCase(), style: ctx.text.labelSmall),
                ),
                RadioGroup<String>(
                  groupValue: value,
                  onChanged: (v) => setState(() => set(v!)),
                  child: Column(children: [
                    for (final n in numbers)
                      RadioListTile<String>(
                        value: n.number,
                        title: Text(formatPhone(n.number)),
                        subtitle: Text(n.label),
                      ),
                  ]),
                ),
              ],
            );
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Choose numbers', style: ctx.text.headlineMedium),
                ),
                group('Call this number', call, (v) => call = v),
                group('WhatsApp number', wa, (v) => wa = v),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, (call, wa == call ? null : wa)),
                    child: const Text('Use these numbers'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
