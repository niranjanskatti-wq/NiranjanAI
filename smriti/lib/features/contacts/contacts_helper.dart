import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/util/phone.dart';

/// A phone number from a contact, with its label ("Mobile", "Work"…).
class ContactNumber {
  const ContactNumber(this.number, this.label);

  final String number; // normalised
  final String label;
}

/// The parts of a phone contact Smriti uses.
class PickedContact {
  PickedContact({
    required this.id,
    required this.name,
    required this.numbers,
    this.lookupKey,
    this.photo,
    this.birthday,
    this.anniversary,
  });

  final String id;
  final String name;
  final List<ContactNumber> numbers;
  final String? lookupKey;
  final Uint8List? photo;
  final fc.Event? birthday;
  final fc.Event? anniversary;

  static PickedContact from(fc.Contact c) {
    final seen = <String>{};
    final numbers = <ContactNumber>[];
    for (final ph in c.phones) {
      final n = normalizePhone(ph.number);
      if (n == null || !seen.add(n)) continue;
      numbers.add(ContactNumber(n, _phoneLabel(ph)));
    }
    fc.Event? find(fc.EventLabel l) => c.events.where((e) => e.label.label == l).firstOrNull;
    return PickedContact(
      id: c.id ?? '',
      name: (c.displayName?.trim().isNotEmpty ?? false) ? c.displayName!.trim() : 'Unnamed',
      numbers: numbers,
      lookupKey: c.android?.identifiers?.lookupKey,
      photo: c.photo?.fullSize ?? c.photo?.thumbnail,
      birthday: find(fc.EventLabel.birthday),
      anniversary: find(fc.EventLabel.anniversary),
    );
  }

  static String _phoneLabel(fc.Phone ph) {
    final custom = ph.label.customLabel;
    if (custom != null && custom.isNotEmpty) return custom;
    final n = ph.label.label.name;
    return n.isEmpty ? 'Phone' : n[0].toUpperCase() + n.substring(1);
  }
}

class ContactsHelper {
  static const pickProps = {
    fc.ContactProperty.name,
    fc.ContactProperty.phone,
    fc.ContactProperty.event,
    fc.ContactProperty.photoFullRes,
    fc.ContactProperty.photoThumbnail,
    fc.ContactProperty.identifiers,
  };

  static Future<bool> hasPermission() => fc.FlutterContacts.permissions.has(fc.PermissionType.read);

  /// Explains why, then asks for read-only contacts access.
  static Future<bool> ensurePermission(BuildContext context) async {
    if (await hasPermission()) return true;
    if (!context.mounted) return false;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Allow contacts?'),
        content: const Text(
          'Smriti reads your contacts to fill in names, photos, numbers and birthdays, '
          'and to keep numbers up to date. It never changes your contacts or sends them anywhere.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
        ],
      ),
    );
    if (go != true) return false;
    final status = await fc.FlutterContacts.permissions.request(fc.PermissionType.read);
    if (status == fc.PermissionStatus.granted || status == fc.PermissionStatus.limited) return true;
    if (status == fc.PermissionStatus.permanentlyDenied && context.mounted) {
      final open = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Contacts are turned off'),
          content: const Text('To use contacts, turn on "Contacts" for Smriti in your phone settings.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Open settings')),
          ],
        ),
      );
      if (open == true) await fc.FlutterContacts.permissions.openSettings();
    }
    return false;
  }

  /// Opens the phone's contact picker. Null if cancelled or not allowed.
  static Future<PickedContact?> pick(BuildContext context) async {
    if (!await ensurePermission(context)) return null;
    try {
      final c = await fc.FlutterContacts.native.showPicker(properties: pickProps);
      if (c == null) return null;
      // The picker may return a partial record; read the full contact by id.
      final full = c.id == null ? c : (await fc.FlutterContacts.get(c.id!, properties: pickProps) ?? c);
      return PickedContact.from(full);
    } on PlatformException {
      return null;
    }
  }

  /// Reads a contact by id, falling back to its Android lookup key when the
  /// id has changed (e.g. after the phone merged two contacts).
  static Future<PickedContact?> get(String id, {String? lookupKey, bool withPhoto = false}) async {
    final props = {
      fc.ContactProperty.name,
      fc.ContactProperty.phone,
      fc.ContactProperty.event,
      fc.ContactProperty.identifiers,
      if (withPhoto) ...[fc.ContactProperty.photoFullRes, fc.ContactProperty.photoThumbnail],
    };
    var c = await fc.FlutterContacts.get(id, properties: props);
    if (c == null && lookupKey != null) {
      c = await fc.FlutterContacts.get(lookupKey, properties: props, androidLookup: true);
    }
    return c == null ? null : PickedContact.from(c);
  }

  /// Every contact with name, numbers, dates and a small photo.
  static Future<List<PickedContact>> all() async {
    final list = await fc.FlutterContacts.getAll(properties: {
      fc.ContactProperty.name,
      fc.ContactProperty.phone,
      fc.ContactProperty.event,
      fc.ContactProperty.photoThumbnail,
      fc.ContactProperty.identifiers,
    });
    final out = list.map(PickedContact.from).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }
}

/// Saves photo bytes inside the app so they survive contact changes.
Future<String> savePhotoBytes(Uint8List bytes) async {
  final dir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'photos'));
  await dir.create(recursive: true);
  final file = File(p.join(dir.path, 'p_${DateTime.now().microsecondsSinceEpoch}.jpg'));
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

/// Copies a picked image file into the app's photo folder.
Future<String> savePhotoFile(String sourcePath) async {
  return savePhotoBytes(await File(sourcePath).readAsBytes());
}
