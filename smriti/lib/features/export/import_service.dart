import 'package:drift/drift.dart' show Value;
import 'package:excel/excel.dart' as xl;

import '../../core/util/phone.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../../data/repository.dart';

enum ImportStatus { ready, duplicate, error }

/// One row from the file, checked but not yet saved.
class ImportRow {
  ImportRow({
    required this.sheet,
    required this.row,
    required this.summary,
    required this.status,
    this.problem,
    this.apply,
  });

  final String sheet;
  final int row;
  final String summary;
  final ImportStatus status;
  final String? problem;

  /// Saves the row. [ctx] shares people created earlier in the same import.
  final Future<void> Function(ImportContext ctx)? apply;
}

class ImportContext {
  ImportContext(this.repo);

  final Repository repo;
  final Map<String, int> peopleByName = {};
  Person? me;
}

/// Reads a Smriti (or hand-made) Excel file into rows to preview.
class ImportService {
  ImportService(this.db);

  final AppDatabase db;

  Future<List<ImportRow>> preview(List<int> bytes) async {
    final book = xl.Excel.decodeBytes(bytes);
    final repo = Repository(db);
    final people = await repo.allPeople();
    final entries = await repo.watchEntries().first;
    final byName = {for (final p in people) _key(p.name): p};
    final out = <ImportRow>[];
    final seenPeople = <String>{};
    final seenEvents = <String>{};

    Map<String, int> header(List<xl.Data?> row) => {
          for (var i = 0; i < row.length; i++)
            if (_text(row[i]).isNotEmpty) _text(row[i]).toLowerCase(): i,
        };

    // ---- People ----
    final pSheet = book.tables['People'];
    if (pSheet != null && pSheet.rows.isNotEmpty) {
      final h = header(pSheet.rows.first);
      for (var r = 1; r < pSheet.rows.length; r++) {
        final row = pSheet.rows[r];
        String v(String col) => h[col] == null || h[col]! >= row.length ? '' : _text(row[h[col]!]);
        final name = v('name');
        if (name.isEmpty) continue;
        final k = _key(name);
        if (byName.containsKey(k) || !seenPeople.add(k)) {
          out.add(ImportRow(sheet: 'People', row: r + 1, summary: name, status: ImportStatus.duplicate, problem: 'Already in Smriti'));
          continue;
        }
        final rel = _relation(v('relationship'));
        out.add(ImportRow(
          sheet: 'People',
          row: r + 1,
          summary: '$name · ${rel.$1.label}',
          status: ImportStatus.ready,
          apply: (ctx) async {
            final id = await ctx.repo.insertPerson(PeopleCompanion.insert(
              name: name,
              nickname: Value(_blank(v('nickname'))),
              relationship: Value(rel.$1.name),
              customRelationship: Value(rel.$2),
              stars: Value((int.tryParse(v('star rating')) ?? 3).clamp(1, 5)),
              birthYear: Value(int.tryParse(v('birth year'))),
              callNumber: Value(normalizePhone(v('phone'))),
              whatsappNumber: Value(_whatsapp(v('phone'), v('whatsapp number'))),
              timeZone: Value(_blank(v('time zone'))),
              notes: Value(_blank(v('notes'))),
              likes: Value(_blank(v('likes'))),
              dislikes: Value(_blank(v('dislikes'))),
              clothingSize: Value(_blank(v('clothing size'))),
              favouriteSweets: Value(_blank(v('favourite sweets'))),
              isArchived: Value(v('archived').toLowerCase() == 'yes'),
            ));
            ctx.peopleByName[k] = id;
            for (final g in v('gift ideas').split(';').map((s) => s.trim()).where((s) => s.isNotEmpty)) {
              await ctx.repo.addGift(id, g);
            }
            for (final g in v('group').split(RegExp(r'[,;]')).map((s) => s.trim()).where((s) => s.isNotEmpty)) {
              await ctx.repo.addToGroupNamed(id, g);
            }
          },
        ));
      }
    }

    // Existing events keyed for duplicate checks.
    for (final e in entries) {
      seenEvents.add(_eventKey(e.people.map((p) => p.name).join('&'), e.type, e.event.day, e.event.month, e.event.title));
    }

    // ---- All Events ----
    final eSheet = book.tables['All Events'];
    if (eSheet != null && eSheet.rows.isNotEmpty) {
      final h = header(eSheet.rows.first);
      for (var r = 1; r < eSheet.rows.length; r++) {
        final row = eSheet.rows[r];
        String v(String col) => h[col] == null || h[col]! >= row.length ? '' : _text(row[h[col]!]);
        xl.Data? cell(String col) => h[col] == null || h[col]! >= row.length ? null : row[h[col]!];
        final rawName = v('name');
        if (rawName.isEmpty) continue;
        final type = _type(v('event type'));
        final date = _date(cell('date'), day: int.tryParse(v('day')), month: int.tryParse(v('month')));
        if (type == null) {
          out.add(ImportRow(sheet: 'All Events', row: r + 1, summary: rawName, status: ImportStatus.error, problem: 'Unknown event type "${v('event type')}"'));
          continue;
        }
        if (date == null) {
          out.add(ImportRow(sheet: 'All Events', row: r + 1, summary: rawName, status: ImportStatus.error, problem: 'Date missing or not understood'));
          continue;
        }
        final names = rawName.split(' & ').map((s) => s.replaceAll(' (me)', '').trim()).where((s) => s.isNotEmpty).toList();
        final isMe = rawName.contains('(me)') || v('relationship').toLowerCase() == 'you';
        final repeat = _repeat(v('repeat'));
        final startYear = int.tryParse(v('start year')) ??
            (repeat == Repeat.once || type != EventType.birthday ? date.$3 : null);
        final key = _eventKey(names.join('&'), type, date.$1, date.$2, null);
        if (!seenEvents.add(key)) {
          out.add(ImportRow(
              sheet: 'All Events', row: r + 1, summary: '$rawName · ${type.label}', status: ImportStatus.duplicate, problem: 'Already in Smriti'));
          continue;
        }
        final rels = v('relationship').split(' & ');
        final nicks = v('nickname').split(' & ');
        out.add(ImportRow(
          sheet: 'All Events',
          row: r + 1,
          summary: '$rawName · ${type.label} · ${date.$1}-${date.$2}',
          status: ImportStatus.ready,
          apply: (ctx) async {
            final ids = <int>[];
            for (var i = 0; i < names.length; i++) {
              final k = _key(names[i]);
              if (isMe) {
                ctx.me ??= await ctx.repo.getMe();
                if (ctx.me != null) {
                  ids.add(ctx.me!.id);
                  continue;
                }
              }
              var id = ctx.peopleByName[k] ?? byName[k]?.id;
              if (id == null) {
                final rel = _relation(i < rels.length ? rels[i] : '');
                id = await ctx.repo.insertPerson(PeopleCompanion.insert(
                  name: names[i],
                  nickname: Value(i < nicks.length ? _blank(nicks[i]) : null),
                  relationship: Value(rel.$1.name),
                  customRelationship: Value(rel.$2),
                  stars: Value((int.tryParse(v('star rating')) ?? 3).clamp(1, 5)),
                  birthYear: Value(type == EventType.birthday ? int.tryParse(v('birth year')) ?? startYear : null),
                  callNumber: Value(names.length == 1 ? normalizePhone(v('phone')) : null),
                  whatsappNumber: Value(names.length == 1 ? _whatsapp(v('phone'), v('whatsapp number')) : null),
                ));
                ctx.peopleByName[k] = id;
              }
              ids.add(id);
            }
            await ctx.repo.saveEvent(
              data: EventsCompanion.insert(
                kind: ids.length > 1 ? EventKind.couple.name : EventKind.person.name,
                type: type.name,
                day: date.$1,
                month: date.$2,
                year: Value(type == EventType.birthday && repeat != Repeat.once ? null : startYear),
                repeat: Value(repeat.name),
                draftMessage: Value(_blank(v('saved message'))),
                notes: Value(_blank(v('notes'))),
              ),
              personIds: ids,
            );
          },
        ));
      }
    }

    // ---- Important Dates ----
    final iSheet = book.tables['Important Dates'];
    if (iSheet != null && iSheet.rows.isNotEmpty) {
      final h = header(iSheet.rows.first);
      for (var r = 1; r < iSheet.rows.length; r++) {
        final row = iSheet.rows[r];
        String v(String col) => h[col] == null || h[col]! >= row.length ? '' : _text(row[h[col]!]);
        xl.Data? cell(String col) => h[col] == null || h[col]! >= row.length ? null : row[h[col]!];
        final title = v('title');
        if (title.isEmpty) continue;
        final type = _type(v('category')) ?? EventType.otherDate;
        final date = _date(cell('date'), day: int.tryParse(v('day')), month: int.tryParse(v('month')));
        if (date == null) {
          out.add(ImportRow(sheet: 'Important Dates', row: r + 1, summary: title, status: ImportStatus.error, problem: 'Date missing or not understood'));
          continue;
        }
        final repeat = _repeat(v('repeat'));
        final key = _eventKey('', type, date.$1, date.$2, title);
        if (!seenEvents.add(key)) {
          out.add(ImportRow(sheet: 'Important Dates', row: r + 1, summary: title, status: ImportStatus.duplicate, problem: 'Already in Smriti'));
          continue;
        }
        final startYear = h.containsKey('start year')
            ? int.tryParse(v('start year'))
            : (repeat == Repeat.yearly ? null : date.$3);
        out.add(ImportRow(
          sheet: 'Important Dates',
          row: r + 1,
          summary: '$title · ${type.label} · ${date.$1}-${date.$2}',
          status: ImportStatus.ready,
          apply: (ctx) async => ctx.repo.saveEvent(
            data: EventsCompanion.insert(
              kind: EventKind.other.name,
              type: type.name,
              title: Value(title),
              day: date.$1,
              month: date.$2,
              year: Value(repeat == Repeat.once ? (startYear ?? date.$3) : startYear),
              repeat: Value(repeat.name),
              notes: Value(_blank(v('notes'))),
            ),
            personIds: const [],
          ),
        ));
      }
    }
    return out;
  }

  /// Saves every ready row; returns how many were added.
  Future<int> apply(List<ImportRow> rows) async {
    final ctx = ImportContext(Repository(db));
    var n = 0;
    await db.transaction(() async {
      // People first so events can use them.
      for (final r in rows.where((r) => r.status == ImportStatus.ready && r.sheet == 'People')) {
        await r.apply!(ctx);
        n++;
      }
      for (final r in rows.where((r) => r.status == ImportStatus.ready && r.sheet != 'People')) {
        await r.apply!(ctx);
        n++;
      }
    });
    return n;
  }

  // ---------- helpers ----------
  static String _key(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static String _eventKey(String names, EventType t, int d, int m, String? title) =>
      '${_key(names)}|${t.name}|$d|$m|${_key(title ?? '')}';

  static String? _blank(String s) => s.trim().isEmpty ? null : s.trim();

  static String? _whatsapp(String phone, String wa) {
    final w = normalizePhone(wa);
    return w == null || w == normalizePhone(phone) ? null : w;
  }

  static String _text(xl.Data? d) {
    final v = d?.value;
    return switch (v) {
      null => '',
      xl.TextCellValue() => v.value.toString().trim(),
      xl.IntCellValue() => '${v.value}',
      xl.DoubleCellValue() => v.value == v.value.roundToDouble() ? '${v.value.round()}' : '${v.value}',
      xl.DateCellValue() => '${v.day.toString().padLeft(2, '0')}-${v.month.toString().padLeft(2, '0')}-${v.year}',
      xl.DateTimeCellValue() => '${v.day.toString().padLeft(2, '0')}-${v.month.toString().padLeft(2, '0')}-${v.year}',
      _ => v.toString().trim(),
    };
  }

  /// (day, month, year?) from a date cell, DD-MM-YYYY text, or Day/Month columns.
  static (int, int, int?)? _date(xl.Data? d, {int? day, int? month}) {
    final v = d?.value;
    int? y;
    if (v is xl.DateCellValue) {
      y = v.year;
      if (day == null) return (v.day, v.month, v.year);
    } else if (v is xl.DateTimeCellValue) {
      y = v.year;
      if (day == null) return (v.day, v.month, v.year);
    } else if (v is xl.IntCellValue || v is xl.DoubleCellValue) {
      final n = v is xl.IntCellValue ? v.value : (v as xl.DoubleCellValue).value.round();
      final dt = DateTime.utc(1899, 12, 30).add(Duration(days: n));
      y = dt.year;
      if (day == null) return (dt.day, dt.month, dt.year);
    } else if (v != null) {
      final m = RegExp(r'^(\d{1,2})[-/.](\d{1,2})(?:[-/.](\d{2,4}))?$').firstMatch(_text(d));
      if (m != null) {
        final dd = int.parse(m.group(1)!), mm = int.parse(m.group(2)!);
        var yy = m.group(3) == null ? null : int.parse(m.group(3)!);
        if (yy != null && yy < 100) yy += yy > 50 ? 1900 : 2000;
        y = yy;
        if (day == null && mm >= 1 && mm <= 12 && dd >= 1 && dd <= 31) return (dd, mm, yy);
      }
    }
    if (day != null && month != null && month >= 1 && month <= 12 && day >= 1 && day <= 31) return (day, month, y);
    return null;
  }

  static (Relationship, String?) _relation(String s) {
    final t = s.trim().toLowerCase();
    if (t.isEmpty) return (Relationship.friend, null);
    for (final r in Relationship.values) {
      if (r.label.toLowerCase() == t || r.name.toLowerCase() == t) return (r, null);
    }
    const alias = {
      'appa': Relationship.father, 'dad': Relationship.father, 'amma': Relationship.mother, 'mom': Relationship.mother,
      'mum': Relationship.mother, 'brother-in-law': Relationship.inLaw, 'sister-in-law': Relationship.inLaw,
      'father-in-law': Relationship.inLaw, 'mother-in-law': Relationship.inLaw, 'grandpa': Relationship.grandfather,
      'grandma': Relationship.grandmother, 'best friend': Relationship.bestFriend,
    };
    return alias[t] != null ? (alias[t]!, null) : (Relationship.custom, s.trim());
  }

  static EventType? _type(String s) {
    final t = s.trim().toLowerCase();
    if (t.isEmpty) return null;
    for (final e in EventType.values) {
      if (e.label.toLowerCase() == t || e.name.toLowerCase() == t) return e;
    }
    if (t.contains('birth')) return EventType.birthday;
    if (t.contains('wedding') || t == 'anniversary') return EventType.weddingAnniversary;
    if (t.contains('insurance')) return EventType.insurance;
    return EventType.custom;
  }

  static Repeat _repeat(String s) {
    final t = s.trim().toLowerCase();
    if (t.contains('month')) return Repeat.monthly;
    if (t.contains('one') || t.contains('once')) return Repeat.once;
    return Repeat.yearly;
  }
}
