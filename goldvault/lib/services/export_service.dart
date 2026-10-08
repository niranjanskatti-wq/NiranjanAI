import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xl;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/format.dart';
import '../data/models.dart';
import '../data/repository.dart';
import 'report_data.dart';

/// Builds .xlsx and .pdf reports fully offline.
class ExportService {
  ExportService(this.repo, this.outDir);

  final VaultRepo repo;
  final Directory outDir;

  String _stamp() => Fmt.isoDateTime(DateTime.now()).replaceAll(':', '').replaceAll('T', '_');

  Future<File> excel() async {
    final tables = await ReportBuilder(repo).build();
    final book = xl.Excel.createExcel();
    final defaultSheet = book.getDefaultSheet() ?? 'Sheet1';
    final headStyle = xl.CellStyle(
      bold: true,
      fontColorHex: xl.ExcelColor.fromHexString('#E0B04B'),
      backgroundColorHex: xl.ExcelColor.fromHexString('#121C33'),
    );
    for (final t in tables) {
      final name = t.title.length > 31 ? t.title.substring(0, 31) : t.title;
      final sheet = book[name];
      sheet.appendRow(t.header.map((h) => xl.TextCellValue(h)).toList());
      for (var c = 0; c < t.header.length; c++) {
        sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0)).cellStyle = headStyle;
        sheet.setColumnWidth(c, c < 2 ? 22 : 15);
      }
      for (final r in t.rows) {
        sheet.appendRow(r.map(_cell).toList());
      }
    }
    if (defaultSheet != tables.first.title) {
      book.setDefaultSheet(tables.first.title);
      book.delete(defaultSheet);
    }
    final bytes = book.encode()!;
    await outDir.create(recursive: true);
    final f = File(p.join(outDir.path, 'GoldVault_${_stamp()}.xlsx'));
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }

  static xl.CellValue? _cell(Object? v) {
    if (v == null) return null;
    if (v is int) return xl.IntCellValue(v);
    if (v is double) return xl.DoubleCellValue(v);
    return xl.TextCellValue(v.toString());
  }

  /// A readable summary report (A4 landscape).
  Future<File> pdf({Uint8List? regularFont, Uint8List? boldFont, Uint8List? titleFont}) async {
    regularFont ??= (await rootBundle.load('assets/fonts/Lato-Regular.ttf')).buffer.asUint8List();
    boldFont ??= (await rootBundle.load('assets/fonts/Lato-Bold.ttf')).buffer.asUint8List();
    titleFont ??= (await rootBundle.load('assets/fonts/PlayfairDisplay.ttf')).buffer.asUint8List();
    final base = pw.Font.ttf(regularFont.buffer.asByteData());
    final bold = pw.Font.ttf(boldFont.buffer.asByteData());
    final title = pw.Font.ttf(titleFont.buffer.asByteData());

    final gold = PdfColor.fromHex('#B8892B');
    final navy = PdfColor.fromHex('#121C33');

    final items = (await repo.items(const ItemQuery())).where((i) => i.isActive).toList();
    final locs = await repo.locationMap();
    final rates = await repo.rates();
    final all = Totals();
    for (final i in items) {
      all.add(i, rates);
    }
    final byLoc = await repo.totalsByLocation();

    String locName(int? id) {
      final l = id == null ? null : locs[id];
      if (l == null) return '';
      final parent = l.parentId == null ? null : locs[l.parentId];
      return parent == null ? l.name : '${parent.name} › ${l.name}';
    }

    pw.Widget stat(String label, String value) => pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: gold, width: 0.8),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 14, color: navy)),
          ]),
        );

    pw.Widget table(List<String> header, List<List<String>> rows) => pw.TableHelper.fromTextArray(
          headers: header,
          data: rows,
          headerStyle: pw.TextStyle(font: bold, color: PdfColors.white, fontSize: 9),
          headerDecoration: pw.BoxDecoration(color: navy),
          cellStyle: const pw.TextStyle(fontSize: 8.5),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF7F2E6)),
          cellAlignment: pw.Alignment.centerLeft,
          border: null,
        );

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: base, bold: bold),
      title: 'GoldVault report',
      author: 'GoldVault',
    );
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      header: (c) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('GoldVault', style: pw.TextStyle(font: title, fontSize: 20, color: gold)),
        pw.Text(ReportBuilder.generatedLine(), style: const pw.TextStyle(fontSize: 9)),
      ]),
      footer: (c) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${c.pageNumber} of ${c.pagesCount} · Private & confidential',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ),
      build: (c) => [
        pw.SizedBox(height: 10),
        pw.Wrap(spacing: 10, runSpacing: 10, children: [
          stat('Ornaments', Fmt.number(all.items)),
          stat('Pieces', Fmt.number(all.pieces)),
          stat('Gold (net)', Fmt.grams(all.gold)),
          stat('Silver (net)', Fmt.grams(all.silver)),
          if (all.platinum > 0) stat('Platinum', Fmt.grams(all.platinum)),
          if (rates.isSet) stat('Estimated value', Fmt.rupees(all.value)),
        ]),
        if (rates.isSet)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6),
            child: pw.Text(
              'Rates used: 24K gold ${Fmt.rupees(rates.gold24)}/g · silver ${Fmt.rupees(rates.silver)}/g'
              '${rates.platinum > 0 ? ' · platinum ${Fmt.rupees(rates.platinum)}/g' : ''}. Estimate of metal value only.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ),
        pw.SizedBox(height: 16),
        pw.Text('By location', style: pw.TextStyle(font: title, fontSize: 14, color: navy)),
        pw.SizedBox(height: 6),
        table(
          ['Location', 'Items', 'Gold', 'Silver', if (rates.isSet) 'Est. value'],
          [
            for (final e in byLoc.entries)
              [
                e.key == null ? 'Out (worn / repair / lent / pledged)' : locName(e.key),
                Fmt.number(e.value.items),
                Fmt.grams(e.value.gold),
                Fmt.grams(e.value.silver),
                if (rates.isSet) Fmt.rupees(e.value.value),
              ],
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Text('Inventory', style: pw.TextStyle(font: title, fontSize: 14, color: navy)),
        pw.SizedBox(height: 6),
        table(
          ['Serial', 'Name', 'Category', 'Purity', 'Gross', 'Net', 'Pcs', 'Location / status', 'Owner', 'HUID'],
          [
            for (final i in items)
              [
                i.serial,
                i.name,
                i.category,
                i.purity ?? '',
                Fmt.decimal(i.grossWt),
                Fmt.decimal(i.netWt),
                '${i.pieces}',
                i.locationId != null ? locName(i.locationId) : '${statusLabelEn(i.status)} ${i.statusNote ?? ''}',
                i.owner ?? '',
                i.huid ?? '',
              ],
          ],
        ),
      ],
    ));
    await outDir.create(recursive: true);
    final f = File(p.join(outDir.path, 'GoldVault_Report_${_stamp()}.pdf'));
    await f.writeAsBytes(await doc.save(), flush: true);
    return f;
  }
}
