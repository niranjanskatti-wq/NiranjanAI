import 'dart:convert';

import 'package:archive/archive.dart';

/// A cell value: text, whole number or date (shown as DD-MM-YYYY).
sealed class XCell {
  const XCell();
}

class XText extends XCell {
  const XText(this.value);
  final String value;
}

class XNum extends XCell {
  const XNum(this.value);
  final num value;
}

class XDate extends XCell {
  const XDate(this.year, this.month, this.day);
  final int year, month, day;
}

class XSheet {
  XSheet(this.name, {required this.columns, this.widths = const []});

  final String name;
  final List<String> columns;
  final List<double> widths;
  final List<List<XCell?>> rows = [];

  /// Rows written in bold (e.g. month headings).
  final Set<int> boldRows = {};

  void add(List<XCell?> row, {bool bold = false}) {
    if (bold) boldRows.add(rows.length);
    rows.add(row);
  }
}

/// Minimal, standards-compliant .xlsx writer: bold frozen header row,
/// column widths, real dates formatted DD-MM-YYYY. Opens in Excel, Google
/// Sheets and WPS Office.
class XlsxWriter {
  static List<int> build(List<XSheet> sheets) {
    final a = Archive();
    void put(String path, String xml) {
      final bytes = utf8.encode(xml);
      a.addFile(ArchiveFile(path, bytes.length, bytes));
    }

    put('[Content_Types].xml', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
${[for (var i = 1; i <= sheets.length; i++) '<Override PartName="/xl/worksheets/sheet$i.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'].join('\n')}
<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>''');
    put('_rels/.rels', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>''');
    put('docProps/core.xml', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<dc:title>Smriti export</dc:title><dc:creator>Smriti</dc:creator>
</cp:coreProperties>''');
    put('docProps/app.xml', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"><Application>Smriti</Application></Properties>''');
    put('xl/workbook.xml', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
<sheets>${[for (var i = 0; i < sheets.length; i++) '<sheet name="${_esc(sheets[i].name)}" sheetId="${i + 1}" r:id="rId${i + 1}"/>'].join()}</sheets>
</workbook>''');
    put('xl/_rels/workbook.xml.rels', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
${[for (var i = 1; i <= sheets.length; i++) '<Relationship Id="rId$i" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet$i.xml"/>'].join('\n')}
<Relationship Id="rId${sheets.length + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''');
    // Styles: 0 normal, 1 bold header (gold fill), 2 date DD-MM-YYYY, 3 bold.
    put('xl/styles.xml', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<numFmts count="1"><numFmt numFmtId="164" formatCode="dd\\-mm\\-yyyy"/></numFmts>
<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts>
<fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FFF1E4C6"/><bgColor indexed="64"/></patternFill></fill></fills>
<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="4">
<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>
<xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/>
<xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1" applyAlignment="1"><alignment vertical="top"/></xf>
<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>
</cellXfs>
<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>''');
    for (var i = 0; i < sheets.length; i++) {
      put('xl/worksheets/sheet${i + 1}.xml', _sheetXml(sheets[i]));
    }
    return ZipEncoder().encode(a)!;
  }

  static String _sheetXml(XSheet s) {
    final b = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
          '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
          'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">')
      ..write('<sheetViews><sheetView workbookViewId="0">'
          '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>'
          '<selection pane="bottomLeft" activeCell="A2" sqref="A2"/></sheetView></sheetViews>')
      ..write('<sheetFormatPr defaultRowHeight="15"/>');
    if (s.widths.isNotEmpty) {
      b.write('<cols>');
      for (var c = 0; c < s.widths.length; c++) {
        b.write('<col min="${c + 1}" max="${c + 1}" width="${s.widths[c]}" customWidth="1"/>');
      }
      b.write('</cols>');
    }
    b.write('<sheetData>');
    b.write('<row r="1">');
    for (var c = 0; c < s.columns.length; c++) {
      b.write('<c r="${_ref(c, 1)}" t="inlineStr" s="1"><is><t>${_esc(s.columns[c])}</t></is></c>');
    }
    b.write('</row>');
    for (var r = 0; r < s.rows.length; r++) {
      final rowNum = r + 2;
      final bold = s.boldRows.contains(r);
      b.write('<row r="$rowNum">');
      final row = s.rows[r];
      for (var c = 0; c < row.length; c++) {
        final v = row[c];
        if (v == null) continue;
        final ref = _ref(c, rowNum);
        switch (v) {
          case XText(:final value):
            if (value.isEmpty) continue;
            b.write('<c r="$ref" t="inlineStr"${bold ? ' s="3"' : ''}><is><t xml:space="preserve">${_esc(value)}</t></is></c>');
          case XNum(:final value):
            b.write('<c r="$ref"${bold ? ' s="3"' : ''}><v>$value</v></c>');
          case XDate():
            b.write('<c r="$ref" s="2"><v>${serial(v.year, v.month, v.day)}</v></c>');
        }
      }
      b.write('</row>');
    }
    b.write('</sheetData>');
    b.write('<autoFilter ref="A1:${_ref(s.columns.length - 1, s.rows.length + 1)}"/>');
    b.write('</worksheet>');
    return b.toString();
  }

  /// Excel's day number for a date (1900 date system).
  static int serial(int y, int m, int d) =>
      DateTime.utc(y, m, d).difference(DateTime.utc(1899, 12, 30)).inDays;

  static String _col(int c) {
    var s = '';
    var n = c + 1;
    while (n > 0) {
      final r = (n - 1) % 26;
      s = String.fromCharCode(65 + r) + s;
      n = (n - 1) ~/ 26;
    }
    return s;
  }

  static String _ref(int c, int r) => '${_col(c)}$r';

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
}
