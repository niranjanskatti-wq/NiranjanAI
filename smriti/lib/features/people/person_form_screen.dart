
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/util/occurrence.dart';
import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../core/util/phone.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/pickers.dart';
import '../contacts/contacts_helper.dart';

/// Add or edit a person. With [fromContacts], opens the contact picker first.
class PersonFormScreen extends ConsumerStatefulWidget {
  const PersonFormScreen({super.key, this.id, this.fromContacts = false, this.isMe = false});

  final int? id;
  final bool fromContacts;
  final bool isMe;

  @override
  ConsumerState<PersonFormScreen> createState() => _PersonFormScreenState();
}

class _PersonFormScreenState extends ConsumerState<PersonFormScreen> {
  final _name = TextEditingController();
  final _nickname = TextEditingController();
  final _customRel = TextEditingController();
  final _call = TextEditingController();
  final _whatsapp = TextEditingController();
  final _notes = TextEditingController();
  final _likes = TextEditingController();
  final _dislikes = TextEditingController();
  final _size = TextEditingController();
  final _sweets = TextEditingController();

  Person? _existing;
  bool _loading = true;
  Relationship _relation = Relationship.friend;
  int _stars = 3;
  int? _birthYear;
  String? _timeZone;
  bool _sameWhatsapp = true;
  String? _photoPath;
  Uint8List? _newPhoto;
  bool _photoRemoved = false;

  // Contact link
  String? _contactId, _lookupKey, _contactName;
  List<ContactNumber> _contactNumbers = const [];

  // New person only: dates to create with them
  DateParts? _birthday;
  DateParts? _anniversary;
  bool _saving = false;

  bool get _isEdit => widget.id != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_isEdit) {
      final p = await ref.read(repoProvider).getPerson(widget.id!);
      if (p != null) {
        _existing = p;
        _name.text = p.name;
        _nickname.text = p.nickname ?? '';
        _relation = p.relation;
        _customRel.text = p.customRelationship ?? '';
        _stars = p.stars;
        _birthYear = realYear(p.birthYear);
        _timeZone = p.timeZone;
        _call.text = formatPhone(p.callNumber);
        _sameWhatsapp = p.whatsappNumber == null;
        _whatsapp.text = formatPhone(p.whatsappNumber);
        _notes.text = p.notes ?? '';
        _likes.text = p.likes ?? '';
        _dislikes.text = p.dislikes ?? '';
        _size.text = p.clothingSize ?? '';
        _sweets.text = p.favouriteSweets ?? '';
        _photoPath = p.photoPath;
        _contactId = p.contactId;
        _lookupKey = p.contactLookupKey;
        if (_contactId != null && await ContactsHelper.hasPermission()) {
          final c = await ContactsHelper.get(_contactId!, lookupKey: _lookupKey);
          _contactName = c?.name;
          _contactNumbers = c?.numbers ?? const [];
        }
      }
    } else if (widget.isMe) {
      _relation = Relationship.self;
    }
    if (mounted) setState(() => _loading = false);
    if (widget.fromContacts && !_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickContact());
    }
  }

  Future<void> _pickContact() async {
    final picked = await ContactsHelper.pick(context);
    if (picked == null || !mounted) return;

    // Duplicate check: same contact or same number already saved.
    final all = await ref.read(repoProvider).allPeople();
    final dup = all.where((p) =>
        p.id != widget.id &&
        (p.contactId == picked.id ||
            picked.numbers.any((n) => n.number == p.callNumber || n.number == p.whatsappNumber)));
    if (dup.isNotEmpty && mounted) {
      final existing = dup.first;
      final open = await confirm(context,
          title: 'Already in Smriti',
          message: '${existing.name} is already saved with this contact or number. Open their profile instead?',
          action: 'Open profile');
      if (open && mounted) {
        context.pushReplacement('/person/${existing.id}');
        return;
      }
    }

    setState(() {
      _contactId = picked.id;
      _lookupKey = picked.lookupKey;
      _contactName = picked.name;
      _contactNumbers = picked.numbers;
      if (!_isEdit || _name.text.trim().isEmpty) _name.text = picked.name;
      if (picked.photo != null && (_photoPath == null || _photoRemoved)) {
        _newPhoto = picked.photo;
        _photoRemoved = false;
      }
      if (!_isEdit) {
        final b = picked.birthday;
        if (b != null && _birthday == null) {
          _birthday = DateParts(b.day, b.month, b.year);
          _birthYear ??= b.year;
        }
        final a = picked.anniversary;
        if (a != null && _anniversary == null) _anniversary = DateParts(a.day, a.month, a.year);
      }
    });
    if (picked.numbers.length == 1) {
      setState(() {
        _call.text = formatPhone(picked.numbers.first.number);
        _sameWhatsapp = true;
      });
    } else if (picked.numbers.length > 1 && mounted) {
      await _chooseNumbers();
    }
  }

  Future<void> _chooseNumbers() async {
    final r = await chooseNumbers(context, _contactNumbers,
        currentCall: normalizePhone(_call.text),
        currentWhatsapp: _sameWhatsapp ? null : normalizePhone(_whatsapp.text));
    if (r == null) return;
    setState(() {
      _call.text = formatPhone(r.$1);
      _sameWhatsapp = r.$2 == null;
      _whatsapp.text = formatPhone(r.$2);
    });
  }

  Future<void> _pickPhoto() async {
    final c = context.c;
    final choice = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery')),
          ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, 'camera')),
          if (_photoPath != null || _newPhoto != null)
            ListTile(
                leading: Icon(Icons.delete_outline, color: c.alert),
                title: Text('Remove photo', style: TextStyle(color: c.alert)),
                onTap: () => Navigator.pop(ctx, 'remove')),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (choice == null) return;
    if (choice == 'remove') {
      setState(() {
        _newPhoto = null;
        _photoRemoved = true;
      });
      return;
    }
    final x = await ImagePicker().pickImage(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 88,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() {
      _newPhoto = bytes;
      _photoRemoved = false;
    });
  }

  String? _clean(TextEditingController t) => t.text.trim().isEmpty ? null : t.text.trim();

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showToast(context, 'Please enter a name');
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(repoProvider);
    final call = normalizePhone(_call.text);
    final wa = _sameWhatsapp ? null : normalizePhone(_whatsapp.text);

    // Remember numbers typed by hand so contact sync never silently replaces them.
    final edited = {...?_existing?.editedFieldSet};
    final fromContact = _contactNumbers.map((n) => n.number).toSet();
    if (call != null && !fromContact.contains(call) && call != _existing?.callNumber) edited.add('callNumber');
    if (call != null && fromContact.contains(call)) edited.remove('callNumber');
    if (wa != null && !fromContact.contains(wa) && wa != _existing?.whatsappNumber) edited.add('whatsappNumber');
    if (wa == null || fromContact.contains(wa)) edited.remove('whatsappNumber');

    String? photo = _photoRemoved ? null : _photoPath;
    if (_newPhoto != null) photo = await savePhotoBytes(_newPhoto!);

    final data = PeopleCompanion(
      name: Value(name),
      nickname: Value(_clean(_nickname)),
      relationship: Value(_relation.name),
      customRelationship: Value(_relation == Relationship.custom ? _clean(_customRel) : null),
      stars: Value(_stars),
      birthYear: Value(_birthYear),
      timeZone: Value(_timeZone),
      callNumber: Value(call),
      whatsappNumber: Value(wa),
      notes: Value(_clean(_notes)),
      likes: Value(_clean(_likes)),
      dislikes: Value(_clean(_dislikes)),
      clothingSize: Value(_clean(_size)),
      favouriteSweets: Value(_clean(_sweets)),
      photoPath: Value(photo),
      contactId: Value(_contactId),
      contactLookupKey: Value(_lookupKey),
      editedFields: Value(edited.join(',')),
      isMe: Value(widget.isMe || (_existing?.isMe ?? false)),
    );

    int id;
    if (_isEdit) {
      id = widget.id!;
      await repo.updatePerson(id, data);
      if (realYear(_existing?.birthYear) != _birthYear) await repo.setBirthYear(id, _birthYear);
    } else {
      id = await repo.insertPerson(data);
      final kind = EventKind.person.name;
      if (_birthday != null) {
        await repo.saveEvent(
          data: EventsCompanion.insert(
            kind: kind,
            type: EventType.birthday.name,
            day: _birthday!.day,
            month: _birthday!.month,
            year: Value(_birthYear),
          ),
          personIds: [id],
        );
      }
      if (_anniversary != null) {
        await repo.saveEvent(
          data: EventsCompanion.insert(
            kind: kind,
            type: EventType.weddingAnniversary.name,
            day: _anniversary!.day,
            month: _anniversary!.month,
            year: Value(_anniversary!.year),
          ),
          personIds: [id],
        );
      }
    }
    HapticFeedback.lightImpact();
    if (!mounted) return;
    showToast(context, _isEdit ? 'Saved' : 'Added $name');
    if (_isEdit || widget.isMe) {
      context.pop();
    } else {
      context.pushReplacement('/person/$id');
    }
  }

  @override
  void dispose() {
    for (final t in [_name, _nickname, _customRel, _call, _whatsapp, _notes, _likes, _dislikes, _size, _sweets]) {
      t.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (_loading) return const Scaffold();
    final title = widget.isMe ? 'Your details' : (_isEdit ? 'Edit person' : 'Add person');
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          children: [
            Center(child: _photoWidget(c)),
            const SizedBox(height: 16),
            if (!widget.isMe) _contactCard(c),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nickname,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nickname', hintText: 'e.g. Appa, Chinnu'),
            ),
            if (!widget.isMe) ...[
              const SizedBox(height: 12),
              _tapField(
                label: 'Relationship',
                value: _relation.label,
                onTap: () async {
                  final r = await pickRelationship(context, _relation);
                  if (r != null) setState(() => _relation = r);
                },
              ),
              if (_relation == Relationship.custom) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _customRel,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Custom relationship', hintText: 'e.g. Godmother'),
                ),
              ],
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Text('How important?', style: context.text.titleMedium)),
                Stars(value: _stars, size: 28, onChanged: (v) => setState(() => _stars = v)),
              ]),
              Text('Only for sorting and filters. It never limits reminders.', style: context.text.bodySmall),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _call,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone number',
                hintText: '98450 12345',
                suffixIcon: _contactNumbers.length > 1
                    ? IconButton(
                        tooltip: 'Choose from contact',
                        onPressed: _chooseNumbers,
                        icon: const Icon(Icons.contact_phone_outlined))
                    : null,
              ),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: const Text('WhatsApp uses the same number'),
              value: _sameWhatsapp,
              onChanged: (v) => setState(() => _sameWhatsapp = v),
            ),
            if (!_sameWhatsapp)
              TextField(
                controller: _whatsapp,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'WhatsApp number'),
              ),
            if (!_isEdit) ...[
              const SizedBox(height: 16),
              _tapField(
                label: widget.isMe ? 'Your birthday' : 'Birthday',
                value: _birthday == null
                    ? 'Add'
                    : fmtEventDate(day: _birthday!.day, month: _birthday!.month, year: _birthday!.year),
                onTap: () async {
                  final d = await pickDate(context, initial: _birthday, title: 'Birthday');
                  if (d != null) {
                    setState(() {
                      _birthday = d;
                      if (d.year != null) _birthYear = d.year;
                    });
                  }
                },
                onClear: _birthday == null ? null : () => setState(() => _birthday = null),
              ),
              const SizedBox(height: 12),
              _tapField(
                label: widget.isMe ? 'Your wedding anniversary' : 'Wedding anniversary',
                value: _anniversary == null
                    ? 'Add'
                    : fmtEventDate(day: _anniversary!.day, month: _anniversary!.month, year: _anniversary!.year),
                onTap: () async {
                  final d = await pickDate(context, initial: _anniversary, title: 'Wedding anniversary');
                  if (d != null) setState(() => _anniversary = d);
                },
                onClear: _anniversary == null ? null : () => setState(() => _anniversary = null),
              ),
              if (!widget.isMe)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text('For a couple\'s anniversary, use + and "Couple event" instead.',
                      style: context.text.bodySmall),
                ),
            ],
            const SizedBox(height: 12),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                title: Text('More options', style: context.text.titleMedium),
                subtitle: Text('Birth year, time zone, notes, likes, sizes', style: context.text.bodySmall),
                childrenPadding: EdgeInsets.zero,
                children: [
                  _tapField(
                    label: 'Birth year',
                    value: _birthYear?.toString() ?? 'Not set',
                    onTap: _pickBirthYear,
                    onClear: _birthYear == null ? null : () => setState(() => _birthYear = null),
                  ),
                  const SizedBox(height: 12),
                  if (!widget.isMe) ...[
                    _tapField(
                      label: 'Time zone',
                      value: _timeZone == null ? 'Same as mine' : _timeZone!.replaceAll('_', ' '),
                      onTap: () async {
                        final z = await pickTimeZone(context, _timeZone);
                        if (z != null) setState(() => _timeZone = z.isEmpty ? null : z);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  _multiline(_notes, 'Notes'),
                  if (!widget.isMe) ...[
                    _multiline(_likes, 'Likes'),
                    _multiline(_dislikes, 'Dislikes'),
                    _line(_size, 'Clothing size'),
                    _line(_sweets, 'Favourite sweets'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(onPressed: _saving ? null : _save, child: Text(_isEdit ? 'Save' : 'Save person')),
        ),
      ),
    );
  }

  Future<void> _pickBirthYear() async {
    final now = DateTime.now().year;
    final y = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Birth year'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: YearPicker(
            firstDate: DateTime(1900),
            lastDate: DateTime(now),
            selectedDate: DateTime(_birthYear ?? now - 30),
            onChanged: (d) => Navigator.pop(ctx, d.year),
          ),
        ),
      ),
    );
    if (y != null) setState(() => _birthYear = y);
  }

  Widget _photoWidget(SmritiColors c) {
    Widget avatar;
    if (_newPhoto != null) {
      avatar = CircleAvatar(radius: 48, backgroundImage: MemoryImage(_newPhoto!));
    } else {
      final shown = _photoRemoved ? null : _existing;
      avatar = PersonAvatar(
        person: shown ??
            Person(
              id: 0,
              name: _name.text.isEmpty ? '+' : _name.text,
              relationship: 'friend',
              stars: 3,
              whatsappApp: 'auto',
              editedFields: '',
              isMe: false,
              isArchived: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
        size: 96,
      );
    }
    return GestureDetector(
      onTap: _pickPhoto,
      child: Stack(children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: c.gold, shape: BoxShape.circle, border: Border.all(color: c.bg, width: 2)),
            child: Icon(Icons.photo_camera_outlined, size: 16, color: c.onGold),
          ),
        ),
      ]),
    );
  }

  Widget _contactCard(SmritiColors c) {
    if (_contactId == null) {
      return OutlinedButton.icon(
        onPressed: _pickContact,
        icon: const Icon(Icons.contacts_outlined),
        label: const Text('Pick from contacts'),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Row(children: [
          Icon(Icons.link_rounded, color: c.goldText),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Linked to contact', style: context.text.bodySmall),
              Text(_contactName ?? 'Phone contact', style: context.text.titleMedium),
            ]),
          ),
          PopupMenuButton<String>(
            tooltip: 'Contact options',
            onSelected: (v) {
              if (v == 'relink') _pickContact();
              if (v == 'unlink') {
                setState(() {
                  _contactId = null;
                  _lookupKey = null;
                  _contactName = null;
                  _contactNumbers = const [];
                });
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'relink', child: Text('Link to a different contact')),
              PopupMenuItem(value: 'unlink', child: Text('Unlink')),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _tapField({required String label, required String value, required VoidCallback onTap, VoidCallback? onClear}) =>
      InkWell(
        borderRadius: BorderRadius.circular(Radii.button),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: onClear == null
                ? const Icon(Icons.chevron_right_rounded)
                : IconButton(tooltip: 'Clear', onPressed: onClear, icon: const Icon(Icons.close_rounded)),
          ),
          child: Text(value, style: context.text.bodyLarge),
        ),
      );

  Widget _multiline(TextEditingController t, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: t,
          minLines: 1,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: label),
        ),
      );

  Widget _line(TextEditingController t, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(controller: t, decoration: InputDecoration(labelText: label)),
      );
}
