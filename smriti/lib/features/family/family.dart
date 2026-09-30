import 'package:drift/drift.dart' show BooleanExpressionOperators, Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

enum Gender { male, female, unknown }

/// How a relative is related. [gen] is the generation: +1 parents, 0 same, -1 children.
enum FamilyRel {
  husband('Husband', 0),
  wife('Wife', 0),
  spouse('Spouse', 0),
  father('Father', 1),
  mother('Mother', 1),
  parent('Parent', 1),
  son('Son', -1),
  daughter('Daughter', -1),
  child('Child', -1),
  brother('Brother', 0),
  sister('Sister', 0),
  sibling('Sibling', 0),
  grandfather('Grandfather', 2),
  grandmother('Grandmother', 2),
  grandparent('Grandparent', 2),
  grandson('Grandson', -2),
  granddaughter('Granddaughter', -2),
  grandchild('Grandchild', -2),
  fatherInLaw('Father-in-law', 1),
  motherInLaw('Mother-in-law', 1),
  parentInLaw('Parent-in-law', 1),
  sonInLaw('Son-in-law', -1),
  daughterInLaw('Daughter-in-law', -1),
  childInLaw('Child-in-law', -1),
  brotherInLaw('Brother-in-law', 0),
  sisterInLaw('Sister-in-law', 0),
  siblingInLaw('Sibling-in-law', 0),
  uncle('Uncle', 1),
  aunt('Aunt', 1),
  uncleAunt('Uncle / Aunt', 1),
  nephew('Nephew', -1),
  niece('Niece', -1),
  nephewNiece('Nephew / Niece', -1),
  cousin('Cousin', 0);

  const FamilyRel(this.label, this.gen);
  final String label;
  final int gen;

  static FamilyRel? parse(String? v) => FamilyRel.values.where((r) => r.name == v).firstOrNull;

  /// The ones offered when adding (the rest are worked out automatically).
  static const choices = [
    husband, wife, father, mother, son, daughter, brother, sister, grandfather, grandmother,
    grandson, granddaughter, fatherInLaw, motherInLaw, sonInLaw, daughterInLaw, brotherInLaw,
    sisterInLaw, uncle, aunt, nephew, niece, cousin,
  ];

  Gender get gender => switch (this) {
        husband || father || son || brother || grandfather || grandson || fatherInLaw || sonInLaw ||
        brotherInLaw || uncle || nephew =>
          Gender.male,
        wife || mother || daughter || sister || grandmother || granddaughter || motherInLaw ||
        daughterInLaw || sisterInLaw || aunt || niece =>
          Gender.female,
        _ => Gender.unknown,
      };

  bool get isSpouse => this == husband || this == wife || this == spouse;
  bool get isParent => this == father || this == mother || this == parent;
  bool get isChild => this == son || this == daughter || this == child;
  bool get isSibling => this == brother || this == sister || this == sibling;

  /// If B is A's [this], what is A to B? [g] is A's gender.
  FamilyRel reciprocal(Gender g) {
    FamilyRel pick(FamilyRel m, FamilyRel f, FamilyRel u) => g == Gender.male ? m : (g == Gender.female ? f : u);
    return switch (this) {
      husband || wife || spouse => pick(husband, wife, spouse),
      father || mother || parent => pick(son, daughter, child),
      son || daughter || child => pick(father, mother, parent),
      brother || sister || sibling => pick(brother, sister, sibling),
      grandfather || grandmother || grandparent => pick(grandson, granddaughter, grandchild),
      grandson || granddaughter || grandchild => pick(grandfather, grandmother, grandparent),
      fatherInLaw || motherInLaw || parentInLaw => pick(sonInLaw, daughterInLaw, childInLaw),
      sonInLaw || daughterInLaw || childInLaw => pick(fatherInLaw, motherInLaw, parentInLaw),
      brotherInLaw || sisterInLaw || siblingInLaw => pick(brotherInLaw, sisterInLaw, siblingInLaw),
      uncle || aunt || uncleAunt => pick(nephew, niece, nephewNiece),
      nephew || niece || nephewNiece => pick(uncle, aunt, uncleAunt),
      cousin => cousin,
    };
  }

  /// The matching "relationship to you", used when adding to your own family.
  Relationship? get asRelationship => switch (this) {
        husband => Relationship.husband,
        wife => Relationship.wife,
        father => Relationship.father,
        mother => Relationship.mother,
        son => Relationship.son,
        daughter => Relationship.daughter,
        brother => Relationship.brother,
        sister => Relationship.sister,
        grandfather => Relationship.grandfather,
        grandmother => Relationship.grandmother,
        uncle => Relationship.uncle,
        aunt => Relationship.aunt,
        cousin => Relationship.cousin,
        niece => Relationship.niece,
        nephew => Relationship.nephew,
        fatherInLaw || motherInLaw || sonInLaw || daughterInLaw || brotherInLaw || sisterInLaw || parentInLaw ||
        childInLaw || siblingInLaw =>
          Relationship.inLaw,
        _ => null,
      };
}

Gender _genderFromRelationship(Relationship r) => switch (r) {
      Relationship.father || Relationship.husband || Relationship.son || Relationship.brother ||
      Relationship.grandfather || Relationship.uncle || Relationship.nephew =>
        Gender.male,
      Relationship.mother || Relationship.wife || Relationship.daughter || Relationship.sister ||
      Relationship.grandmother || Relationship.aunt || Relationship.niece =>
        Gender.female,
      _ => Gender.unknown,
    };

/// One family member as seen from a person.
class Relative {
  const Relative(this.person, this.rel);
  final Person person;
  final FamilyRel rel;
}

class FamilyRepo {
  FamilyRepo(this.db);
  final AppDatabase db;

  Future<List<FamilyLink>> _links() => db.select(db.familyLinks).get();

  /// What we know about someone's gender: from how others name them, then their relationship to you.
  Future<Gender> genderOf(Person p) async {
    for (final l in await (db.select(db.familyLinks)..where((l) => l.relativeId.equals(p.id))).get()) {
      final g = FamilyRel.parse(l.relation)?.gender ?? Gender.unknown;
      if (g != Gender.unknown) return g;
    }
    return _genderFromRelationship(Relationship.parse(p.relationship));
  }

  /// Saves "[relative] is [person]'s [rel]" and the matching link the other way.
  Future<void> link(Person person, Person relative, FamilyRel rel) => db.transaction(() async {
        await unlink(person.id, relative.id);
        final back = rel.reciprocal(await genderOf(person));
        await db.into(db.familyLinks).insert(
            FamilyLinksCompanion.insert(personId: person.id, relativeId: relative.id, relation: rel.name));
        await db.into(db.familyLinks).insert(
            FamilyLinksCompanion.insert(personId: relative.id, relativeId: person.id, relation: back.name));
        // Adding to your own family also fixes their "relationship to you".
        final asMe = rel.asRelationship;
        if (person.isMe && asMe != null) {
          final r = Relationship.parse(relative.relationship);
          if (r == Relationship.friend || r == Relationship.custom || r == Relationship.inLaw) {
            await (db.update(db.people)..where((p) => p.id.equals(relative.id)))
                .write(PeopleCompanion(relationship: Value(asMe.name)));
          }
        }
      });

  Future<void> unlink(int a, int b) => (db.delete(db.familyLinks)
        ..where((l) => (l.personId.equals(a) & l.relativeId.equals(b)) | (l.personId.equals(b) & l.relativeId.equals(a))))
      .go();

  /// A person's relatives, including brothers and sisters found through shared parents.
  static List<Relative> relativesOf(int personId, List<FamilyLink> links, Map<int, Person> people) {
    final out = <int, Relative>{};
    for (final l in links.where((l) => l.personId == personId)) {
      final p = people[l.relativeId];
      final r = FamilyRel.parse(l.relation);
      if (p != null && r != null) out[p.id] = Relative(p, r);
    }
    // Other children of my parents are my siblings.
    for (final parent in out.values.where((r) => r.rel.isParent).toList()) {
      for (final l in links.where((l) => l.personId == parent.person.id)) {
        final r = FamilyRel.parse(l.relation);
        final p = people[l.relativeId];
        if (r == null || !r.isChild || p == null || p.id == personId || out.containsKey(p.id)) continue;
        out[p.id] = Relative(p, switch (r) {
          FamilyRel.son => FamilyRel.brother,
          FamilyRel.daughter => FamilyRel.sister,
          _ => FamilyRel.sibling,
        });
      }
    }
    return out.values.toList()..sort((a, b) => b.rel.gen != a.rel.gen ? b.rel.gen.compareTo(a.rel.gen) : a.rel.index.compareTo(b.rel.index));
  }

  Future<List<Relative>> relatives(int personId) async {
    final people = {for (final p in await db.select(db.people).get()) p.id: p};
    return relativesOf(personId, await _links(), people);
  }
}

final familyLinksProvider = StreamProvider<List<FamilyLink>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.familyLinks).watch();
});

final relativesProvider = Provider.family<List<Relative>, int>((ref, personId) {
  final links = ref.watch(familyLinksProvider).value ?? const [];
  final people = {
    for (final p in [...?ref.watch(peopleProvider).value, ...?ref.watch(archivedPeopleProvider).value]) p.id: p,
  };
  final me = ref.watch(meProvider).value;
  if (me != null) people[me.id] = me;
  return FamilyRepo.relativesOf(personId, links, people);
});

// ---------------------------------------------------------------------------
// Adding a family member

Future<void> addFamilyMember(BuildContext context, WidgetRef ref, Person person) async {
  final rel = await showModalBottomSheet<FamilyRel>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(person.isMe ? 'Add to your family' : "Add to ${person.nickname ?? person.name}'s family",
              style: ctx.text.titleLarge),
          const SizedBox(height: 4),
          Text('Who are you adding?', style: ctx.text.bodySmall),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final r in FamilyRel.choices)
              ActionChip(label: Text(r.label), onPressed: () => Navigator.pop(ctx, r)),
          ]),
        ]),
      ),
    ),
  );
  if (rel == null || !context.mounted) return;

  final existing = ref.read(relativesProvider(person.id)).map((r) => r.person.id).toSet();
  final all = [...?ref.read(peopleProvider).value]
      .where((p) => p.id != person.id && !existing.contains(p.id))
      .toList();
  final me = ref.read(meProvider).value;
  if (me != null && me.id != person.id && !existing.contains(me.id) && !all.any((p) => p.id == me.id)) all.insert(0, me);

  final picked = await showModalBottomSheet<Object>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (ctx) => _PickRelative(people: all, rel: rel),
  );
  if (picked == null || !context.mounted) return;
  final repo = ref.read(repoProvider);
  Person relative;
  if (picked is String) {
    final id = await repo.insertPerson(PeopleCompanion.insert(
      name: picked,
      relationship: Value(person.isMe ? (rel.asRelationship ?? Relationship.friend).name : Relationship.friend.name),
    ));
    relative = (await repo.allPeople()).firstWhere((p) => p.id == id);
  } else {
    relative = picked as Person;
  }
  await FamilyRepo(ref.read(databaseProvider)).link(person, relative, rel);
  HapticFeedback.lightImpact();
  if (context.mounted) showToast(context, '${relative.nickname ?? relative.name} added as ${rel.label.toLowerCase()}');
}

class _PickRelative extends StatefulWidget {
  const _PickRelative({required this.people, required this.rel});

  final List<Person> people;
  final FamilyRel rel;

  @override
  State<_PickRelative> createState() => _PickRelativeState();
}

class _PickRelativeState extends State<_PickRelative> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase();
    final list = widget.people
        .where((p) => p.name.toLowerCase().contains(q) || (p.nickname ?? '').toLowerCase().contains(q))
        .toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(children: [
            Expanded(child: Text('Choose the ${widget.rel.label.toLowerCase()}', style: context.text.titleLarge)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search, or type a new name'),
            onChanged: (v) => setState(() => _q = v.trim()),
          ),
        ),
        if (_q.isNotEmpty)
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_add_alt_1_rounded)),
            title: Text('Add "$_q" as a new person'),
            subtitle: const Text('You can add their birthday later'),
            onTap: () => Navigator.pop(context, _q),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final p = list[i];
              return ListTile(
                leading: PersonAvatar(person: p, size: 38),
                title: Text(p.isMe ? '${p.name} (you)' : p.name),
                subtitle: p.nickname == null ? null : Text(p.nickname!),
                onTap: () => Navigator.pop(context, p),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile card and tree

String _group(FamilyRel r) {
  if (r.isSpouse) return 'Spouse';
  if (r.isParent) return 'Parents';
  if (r.isChild) return 'Children';
  if (r.isSibling) return 'Brothers & sisters';
  return switch (r.gen) {
    2 => 'Grandparents',
    -2 => 'Grandchildren',
    _ => 'Other family',
  };
}

const _groupOrder = ['Spouse', 'Parents', 'Children', 'Brothers & sisters', 'Grandparents', 'Grandchildren', 'Other family'];

class FamilyCard extends ConsumerWidget {
  const FamilyCard({super.key, required this.person});

  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final relatives = ref.watch(relativesProvider(person.id));
    final groups = <String, List<Relative>>{};
    for (final r in relatives) {
      (groups[_group(r.rel)] ??= []).add(r);
    }
    return InfoCard(
      title: 'Family',
      trailing: TextButton.icon(
        onPressed: () => addFamilyMember(context, ref, person),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Add'),
      ),
      children: [
        if (relatives.isEmpty)
          Text(
            person.isMe
                ? 'Add your husband or wife, parents, children, brothers and sisters, and see them as a family tree.'
                : 'Add ${person.nickname ?? person.name}’s husband or wife, children, parents… to keep the family together.',
            style: context.text.bodyMedium?.copyWith(color: c.muted),
          ),
        for (final g in _groupOrder)
          if (groups[g] != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Text(g, style: context.text.labelMedium?.copyWith(color: c.muted)),
            ),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final r in groups[g]!) _RelativeChip(owner: person, relative: r),
            ]),
          ],
        if (relatives.isNotEmpty) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.push('/person/${person.id}/family'),
            icon: const Icon(Icons.account_tree_outlined),
            label: const Text('See family tree'),
          ),
        ],
      ],
    );
  }
}

class _RelativeChip extends ConsumerWidget {
  const _RelativeChip({required this.owner, required this.relative});

  final Person owner;
  final Relative relative;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final p = relative.person;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => context.push('/person/${p.id}'),
      onLongPress: () async {
        final ok = await confirm(context,
            title: 'Remove from family?',
            message: '${p.nickname ?? p.name} stays in Smriti; only the family link is removed.',
            action: 'Remove');
        if (ok) await FamilyRepo(ref.read(databaseProvider)).unlink(owner.id, p.id);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
        decoration: BoxDecoration(border: Border.all(color: c.line), borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          PersonAvatar(person: p, size: 30),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(p.isMe ? 'You' : (p.nickname ?? p.name), style: context.text.titleSmall),
            Text(relative.rel.label, style: context.text.bodySmall?.copyWith(fontSize: 11)),
          ]),
        ]),
      ),
    );
  }
}

/// The family by generation: grandparents at the top, grandchildren at the bottom.
class FamilyTreeScreen extends ConsumerWidget {
  const FamilyTreeScreen({super.key, required this.personId});

  final int personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final person = ref.watch(personProvider(personId)).value;
    if (person == null) return const Scaffold();
    final relatives = ref.watch(relativesProvider(personId));

    List<Relative> at(int gen) => relatives.where((r) => r.rel.gen == gen).toList();
    final spouses = relatives.where((r) => r.rel.isSpouse).toList();
    final sameGen = at(0).where((r) => !r.rel.isSpouse).toList();

    Widget row(String label, List<Widget> nodes) => Column(children: [
          Text(label.toUpperCase(), style: context.text.labelSmall),
          const SizedBox(height: 8),
          Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 12, children: nodes),
        ]);
    Widget link() => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: SizedBox(width: 2, height: 22, child: ColoredBox(color: c.gold.withValues(alpha: 0.5))),
          ),
        );

    final rows = <Widget>[];
    void addRow(String label, List<Relative> list) {
      if (list.isEmpty) return;
      if (rows.isNotEmpty) rows.add(link());
      rows.add(row(label, [for (final r in list) _Node(person: r.person, label: r.rel.label)]));
    }

    addRow('Grandparents', at(2));
    addRow('Parents & elders', at(1));
    if (rows.isNotEmpty) rows.add(link());
    rows.add(row(person.isMe ? 'You' : (person.nickname ?? person.name), [
      _Node(person: person, label: person.isMe ? 'You' : person.relationLabelShort, highlight: true),
      for (final s in spouses) _Node(person: s.person, label: s.rel.label),
    ]));
    if (sameGen.isNotEmpty) {
      rows.add(const SizedBox(height: 16));
      rows.add(row('Brothers, sisters & cousins', [for (final r in sameGen) _Node(person: r.person, label: r.rel.label)]));
    }
    addRow('Children & next generation', at(-1));
    addRow('Grandchildren', at(-2));

    return Scaffold(
      appBar: AppBar(title: Text(person.isMe ? 'Your family' : "${person.nickname ?? person.name}'s family")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => addFamilyMember(context, ref, person),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add family'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          ...rows,
          const SizedBox(height: 20),
          Text('Tap anyone to open their page. Long-press a name on a profile’s Family card to remove the link.',
              textAlign: TextAlign.center, style: context.text.bodySmall),
        ],
      ),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.person, required this.label, this.highlight = false});

  final Person person;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: highlight ? null : () => context.push('/person/${person.id}/family'),
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: highlight ? c.gold.withValues(alpha: 0.14) : c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: highlight ? c.gold : c.line, width: highlight ? 1.5 : 1),
        ),
        child: Column(children: [
          PersonAvatar(person: person, size: 48),
          const SizedBox(height: 6),
          Text(person.isMe ? 'You' : (person.nickname ?? person.name.split(' ').first),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
          Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(fontSize: 11)),
        ]),
      ),
    );
  }
}

extension on Person {
  String get relationLabelShort => Relationship.parse(relationship).label;
}
