import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

import '../../core/util/phone.dart';
import '../../data/database.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import 'contacts_helper.dart';

/// Keeps linked people's numbers in step with the phone's contacts.
///
/// Rules (from the acceptance criteria): never create duplicates, never
/// overwrite a number the user typed without telling them, and always leave
/// a small notice when something changes.
class ContactSync {
  ContactSync(this.repo);

  final Repository repo;
  static bool _running = false;

  Future<void> run() async {
    if (_running) return;
    _running = true;
    try {
      if (!await ContactsHelper.hasPermission()) return;
      for (final person in await repo.linkedPeople()) {
        await _syncOne(person);
      }
    } catch (e) {
      debugPrint('Contact sync skipped: $e');
    } finally {
      _running = false;
    }
  }

  Future<void> _syncOne(Person person) async {
    final contact = await ContactsHelper.get(person.contactId!, lookupKey: person.contactLookupKey);
    if (contact == null) {
      await repo.updatePerson(
          person.id, const PeopleCompanion(contactId: Value(null), contactLookupKey: Value(null)));
      await _notice(person, "${person.shortName}'s contact was removed from your phone. "
          'Smriti kept their details and unlinked it.');
      return;
    }
    if (contact.id != person.contactId || contact.lookupKey != person.contactLookupKey) {
      await repo.updatePerson(person.id,
          PeopleCompanion(contactId: Value(contact.id), contactLookupKey: Value(contact.lookupKey)));
    }
    final numbers = contact.numbers.map((n) => n.number).toList();
    if (numbers.isEmpty) return;
    final edited = person.editedFieldSet;

    // Call number
    final call = person.callNumber;
    if (call == null) {
      if (numbers.length == 1) {
        await repo.updatePerson(person.id, PeopleCompanion(callNumber: Value(numbers.first)));
        await _notice(person, "Added ${person.shortName}'s number from contacts: ${formatPhone(numbers.first)}.");
      }
    } else if (!numbers.contains(call)) {
      if (edited.contains('callNumber')) {
        await _notice(person, "${person.shortName}'s number changed in your contacts. "
            'Your saved number was kept. Open their profile to review.');
      } else if (numbers.length == 1) {
        await repo.updatePerson(person.id, PeopleCompanion(callNumber: Value(numbers.first)));
        await _notice(person,
            "Updated ${person.shortName}'s number to ${formatPhone(numbers.first)} from your contacts.");
      } else {
        await _notice(person, "${person.shortName}'s number changed in your contacts. "
            'Open their profile and tap Edit to choose the right one.');
      }
    }

    // WhatsApp number (only when set separately from the call number)
    final wa = person.whatsappNumber;
    if (wa != null && !numbers.contains(wa) && !edited.contains('whatsappNumber')) {
      if (numbers.length == 1) {
        await repo.updatePerson(person.id, const PeopleCompanion(whatsappNumber: Value(null)));
        await _notice(person,
            "${person.shortName}'s WhatsApp number now uses ${formatPhone(numbers.first)} from your contacts.");
      }
    }
  }

  Future<void> _notice(Person person, String message) async {
    final existing = await repo.db.select(repo.db.contactNotices).get();
    final dup = existing.any((n) => n.personId == person.id && n.message == message && !n.seen);
    if (!dup) await repo.addNotice(person.id, message);
  }
}
