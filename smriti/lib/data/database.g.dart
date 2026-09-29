// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $PeopleTable extends People with TableInfo<$PeopleTable, Person> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeopleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _relationshipMeta = const VerificationMeta(
    'relationship',
  );
  @override
  late final GeneratedColumn<String> relationship = GeneratedColumn<String>(
    'relationship',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('friend'),
  );
  static const VerificationMeta _customRelationshipMeta =
      const VerificationMeta('customRelationship');
  @override
  late final GeneratedColumn<String> customRelationship =
      GeneratedColumn<String>(
        'custom_relationship',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _starsMeta = const VerificationMeta('stars');
  @override
  late final GeneratedColumn<int> stars = GeneratedColumn<int>(
    'stars',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _birthYearMeta = const VerificationMeta(
    'birthYear',
  );
  @override
  late final GeneratedColumn<int> birthYear = GeneratedColumn<int>(
    'birth_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeZoneMeta = const VerificationMeta(
    'timeZone',
  );
  @override
  late final GeneratedColumn<String> timeZone = GeneratedColumn<String>(
    'time_zone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _callNumberMeta = const VerificationMeta(
    'callNumber',
  );
  @override
  late final GeneratedColumn<String> callNumber = GeneratedColumn<String>(
    'call_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _whatsappNumberMeta = const VerificationMeta(
    'whatsappNumber',
  );
  @override
  late final GeneratedColumn<String> whatsappNumber = GeneratedColumn<String>(
    'whatsapp_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _likesMeta = const VerificationMeta('likes');
  @override
  late final GeneratedColumn<String> likes = GeneratedColumn<String>(
    'likes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dislikesMeta = const VerificationMeta(
    'dislikes',
  );
  @override
  late final GeneratedColumn<String> dislikes = GeneratedColumn<String>(
    'dislikes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clothingSizeMeta = const VerificationMeta(
    'clothingSize',
  );
  @override
  late final GeneratedColumn<String> clothingSize = GeneratedColumn<String>(
    'clothing_size',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _favouriteSweetsMeta = const VerificationMeta(
    'favouriteSweets',
  );
  @override
  late final GeneratedColumn<String> favouriteSweets = GeneratedColumn<String>(
    'favourite_sweets',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contactIdMeta = const VerificationMeta(
    'contactId',
  );
  @override
  late final GeneratedColumn<String> contactId = GeneratedColumn<String>(
    'contact_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contactLookupKeyMeta = const VerificationMeta(
    'contactLookupKey',
  );
  @override
  late final GeneratedColumn<String> contactLookupKey = GeneratedColumn<String>(
    'contact_lookup_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _editedFieldsMeta = const VerificationMeta(
    'editedFields',
  );
  @override
  late final GeneratedColumn<String> editedFields = GeneratedColumn<String>(
    'edited_fields',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isMeMeta = const VerificationMeta('isMe');
  @override
  late final GeneratedColumn<bool> isMe = GeneratedColumn<bool>(
    'is_me',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_me" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    nickname,
    photoPath,
    relationship,
    customRelationship,
    stars,
    birthYear,
    timeZone,
    callNumber,
    whatsappNumber,
    notes,
    likes,
    dislikes,
    clothingSize,
    favouriteSweets,
    contactId,
    contactLookupKey,
    editedFields,
    isMe,
    isArchived,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'people';
  @override
  VerificationContext validateIntegrity(
    Insertable<Person> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('relationship')) {
      context.handle(
        _relationshipMeta,
        relationship.isAcceptableOrUnknown(
          data['relationship']!,
          _relationshipMeta,
        ),
      );
    }
    if (data.containsKey('custom_relationship')) {
      context.handle(
        _customRelationshipMeta,
        customRelationship.isAcceptableOrUnknown(
          data['custom_relationship']!,
          _customRelationshipMeta,
        ),
      );
    }
    if (data.containsKey('stars')) {
      context.handle(
        _starsMeta,
        stars.isAcceptableOrUnknown(data['stars']!, _starsMeta),
      );
    }
    if (data.containsKey('birth_year')) {
      context.handle(
        _birthYearMeta,
        birthYear.isAcceptableOrUnknown(data['birth_year']!, _birthYearMeta),
      );
    }
    if (data.containsKey('time_zone')) {
      context.handle(
        _timeZoneMeta,
        timeZone.isAcceptableOrUnknown(data['time_zone']!, _timeZoneMeta),
      );
    }
    if (data.containsKey('call_number')) {
      context.handle(
        _callNumberMeta,
        callNumber.isAcceptableOrUnknown(data['call_number']!, _callNumberMeta),
      );
    }
    if (data.containsKey('whatsapp_number')) {
      context.handle(
        _whatsappNumberMeta,
        whatsappNumber.isAcceptableOrUnknown(
          data['whatsapp_number']!,
          _whatsappNumberMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('likes')) {
      context.handle(
        _likesMeta,
        likes.isAcceptableOrUnknown(data['likes']!, _likesMeta),
      );
    }
    if (data.containsKey('dislikes')) {
      context.handle(
        _dislikesMeta,
        dislikes.isAcceptableOrUnknown(data['dislikes']!, _dislikesMeta),
      );
    }
    if (data.containsKey('clothing_size')) {
      context.handle(
        _clothingSizeMeta,
        clothingSize.isAcceptableOrUnknown(
          data['clothing_size']!,
          _clothingSizeMeta,
        ),
      );
    }
    if (data.containsKey('favourite_sweets')) {
      context.handle(
        _favouriteSweetsMeta,
        favouriteSweets.isAcceptableOrUnknown(
          data['favourite_sweets']!,
          _favouriteSweetsMeta,
        ),
      );
    }
    if (data.containsKey('contact_id')) {
      context.handle(
        _contactIdMeta,
        contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta),
      );
    }
    if (data.containsKey('contact_lookup_key')) {
      context.handle(
        _contactLookupKeyMeta,
        contactLookupKey.isAcceptableOrUnknown(
          data['contact_lookup_key']!,
          _contactLookupKeyMeta,
        ),
      );
    }
    if (data.containsKey('edited_fields')) {
      context.handle(
        _editedFieldsMeta,
        editedFields.isAcceptableOrUnknown(
          data['edited_fields']!,
          _editedFieldsMeta,
        ),
      );
    }
    if (data.containsKey('is_me')) {
      context.handle(
        _isMeMeta,
        isMe.isAcceptableOrUnknown(data['is_me']!, _isMeMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Person map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Person(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      ),
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      relationship: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relationship'],
      )!,
      customRelationship: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_relationship'],
      ),
      stars: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stars'],
      )!,
      birthYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}birth_year'],
      ),
      timeZone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_zone'],
      ),
      callNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}call_number'],
      ),
      whatsappNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}whatsapp_number'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      likes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}likes'],
      ),
      dislikes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dislikes'],
      ),
      clothingSize: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clothing_size'],
      ),
      favouriteSweets: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}favourite_sweets'],
      ),
      contactId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_id'],
      ),
      contactLookupKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_lookup_key'],
      ),
      editedFields: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}edited_fields'],
      )!,
      isMe: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_me'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PeopleTable createAlias(String alias) {
    return $PeopleTable(attachedDatabase, alias);
  }
}

class Person extends DataClass implements Insertable<Person> {
  final int id;
  final String name;
  final String? nickname;
  final String? photoPath;
  final String relationship;
  final String? customRelationship;
  final int stars;
  final int? birthYear;

  /// IANA time zone, e.g. "America/New_York". Null means the owner's.
  final String? timeZone;

  /// Normalised numbers (+91…). A null WhatsApp number means "same as call".
  final String? callNumber;
  final String? whatsappNumber;
  final String? notes;
  final String? likes;
  final String? dislikes;
  final String? clothingSize;
  final String? favouriteSweets;

  /// Phone contact this person is linked to, if any.
  final String? contactId;

  /// Android lookup key: finds the contact again if its id changes.
  final String? contactLookupKey;

  /// Comma-separated field names the user edited by hand ("callNumber",
  /// "whatsappNumber"). Contact sync never silently overwrites these.
  final String editedFields;
  final bool isMe;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Person({
    required this.id,
    required this.name,
    this.nickname,
    this.photoPath,
    required this.relationship,
    this.customRelationship,
    required this.stars,
    this.birthYear,
    this.timeZone,
    this.callNumber,
    this.whatsappNumber,
    this.notes,
    this.likes,
    this.dislikes,
    this.clothingSize,
    this.favouriteSweets,
    this.contactId,
    this.contactLookupKey,
    required this.editedFields,
    required this.isMe,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || nickname != null) {
      map['nickname'] = Variable<String>(nickname);
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['relationship'] = Variable<String>(relationship);
    if (!nullToAbsent || customRelationship != null) {
      map['custom_relationship'] = Variable<String>(customRelationship);
    }
    map['stars'] = Variable<int>(stars);
    if (!nullToAbsent || birthYear != null) {
      map['birth_year'] = Variable<int>(birthYear);
    }
    if (!nullToAbsent || timeZone != null) {
      map['time_zone'] = Variable<String>(timeZone);
    }
    if (!nullToAbsent || callNumber != null) {
      map['call_number'] = Variable<String>(callNumber);
    }
    if (!nullToAbsent || whatsappNumber != null) {
      map['whatsapp_number'] = Variable<String>(whatsappNumber);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || likes != null) {
      map['likes'] = Variable<String>(likes);
    }
    if (!nullToAbsent || dislikes != null) {
      map['dislikes'] = Variable<String>(dislikes);
    }
    if (!nullToAbsent || clothingSize != null) {
      map['clothing_size'] = Variable<String>(clothingSize);
    }
    if (!nullToAbsent || favouriteSweets != null) {
      map['favourite_sweets'] = Variable<String>(favouriteSweets);
    }
    if (!nullToAbsent || contactId != null) {
      map['contact_id'] = Variable<String>(contactId);
    }
    if (!nullToAbsent || contactLookupKey != null) {
      map['contact_lookup_key'] = Variable<String>(contactLookupKey);
    }
    map['edited_fields'] = Variable<String>(editedFields);
    map['is_me'] = Variable<bool>(isMe);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PeopleCompanion toCompanion(bool nullToAbsent) {
    return PeopleCompanion(
      id: Value(id),
      name: Value(name),
      nickname: nickname == null && nullToAbsent
          ? const Value.absent()
          : Value(nickname),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      relationship: Value(relationship),
      customRelationship: customRelationship == null && nullToAbsent
          ? const Value.absent()
          : Value(customRelationship),
      stars: Value(stars),
      birthYear: birthYear == null && nullToAbsent
          ? const Value.absent()
          : Value(birthYear),
      timeZone: timeZone == null && nullToAbsent
          ? const Value.absent()
          : Value(timeZone),
      callNumber: callNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(callNumber),
      whatsappNumber: whatsappNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(whatsappNumber),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      likes: likes == null && nullToAbsent
          ? const Value.absent()
          : Value(likes),
      dislikes: dislikes == null && nullToAbsent
          ? const Value.absent()
          : Value(dislikes),
      clothingSize: clothingSize == null && nullToAbsent
          ? const Value.absent()
          : Value(clothingSize),
      favouriteSweets: favouriteSweets == null && nullToAbsent
          ? const Value.absent()
          : Value(favouriteSweets),
      contactId: contactId == null && nullToAbsent
          ? const Value.absent()
          : Value(contactId),
      contactLookupKey: contactLookupKey == null && nullToAbsent
          ? const Value.absent()
          : Value(contactLookupKey),
      editedFields: Value(editedFields),
      isMe: Value(isMe),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Person.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Person(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      nickname: serializer.fromJson<String?>(json['nickname']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      relationship: serializer.fromJson<String>(json['relationship']),
      customRelationship: serializer.fromJson<String?>(
        json['customRelationship'],
      ),
      stars: serializer.fromJson<int>(json['stars']),
      birthYear: serializer.fromJson<int?>(json['birthYear']),
      timeZone: serializer.fromJson<String?>(json['timeZone']),
      callNumber: serializer.fromJson<String?>(json['callNumber']),
      whatsappNumber: serializer.fromJson<String?>(json['whatsappNumber']),
      notes: serializer.fromJson<String?>(json['notes']),
      likes: serializer.fromJson<String?>(json['likes']),
      dislikes: serializer.fromJson<String?>(json['dislikes']),
      clothingSize: serializer.fromJson<String?>(json['clothingSize']),
      favouriteSweets: serializer.fromJson<String?>(json['favouriteSweets']),
      contactId: serializer.fromJson<String?>(json['contactId']),
      contactLookupKey: serializer.fromJson<String?>(json['contactLookupKey']),
      editedFields: serializer.fromJson<String>(json['editedFields']),
      isMe: serializer.fromJson<bool>(json['isMe']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'nickname': serializer.toJson<String?>(nickname),
      'photoPath': serializer.toJson<String?>(photoPath),
      'relationship': serializer.toJson<String>(relationship),
      'customRelationship': serializer.toJson<String?>(customRelationship),
      'stars': serializer.toJson<int>(stars),
      'birthYear': serializer.toJson<int?>(birthYear),
      'timeZone': serializer.toJson<String?>(timeZone),
      'callNumber': serializer.toJson<String?>(callNumber),
      'whatsappNumber': serializer.toJson<String?>(whatsappNumber),
      'notes': serializer.toJson<String?>(notes),
      'likes': serializer.toJson<String?>(likes),
      'dislikes': serializer.toJson<String?>(dislikes),
      'clothingSize': serializer.toJson<String?>(clothingSize),
      'favouriteSweets': serializer.toJson<String?>(favouriteSweets),
      'contactId': serializer.toJson<String?>(contactId),
      'contactLookupKey': serializer.toJson<String?>(contactLookupKey),
      'editedFields': serializer.toJson<String>(editedFields),
      'isMe': serializer.toJson<bool>(isMe),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Person copyWith({
    int? id,
    String? name,
    Value<String?> nickname = const Value.absent(),
    Value<String?> photoPath = const Value.absent(),
    String? relationship,
    Value<String?> customRelationship = const Value.absent(),
    int? stars,
    Value<int?> birthYear = const Value.absent(),
    Value<String?> timeZone = const Value.absent(),
    Value<String?> callNumber = const Value.absent(),
    Value<String?> whatsappNumber = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> likes = const Value.absent(),
    Value<String?> dislikes = const Value.absent(),
    Value<String?> clothingSize = const Value.absent(),
    Value<String?> favouriteSweets = const Value.absent(),
    Value<String?> contactId = const Value.absent(),
    Value<String?> contactLookupKey = const Value.absent(),
    String? editedFields,
    bool? isMe,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Person(
    id: id ?? this.id,
    name: name ?? this.name,
    nickname: nickname.present ? nickname.value : this.nickname,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    relationship: relationship ?? this.relationship,
    customRelationship: customRelationship.present
        ? customRelationship.value
        : this.customRelationship,
    stars: stars ?? this.stars,
    birthYear: birthYear.present ? birthYear.value : this.birthYear,
    timeZone: timeZone.present ? timeZone.value : this.timeZone,
    callNumber: callNumber.present ? callNumber.value : this.callNumber,
    whatsappNumber: whatsappNumber.present
        ? whatsappNumber.value
        : this.whatsappNumber,
    notes: notes.present ? notes.value : this.notes,
    likes: likes.present ? likes.value : this.likes,
    dislikes: dislikes.present ? dislikes.value : this.dislikes,
    clothingSize: clothingSize.present ? clothingSize.value : this.clothingSize,
    favouriteSweets: favouriteSweets.present
        ? favouriteSweets.value
        : this.favouriteSweets,
    contactId: contactId.present ? contactId.value : this.contactId,
    contactLookupKey: contactLookupKey.present
        ? contactLookupKey.value
        : this.contactLookupKey,
    editedFields: editedFields ?? this.editedFields,
    isMe: isMe ?? this.isMe,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Person copyWithCompanion(PeopleCompanion data) {
    return Person(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      relationship: data.relationship.present
          ? data.relationship.value
          : this.relationship,
      customRelationship: data.customRelationship.present
          ? data.customRelationship.value
          : this.customRelationship,
      stars: data.stars.present ? data.stars.value : this.stars,
      birthYear: data.birthYear.present ? data.birthYear.value : this.birthYear,
      timeZone: data.timeZone.present ? data.timeZone.value : this.timeZone,
      callNumber: data.callNumber.present
          ? data.callNumber.value
          : this.callNumber,
      whatsappNumber: data.whatsappNumber.present
          ? data.whatsappNumber.value
          : this.whatsappNumber,
      notes: data.notes.present ? data.notes.value : this.notes,
      likes: data.likes.present ? data.likes.value : this.likes,
      dislikes: data.dislikes.present ? data.dislikes.value : this.dislikes,
      clothingSize: data.clothingSize.present
          ? data.clothingSize.value
          : this.clothingSize,
      favouriteSweets: data.favouriteSweets.present
          ? data.favouriteSweets.value
          : this.favouriteSweets,
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      contactLookupKey: data.contactLookupKey.present
          ? data.contactLookupKey.value
          : this.contactLookupKey,
      editedFields: data.editedFields.present
          ? data.editedFields.value
          : this.editedFields,
      isMe: data.isMe.present ? data.isMe.value : this.isMe,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Person(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nickname: $nickname, ')
          ..write('photoPath: $photoPath, ')
          ..write('relationship: $relationship, ')
          ..write('customRelationship: $customRelationship, ')
          ..write('stars: $stars, ')
          ..write('birthYear: $birthYear, ')
          ..write('timeZone: $timeZone, ')
          ..write('callNumber: $callNumber, ')
          ..write('whatsappNumber: $whatsappNumber, ')
          ..write('notes: $notes, ')
          ..write('likes: $likes, ')
          ..write('dislikes: $dislikes, ')
          ..write('clothingSize: $clothingSize, ')
          ..write('favouriteSweets: $favouriteSweets, ')
          ..write('contactId: $contactId, ')
          ..write('contactLookupKey: $contactLookupKey, ')
          ..write('editedFields: $editedFields, ')
          ..write('isMe: $isMe, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    nickname,
    photoPath,
    relationship,
    customRelationship,
    stars,
    birthYear,
    timeZone,
    callNumber,
    whatsappNumber,
    notes,
    likes,
    dislikes,
    clothingSize,
    favouriteSweets,
    contactId,
    contactLookupKey,
    editedFields,
    isMe,
    isArchived,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Person &&
          other.id == this.id &&
          other.name == this.name &&
          other.nickname == this.nickname &&
          other.photoPath == this.photoPath &&
          other.relationship == this.relationship &&
          other.customRelationship == this.customRelationship &&
          other.stars == this.stars &&
          other.birthYear == this.birthYear &&
          other.timeZone == this.timeZone &&
          other.callNumber == this.callNumber &&
          other.whatsappNumber == this.whatsappNumber &&
          other.notes == this.notes &&
          other.likes == this.likes &&
          other.dislikes == this.dislikes &&
          other.clothingSize == this.clothingSize &&
          other.favouriteSweets == this.favouriteSweets &&
          other.contactId == this.contactId &&
          other.contactLookupKey == this.contactLookupKey &&
          other.editedFields == this.editedFields &&
          other.isMe == this.isMe &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PeopleCompanion extends UpdateCompanion<Person> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> nickname;
  final Value<String?> photoPath;
  final Value<String> relationship;
  final Value<String?> customRelationship;
  final Value<int> stars;
  final Value<int?> birthYear;
  final Value<String?> timeZone;
  final Value<String?> callNumber;
  final Value<String?> whatsappNumber;
  final Value<String?> notes;
  final Value<String?> likes;
  final Value<String?> dislikes;
  final Value<String?> clothingSize;
  final Value<String?> favouriteSweets;
  final Value<String?> contactId;
  final Value<String?> contactLookupKey;
  final Value<String> editedFields;
  final Value<bool> isMe;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PeopleCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.nickname = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.relationship = const Value.absent(),
    this.customRelationship = const Value.absent(),
    this.stars = const Value.absent(),
    this.birthYear = const Value.absent(),
    this.timeZone = const Value.absent(),
    this.callNumber = const Value.absent(),
    this.whatsappNumber = const Value.absent(),
    this.notes = const Value.absent(),
    this.likes = const Value.absent(),
    this.dislikes = const Value.absent(),
    this.clothingSize = const Value.absent(),
    this.favouriteSweets = const Value.absent(),
    this.contactId = const Value.absent(),
    this.contactLookupKey = const Value.absent(),
    this.editedFields = const Value.absent(),
    this.isMe = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PeopleCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.nickname = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.relationship = const Value.absent(),
    this.customRelationship = const Value.absent(),
    this.stars = const Value.absent(),
    this.birthYear = const Value.absent(),
    this.timeZone = const Value.absent(),
    this.callNumber = const Value.absent(),
    this.whatsappNumber = const Value.absent(),
    this.notes = const Value.absent(),
    this.likes = const Value.absent(),
    this.dislikes = const Value.absent(),
    this.clothingSize = const Value.absent(),
    this.favouriteSweets = const Value.absent(),
    this.contactId = const Value.absent(),
    this.contactLookupKey = const Value.absent(),
    this.editedFields = const Value.absent(),
    this.isMe = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Person> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? nickname,
    Expression<String>? photoPath,
    Expression<String>? relationship,
    Expression<String>? customRelationship,
    Expression<int>? stars,
    Expression<int>? birthYear,
    Expression<String>? timeZone,
    Expression<String>? callNumber,
    Expression<String>? whatsappNumber,
    Expression<String>? notes,
    Expression<String>? likes,
    Expression<String>? dislikes,
    Expression<String>? clothingSize,
    Expression<String>? favouriteSweets,
    Expression<String>? contactId,
    Expression<String>? contactLookupKey,
    Expression<String>? editedFields,
    Expression<bool>? isMe,
    Expression<bool>? isArchived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (nickname != null) 'nickname': nickname,
      if (photoPath != null) 'photo_path': photoPath,
      if (relationship != null) 'relationship': relationship,
      if (customRelationship != null) 'custom_relationship': customRelationship,
      if (stars != null) 'stars': stars,
      if (birthYear != null) 'birth_year': birthYear,
      if (timeZone != null) 'time_zone': timeZone,
      if (callNumber != null) 'call_number': callNumber,
      if (whatsappNumber != null) 'whatsapp_number': whatsappNumber,
      if (notes != null) 'notes': notes,
      if (likes != null) 'likes': likes,
      if (dislikes != null) 'dislikes': dislikes,
      if (clothingSize != null) 'clothing_size': clothingSize,
      if (favouriteSweets != null) 'favourite_sweets': favouriteSweets,
      if (contactId != null) 'contact_id': contactId,
      if (contactLookupKey != null) 'contact_lookup_key': contactLookupKey,
      if (editedFields != null) 'edited_fields': editedFields,
      if (isMe != null) 'is_me': isMe,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PeopleCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? nickname,
    Value<String?>? photoPath,
    Value<String>? relationship,
    Value<String?>? customRelationship,
    Value<int>? stars,
    Value<int?>? birthYear,
    Value<String?>? timeZone,
    Value<String?>? callNumber,
    Value<String?>? whatsappNumber,
    Value<String?>? notes,
    Value<String?>? likes,
    Value<String?>? dislikes,
    Value<String?>? clothingSize,
    Value<String?>? favouriteSweets,
    Value<String?>? contactId,
    Value<String?>? contactLookupKey,
    Value<String>? editedFields,
    Value<bool>? isMe,
    Value<bool>? isArchived,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PeopleCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      photoPath: photoPath ?? this.photoPath,
      relationship: relationship ?? this.relationship,
      customRelationship: customRelationship ?? this.customRelationship,
      stars: stars ?? this.stars,
      birthYear: birthYear ?? this.birthYear,
      timeZone: timeZone ?? this.timeZone,
      callNumber: callNumber ?? this.callNumber,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      notes: notes ?? this.notes,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      clothingSize: clothingSize ?? this.clothingSize,
      favouriteSweets: favouriteSweets ?? this.favouriteSweets,
      contactId: contactId ?? this.contactId,
      contactLookupKey: contactLookupKey ?? this.contactLookupKey,
      editedFields: editedFields ?? this.editedFields,
      isMe: isMe ?? this.isMe,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (relationship.present) {
      map['relationship'] = Variable<String>(relationship.value);
    }
    if (customRelationship.present) {
      map['custom_relationship'] = Variable<String>(customRelationship.value);
    }
    if (stars.present) {
      map['stars'] = Variable<int>(stars.value);
    }
    if (birthYear.present) {
      map['birth_year'] = Variable<int>(birthYear.value);
    }
    if (timeZone.present) {
      map['time_zone'] = Variable<String>(timeZone.value);
    }
    if (callNumber.present) {
      map['call_number'] = Variable<String>(callNumber.value);
    }
    if (whatsappNumber.present) {
      map['whatsapp_number'] = Variable<String>(whatsappNumber.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (likes.present) {
      map['likes'] = Variable<String>(likes.value);
    }
    if (dislikes.present) {
      map['dislikes'] = Variable<String>(dislikes.value);
    }
    if (clothingSize.present) {
      map['clothing_size'] = Variable<String>(clothingSize.value);
    }
    if (favouriteSweets.present) {
      map['favourite_sweets'] = Variable<String>(favouriteSweets.value);
    }
    if (contactId.present) {
      map['contact_id'] = Variable<String>(contactId.value);
    }
    if (contactLookupKey.present) {
      map['contact_lookup_key'] = Variable<String>(contactLookupKey.value);
    }
    if (editedFields.present) {
      map['edited_fields'] = Variable<String>(editedFields.value);
    }
    if (isMe.present) {
      map['is_me'] = Variable<bool>(isMe.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeopleCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nickname: $nickname, ')
          ..write('photoPath: $photoPath, ')
          ..write('relationship: $relationship, ')
          ..write('customRelationship: $customRelationship, ')
          ..write('stars: $stars, ')
          ..write('birthYear: $birthYear, ')
          ..write('timeZone: $timeZone, ')
          ..write('callNumber: $callNumber, ')
          ..write('whatsappNumber: $whatsappNumber, ')
          ..write('notes: $notes, ')
          ..write('likes: $likes, ')
          ..write('dislikes: $dislikes, ')
          ..write('clothingSize: $clothingSize, ')
          ..write('favouriteSweets: $favouriteSweets, ')
          ..write('contactId: $contactId, ')
          ..write('contactLookupKey: $contactLookupKey, ')
          ..write('editedFields: $editedFields, ')
          ..write('isMe: $isMe, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $EventsTable extends Events with TableInfo<$EventsTable, Event> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customLabelMeta = const VerificationMeta(
    'customLabel',
  );
  @override
  late final GeneratedColumn<String> customLabel = GeneratedColumn<String>(
    'custom_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repeatMeta = const VerificationMeta('repeat');
  @override
  late final GeneratedColumn<String> repeat = GeneratedColumn<String>(
    'repeat',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('yearly'),
  );
  static const VerificationMeta _feb29RuleMeta = const VerificationMeta(
    'feb29Rule',
  );
  @override
  late final GeneratedColumn<String> feb29Rule = GeneratedColumn<String>(
    'feb29_rule',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('feb28'),
  );
  static const VerificationMeta _starsMeta = const VerificationMeta('stars');
  @override
  late final GeneratedColumn<int> stars = GeneratedColumn<int>(
    'stars',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sendWishesToIdMeta = const VerificationMeta(
    'sendWishesToId',
  );
  @override
  late final GeneratedColumn<int> sendWishesToId = GeneratedColumn<int>(
    'send_wishes_to_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _alarmClockMeta = const VerificationMeta(
    'alarmClock',
  );
  @override
  late final GeneratedColumn<String> alarmClock = GeneratedColumn<String>(
    'alarm_clock',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('mine'),
  );
  static const VerificationMeta _draftMessageMeta = const VerificationMeta(
    'draftMessage',
  );
  @override
  late final GeneratedColumn<String> draftMessage = GeneratedColumn<String>(
    'draft_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _belatedNudgeMeta = const VerificationMeta(
    'belatedNudge',
  );
  @override
  late final GeneratedColumn<bool> belatedNudge = GeneratedColumn<bool>(
    'belated_nudge',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("belated_nudge" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _soundMeta = const VerificationMeta('sound');
  @override
  late final GeneratedColumn<String> sound = GeneratedColumn<String>(
    'sound',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    type,
    customLabel,
    title,
    day,
    month,
    year,
    repeat,
    feb29Rule,
    stars,
    notes,
    sendWishesToId,
    alarmClock,
    draftMessage,
    belatedNudge,
    sound,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(
    Insertable<Event> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('custom_label')) {
      context.handle(
        _customLabelMeta,
        customLabel.isAcceptableOrUnknown(
          data['custom_label']!,
          _customLabelMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('repeat')) {
      context.handle(
        _repeatMeta,
        repeat.isAcceptableOrUnknown(data['repeat']!, _repeatMeta),
      );
    }
    if (data.containsKey('feb29_rule')) {
      context.handle(
        _feb29RuleMeta,
        feb29Rule.isAcceptableOrUnknown(data['feb29_rule']!, _feb29RuleMeta),
      );
    }
    if (data.containsKey('stars')) {
      context.handle(
        _starsMeta,
        stars.isAcceptableOrUnknown(data['stars']!, _starsMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('send_wishes_to_id')) {
      context.handle(
        _sendWishesToIdMeta,
        sendWishesToId.isAcceptableOrUnknown(
          data['send_wishes_to_id']!,
          _sendWishesToIdMeta,
        ),
      );
    }
    if (data.containsKey('alarm_clock')) {
      context.handle(
        _alarmClockMeta,
        alarmClock.isAcceptableOrUnknown(data['alarm_clock']!, _alarmClockMeta),
      );
    }
    if (data.containsKey('draft_message')) {
      context.handle(
        _draftMessageMeta,
        draftMessage.isAcceptableOrUnknown(
          data['draft_message']!,
          _draftMessageMeta,
        ),
      );
    }
    if (data.containsKey('belated_nudge')) {
      context.handle(
        _belatedNudgeMeta,
        belatedNudge.isAcceptableOrUnknown(
          data['belated_nudge']!,
          _belatedNudgeMeta,
        ),
      );
    }
    if (data.containsKey('sound')) {
      context.handle(
        _soundMeta,
        sound.isAcceptableOrUnknown(data['sound']!, _soundMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Event map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Event(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      customLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_label'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      repeat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat'],
      )!,
      feb29Rule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feb29_rule'],
      )!,
      stars: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stars'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      sendWishesToId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}send_wishes_to_id'],
      ),
      alarmClock: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alarm_clock'],
      )!,
      draftMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}draft_message'],
      ),
      belatedNudge: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}belated_nudge'],
      )!,
      sound: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sound'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }
}

class Event extends DataClass implements Insertable<Event> {
  final int id;

  /// [EventKind] name: person, couple or other.
  final String kind;

  /// [EventType] name.
  final String type;

  /// Label for custom types, e.g. "Housewarming".
  final String? customLabel;

  /// Title for non-person events, e.g. "Car insurance".
  final String? title;
  final int day;
  final int month;

  /// Start year: optional for yearly/monthly, required for one-time.
  final int? year;

  /// [Repeat] name.
  final String repeat;

  /// [Feb29Rule] name.
  final String feb29Rule;

  /// Own rating; null means use the person's.
  final int? stars;
  final String? notes;

  /// Person whose number Call and Share use (Phase 2).
  final int? sendWishesToId;

  /// "mine" or "theirs" midnight (Phase 3).
  final String alarmClock;
  final String? draftMessage;
  final bool belatedNudge;
  final String? sound;
  final DateTime createdAt;
  const Event({
    required this.id,
    required this.kind,
    required this.type,
    this.customLabel,
    this.title,
    required this.day,
    required this.month,
    this.year,
    required this.repeat,
    required this.feb29Rule,
    this.stars,
    this.notes,
    this.sendWishesToId,
    required this.alarmClock,
    this.draftMessage,
    required this.belatedNudge,
    this.sound,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || customLabel != null) {
      map['custom_label'] = Variable<String>(customLabel);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['day'] = Variable<int>(day);
    map['month'] = Variable<int>(month);
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    map['repeat'] = Variable<String>(repeat);
    map['feb29_rule'] = Variable<String>(feb29Rule);
    if (!nullToAbsent || stars != null) {
      map['stars'] = Variable<int>(stars);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || sendWishesToId != null) {
      map['send_wishes_to_id'] = Variable<int>(sendWishesToId);
    }
    map['alarm_clock'] = Variable<String>(alarmClock);
    if (!nullToAbsent || draftMessage != null) {
      map['draft_message'] = Variable<String>(draftMessage);
    }
    map['belated_nudge'] = Variable<bool>(belatedNudge);
    if (!nullToAbsent || sound != null) {
      map['sound'] = Variable<String>(sound);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      id: Value(id),
      kind: Value(kind),
      type: Value(type),
      customLabel: customLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(customLabel),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      day: Value(day),
      month: Value(month),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      repeat: Value(repeat),
      feb29Rule: Value(feb29Rule),
      stars: stars == null && nullToAbsent
          ? const Value.absent()
          : Value(stars),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      sendWishesToId: sendWishesToId == null && nullToAbsent
          ? const Value.absent()
          : Value(sendWishesToId),
      alarmClock: Value(alarmClock),
      draftMessage: draftMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(draftMessage),
      belatedNudge: Value(belatedNudge),
      sound: sound == null && nullToAbsent
          ? const Value.absent()
          : Value(sound),
      createdAt: Value(createdAt),
    );
  }

  factory Event.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Event(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      type: serializer.fromJson<String>(json['type']),
      customLabel: serializer.fromJson<String?>(json['customLabel']),
      title: serializer.fromJson<String?>(json['title']),
      day: serializer.fromJson<int>(json['day']),
      month: serializer.fromJson<int>(json['month']),
      year: serializer.fromJson<int?>(json['year']),
      repeat: serializer.fromJson<String>(json['repeat']),
      feb29Rule: serializer.fromJson<String>(json['feb29Rule']),
      stars: serializer.fromJson<int?>(json['stars']),
      notes: serializer.fromJson<String?>(json['notes']),
      sendWishesToId: serializer.fromJson<int?>(json['sendWishesToId']),
      alarmClock: serializer.fromJson<String>(json['alarmClock']),
      draftMessage: serializer.fromJson<String?>(json['draftMessage']),
      belatedNudge: serializer.fromJson<bool>(json['belatedNudge']),
      sound: serializer.fromJson<String?>(json['sound']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'type': serializer.toJson<String>(type),
      'customLabel': serializer.toJson<String?>(customLabel),
      'title': serializer.toJson<String?>(title),
      'day': serializer.toJson<int>(day),
      'month': serializer.toJson<int>(month),
      'year': serializer.toJson<int?>(year),
      'repeat': serializer.toJson<String>(repeat),
      'feb29Rule': serializer.toJson<String>(feb29Rule),
      'stars': serializer.toJson<int?>(stars),
      'notes': serializer.toJson<String?>(notes),
      'sendWishesToId': serializer.toJson<int?>(sendWishesToId),
      'alarmClock': serializer.toJson<String>(alarmClock),
      'draftMessage': serializer.toJson<String?>(draftMessage),
      'belatedNudge': serializer.toJson<bool>(belatedNudge),
      'sound': serializer.toJson<String?>(sound),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Event copyWith({
    int? id,
    String? kind,
    String? type,
    Value<String?> customLabel = const Value.absent(),
    Value<String?> title = const Value.absent(),
    int? day,
    int? month,
    Value<int?> year = const Value.absent(),
    String? repeat,
    String? feb29Rule,
    Value<int?> stars = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<int?> sendWishesToId = const Value.absent(),
    String? alarmClock,
    Value<String?> draftMessage = const Value.absent(),
    bool? belatedNudge,
    Value<String?> sound = const Value.absent(),
    DateTime? createdAt,
  }) => Event(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    type: type ?? this.type,
    customLabel: customLabel.present ? customLabel.value : this.customLabel,
    title: title.present ? title.value : this.title,
    day: day ?? this.day,
    month: month ?? this.month,
    year: year.present ? year.value : this.year,
    repeat: repeat ?? this.repeat,
    feb29Rule: feb29Rule ?? this.feb29Rule,
    stars: stars.present ? stars.value : this.stars,
    notes: notes.present ? notes.value : this.notes,
    sendWishesToId: sendWishesToId.present
        ? sendWishesToId.value
        : this.sendWishesToId,
    alarmClock: alarmClock ?? this.alarmClock,
    draftMessage: draftMessage.present ? draftMessage.value : this.draftMessage,
    belatedNudge: belatedNudge ?? this.belatedNudge,
    sound: sound.present ? sound.value : this.sound,
    createdAt: createdAt ?? this.createdAt,
  );
  Event copyWithCompanion(EventsCompanion data) {
    return Event(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      type: data.type.present ? data.type.value : this.type,
      customLabel: data.customLabel.present
          ? data.customLabel.value
          : this.customLabel,
      title: data.title.present ? data.title.value : this.title,
      day: data.day.present ? data.day.value : this.day,
      month: data.month.present ? data.month.value : this.month,
      year: data.year.present ? data.year.value : this.year,
      repeat: data.repeat.present ? data.repeat.value : this.repeat,
      feb29Rule: data.feb29Rule.present ? data.feb29Rule.value : this.feb29Rule,
      stars: data.stars.present ? data.stars.value : this.stars,
      notes: data.notes.present ? data.notes.value : this.notes,
      sendWishesToId: data.sendWishesToId.present
          ? data.sendWishesToId.value
          : this.sendWishesToId,
      alarmClock: data.alarmClock.present
          ? data.alarmClock.value
          : this.alarmClock,
      draftMessage: data.draftMessage.present
          ? data.draftMessage.value
          : this.draftMessage,
      belatedNudge: data.belatedNudge.present
          ? data.belatedNudge.value
          : this.belatedNudge,
      sound: data.sound.present ? data.sound.value : this.sound,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Event(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('type: $type, ')
          ..write('customLabel: $customLabel, ')
          ..write('title: $title, ')
          ..write('day: $day, ')
          ..write('month: $month, ')
          ..write('year: $year, ')
          ..write('repeat: $repeat, ')
          ..write('feb29Rule: $feb29Rule, ')
          ..write('stars: $stars, ')
          ..write('notes: $notes, ')
          ..write('sendWishesToId: $sendWishesToId, ')
          ..write('alarmClock: $alarmClock, ')
          ..write('draftMessage: $draftMessage, ')
          ..write('belatedNudge: $belatedNudge, ')
          ..write('sound: $sound, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    type,
    customLabel,
    title,
    day,
    month,
    year,
    repeat,
    feb29Rule,
    stars,
    notes,
    sendWishesToId,
    alarmClock,
    draftMessage,
    belatedNudge,
    sound,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Event &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.type == this.type &&
          other.customLabel == this.customLabel &&
          other.title == this.title &&
          other.day == this.day &&
          other.month == this.month &&
          other.year == this.year &&
          other.repeat == this.repeat &&
          other.feb29Rule == this.feb29Rule &&
          other.stars == this.stars &&
          other.notes == this.notes &&
          other.sendWishesToId == this.sendWishesToId &&
          other.alarmClock == this.alarmClock &&
          other.draftMessage == this.draftMessage &&
          other.belatedNudge == this.belatedNudge &&
          other.sound == this.sound &&
          other.createdAt == this.createdAt);
}

class EventsCompanion extends UpdateCompanion<Event> {
  final Value<int> id;
  final Value<String> kind;
  final Value<String> type;
  final Value<String?> customLabel;
  final Value<String?> title;
  final Value<int> day;
  final Value<int> month;
  final Value<int?> year;
  final Value<String> repeat;
  final Value<String> feb29Rule;
  final Value<int?> stars;
  final Value<String?> notes;
  final Value<int?> sendWishesToId;
  final Value<String> alarmClock;
  final Value<String?> draftMessage;
  final Value<bool> belatedNudge;
  final Value<String?> sound;
  final Value<DateTime> createdAt;
  const EventsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.type = const Value.absent(),
    this.customLabel = const Value.absent(),
    this.title = const Value.absent(),
    this.day = const Value.absent(),
    this.month = const Value.absent(),
    this.year = const Value.absent(),
    this.repeat = const Value.absent(),
    this.feb29Rule = const Value.absent(),
    this.stars = const Value.absent(),
    this.notes = const Value.absent(),
    this.sendWishesToId = const Value.absent(),
    this.alarmClock = const Value.absent(),
    this.draftMessage = const Value.absent(),
    this.belatedNudge = const Value.absent(),
    this.sound = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  EventsCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    required String type,
    this.customLabel = const Value.absent(),
    this.title = const Value.absent(),
    required int day,
    required int month,
    this.year = const Value.absent(),
    this.repeat = const Value.absent(),
    this.feb29Rule = const Value.absent(),
    this.stars = const Value.absent(),
    this.notes = const Value.absent(),
    this.sendWishesToId = const Value.absent(),
    this.alarmClock = const Value.absent(),
    this.draftMessage = const Value.absent(),
    this.belatedNudge = const Value.absent(),
    this.sound = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : kind = Value(kind),
       type = Value(type),
       day = Value(day),
       month = Value(month);
  static Insertable<Event> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? type,
    Expression<String>? customLabel,
    Expression<String>? title,
    Expression<int>? day,
    Expression<int>? month,
    Expression<int>? year,
    Expression<String>? repeat,
    Expression<String>? feb29Rule,
    Expression<int>? stars,
    Expression<String>? notes,
    Expression<int>? sendWishesToId,
    Expression<String>? alarmClock,
    Expression<String>? draftMessage,
    Expression<bool>? belatedNudge,
    Expression<String>? sound,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (type != null) 'type': type,
      if (customLabel != null) 'custom_label': customLabel,
      if (title != null) 'title': title,
      if (day != null) 'day': day,
      if (month != null) 'month': month,
      if (year != null) 'year': year,
      if (repeat != null) 'repeat': repeat,
      if (feb29Rule != null) 'feb29_rule': feb29Rule,
      if (stars != null) 'stars': stars,
      if (notes != null) 'notes': notes,
      if (sendWishesToId != null) 'send_wishes_to_id': sendWishesToId,
      if (alarmClock != null) 'alarm_clock': alarmClock,
      if (draftMessage != null) 'draft_message': draftMessage,
      if (belatedNudge != null) 'belated_nudge': belatedNudge,
      if (sound != null) 'sound': sound,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  EventsCompanion copyWith({
    Value<int>? id,
    Value<String>? kind,
    Value<String>? type,
    Value<String?>? customLabel,
    Value<String?>? title,
    Value<int>? day,
    Value<int>? month,
    Value<int?>? year,
    Value<String>? repeat,
    Value<String>? feb29Rule,
    Value<int?>? stars,
    Value<String?>? notes,
    Value<int?>? sendWishesToId,
    Value<String>? alarmClock,
    Value<String?>? draftMessage,
    Value<bool>? belatedNudge,
    Value<String?>? sound,
    Value<DateTime>? createdAt,
  }) {
    return EventsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      type: type ?? this.type,
      customLabel: customLabel ?? this.customLabel,
      title: title ?? this.title,
      day: day ?? this.day,
      month: month ?? this.month,
      year: year ?? this.year,
      repeat: repeat ?? this.repeat,
      feb29Rule: feb29Rule ?? this.feb29Rule,
      stars: stars ?? this.stars,
      notes: notes ?? this.notes,
      sendWishesToId: sendWishesToId ?? this.sendWishesToId,
      alarmClock: alarmClock ?? this.alarmClock,
      draftMessage: draftMessage ?? this.draftMessage,
      belatedNudge: belatedNudge ?? this.belatedNudge,
      sound: sound ?? this.sound,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (customLabel.present) {
      map['custom_label'] = Variable<String>(customLabel.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (repeat.present) {
      map['repeat'] = Variable<String>(repeat.value);
    }
    if (feb29Rule.present) {
      map['feb29_rule'] = Variable<String>(feb29Rule.value);
    }
    if (stars.present) {
      map['stars'] = Variable<int>(stars.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (sendWishesToId.present) {
      map['send_wishes_to_id'] = Variable<int>(sendWishesToId.value);
    }
    if (alarmClock.present) {
      map['alarm_clock'] = Variable<String>(alarmClock.value);
    }
    if (draftMessage.present) {
      map['draft_message'] = Variable<String>(draftMessage.value);
    }
    if (belatedNudge.present) {
      map['belated_nudge'] = Variable<bool>(belatedNudge.value);
    }
    if (sound.present) {
      map['sound'] = Variable<String>(sound.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('type: $type, ')
          ..write('customLabel: $customLabel, ')
          ..write('title: $title, ')
          ..write('day: $day, ')
          ..write('month: $month, ')
          ..write('year: $year, ')
          ..write('repeat: $repeat, ')
          ..write('feb29Rule: $feb29Rule, ')
          ..write('stars: $stars, ')
          ..write('notes: $notes, ')
          ..write('sendWishesToId: $sendWishesToId, ')
          ..write('alarmClock: $alarmClock, ')
          ..write('draftMessage: $draftMessage, ')
          ..write('belatedNudge: $belatedNudge, ')
          ..write('sound: $sound, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $EventPeopleTable extends EventPeople
    with TableInfo<$EventPeopleTable, EventPeopleData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventPeopleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<int> eventId = GeneratedColumn<int>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES events (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES people (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<int> role = GeneratedColumn<int>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [eventId, personId, role];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_people';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventPeopleData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId, personId};
  @override
  EventPeopleData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventPeopleData(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}event_id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}role'],
      )!,
    );
  }

  @override
  $EventPeopleTable createAlias(String alias) {
    return $EventPeopleTable(attachedDatabase, alias);
  }
}

class EventPeopleData extends DataClass implements Insertable<EventPeopleData> {
  final int eventId;
  final int personId;

  /// 0 = primary, 1 = partner. Sets the order in "Ravi & Priya".
  final int role;
  const EventPeopleData({
    required this.eventId,
    required this.personId,
    required this.role,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<int>(eventId);
    map['person_id'] = Variable<int>(personId);
    map['role'] = Variable<int>(role);
    return map;
  }

  EventPeopleCompanion toCompanion(bool nullToAbsent) {
    return EventPeopleCompanion(
      eventId: Value(eventId),
      personId: Value(personId),
      role: Value(role),
    );
  }

  factory EventPeopleData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventPeopleData(
      eventId: serializer.fromJson<int>(json['eventId']),
      personId: serializer.fromJson<int>(json['personId']),
      role: serializer.fromJson<int>(json['role']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<int>(eventId),
      'personId': serializer.toJson<int>(personId),
      'role': serializer.toJson<int>(role),
    };
  }

  EventPeopleData copyWith({int? eventId, int? personId, int? role}) =>
      EventPeopleData(
        eventId: eventId ?? this.eventId,
        personId: personId ?? this.personId,
        role: role ?? this.role,
      );
  EventPeopleData copyWithCompanion(EventPeopleCompanion data) {
    return EventPeopleData(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      personId: data.personId.present ? data.personId.value : this.personId,
      role: data.role.present ? data.role.value : this.role,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventPeopleData(')
          ..write('eventId: $eventId, ')
          ..write('personId: $personId, ')
          ..write('role: $role')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(eventId, personId, role);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventPeopleData &&
          other.eventId == this.eventId &&
          other.personId == this.personId &&
          other.role == this.role);
}

class EventPeopleCompanion extends UpdateCompanion<EventPeopleData> {
  final Value<int> eventId;
  final Value<int> personId;
  final Value<int> role;
  final Value<int> rowid;
  const EventPeopleCompanion({
    this.eventId = const Value.absent(),
    this.personId = const Value.absent(),
    this.role = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventPeopleCompanion.insert({
    required int eventId,
    required int personId,
    this.role = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       personId = Value(personId);
  static Insertable<EventPeopleData> custom({
    Expression<int>? eventId,
    Expression<int>? personId,
    Expression<int>? role,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (personId != null) 'person_id': personId,
      if (role != null) 'role': role,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventPeopleCompanion copyWith({
    Value<int>? eventId,
    Value<int>? personId,
    Value<int>? role,
    Value<int>? rowid,
  }) {
    return EventPeopleCompanion(
      eventId: eventId ?? this.eventId,
      personId: personId ?? this.personId,
      role: role ?? this.role,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<int>(eventId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (role.present) {
      map['role'] = Variable<int>(role.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventPeopleCompanion(')
          ..write('eventId: $eventId, ')
          ..write('personId: $personId, ')
          ..write('role: $role, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GiftIdeasTable extends GiftIdeas
    with TableInfo<$GiftIdeasTable, GiftIdea> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GiftIdeasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES people (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _ideaMeta = const VerificationMeta('idea');
  @override
  late final GeneratedColumn<String> idea = GeneratedColumn<String>(
    'idea',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purchasedMeta = const VerificationMeta(
    'purchased',
  );
  @override
  late final GeneratedColumn<bool> purchased = GeneratedColumn<bool>(
    'purchased',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("purchased" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personId,
    idea,
    purchased,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gift_ideas';
  @override
  VerificationContext validateIntegrity(
    Insertable<GiftIdea> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('idea')) {
      context.handle(
        _ideaMeta,
        idea.isAcceptableOrUnknown(data['idea']!, _ideaMeta),
      );
    } else if (isInserting) {
      context.missing(_ideaMeta);
    }
    if (data.containsKey('purchased')) {
      context.handle(
        _purchasedMeta,
        purchased.isAcceptableOrUnknown(data['purchased']!, _purchasedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GiftIdea map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GiftIdea(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      )!,
      idea: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idea'],
      )!,
      purchased: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}purchased'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $GiftIdeasTable createAlias(String alias) {
    return $GiftIdeasTable(attachedDatabase, alias);
  }
}

class GiftIdea extends DataClass implements Insertable<GiftIdea> {
  final int id;
  final int personId;
  final String idea;
  final bool purchased;
  final DateTime createdAt;
  const GiftIdea({
    required this.id,
    required this.personId,
    required this.idea,
    required this.purchased,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['person_id'] = Variable<int>(personId);
    map['idea'] = Variable<String>(idea);
    map['purchased'] = Variable<bool>(purchased);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GiftIdeasCompanion toCompanion(bool nullToAbsent) {
    return GiftIdeasCompanion(
      id: Value(id),
      personId: Value(personId),
      idea: Value(idea),
      purchased: Value(purchased),
      createdAt: Value(createdAt),
    );
  }

  factory GiftIdea.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GiftIdea(
      id: serializer.fromJson<int>(json['id']),
      personId: serializer.fromJson<int>(json['personId']),
      idea: serializer.fromJson<String>(json['idea']),
      purchased: serializer.fromJson<bool>(json['purchased']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'personId': serializer.toJson<int>(personId),
      'idea': serializer.toJson<String>(idea),
      'purchased': serializer.toJson<bool>(purchased),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  GiftIdea copyWith({
    int? id,
    int? personId,
    String? idea,
    bool? purchased,
    DateTime? createdAt,
  }) => GiftIdea(
    id: id ?? this.id,
    personId: personId ?? this.personId,
    idea: idea ?? this.idea,
    purchased: purchased ?? this.purchased,
    createdAt: createdAt ?? this.createdAt,
  );
  GiftIdea copyWithCompanion(GiftIdeasCompanion data) {
    return GiftIdea(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      idea: data.idea.present ? data.idea.value : this.idea,
      purchased: data.purchased.present ? data.purchased.value : this.purchased,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GiftIdea(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('idea: $idea, ')
          ..write('purchased: $purchased, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, personId, idea, purchased, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GiftIdea &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.idea == this.idea &&
          other.purchased == this.purchased &&
          other.createdAt == this.createdAt);
}

class GiftIdeasCompanion extends UpdateCompanion<GiftIdea> {
  final Value<int> id;
  final Value<int> personId;
  final Value<String> idea;
  final Value<bool> purchased;
  final Value<DateTime> createdAt;
  const GiftIdeasCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.idea = const Value.absent(),
    this.purchased = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  GiftIdeasCompanion.insert({
    this.id = const Value.absent(),
    required int personId,
    required String idea,
    this.purchased = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : personId = Value(personId),
       idea = Value(idea);
  static Insertable<GiftIdea> custom({
    Expression<int>? id,
    Expression<int>? personId,
    Expression<String>? idea,
    Expression<bool>? purchased,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (idea != null) 'idea': idea,
      if (purchased != null) 'purchased': purchased,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  GiftIdeasCompanion copyWith({
    Value<int>? id,
    Value<int>? personId,
    Value<String>? idea,
    Value<bool>? purchased,
    Value<DateTime>? createdAt,
  }) {
    return GiftIdeasCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      idea: idea ?? this.idea,
      purchased: purchased ?? this.purchased,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (idea.present) {
      map['idea'] = Variable<String>(idea.value);
    }
    if (purchased.present) {
      map['purchased'] = Variable<bool>(purchased.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GiftIdeasCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('idea: $idea, ')
          ..write('purchased: $purchased, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ContactNoticesTable extends ContactNotices
    with TableInfo<$ContactNoticesTable, ContactNotice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactNoticesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES people (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seenMeta = const VerificationMeta('seen');
  @override
  late final GeneratedColumn<bool> seen = GeneratedColumn<bool>(
    'seen',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("seen" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personId,
    message,
    seen,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contact_notices';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContactNotice> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('seen')) {
      context.handle(
        _seenMeta,
        seen.isAcceptableOrUnknown(data['seen']!, _seenMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContactNotice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContactNotice(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      seen: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}seen'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ContactNoticesTable createAlias(String alias) {
    return $ContactNoticesTable(attachedDatabase, alias);
  }
}

class ContactNotice extends DataClass implements Insertable<ContactNotice> {
  final int id;
  final int personId;
  final String message;
  final bool seen;
  final DateTime createdAt;
  const ContactNotice({
    required this.id,
    required this.personId,
    required this.message,
    required this.seen,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['person_id'] = Variable<int>(personId);
    map['message'] = Variable<String>(message);
    map['seen'] = Variable<bool>(seen);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ContactNoticesCompanion toCompanion(bool nullToAbsent) {
    return ContactNoticesCompanion(
      id: Value(id),
      personId: Value(personId),
      message: Value(message),
      seen: Value(seen),
      createdAt: Value(createdAt),
    );
  }

  factory ContactNotice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContactNotice(
      id: serializer.fromJson<int>(json['id']),
      personId: serializer.fromJson<int>(json['personId']),
      message: serializer.fromJson<String>(json['message']),
      seen: serializer.fromJson<bool>(json['seen']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'personId': serializer.toJson<int>(personId),
      'message': serializer.toJson<String>(message),
      'seen': serializer.toJson<bool>(seen),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ContactNotice copyWith({
    int? id,
    int? personId,
    String? message,
    bool? seen,
    DateTime? createdAt,
  }) => ContactNotice(
    id: id ?? this.id,
    personId: personId ?? this.personId,
    message: message ?? this.message,
    seen: seen ?? this.seen,
    createdAt: createdAt ?? this.createdAt,
  );
  ContactNotice copyWithCompanion(ContactNoticesCompanion data) {
    return ContactNotice(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      message: data.message.present ? data.message.value : this.message,
      seen: data.seen.present ? data.seen.value : this.seen,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContactNotice(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('message: $message, ')
          ..write('seen: $seen, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, personId, message, seen, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContactNotice &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.message == this.message &&
          other.seen == this.seen &&
          other.createdAt == this.createdAt);
}

class ContactNoticesCompanion extends UpdateCompanion<ContactNotice> {
  final Value<int> id;
  final Value<int> personId;
  final Value<String> message;
  final Value<bool> seen;
  final Value<DateTime> createdAt;
  const ContactNoticesCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.message = const Value.absent(),
    this.seen = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ContactNoticesCompanion.insert({
    this.id = const Value.absent(),
    required int personId,
    required String message,
    this.seen = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : personId = Value(personId),
       message = Value(message);
  static Insertable<ContactNotice> custom({
    Expression<int>? id,
    Expression<int>? personId,
    Expression<String>? message,
    Expression<bool>? seen,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (message != null) 'message': message,
      if (seen != null) 'seen': seen,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ContactNoticesCompanion copyWith({
    Value<int>? id,
    Value<int>? personId,
    Value<String>? message,
    Value<bool>? seen,
    Value<DateTime>? createdAt,
  }) {
    return ContactNoticesCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      message: message ?? this.message,
      seen: seen ?? this.seen,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (seen.present) {
      map['seen'] = Variable<bool>(seen.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactNoticesCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('message: $message, ')
          ..write('seen: $seen, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PeopleTable people = $PeopleTable(this);
  late final $EventsTable events = $EventsTable(this);
  late final $EventPeopleTable eventPeople = $EventPeopleTable(this);
  late final $GiftIdeasTable giftIdeas = $GiftIdeasTable(this);
  late final $ContactNoticesTable contactNotices = $ContactNoticesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    people,
    events,
    eventPeople,
    giftIdeas,
    contactNotices,
    settings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'events',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('event_people', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'people',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('event_people', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'people',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('gift_ideas', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'people',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('contact_notices', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$PeopleTableCreateCompanionBuilder = PeopleCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> nickname,
  Value<String?> photoPath,
  Value<String> relationship,
  Value<String?> customRelationship,
  Value<int> stars,
  Value<int?> birthYear,
  Value<String?> timeZone,
  Value<String?> callNumber,
  Value<String?> whatsappNumber,
  Value<String?> notes,
  Value<String?> likes,
  Value<String?> dislikes,
  Value<String?> clothingSize,
  Value<String?> favouriteSweets,
  Value<String?> contactId,
  Value<String?> contactLookupKey,
  Value<String> editedFields,
  Value<bool> isMe,
  Value<bool> isArchived,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$PeopleTableUpdateCompanionBuilder = PeopleCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> nickname,
  Value<String?> photoPath,
  Value<String> relationship,
  Value<String?> customRelationship,
  Value<int> stars,
  Value<int?> birthYear,
  Value<String?> timeZone,
  Value<String?> callNumber,
  Value<String?> whatsappNumber,
  Value<String?> notes,
  Value<String?> likes,
  Value<String?> dislikes,
  Value<String?> clothingSize,
  Value<String?> favouriteSweets,
  Value<String?> contactId,
  Value<String?> contactLookupKey,
  Value<String> editedFields,
  Value<bool> isMe,
  Value<bool> isArchived,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$PeopleTableReferences
    extends BaseReferences<_$AppDatabase, $PeopleTable, Person> {
  $$PeopleTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EventPeopleTable, List<EventPeopleData>>
  _eventPeopleRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.eventPeople,
    aliasName: 'people__id__event_people__person_id',
  );

  $$EventPeopleTableProcessedTableManager get eventPeopleRefs {
    final manager = $$EventPeopleTableTableManager(
      $_db,
      $_db.eventPeople,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventPeopleRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GiftIdeasTable, List<GiftIdea>>
  _giftIdeasRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.giftIdeas,
    aliasName: 'people__id__gift_ideas__person_id',
  );

  $$GiftIdeasTableProcessedTableManager get giftIdeasRefs {
    final manager = $$GiftIdeasTableTableManager(
      $_db,
      $_db.giftIdeas,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_giftIdeasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ContactNoticesTable, List<ContactNotice>>
  _contactNoticesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.contactNotices,
    aliasName: 'people__id__contact_notices__person_id',
  );

  $$ContactNoticesTableProcessedTableManager get contactNoticesRefs {
    final manager = $$ContactNoticesTableTableManager(
      $_db,
      $_db.contactNotices,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_contactNoticesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PeopleTableFilterComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customRelationship => $composableBuilder(
    column: $table.customRelationship,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stars => $composableBuilder(
    column: $table.stars,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get birthYear => $composableBuilder(
    column: $table.birthYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeZone => $composableBuilder(
    column: $table.timeZone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get callNumber => $composableBuilder(
    column: $table.callNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get whatsappNumber => $composableBuilder(
    column: $table.whatsappNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get likes => $composableBuilder(
    column: $table.likes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dislikes => $composableBuilder(
    column: $table.dislikes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clothingSize => $composableBuilder(
    column: $table.clothingSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get favouriteSweets => $composableBuilder(
    column: $table.favouriteSweets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactId => $composableBuilder(
    column: $table.contactId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactLookupKey => $composableBuilder(
    column: $table.contactLookupKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get editedFields => $composableBuilder(
    column: $table.editedFields,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMe => $composableBuilder(
    column: $table.isMe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> eventPeopleRefs(
    Expression<bool> Function($$EventPeopleTableFilterComposer f) f,
  ) {
    final $$EventPeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventPeople,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventPeopleTableFilterComposer(
            $db: $db,
            $table: $db.eventPeople,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> giftIdeasRefs(
    Expression<bool> Function($$GiftIdeasTableFilterComposer f) f,
  ) {
    final $$GiftIdeasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.giftIdeas,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GiftIdeasTableFilterComposer(
            $db: $db,
            $table: $db.giftIdeas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> contactNoticesRefs(
    Expression<bool> Function($$ContactNoticesTableFilterComposer f) f,
  ) {
    final $$ContactNoticesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.contactNotices,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactNoticesTableFilterComposer(
            $db: $db,
            $table: $db.contactNotices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PeopleTableOrderingComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customRelationship => $composableBuilder(
    column: $table.customRelationship,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stars => $composableBuilder(
    column: $table.stars,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get birthYear => $composableBuilder(
    column: $table.birthYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeZone => $composableBuilder(
    column: $table.timeZone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get callNumber => $composableBuilder(
    column: $table.callNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get whatsappNumber => $composableBuilder(
    column: $table.whatsappNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get likes => $composableBuilder(
    column: $table.likes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dislikes => $composableBuilder(
    column: $table.dislikes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clothingSize => $composableBuilder(
    column: $table.clothingSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get favouriteSweets => $composableBuilder(
    column: $table.favouriteSweets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactId => $composableBuilder(
    column: $table.contactId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactLookupKey => $composableBuilder(
    column: $table.contactLookupKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get editedFields => $composableBuilder(
    column: $table.editedFields,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMe => $composableBuilder(
    column: $table.isMe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeopleTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customRelationship => $composableBuilder(
    column: $table.customRelationship,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stars =>
      $composableBuilder(column: $table.stars, builder: (column) => column);

  GeneratedColumn<int> get birthYear =>
      $composableBuilder(column: $table.birthYear, builder: (column) => column);

  GeneratedColumn<String> get timeZone =>
      $composableBuilder(column: $table.timeZone, builder: (column) => column);

  GeneratedColumn<String> get callNumber => $composableBuilder(
    column: $table.callNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get whatsappNumber => $composableBuilder(
    column: $table.whatsappNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get likes =>
      $composableBuilder(column: $table.likes, builder: (column) => column);

  GeneratedColumn<String> get dislikes =>
      $composableBuilder(column: $table.dislikes, builder: (column) => column);

  GeneratedColumn<String> get clothingSize => $composableBuilder(
    column: $table.clothingSize,
    builder: (column) => column,
  );

  GeneratedColumn<String> get favouriteSweets => $composableBuilder(
    column: $table.favouriteSweets,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contactId =>
      $composableBuilder(column: $table.contactId, builder: (column) => column);

  GeneratedColumn<String> get contactLookupKey => $composableBuilder(
    column: $table.contactLookupKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get editedFields => $composableBuilder(
    column: $table.editedFields,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isMe =>
      $composableBuilder(column: $table.isMe, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> eventPeopleRefs<T extends Object>(
    Expression<T> Function($$EventPeopleTableAnnotationComposer a) f,
  ) {
    final $$EventPeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventPeople,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventPeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.eventPeople,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> giftIdeasRefs<T extends Object>(
    Expression<T> Function($$GiftIdeasTableAnnotationComposer a) f,
  ) {
    final $$GiftIdeasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.giftIdeas,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GiftIdeasTableAnnotationComposer(
            $db: $db,
            $table: $db.giftIdeas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> contactNoticesRefs<T extends Object>(
    Expression<T> Function($$ContactNoticesTableAnnotationComposer a) f,
  ) {
    final $$ContactNoticesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.contactNotices,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactNoticesTableAnnotationComposer(
            $db: $db,
            $table: $db.contactNotices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PeopleTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeopleTable,
          Person,
          $$PeopleTableFilterComposer,
          $$PeopleTableOrderingComposer,
          $$PeopleTableAnnotationComposer,
          $$PeopleTableCreateCompanionBuilder,
          $$PeopleTableUpdateCompanionBuilder,
          (Person, $$PeopleTableReferences),
          Person,
          PrefetchHooks Function({
            bool eventPeopleRefs,
            bool giftIdeasRefs,
            bool contactNoticesRefs,
          })
        > {
  $$PeopleTableTableManager(_$AppDatabase db, $PeopleTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeopleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeopleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeopleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> nickname = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<String> relationship = const Value.absent(),
                Value<String?> customRelationship = const Value.absent(),
                Value<int> stars = const Value.absent(),
                Value<int?> birthYear = const Value.absent(),
                Value<String?> timeZone = const Value.absent(),
                Value<String?> callNumber = const Value.absent(),
                Value<String?> whatsappNumber = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> likes = const Value.absent(),
                Value<String?> dislikes = const Value.absent(),
                Value<String?> clothingSize = const Value.absent(),
                Value<String?> favouriteSweets = const Value.absent(),
                Value<String?> contactId = const Value.absent(),
                Value<String?> contactLookupKey = const Value.absent(),
                Value<String> editedFields = const Value.absent(),
                Value<bool> isMe = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PeopleCompanion(
                id: id,
                name: name,
                nickname: nickname,
                photoPath: photoPath,
                relationship: relationship,
                customRelationship: customRelationship,
                stars: stars,
                birthYear: birthYear,
                timeZone: timeZone,
                callNumber: callNumber,
                whatsappNumber: whatsappNumber,
                notes: notes,
                likes: likes,
                dislikes: dislikes,
                clothingSize: clothingSize,
                favouriteSweets: favouriteSweets,
                contactId: contactId,
                contactLookupKey: contactLookupKey,
                editedFields: editedFields,
                isMe: isMe,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> nickname = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<String> relationship = const Value.absent(),
                Value<String?> customRelationship = const Value.absent(),
                Value<int> stars = const Value.absent(),
                Value<int?> birthYear = const Value.absent(),
                Value<String?> timeZone = const Value.absent(),
                Value<String?> callNumber = const Value.absent(),
                Value<String?> whatsappNumber = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> likes = const Value.absent(),
                Value<String?> dislikes = const Value.absent(),
                Value<String?> clothingSize = const Value.absent(),
                Value<String?> favouriteSweets = const Value.absent(),
                Value<String?> contactId = const Value.absent(),
                Value<String?> contactLookupKey = const Value.absent(),
                Value<String> editedFields = const Value.absent(),
                Value<bool> isMe = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PeopleCompanion.insert(
                id: id,
                name: name,
                nickname: nickname,
                photoPath: photoPath,
                relationship: relationship,
                customRelationship: customRelationship,
                stars: stars,
                birthYear: birthYear,
                timeZone: timeZone,
                callNumber: callNumber,
                whatsappNumber: whatsappNumber,
                notes: notes,
                likes: likes,
                dislikes: dislikes,
                clothingSize: clothingSize,
                favouriteSweets: favouriteSweets,
                contactId: contactId,
                contactLookupKey: contactLookupKey,
                editedFields: editedFields,
                isMe: isMe,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PeopleTable, Person>(table),
                  $$PeopleTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                eventPeopleRefs = false,
                giftIdeasRefs = false,
                contactNoticesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (eventPeopleRefs) db.eventPeople,
                    if (giftIdeasRefs) db.giftIdeas,
                    if (contactNoticesRefs) db.contactNotices,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (eventPeopleRefs)
                        await $_getPrefetchedData<
                          Person,
                          $PeopleTable,
                          EventPeopleData
                        >(
                          currentTable: table,
                          referencedTable: $$PeopleTableReferences
                              ._eventPeopleRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PeopleTableReferences(
                                db,
                                table,
                                p0,
                              ).eventPeopleRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (giftIdeasRefs)
                        await $_getPrefetchedData<
                          Person,
                          $PeopleTable,
                          GiftIdea
                        >(
                          currentTable: table,
                          referencedTable: $$PeopleTableReferences
                              ._giftIdeasRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PeopleTableReferences(
                                db,
                                table,
                                p0,
                              ).giftIdeasRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (contactNoticesRefs)
                        await $_getPrefetchedData<
                          Person,
                          $PeopleTable,
                          ContactNotice
                        >(
                          currentTable: table,
                          referencedTable: $$PeopleTableReferences
                              ._contactNoticesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PeopleTableReferences(
                                db,
                                table,
                                p0,
                              ).contactNoticesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PeopleTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeopleTable,
      Person,
      $$PeopleTableFilterComposer,
      $$PeopleTableOrderingComposer,
      $$PeopleTableAnnotationComposer,
      $$PeopleTableCreateCompanionBuilder,
      $$PeopleTableUpdateCompanionBuilder,
      (Person, $$PeopleTableReferences),
      Person,
      PrefetchHooks Function({
        bool eventPeopleRefs,
        bool giftIdeasRefs,
        bool contactNoticesRefs,
      })
    >;
typedef $$EventsTableCreateCompanionBuilder = EventsCompanion Function({
  Value<int> id,
  required String kind,
  required String type,
  Value<String?> customLabel,
  Value<String?> title,
  required int day,
  required int month,
  Value<int?> year,
  Value<String> repeat,
  Value<String> feb29Rule,
  Value<int?> stars,
  Value<String?> notes,
  Value<int?> sendWishesToId,
  Value<String> alarmClock,
  Value<String?> draftMessage,
  Value<bool> belatedNudge,
  Value<String?> sound,
  Value<DateTime> createdAt,
});
typedef $$EventsTableUpdateCompanionBuilder = EventsCompanion Function({
  Value<int> id,
  Value<String> kind,
  Value<String> type,
  Value<String?> customLabel,
  Value<String?> title,
  Value<int> day,
  Value<int> month,
  Value<int?> year,
  Value<String> repeat,
  Value<String> feb29Rule,
  Value<int?> stars,
  Value<String?> notes,
  Value<int?> sendWishesToId,
  Value<String> alarmClock,
  Value<String?> draftMessage,
  Value<bool> belatedNudge,
  Value<String?> sound,
  Value<DateTime> createdAt,
});

final class $$EventsTableReferences
    extends BaseReferences<_$AppDatabase, $EventsTable, Event> {
  $$EventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EventPeopleTable, List<EventPeopleData>>
  _eventPeopleRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.eventPeople,
    aliasName: 'events__id__event_people__event_id',
  );

  $$EventPeopleTableProcessedTableManager get eventPeopleRefs {
    final manager = $$EventPeopleTableTableManager(
      $_db,
      $_db.eventPeople,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventPeopleRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EventsTableFilterComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customLabel => $composableBuilder(
    column: $table.customLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeat => $composableBuilder(
    column: $table.repeat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feb29Rule => $composableBuilder(
    column: $table.feb29Rule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stars => $composableBuilder(
    column: $table.stars,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sendWishesToId => $composableBuilder(
    column: $table.sendWishesToId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alarmClock => $composableBuilder(
    column: $table.alarmClock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get draftMessage => $composableBuilder(
    column: $table.draftMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get belatedNudge => $composableBuilder(
    column: $table.belatedNudge,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sound => $composableBuilder(
    column: $table.sound,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> eventPeopleRefs(
    Expression<bool> Function($$EventPeopleTableFilterComposer f) f,
  ) {
    final $$EventPeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventPeople,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventPeopleTableFilterComposer(
            $db: $db,
            $table: $db.eventPeople,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EventsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customLabel => $composableBuilder(
    column: $table.customLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeat => $composableBuilder(
    column: $table.repeat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feb29Rule => $composableBuilder(
    column: $table.feb29Rule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stars => $composableBuilder(
    column: $table.stars,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sendWishesToId => $composableBuilder(
    column: $table.sendWishesToId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alarmClock => $composableBuilder(
    column: $table.alarmClock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get draftMessage => $composableBuilder(
    column: $table.draftMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get belatedNudge => $composableBuilder(
    column: $table.belatedNudge,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sound => $composableBuilder(
    column: $table.sound,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get customLabel => $composableBuilder(
    column: $table.customLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get repeat =>
      $composableBuilder(column: $table.repeat, builder: (column) => column);

  GeneratedColumn<String> get feb29Rule =>
      $composableBuilder(column: $table.feb29Rule, builder: (column) => column);

  GeneratedColumn<int> get stars =>
      $composableBuilder(column: $table.stars, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get sendWishesToId => $composableBuilder(
    column: $table.sendWishesToId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get alarmClock => $composableBuilder(
    column: $table.alarmClock,
    builder: (column) => column,
  );

  GeneratedColumn<String> get draftMessage => $composableBuilder(
    column: $table.draftMessage,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get belatedNudge => $composableBuilder(
    column: $table.belatedNudge,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sound =>
      $composableBuilder(column: $table.sound, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> eventPeopleRefs<T extends Object>(
    Expression<T> Function($$EventPeopleTableAnnotationComposer a) f,
  ) {
    final $$EventPeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventPeople,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventPeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.eventPeople,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventsTable,
          Event,
          $$EventsTableFilterComposer,
          $$EventsTableOrderingComposer,
          $$EventsTableAnnotationComposer,
          $$EventsTableCreateCompanionBuilder,
          $$EventsTableUpdateCompanionBuilder,
          (Event, $$EventsTableReferences),
          Event,
          PrefetchHooks Function({bool eventPeopleRefs})
        > {
  $$EventsTableTableManager(_$AppDatabase db, $EventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> customLabel = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<int> day = const Value.absent(),
                Value<int> month = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String> repeat = const Value.absent(),
                Value<String> feb29Rule = const Value.absent(),
                Value<int?> stars = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> sendWishesToId = const Value.absent(),
                Value<String> alarmClock = const Value.absent(),
                Value<String?> draftMessage = const Value.absent(),
                Value<bool> belatedNudge = const Value.absent(),
                Value<String?> sound = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EventsCompanion(
                id: id,
                kind: kind,
                type: type,
                customLabel: customLabel,
                title: title,
                day: day,
                month: month,
                year: year,
                repeat: repeat,
                feb29Rule: feb29Rule,
                stars: stars,
                notes: notes,
                sendWishesToId: sendWishesToId,
                alarmClock: alarmClock,
                draftMessage: draftMessage,
                belatedNudge: belatedNudge,
                sound: sound,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kind,
                required String type,
                Value<String?> customLabel = const Value.absent(),
                Value<String?> title = const Value.absent(),
                required int day,
                required int month,
                Value<int?> year = const Value.absent(),
                Value<String> repeat = const Value.absent(),
                Value<String> feb29Rule = const Value.absent(),
                Value<int?> stars = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> sendWishesToId = const Value.absent(),
                Value<String> alarmClock = const Value.absent(),
                Value<String?> draftMessage = const Value.absent(),
                Value<bool> belatedNudge = const Value.absent(),
                Value<String?> sound = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EventsCompanion.insert(
                id: id,
                kind: kind,
                type: type,
                customLabel: customLabel,
                title: title,
                day: day,
                month: month,
                year: year,
                repeat: repeat,
                feb29Rule: feb29Rule,
                stars: stars,
                notes: notes,
                sendWishesToId: sendWishesToId,
                alarmClock: alarmClock,
                draftMessage: draftMessage,
                belatedNudge: belatedNudge,
                sound: sound,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EventsTable, Event>(table),
                  $$EventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({eventPeopleRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (eventPeopleRefs) db.eventPeople],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (eventPeopleRefs)
                    await $_getPrefetchedData<
                      Event,
                      $EventsTable,
                      EventPeopleData
                    >(
                      currentTable: table,
                      referencedTable: $$EventsTableReferences
                          ._eventPeopleRefsTable(db),
                      managerFromTypedResult: (p0) => $$EventsTableReferences(
                        db,
                        table,
                        p0,
                      ).eventPeopleRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.eventId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$EventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventsTable,
      Event,
      $$EventsTableFilterComposer,
      $$EventsTableOrderingComposer,
      $$EventsTableAnnotationComposer,
      $$EventsTableCreateCompanionBuilder,
      $$EventsTableUpdateCompanionBuilder,
      (Event, $$EventsTableReferences),
      Event,
      PrefetchHooks Function({bool eventPeopleRefs})
    >;
typedef $$EventPeopleTableCreateCompanionBuilder =
    EventPeopleCompanion Function({
      required int eventId,
      required int personId,
      Value<int> role,
      Value<int> rowid,
    });
typedef $$EventPeopleTableUpdateCompanionBuilder =
    EventPeopleCompanion Function({
      Value<int> eventId,
      Value<int> personId,
      Value<int> role,
      Value<int> rowid,
    });

final class $$EventPeopleTableReferences
    extends BaseReferences<_$AppDatabase, $EventPeopleTable, EventPeopleData> {
  $$EventPeopleTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EventsTable _eventIdTable(_$AppDatabase db) =>
      db.events.createAlias('event_people__event_id__events__id');

  $$EventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<int>('event_id')!;

    final manager = $$EventsTableTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PeopleTable _personIdTable(_$AppDatabase db) =>
      db.people.createAlias('event_people__person_id__people__id');

  $$PeopleTableProcessedTableManager get personId {
    final $_column = $_itemColumn<int>('person_id')!;

    final manager = $$PeopleTableTableManager(
      $_db,
      $_db.people,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EventPeopleTableFilterComposer
    extends Composer<_$AppDatabase, $EventPeopleTable> {
  $$EventPeopleTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  $$EventsTableFilterComposer get eventId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableFilterComposer get personId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableFilterComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventPeopleTableOrderingComposer
    extends Composer<_$AppDatabase, $EventPeopleTable> {
  $$EventPeopleTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  $$EventsTableOrderingComposer get eventId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableOrderingComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableOrderingComposer get personId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableOrderingComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventPeopleTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventPeopleTable> {
  $$EventPeopleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  $$EventsTableAnnotationComposer get eventId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableAnnotationComposer get personId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventPeopleTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventPeopleTable,
          EventPeopleData,
          $$EventPeopleTableFilterComposer,
          $$EventPeopleTableOrderingComposer,
          $$EventPeopleTableAnnotationComposer,
          $$EventPeopleTableCreateCompanionBuilder,
          $$EventPeopleTableUpdateCompanionBuilder,
          (EventPeopleData, $$EventPeopleTableReferences),
          EventPeopleData,
          PrefetchHooks Function({bool eventId, bool personId})
        > {
  $$EventPeopleTableTableManager(_$AppDatabase db, $EventPeopleTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventPeopleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventPeopleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventPeopleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> eventId = const Value.absent(),
                Value<int> personId = const Value.absent(),
                Value<int> role = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventPeopleCompanion(
                eventId: eventId,
                personId: personId,
                role: role,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int eventId,
                required int personId,
                Value<int> role = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventPeopleCompanion.insert(
                eventId: eventId,
                personId: personId,
                role: role,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EventPeopleTable, EventPeopleData>(table),
                  $$EventPeopleTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({eventId = false, personId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (eventId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.eventId,
                        referencedTable: $$EventPeopleTableReferences
                            ._eventIdTable(db),
                        referencedColumn: $$EventPeopleTableReferences
                            ._eventIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (personId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.personId,
                        referencedTable: $$EventPeopleTableReferences
                            ._personIdTable(db),
                        referencedColumn: $$EventPeopleTableReferences
                            ._personIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EventPeopleTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventPeopleTable,
      EventPeopleData,
      $$EventPeopleTableFilterComposer,
      $$EventPeopleTableOrderingComposer,
      $$EventPeopleTableAnnotationComposer,
      $$EventPeopleTableCreateCompanionBuilder,
      $$EventPeopleTableUpdateCompanionBuilder,
      (EventPeopleData, $$EventPeopleTableReferences),
      EventPeopleData,
      PrefetchHooks Function({bool eventId, bool personId})
    >;
typedef $$GiftIdeasTableCreateCompanionBuilder = GiftIdeasCompanion Function({
  Value<int> id,
  required int personId,
  required String idea,
  Value<bool> purchased,
  Value<DateTime> createdAt,
});
typedef $$GiftIdeasTableUpdateCompanionBuilder = GiftIdeasCompanion Function({
  Value<int> id,
  Value<int> personId,
  Value<String> idea,
  Value<bool> purchased,
  Value<DateTime> createdAt,
});

final class $$GiftIdeasTableReferences
    extends BaseReferences<_$AppDatabase, $GiftIdeasTable, GiftIdea> {
  $$GiftIdeasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PeopleTable _personIdTable(_$AppDatabase db) =>
      db.people.createAlias('gift_ideas__person_id__people__id');

  $$PeopleTableProcessedTableManager get personId {
    final $_column = $_itemColumn<int>('person_id')!;

    final manager = $$PeopleTableTableManager(
      $_db,
      $_db.people,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GiftIdeasTableFilterComposer
    extends Composer<_$AppDatabase, $GiftIdeasTable> {
  $$GiftIdeasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idea => $composableBuilder(
    column: $table.idea,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get purchased => $composableBuilder(
    column: $table.purchased,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PeopleTableFilterComposer get personId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableFilterComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GiftIdeasTableOrderingComposer
    extends Composer<_$AppDatabase, $GiftIdeasTable> {
  $$GiftIdeasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idea => $composableBuilder(
    column: $table.idea,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get purchased => $composableBuilder(
    column: $table.purchased,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PeopleTableOrderingComposer get personId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableOrderingComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GiftIdeasTableAnnotationComposer
    extends Composer<_$AppDatabase, $GiftIdeasTable> {
  $$GiftIdeasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get idea =>
      $composableBuilder(column: $table.idea, builder: (column) => column);

  GeneratedColumn<bool> get purchased =>
      $composableBuilder(column: $table.purchased, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PeopleTableAnnotationComposer get personId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GiftIdeasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GiftIdeasTable,
          GiftIdea,
          $$GiftIdeasTableFilterComposer,
          $$GiftIdeasTableOrderingComposer,
          $$GiftIdeasTableAnnotationComposer,
          $$GiftIdeasTableCreateCompanionBuilder,
          $$GiftIdeasTableUpdateCompanionBuilder,
          (GiftIdea, $$GiftIdeasTableReferences),
          GiftIdea,
          PrefetchHooks Function({bool personId})
        > {
  $$GiftIdeasTableTableManager(_$AppDatabase db, $GiftIdeasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GiftIdeasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GiftIdeasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GiftIdeasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> personId = const Value.absent(),
                Value<String> idea = const Value.absent(),
                Value<bool> purchased = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => GiftIdeasCompanion(
                id: id,
                personId: personId,
                idea: idea,
                purchased: purchased,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int personId,
                required String idea,
                Value<bool> purchased = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => GiftIdeasCompanion.insert(
                id: id,
                personId: personId,
                idea: idea,
                purchased: purchased,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GiftIdeasTable, GiftIdea>(table),
                  $$GiftIdeasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (personId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.personId,
                        referencedTable: $$GiftIdeasTableReferences
                            ._personIdTable(db),
                        referencedColumn: $$GiftIdeasTableReferences
                            ._personIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GiftIdeasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GiftIdeasTable,
      GiftIdea,
      $$GiftIdeasTableFilterComposer,
      $$GiftIdeasTableOrderingComposer,
      $$GiftIdeasTableAnnotationComposer,
      $$GiftIdeasTableCreateCompanionBuilder,
      $$GiftIdeasTableUpdateCompanionBuilder,
      (GiftIdea, $$GiftIdeasTableReferences),
      GiftIdea,
      PrefetchHooks Function({bool personId})
    >;
typedef $$ContactNoticesTableCreateCompanionBuilder =
    ContactNoticesCompanion Function({
      Value<int> id,
      required int personId,
      required String message,
      Value<bool> seen,
      Value<DateTime> createdAt,
    });
typedef $$ContactNoticesTableUpdateCompanionBuilder =
    ContactNoticesCompanion Function({
      Value<int> id,
      Value<int> personId,
      Value<String> message,
      Value<bool> seen,
      Value<DateTime> createdAt,
    });

final class $$ContactNoticesTableReferences
    extends BaseReferences<_$AppDatabase, $ContactNoticesTable, ContactNotice> {
  $$ContactNoticesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PeopleTable _personIdTable(_$AppDatabase db) =>
      db.people.createAlias('contact_notices__person_id__people__id');

  $$PeopleTableProcessedTableManager get personId {
    final $_column = $_itemColumn<int>('person_id')!;

    final manager = $$PeopleTableTableManager(
      $_db,
      $_db.people,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ContactNoticesTableFilterComposer
    extends Composer<_$AppDatabase, $ContactNoticesTable> {
  $$ContactNoticesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get seen => $composableBuilder(
    column: $table.seen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PeopleTableFilterComposer get personId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableFilterComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContactNoticesTableOrderingComposer
    extends Composer<_$AppDatabase, $ContactNoticesTable> {
  $$ContactNoticesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get seen => $composableBuilder(
    column: $table.seen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PeopleTableOrderingComposer get personId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableOrderingComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContactNoticesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContactNoticesTable> {
  $$ContactNoticesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<bool> get seen =>
      $composableBuilder(column: $table.seen, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PeopleTableAnnotationComposer get personId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContactNoticesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContactNoticesTable,
          ContactNotice,
          $$ContactNoticesTableFilterComposer,
          $$ContactNoticesTableOrderingComposer,
          $$ContactNoticesTableAnnotationComposer,
          $$ContactNoticesTableCreateCompanionBuilder,
          $$ContactNoticesTableUpdateCompanionBuilder,
          (ContactNotice, $$ContactNoticesTableReferences),
          ContactNotice,
          PrefetchHooks Function({bool personId})
        > {
  $$ContactNoticesTableTableManager(
    _$AppDatabase db,
    $ContactNoticesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactNoticesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactNoticesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactNoticesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> personId = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<bool> seen = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ContactNoticesCompanion(
                id: id,
                personId: personId,
                message: message,
                seen: seen,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int personId,
                required String message,
                Value<bool> seen = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ContactNoticesCompanion.insert(
                id: id,
                personId: personId,
                message: message,
                seen: seen,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ContactNoticesTable, ContactNotice>(table),
                  $$ContactNoticesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (personId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.personId,
                        referencedTable: $$ContactNoticesTableReferences
                            ._personIdTable(db),
                        referencedColumn: $$ContactNoticesTableReferences
                            ._personIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ContactNoticesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContactNoticesTable,
      ContactNotice,
      $$ContactNoticesTableFilterComposer,
      $$ContactNoticesTableOrderingComposer,
      $$ContactNoticesTableAnnotationComposer,
      $$ContactNoticesTableCreateCompanionBuilder,
      $$ContactNoticesTableUpdateCompanionBuilder,
      (ContactNotice, $$ContactNoticesTableReferences),
      ContactNotice,
      PrefetchHooks Function({bool personId})
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PeopleTableTableManager get people =>
      $$PeopleTableTableManager(_db, _db.people);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$EventPeopleTableTableManager get eventPeople =>
      $$EventPeopleTableTableManager(_db, _db.eventPeople);
  $$GiftIdeasTableTableManager get giftIdeas =>
      $$GiftIdeasTableTableManager(_db, _db.giftIdeas);
  $$ContactNoticesTableTableManager get contactNotices =>
      $$ContactNoticesTableTableManager(_db, _db.contactNotices);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
