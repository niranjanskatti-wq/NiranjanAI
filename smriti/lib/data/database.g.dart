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
  static const VerificationMeta _whatsappAppMeta = const VerificationMeta(
    'whatsappApp',
  );
  @override
  late final GeneratedColumn<String> whatsappApp = GeneratedColumn<String>(
    'whatsapp_app',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('auto'),
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
    whatsappApp,
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
    if (data.containsKey('whatsapp_app')) {
      context.handle(
        _whatsappAppMeta,
        whatsappApp.isAcceptableOrUnknown(
          data['whatsapp_app']!,
          _whatsappAppMeta,
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
      whatsappApp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}whatsapp_app'],
      )!,
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

  /// "auto" (ask if both are installed), "whatsapp" or "business".
  final String whatsappApp;
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
    required this.whatsappApp,
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
    map['whatsapp_app'] = Variable<String>(whatsappApp);
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
      whatsappApp: Value(whatsappApp),
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
      whatsappApp: serializer.fromJson<String>(json['whatsappApp']),
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
      'whatsappApp': serializer.toJson<String>(whatsappApp),
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
    String? whatsappApp,
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
    whatsappApp: whatsappApp ?? this.whatsappApp,
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
      whatsappApp: data.whatsappApp.present
          ? data.whatsappApp.value
          : this.whatsappApp,
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
          ..write('whatsappApp: $whatsappApp, ')
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
    whatsappApp,
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
          other.whatsappApp == this.whatsappApp &&
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
  final Value<String> whatsappApp;
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
    this.whatsappApp = const Value.absent(),
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
    this.whatsappApp = const Value.absent(),
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
    Expression<String>? whatsappApp,
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
      if (whatsappApp != null) 'whatsapp_app': whatsappApp,
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
    Value<String>? whatsappApp,
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
      whatsappApp: whatsappApp ?? this.whatsappApp,
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
    if (whatsappApp.present) {
      map['whatsapp_app'] = Variable<String>(whatsappApp.value);
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
          ..write('whatsappApp: $whatsappApp, ')
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
  static const VerificationMeta _budgetMeta = const VerificationMeta('budget');
  @override
  late final GeneratedColumn<int> budget = GeneratedColumn<int>(
    'budget',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<int> eventId = GeneratedColumn<int>(
    'event_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES events (id) ON DELETE SET NULL',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personId,
    idea,
    purchased,
    createdAt,
    budget,
    eventId,
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
    if (data.containsKey('budget')) {
      context.handle(
        _budgetMeta,
        budget.isAcceptableOrUnknown(data['budget']!, _budgetMeta),
      );
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
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
      budget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}budget'],
      ),
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}event_id'],
      ),
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

  /// Planned spend in rupees.
  final int? budget;

  /// Which occasion the gift is for.
  final int? eventId;
  const GiftIdea({
    required this.id,
    required this.personId,
    required this.idea,
    required this.purchased,
    required this.createdAt,
    this.budget,
    this.eventId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['person_id'] = Variable<int>(personId);
    map['idea'] = Variable<String>(idea);
    map['purchased'] = Variable<bool>(purchased);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || budget != null) {
      map['budget'] = Variable<int>(budget);
    }
    if (!nullToAbsent || eventId != null) {
      map['event_id'] = Variable<int>(eventId);
    }
    return map;
  }

  GiftIdeasCompanion toCompanion(bool nullToAbsent) {
    return GiftIdeasCompanion(
      id: Value(id),
      personId: Value(personId),
      idea: Value(idea),
      purchased: Value(purchased),
      createdAt: Value(createdAt),
      budget: budget == null && nullToAbsent
          ? const Value.absent()
          : Value(budget),
      eventId: eventId == null && nullToAbsent
          ? const Value.absent()
          : Value(eventId),
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
      budget: serializer.fromJson<int?>(json['budget']),
      eventId: serializer.fromJson<int?>(json['eventId']),
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
      'budget': serializer.toJson<int?>(budget),
      'eventId': serializer.toJson<int?>(eventId),
    };
  }

  GiftIdea copyWith({
    int? id,
    int? personId,
    String? idea,
    bool? purchased,
    DateTime? createdAt,
    Value<int?> budget = const Value.absent(),
    Value<int?> eventId = const Value.absent(),
  }) => GiftIdea(
    id: id ?? this.id,
    personId: personId ?? this.personId,
    idea: idea ?? this.idea,
    purchased: purchased ?? this.purchased,
    createdAt: createdAt ?? this.createdAt,
    budget: budget.present ? budget.value : this.budget,
    eventId: eventId.present ? eventId.value : this.eventId,
  );
  GiftIdea copyWithCompanion(GiftIdeasCompanion data) {
    return GiftIdea(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      idea: data.idea.present ? data.idea.value : this.idea,
      purchased: data.purchased.present ? data.purchased.value : this.purchased,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      budget: data.budget.present ? data.budget.value : this.budget,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GiftIdea(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('idea: $idea, ')
          ..write('purchased: $purchased, ')
          ..write('createdAt: $createdAt, ')
          ..write('budget: $budget, ')
          ..write('eventId: $eventId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, personId, idea, purchased, createdAt, budget, eventId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GiftIdea &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.idea == this.idea &&
          other.purchased == this.purchased &&
          other.createdAt == this.createdAt &&
          other.budget == this.budget &&
          other.eventId == this.eventId);
}

class GiftIdeasCompanion extends UpdateCompanion<GiftIdea> {
  final Value<int> id;
  final Value<int> personId;
  final Value<String> idea;
  final Value<bool> purchased;
  final Value<DateTime> createdAt;
  final Value<int?> budget;
  final Value<int?> eventId;
  const GiftIdeasCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.idea = const Value.absent(),
    this.purchased = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.budget = const Value.absent(),
    this.eventId = const Value.absent(),
  });
  GiftIdeasCompanion.insert({
    this.id = const Value.absent(),
    required int personId,
    required String idea,
    this.purchased = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.budget = const Value.absent(),
    this.eventId = const Value.absent(),
  }) : personId = Value(personId),
       idea = Value(idea);
  static Insertable<GiftIdea> custom({
    Expression<int>? id,
    Expression<int>? personId,
    Expression<String>? idea,
    Expression<bool>? purchased,
    Expression<DateTime>? createdAt,
    Expression<int>? budget,
    Expression<int>? eventId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (idea != null) 'idea': idea,
      if (purchased != null) 'purchased': purchased,
      if (createdAt != null) 'created_at': createdAt,
      if (budget != null) 'budget': budget,
      if (eventId != null) 'event_id': eventId,
    });
  }

  GiftIdeasCompanion copyWith({
    Value<int>? id,
    Value<int>? personId,
    Value<String>? idea,
    Value<bool>? purchased,
    Value<DateTime>? createdAt,
    Value<int?>? budget,
    Value<int?>? eventId,
  }) {
    return GiftIdeasCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      idea: idea ?? this.idea,
      purchased: purchased ?? this.purchased,
      createdAt: createdAt ?? this.createdAt,
      budget: budget ?? this.budget,
      eventId: eventId ?? this.eventId,
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
    if (budget.present) {
      map['budget'] = Variable<int>(budget.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<int>(eventId.value);
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
          ..write('createdAt: $createdAt, ')
          ..write('budget: $budget, ')
          ..write('eventId: $eventId')
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

class $WishLogsTable extends WishLogs with TableInfo<$WishLogsTable, WishLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WishLogsTable(this.attachedDatabase, [this._alias]);
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
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES people (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<int> eventId = GeneratedColumn<int>(
    'event_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES events (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _festivalIdMeta = const VerificationMeta(
    'festivalId',
  );
  @override
  late final GeneratedColumn<String> festivalId = GeneratedColumn<String>(
    'festival_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occasionDateMeta = const VerificationMeta(
    'occasionDate',
  );
  @override
  late final GeneratedColumn<String> occasionDate = GeneratedColumn<String>(
    'occasion_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confirmedMeta = const VerificationMeta(
    'confirmed',
  );
  @override
  late final GeneratedColumn<bool> confirmed = GeneratedColumn<bool>(
    'confirmed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("confirmed" IN (0, 1))',
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
    eventId,
    festivalId,
    occasionDate,
    method,
    message,
    templateId,
    confirmed,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wish_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<WishLog> instance, {
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
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    }
    if (data.containsKey('festival_id')) {
      context.handle(
        _festivalIdMeta,
        festivalId.isAcceptableOrUnknown(data['festival_id']!, _festivalIdMeta),
      );
    }
    if (data.containsKey('occasion_date')) {
      context.handle(
        _occasionDateMeta,
        occasionDate.isAcceptableOrUnknown(
          data['occasion_date']!,
          _occasionDateMeta,
        ),
      );
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    }
    if (data.containsKey('confirmed')) {
      context.handle(
        _confirmedMeta,
        confirmed.isAcceptableOrUnknown(data['confirmed']!, _confirmedMeta),
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
  WishLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WishLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      ),
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}event_id'],
      ),
      festivalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}festival_id'],
      ),
      occasionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occasion_date'],
      ),
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      ),
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      ),
      confirmed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}confirmed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WishLogsTable createAlias(String alias) {
    return $WishLogsTable(attachedDatabase, alias);
  }
}

class WishLog extends DataClass implements Insertable<WishLog> {
  final int id;

  /// Person the call or message went to.
  final int? personId;
  final int? eventId;

  /// Festival id from assets/festivals (Phase 5).
  final String? festivalId;

  /// The occurrence this was for, "yyyy-mm-dd".
  final String? occasionDate;

  /// call, whatsapp, sms, copy, share, card, manual.
  final String method;
  final String? message;
  final String? templateId;

  /// True once the user confirms "Mark as wished".
  final bool confirmed;
  final DateTime createdAt;
  const WishLog({
    required this.id,
    this.personId,
    this.eventId,
    this.festivalId,
    this.occasionDate,
    required this.method,
    this.message,
    this.templateId,
    required this.confirmed,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || personId != null) {
      map['person_id'] = Variable<int>(personId);
    }
    if (!nullToAbsent || eventId != null) {
      map['event_id'] = Variable<int>(eventId);
    }
    if (!nullToAbsent || festivalId != null) {
      map['festival_id'] = Variable<String>(festivalId);
    }
    if (!nullToAbsent || occasionDate != null) {
      map['occasion_date'] = Variable<String>(occasionDate);
    }
    map['method'] = Variable<String>(method);
    if (!nullToAbsent || message != null) {
      map['message'] = Variable<String>(message);
    }
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<String>(templateId);
    }
    map['confirmed'] = Variable<bool>(confirmed);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WishLogsCompanion toCompanion(bool nullToAbsent) {
    return WishLogsCompanion(
      id: Value(id),
      personId: personId == null && nullToAbsent
          ? const Value.absent()
          : Value(personId),
      eventId: eventId == null && nullToAbsent
          ? const Value.absent()
          : Value(eventId),
      festivalId: festivalId == null && nullToAbsent
          ? const Value.absent()
          : Value(festivalId),
      occasionDate: occasionDate == null && nullToAbsent
          ? const Value.absent()
          : Value(occasionDate),
      method: Value(method),
      message: message == null && nullToAbsent
          ? const Value.absent()
          : Value(message),
      templateId: templateId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateId),
      confirmed: Value(confirmed),
      createdAt: Value(createdAt),
    );
  }

  factory WishLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WishLog(
      id: serializer.fromJson<int>(json['id']),
      personId: serializer.fromJson<int?>(json['personId']),
      eventId: serializer.fromJson<int?>(json['eventId']),
      festivalId: serializer.fromJson<String?>(json['festivalId']),
      occasionDate: serializer.fromJson<String?>(json['occasionDate']),
      method: serializer.fromJson<String>(json['method']),
      message: serializer.fromJson<String?>(json['message']),
      templateId: serializer.fromJson<String?>(json['templateId']),
      confirmed: serializer.fromJson<bool>(json['confirmed']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'personId': serializer.toJson<int?>(personId),
      'eventId': serializer.toJson<int?>(eventId),
      'festivalId': serializer.toJson<String?>(festivalId),
      'occasionDate': serializer.toJson<String?>(occasionDate),
      'method': serializer.toJson<String>(method),
      'message': serializer.toJson<String?>(message),
      'templateId': serializer.toJson<String?>(templateId),
      'confirmed': serializer.toJson<bool>(confirmed),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  WishLog copyWith({
    int? id,
    Value<int?> personId = const Value.absent(),
    Value<int?> eventId = const Value.absent(),
    Value<String?> festivalId = const Value.absent(),
    Value<String?> occasionDate = const Value.absent(),
    String? method,
    Value<String?> message = const Value.absent(),
    Value<String?> templateId = const Value.absent(),
    bool? confirmed,
    DateTime? createdAt,
  }) => WishLog(
    id: id ?? this.id,
    personId: personId.present ? personId.value : this.personId,
    eventId: eventId.present ? eventId.value : this.eventId,
    festivalId: festivalId.present ? festivalId.value : this.festivalId,
    occasionDate: occasionDate.present ? occasionDate.value : this.occasionDate,
    method: method ?? this.method,
    message: message.present ? message.value : this.message,
    templateId: templateId.present ? templateId.value : this.templateId,
    confirmed: confirmed ?? this.confirmed,
    createdAt: createdAt ?? this.createdAt,
  );
  WishLog copyWithCompanion(WishLogsCompanion data) {
    return WishLog(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      festivalId: data.festivalId.present
          ? data.festivalId.value
          : this.festivalId,
      occasionDate: data.occasionDate.present
          ? data.occasionDate.value
          : this.occasionDate,
      method: data.method.present ? data.method.value : this.method,
      message: data.message.present ? data.message.value : this.message,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      confirmed: data.confirmed.present ? data.confirmed.value : this.confirmed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WishLog(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('eventId: $eventId, ')
          ..write('festivalId: $festivalId, ')
          ..write('occasionDate: $occasionDate, ')
          ..write('method: $method, ')
          ..write('message: $message, ')
          ..write('templateId: $templateId, ')
          ..write('confirmed: $confirmed, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    personId,
    eventId,
    festivalId,
    occasionDate,
    method,
    message,
    templateId,
    confirmed,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WishLog &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.eventId == this.eventId &&
          other.festivalId == this.festivalId &&
          other.occasionDate == this.occasionDate &&
          other.method == this.method &&
          other.message == this.message &&
          other.templateId == this.templateId &&
          other.confirmed == this.confirmed &&
          other.createdAt == this.createdAt);
}

class WishLogsCompanion extends UpdateCompanion<WishLog> {
  final Value<int> id;
  final Value<int?> personId;
  final Value<int?> eventId;
  final Value<String?> festivalId;
  final Value<String?> occasionDate;
  final Value<String> method;
  final Value<String?> message;
  final Value<String?> templateId;
  final Value<bool> confirmed;
  final Value<DateTime> createdAt;
  const WishLogsCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.festivalId = const Value.absent(),
    this.occasionDate = const Value.absent(),
    this.method = const Value.absent(),
    this.message = const Value.absent(),
    this.templateId = const Value.absent(),
    this.confirmed = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WishLogsCompanion.insert({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.festivalId = const Value.absent(),
    this.occasionDate = const Value.absent(),
    required String method,
    this.message = const Value.absent(),
    this.templateId = const Value.absent(),
    this.confirmed = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : method = Value(method);
  static Insertable<WishLog> custom({
    Expression<int>? id,
    Expression<int>? personId,
    Expression<int>? eventId,
    Expression<String>? festivalId,
    Expression<String>? occasionDate,
    Expression<String>? method,
    Expression<String>? message,
    Expression<String>? templateId,
    Expression<bool>? confirmed,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (eventId != null) 'event_id': eventId,
      if (festivalId != null) 'festival_id': festivalId,
      if (occasionDate != null) 'occasion_date': occasionDate,
      if (method != null) 'method': method,
      if (message != null) 'message': message,
      if (templateId != null) 'template_id': templateId,
      if (confirmed != null) 'confirmed': confirmed,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WishLogsCompanion copyWith({
    Value<int>? id,
    Value<int?>? personId,
    Value<int?>? eventId,
    Value<String?>? festivalId,
    Value<String?>? occasionDate,
    Value<String>? method,
    Value<String?>? message,
    Value<String?>? templateId,
    Value<bool>? confirmed,
    Value<DateTime>? createdAt,
  }) {
    return WishLogsCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      eventId: eventId ?? this.eventId,
      festivalId: festivalId ?? this.festivalId,
      occasionDate: occasionDate ?? this.occasionDate,
      method: method ?? this.method,
      message: message ?? this.message,
      templateId: templateId ?? this.templateId,
      confirmed: confirmed ?? this.confirmed,
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
    if (eventId.present) {
      map['event_id'] = Variable<int>(eventId.value);
    }
    if (festivalId.present) {
      map['festival_id'] = Variable<String>(festivalId.value);
    }
    if (occasionDate.present) {
      map['occasion_date'] = Variable<String>(occasionDate.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (confirmed.present) {
      map['confirmed'] = Variable<bool>(confirmed.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WishLogsCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('eventId: $eventId, ')
          ..write('festivalId: $festivalId, ')
          ..write('occasionDate: $occasionDate, ')
          ..write('method: $method, ')
          ..write('message: $message, ')
          ..write('templateId: $templateId, ')
          ..write('confirmed: $confirmed, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, Reminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _daysBeforeMeta = const VerificationMeta(
    'daysBefore',
  );
  @override
  late final GeneratedColumn<int> daysBefore = GeneratedColumn<int>(
    'days_before',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _minuteOfDayMeta = const VerificationMeta(
    'minuteOfDay',
  );
  @override
  late final GeneratedColumn<int> minuteOfDay = GeneratedColumn<int>(
    'minute_of_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(480),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventId,
    kind,
    daysBefore,
    minuteOfDay,
    enabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('days_before')) {
      context.handle(
        _daysBeforeMeta,
        daysBefore.isAcceptableOrUnknown(data['days_before']!, _daysBeforeMeta),
      );
    }
    if (data.containsKey('minute_of_day')) {
      context.handle(
        _minuteOfDayMeta,
        minuteOfDay.isAcceptableOrUnknown(
          data['minute_of_day']!,
          _minuteOfDayMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}event_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      daysBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}days_before'],
      )!,
      minuteOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minute_of_day'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class Reminder extends DataClass implements Insertable<Reminder> {
  final int id;
  final int eventId;

  /// midnight, morning, custom, daysBefore, gift.
  final String kind;

  /// 0 = on the day.
  final int daysBefore;

  /// Time of day in minutes after midnight (480 = 8:00 AM).
  final int minuteOfDay;
  final bool enabled;
  const Reminder({
    required this.id,
    required this.eventId,
    required this.kind,
    required this.daysBefore,
    required this.minuteOfDay,
    required this.enabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['event_id'] = Variable<int>(eventId);
    map['kind'] = Variable<String>(kind);
    map['days_before'] = Variable<int>(daysBefore);
    map['minute_of_day'] = Variable<int>(minuteOfDay);
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      eventId: Value(eventId),
      kind: Value(kind),
      daysBefore: Value(daysBefore),
      minuteOfDay: Value(minuteOfDay),
      enabled: Value(enabled),
    );
  }

  factory Reminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reminder(
      id: serializer.fromJson<int>(json['id']),
      eventId: serializer.fromJson<int>(json['eventId']),
      kind: serializer.fromJson<String>(json['kind']),
      daysBefore: serializer.fromJson<int>(json['daysBefore']),
      minuteOfDay: serializer.fromJson<int>(json['minuteOfDay']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'eventId': serializer.toJson<int>(eventId),
      'kind': serializer.toJson<String>(kind),
      'daysBefore': serializer.toJson<int>(daysBefore),
      'minuteOfDay': serializer.toJson<int>(minuteOfDay),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  Reminder copyWith({
    int? id,
    int? eventId,
    String? kind,
    int? daysBefore,
    int? minuteOfDay,
    bool? enabled,
  }) => Reminder(
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    kind: kind ?? this.kind,
    daysBefore: daysBefore ?? this.daysBefore,
    minuteOfDay: minuteOfDay ?? this.minuteOfDay,
    enabled: enabled ?? this.enabled,
  );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      kind: data.kind.present ? data.kind.value : this.kind,
      daysBefore: data.daysBefore.present
          ? data.daysBefore.value
          : this.daysBefore,
      minuteOfDay: data.minuteOfDay.present
          ? data.minuteOfDay.value
          : this.minuteOfDay,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('kind: $kind, ')
          ..write('daysBefore: $daysBefore, ')
          ..write('minuteOfDay: $minuteOfDay, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, eventId, kind, daysBefore, minuteOfDay, enabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.kind == this.kind &&
          other.daysBefore == this.daysBefore &&
          other.minuteOfDay == this.minuteOfDay &&
          other.enabled == this.enabled);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<int> id;
  final Value<int> eventId;
  final Value<String> kind;
  final Value<int> daysBefore;
  final Value<int> minuteOfDay;
  final Value<bool> enabled;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.kind = const Value.absent(),
    this.daysBefore = const Value.absent(),
    this.minuteOfDay = const Value.absent(),
    this.enabled = const Value.absent(),
  });
  RemindersCompanion.insert({
    this.id = const Value.absent(),
    required int eventId,
    required String kind,
    this.daysBefore = const Value.absent(),
    this.minuteOfDay = const Value.absent(),
    this.enabled = const Value.absent(),
  }) : eventId = Value(eventId),
       kind = Value(kind);
  static Insertable<Reminder> custom({
    Expression<int>? id,
    Expression<int>? eventId,
    Expression<String>? kind,
    Expression<int>? daysBefore,
    Expression<int>? minuteOfDay,
    Expression<bool>? enabled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (kind != null) 'kind': kind,
      if (daysBefore != null) 'days_before': daysBefore,
      if (minuteOfDay != null) 'minute_of_day': minuteOfDay,
      if (enabled != null) 'enabled': enabled,
    });
  }

  RemindersCompanion copyWith({
    Value<int>? id,
    Value<int>? eventId,
    Value<String>? kind,
    Value<int>? daysBefore,
    Value<int>? minuteOfDay,
    Value<bool>? enabled,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      kind: kind ?? this.kind,
      daysBefore: daysBefore ?? this.daysBefore,
      minuteOfDay: minuteOfDay ?? this.minuteOfDay,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<int>(eventId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (daysBefore.present) {
      map['days_before'] = Variable<int>(daysBefore.value);
    }
    if (minuteOfDay.present) {
      map['minute_of_day'] = Variable<int>(minuteOfDay.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('kind: $kind, ')
          ..write('daysBefore: $daysBefore, ')
          ..write('minuteOfDay: $minuteOfDay, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }
}

class $UserMessagesTable extends UserMessages
    with TableInfo<$UserMessagesTable, UserMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserMessagesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _occasionMeta = const VerificationMeta(
    'occasion',
  );
  @override
  late final GeneratedColumn<String> occasion = GeneratedColumn<String>(
    'occasion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relationsMeta = const VerificationMeta(
    'relations',
  );
  @override
  late final GeneratedColumn<String> relations = GeneratedColumn<String>(
    'relations',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('any'),
  );
  static const VerificationMeta _toneMeta = const VerificationMeta('tone');
  @override
  late final GeneratedColumn<String> tone = GeneratedColumn<String>(
    'tone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('short'),
  );
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('en'),
  );
  static const VerificationMeta _festivalMeta = const VerificationMeta(
    'festival',
  );
  @override
  late final GeneratedColumn<String> festival = GeneratedColumn<String>(
    'festival',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseIdMeta = const VerificationMeta('baseId');
  @override
  late final GeneratedColumn<String> baseId = GeneratedColumn<String>(
    'base_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _favouriteMeta = const VerificationMeta(
    'favourite',
  );
  @override
  late final GeneratedColumn<bool> favourite = GeneratedColumn<bool>(
    'favourite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("favourite" IN (0, 1))',
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
    occasion,
    relations,
    tone,
    lang,
    festival,
    body,
    baseId,
    favourite,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('occasion')) {
      context.handle(
        _occasionMeta,
        occasion.isAcceptableOrUnknown(data['occasion']!, _occasionMeta),
      );
    } else if (isInserting) {
      context.missing(_occasionMeta);
    }
    if (data.containsKey('relations')) {
      context.handle(
        _relationsMeta,
        relations.isAcceptableOrUnknown(data['relations']!, _relationsMeta),
      );
    }
    if (data.containsKey('tone')) {
      context.handle(
        _toneMeta,
        tone.isAcceptableOrUnknown(data['tone']!, _toneMeta),
      );
    }
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    }
    if (data.containsKey('festival')) {
      context.handle(
        _festivalMeta,
        festival.isAcceptableOrUnknown(data['festival']!, _festivalMeta),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('base_id')) {
      context.handle(
        _baseIdMeta,
        baseId.isAcceptableOrUnknown(data['base_id']!, _baseIdMeta),
      );
    }
    if (data.containsKey('favourite')) {
      context.handle(
        _favouriteMeta,
        favourite.isAcceptableOrUnknown(data['favourite']!, _favouriteMeta),
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
  UserMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserMessage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      occasion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occasion'],
      )!,
      relations: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relations'],
      )!,
      tone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tone'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      festival: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}festival'],
      ),
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      baseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_id'],
      ),
      favourite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}favourite'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UserMessagesTable createAlias(String alias) {
    return $UserMessagesTable(attachedDatabase, alias);
  }
}

class UserMessage extends DataClass implements Insertable<UserMessage> {
  final int id;
  final String occasion;

  /// Comma-separated relation names or families, or "any".
  final String relations;
  final String tone;
  final String lang;
  final String? festival;
  final String body;

  /// Built-in message this replaces, if it is an edit.
  final String? baseId;
  final bool favourite;
  final DateTime createdAt;
  const UserMessage({
    required this.id,
    required this.occasion,
    required this.relations,
    required this.tone,
    required this.lang,
    this.festival,
    required this.body,
    this.baseId,
    required this.favourite,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['occasion'] = Variable<String>(occasion);
    map['relations'] = Variable<String>(relations);
    map['tone'] = Variable<String>(tone);
    map['lang'] = Variable<String>(lang);
    if (!nullToAbsent || festival != null) {
      map['festival'] = Variable<String>(festival);
    }
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || baseId != null) {
      map['base_id'] = Variable<String>(baseId);
    }
    map['favourite'] = Variable<bool>(favourite);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UserMessagesCompanion toCompanion(bool nullToAbsent) {
    return UserMessagesCompanion(
      id: Value(id),
      occasion: Value(occasion),
      relations: Value(relations),
      tone: Value(tone),
      lang: Value(lang),
      festival: festival == null && nullToAbsent
          ? const Value.absent()
          : Value(festival),
      body: Value(body),
      baseId: baseId == null && nullToAbsent
          ? const Value.absent()
          : Value(baseId),
      favourite: Value(favourite),
      createdAt: Value(createdAt),
    );
  }

  factory UserMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserMessage(
      id: serializer.fromJson<int>(json['id']),
      occasion: serializer.fromJson<String>(json['occasion']),
      relations: serializer.fromJson<String>(json['relations']),
      tone: serializer.fromJson<String>(json['tone']),
      lang: serializer.fromJson<String>(json['lang']),
      festival: serializer.fromJson<String?>(json['festival']),
      body: serializer.fromJson<String>(json['body']),
      baseId: serializer.fromJson<String?>(json['baseId']),
      favourite: serializer.fromJson<bool>(json['favourite']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'occasion': serializer.toJson<String>(occasion),
      'relations': serializer.toJson<String>(relations),
      'tone': serializer.toJson<String>(tone),
      'lang': serializer.toJson<String>(lang),
      'festival': serializer.toJson<String?>(festival),
      'body': serializer.toJson<String>(body),
      'baseId': serializer.toJson<String?>(baseId),
      'favourite': serializer.toJson<bool>(favourite),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserMessage copyWith({
    int? id,
    String? occasion,
    String? relations,
    String? tone,
    String? lang,
    Value<String?> festival = const Value.absent(),
    String? body,
    Value<String?> baseId = const Value.absent(),
    bool? favourite,
    DateTime? createdAt,
  }) => UserMessage(
    id: id ?? this.id,
    occasion: occasion ?? this.occasion,
    relations: relations ?? this.relations,
    tone: tone ?? this.tone,
    lang: lang ?? this.lang,
    festival: festival.present ? festival.value : this.festival,
    body: body ?? this.body,
    baseId: baseId.present ? baseId.value : this.baseId,
    favourite: favourite ?? this.favourite,
    createdAt: createdAt ?? this.createdAt,
  );
  UserMessage copyWithCompanion(UserMessagesCompanion data) {
    return UserMessage(
      id: data.id.present ? data.id.value : this.id,
      occasion: data.occasion.present ? data.occasion.value : this.occasion,
      relations: data.relations.present ? data.relations.value : this.relations,
      tone: data.tone.present ? data.tone.value : this.tone,
      lang: data.lang.present ? data.lang.value : this.lang,
      festival: data.festival.present ? data.festival.value : this.festival,
      body: data.body.present ? data.body.value : this.body,
      baseId: data.baseId.present ? data.baseId.value : this.baseId,
      favourite: data.favourite.present ? data.favourite.value : this.favourite,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserMessage(')
          ..write('id: $id, ')
          ..write('occasion: $occasion, ')
          ..write('relations: $relations, ')
          ..write('tone: $tone, ')
          ..write('lang: $lang, ')
          ..write('festival: $festival, ')
          ..write('body: $body, ')
          ..write('baseId: $baseId, ')
          ..write('favourite: $favourite, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    occasion,
    relations,
    tone,
    lang,
    festival,
    body,
    baseId,
    favourite,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserMessage &&
          other.id == this.id &&
          other.occasion == this.occasion &&
          other.relations == this.relations &&
          other.tone == this.tone &&
          other.lang == this.lang &&
          other.festival == this.festival &&
          other.body == this.body &&
          other.baseId == this.baseId &&
          other.favourite == this.favourite &&
          other.createdAt == this.createdAt);
}

class UserMessagesCompanion extends UpdateCompanion<UserMessage> {
  final Value<int> id;
  final Value<String> occasion;
  final Value<String> relations;
  final Value<String> tone;
  final Value<String> lang;
  final Value<String?> festival;
  final Value<String> body;
  final Value<String?> baseId;
  final Value<bool> favourite;
  final Value<DateTime> createdAt;
  const UserMessagesCompanion({
    this.id = const Value.absent(),
    this.occasion = const Value.absent(),
    this.relations = const Value.absent(),
    this.tone = const Value.absent(),
    this.lang = const Value.absent(),
    this.festival = const Value.absent(),
    this.body = const Value.absent(),
    this.baseId = const Value.absent(),
    this.favourite = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UserMessagesCompanion.insert({
    this.id = const Value.absent(),
    required String occasion,
    this.relations = const Value.absent(),
    this.tone = const Value.absent(),
    this.lang = const Value.absent(),
    this.festival = const Value.absent(),
    required String body,
    this.baseId = const Value.absent(),
    this.favourite = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : occasion = Value(occasion),
       body = Value(body);
  static Insertable<UserMessage> custom({
    Expression<int>? id,
    Expression<String>? occasion,
    Expression<String>? relations,
    Expression<String>? tone,
    Expression<String>? lang,
    Expression<String>? festival,
    Expression<String>? body,
    Expression<String>? baseId,
    Expression<bool>? favourite,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (occasion != null) 'occasion': occasion,
      if (relations != null) 'relations': relations,
      if (tone != null) 'tone': tone,
      if (lang != null) 'lang': lang,
      if (festival != null) 'festival': festival,
      if (body != null) 'body': body,
      if (baseId != null) 'base_id': baseId,
      if (favourite != null) 'favourite': favourite,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UserMessagesCompanion copyWith({
    Value<int>? id,
    Value<String>? occasion,
    Value<String>? relations,
    Value<String>? tone,
    Value<String>? lang,
    Value<String?>? festival,
    Value<String>? body,
    Value<String?>? baseId,
    Value<bool>? favourite,
    Value<DateTime>? createdAt,
  }) {
    return UserMessagesCompanion(
      id: id ?? this.id,
      occasion: occasion ?? this.occasion,
      relations: relations ?? this.relations,
      tone: tone ?? this.tone,
      lang: lang ?? this.lang,
      festival: festival ?? this.festival,
      body: body ?? this.body,
      baseId: baseId ?? this.baseId,
      favourite: favourite ?? this.favourite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (occasion.present) {
      map['occasion'] = Variable<String>(occasion.value);
    }
    if (relations.present) {
      map['relations'] = Variable<String>(relations.value);
    }
    if (tone.present) {
      map['tone'] = Variable<String>(tone.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (festival.present) {
      map['festival'] = Variable<String>(festival.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (baseId.present) {
      map['base_id'] = Variable<String>(baseId.value);
    }
    if (favourite.present) {
      map['favourite'] = Variable<bool>(favourite.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserMessagesCompanion(')
          ..write('id: $id, ')
          ..write('occasion: $occasion, ')
          ..write('relations: $relations, ')
          ..write('tone: $tone, ')
          ..write('lang: $lang, ')
          ..write('festival: $festival, ')
          ..write('body: $body, ')
          ..write('baseId: $baseId, ')
          ..write('favourite: $favourite, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FavouriteMessagesTable extends FavouriteMessages
    with TableInfo<$FavouriteMessagesTable, FavouriteMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavouriteMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [templateId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favourite_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavouriteMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {templateId};
  @override
  FavouriteMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavouriteMessage(
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
    );
  }

  @override
  $FavouriteMessagesTable createAlias(String alias) {
    return $FavouriteMessagesTable(attachedDatabase, alias);
  }
}

class FavouriteMessage extends DataClass
    implements Insertable<FavouriteMessage> {
  final String templateId;
  const FavouriteMessage({required this.templateId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['template_id'] = Variable<String>(templateId);
    return map;
  }

  FavouriteMessagesCompanion toCompanion(bool nullToAbsent) {
    return FavouriteMessagesCompanion(templateId: Value(templateId));
  }

  factory FavouriteMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavouriteMessage(
      templateId: serializer.fromJson<String>(json['templateId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'templateId': serializer.toJson<String>(templateId),
    };
  }

  FavouriteMessage copyWith({String? templateId}) =>
      FavouriteMessage(templateId: templateId ?? this.templateId);
  FavouriteMessage copyWithCompanion(FavouriteMessagesCompanion data) {
    return FavouriteMessage(
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavouriteMessage(')
          ..write('templateId: $templateId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => templateId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavouriteMessage && other.templateId == this.templateId);
}

class FavouriteMessagesCompanion extends UpdateCompanion<FavouriteMessage> {
  final Value<String> templateId;
  final Value<int> rowid;
  const FavouriteMessagesCompanion({
    this.templateId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavouriteMessagesCompanion.insert({
    required String templateId,
    this.rowid = const Value.absent(),
  }) : templateId = Value(templateId);
  static Insertable<FavouriteMessage> custom({
    Expression<String>? templateId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (templateId != null) 'template_id': templateId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavouriteMessagesCompanion copyWith({
    Value<String>? templateId,
    Value<int>? rowid,
  }) {
    return FavouriteMessagesCompanion(
      templateId: templateId ?? this.templateId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavouriteMessagesCompanion(')
          ..write('templateId: $templateId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FestivalOverridesTable extends FestivalOverrides
    with TableInfo<$FestivalOverridesTable, FestivalOverride> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FestivalOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _festivalIdMeta = const VerificationMeta(
    'festivalId',
  );
  @override
  late final GeneratedColumn<String> festivalId = GeneratedColumn<String>(
    'festival_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _datesMeta = const VerificationMeta('dates');
  @override
  late final GeneratedColumn<String> dates = GeneratedColumn<String>(
    'dates',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _suggestMeta = const VerificationMeta(
    'suggest',
  );
  @override
  late final GeneratedColumn<String> suggest = GeneratedColumn<String>(
    'suggest',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    festivalId,
    enabled,
    name,
    dates,
    suggest,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'festival_overrides';
  @override
  VerificationContext validateIntegrity(
    Insertable<FestivalOverride> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('festival_id')) {
      context.handle(
        _festivalIdMeta,
        festivalId.isAcceptableOrUnknown(data['festival_id']!, _festivalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_festivalIdMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('dates')) {
      context.handle(
        _datesMeta,
        dates.isAcceptableOrUnknown(data['dates']!, _datesMeta),
      );
    }
    if (data.containsKey('suggest')) {
      context.handle(
        _suggestMeta,
        suggest.isAcceptableOrUnknown(data['suggest']!, _suggestMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {festivalId};
  @override
  FestivalOverride map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FestivalOverride(
      festivalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}festival_id'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      dates: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dates'],
      ),
      suggest: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}suggest'],
      ),
    );
  }

  @override
  $FestivalOverridesTable createAlias(String alias) {
    return $FestivalOverridesTable(attachedDatabase, alias);
  }
}

class FestivalOverride extends DataClass
    implements Insertable<FestivalOverride> {
  final String festivalId;
  final bool? enabled;
  final String? name;

  /// JSON map of year → "yyyy-mm-dd" for dates you corrected.
  final String? dates;

  /// Comma-separated relations to suggest in Wish Mode.
  final String? suggest;
  const FestivalOverride({
    required this.festivalId,
    this.enabled,
    this.name,
    this.dates,
    this.suggest,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['festival_id'] = Variable<String>(festivalId);
    if (!nullToAbsent || enabled != null) {
      map['enabled'] = Variable<bool>(enabled);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || dates != null) {
      map['dates'] = Variable<String>(dates);
    }
    if (!nullToAbsent || suggest != null) {
      map['suggest'] = Variable<String>(suggest);
    }
    return map;
  }

  FestivalOverridesCompanion toCompanion(bool nullToAbsent) {
    return FestivalOverridesCompanion(
      festivalId: Value(festivalId),
      enabled: enabled == null && nullToAbsent
          ? const Value.absent()
          : Value(enabled),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      dates: dates == null && nullToAbsent
          ? const Value.absent()
          : Value(dates),
      suggest: suggest == null && nullToAbsent
          ? const Value.absent()
          : Value(suggest),
    );
  }

  factory FestivalOverride.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FestivalOverride(
      festivalId: serializer.fromJson<String>(json['festivalId']),
      enabled: serializer.fromJson<bool?>(json['enabled']),
      name: serializer.fromJson<String?>(json['name']),
      dates: serializer.fromJson<String?>(json['dates']),
      suggest: serializer.fromJson<String?>(json['suggest']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'festivalId': serializer.toJson<String>(festivalId),
      'enabled': serializer.toJson<bool?>(enabled),
      'name': serializer.toJson<String?>(name),
      'dates': serializer.toJson<String?>(dates),
      'suggest': serializer.toJson<String?>(suggest),
    };
  }

  FestivalOverride copyWith({
    String? festivalId,
    Value<bool?> enabled = const Value.absent(),
    Value<String?> name = const Value.absent(),
    Value<String?> dates = const Value.absent(),
    Value<String?> suggest = const Value.absent(),
  }) => FestivalOverride(
    festivalId: festivalId ?? this.festivalId,
    enabled: enabled.present ? enabled.value : this.enabled,
    name: name.present ? name.value : this.name,
    dates: dates.present ? dates.value : this.dates,
    suggest: suggest.present ? suggest.value : this.suggest,
  );
  FestivalOverride copyWithCompanion(FestivalOverridesCompanion data) {
    return FestivalOverride(
      festivalId: data.festivalId.present
          ? data.festivalId.value
          : this.festivalId,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      name: data.name.present ? data.name.value : this.name,
      dates: data.dates.present ? data.dates.value : this.dates,
      suggest: data.suggest.present ? data.suggest.value : this.suggest,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FestivalOverride(')
          ..write('festivalId: $festivalId, ')
          ..write('enabled: $enabled, ')
          ..write('name: $name, ')
          ..write('dates: $dates, ')
          ..write('suggest: $suggest')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(festivalId, enabled, name, dates, suggest);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FestivalOverride &&
          other.festivalId == this.festivalId &&
          other.enabled == this.enabled &&
          other.name == this.name &&
          other.dates == this.dates &&
          other.suggest == this.suggest);
}

class FestivalOverridesCompanion extends UpdateCompanion<FestivalOverride> {
  final Value<String> festivalId;
  final Value<bool?> enabled;
  final Value<String?> name;
  final Value<String?> dates;
  final Value<String?> suggest;
  final Value<int> rowid;
  const FestivalOverridesCompanion({
    this.festivalId = const Value.absent(),
    this.enabled = const Value.absent(),
    this.name = const Value.absent(),
    this.dates = const Value.absent(),
    this.suggest = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FestivalOverridesCompanion.insert({
    required String festivalId,
    this.enabled = const Value.absent(),
    this.name = const Value.absent(),
    this.dates = const Value.absent(),
    this.suggest = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : festivalId = Value(festivalId);
  static Insertable<FestivalOverride> custom({
    Expression<String>? festivalId,
    Expression<bool>? enabled,
    Expression<String>? name,
    Expression<String>? dates,
    Expression<String>? suggest,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (festivalId != null) 'festival_id': festivalId,
      if (enabled != null) 'enabled': enabled,
      if (name != null) 'name': name,
      if (dates != null) 'dates': dates,
      if (suggest != null) 'suggest': suggest,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FestivalOverridesCompanion copyWith({
    Value<String>? festivalId,
    Value<bool?>? enabled,
    Value<String?>? name,
    Value<String?>? dates,
    Value<String?>? suggest,
    Value<int>? rowid,
  }) {
    return FestivalOverridesCompanion(
      festivalId: festivalId ?? this.festivalId,
      enabled: enabled ?? this.enabled,
      name: name ?? this.name,
      dates: dates ?? this.dates,
      suggest: suggest ?? this.suggest,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (festivalId.present) {
      map['festival_id'] = Variable<String>(festivalId.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dates.present) {
      map['dates'] = Variable<String>(dates.value);
    }
    if (suggest.present) {
      map['suggest'] = Variable<String>(suggest.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FestivalOverridesCompanion(')
          ..write('festivalId: $festivalId, ')
          ..write('enabled: $enabled, ')
          ..write('name: $name, ')
          ..write('dates: $dates, ')
          ..write('suggest: $suggest, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomFestivalsTable extends CustomFestivals
    with TableInfo<$CustomFestivalsTable, CustomFestival> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomFestivalsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>(
    'day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _datesMeta = const VerificationMeta('dates');
  @override
  late final GeneratedColumn<String> dates = GeneratedColumn<String>(
    'dates',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _suggestMeta = const VerificationMeta(
    'suggest',
  );
  @override
  late final GeneratedColumn<String> suggest = GeneratedColumn<String>(
    'suggest',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    month,
    day,
    dates,
    enabled,
    suggest,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_festivals';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomFestival> instance, {
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
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    }
    if (data.containsKey('dates')) {
      context.handle(
        _datesMeta,
        dates.isAcceptableOrUnknown(data['dates']!, _datesMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('suggest')) {
      context.handle(
        _suggestMeta,
        suggest.isAcceptableOrUnknown(data['suggest']!, _suggestMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomFestival map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomFestival(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month'],
      ),
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day'],
      ),
      dates: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dates'],
      ),
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      suggest: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}suggest'],
      )!,
    );
  }

  @override
  $CustomFestivalsTable createAlias(String alias) {
    return $CustomFestivalsTable(attachedDatabase, alias);
  }
}

class CustomFestival extends DataClass implements Insertable<CustomFestival> {
  final int id;
  final String name;

  /// Same date every year (month/day), or specific dates in [dates].
  final int? month;
  final int? day;
  final String? dates;
  final bool enabled;
  final String suggest;
  const CustomFestival({
    required this.id,
    required this.name,
    this.month,
    this.day,
    this.dates,
    required this.enabled,
    required this.suggest,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || month != null) {
      map['month'] = Variable<int>(month);
    }
    if (!nullToAbsent || day != null) {
      map['day'] = Variable<int>(day);
    }
    if (!nullToAbsent || dates != null) {
      map['dates'] = Variable<String>(dates);
    }
    map['enabled'] = Variable<bool>(enabled);
    map['suggest'] = Variable<String>(suggest);
    return map;
  }

  CustomFestivalsCompanion toCompanion(bool nullToAbsent) {
    return CustomFestivalsCompanion(
      id: Value(id),
      name: Value(name),
      month: month == null && nullToAbsent
          ? const Value.absent()
          : Value(month),
      day: day == null && nullToAbsent ? const Value.absent() : Value(day),
      dates: dates == null && nullToAbsent
          ? const Value.absent()
          : Value(dates),
      enabled: Value(enabled),
      suggest: Value(suggest),
    );
  }

  factory CustomFestival.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomFestival(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      month: serializer.fromJson<int?>(json['month']),
      day: serializer.fromJson<int?>(json['day']),
      dates: serializer.fromJson<String?>(json['dates']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      suggest: serializer.fromJson<String>(json['suggest']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'month': serializer.toJson<int?>(month),
      'day': serializer.toJson<int?>(day),
      'dates': serializer.toJson<String?>(dates),
      'enabled': serializer.toJson<bool>(enabled),
      'suggest': serializer.toJson<String>(suggest),
    };
  }

  CustomFestival copyWith({
    int? id,
    String? name,
    Value<int?> month = const Value.absent(),
    Value<int?> day = const Value.absent(),
    Value<String?> dates = const Value.absent(),
    bool? enabled,
    String? suggest,
  }) => CustomFestival(
    id: id ?? this.id,
    name: name ?? this.name,
    month: month.present ? month.value : this.month,
    day: day.present ? day.value : this.day,
    dates: dates.present ? dates.value : this.dates,
    enabled: enabled ?? this.enabled,
    suggest: suggest ?? this.suggest,
  );
  CustomFestival copyWithCompanion(CustomFestivalsCompanion data) {
    return CustomFestival(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      month: data.month.present ? data.month.value : this.month,
      day: data.day.present ? data.day.value : this.day,
      dates: data.dates.present ? data.dates.value : this.dates,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      suggest: data.suggest.present ? data.suggest.value : this.suggest,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomFestival(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('month: $month, ')
          ..write('day: $day, ')
          ..write('dates: $dates, ')
          ..write('enabled: $enabled, ')
          ..write('suggest: $suggest')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, month, day, dates, enabled, suggest);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomFestival &&
          other.id == this.id &&
          other.name == this.name &&
          other.month == this.month &&
          other.day == this.day &&
          other.dates == this.dates &&
          other.enabled == this.enabled &&
          other.suggest == this.suggest);
}

class CustomFestivalsCompanion extends UpdateCompanion<CustomFestival> {
  final Value<int> id;
  final Value<String> name;
  final Value<int?> month;
  final Value<int?> day;
  final Value<String?> dates;
  final Value<bool> enabled;
  final Value<String> suggest;
  const CustomFestivalsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.month = const Value.absent(),
    this.day = const Value.absent(),
    this.dates = const Value.absent(),
    this.enabled = const Value.absent(),
    this.suggest = const Value.absent(),
  });
  CustomFestivalsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.month = const Value.absent(),
    this.day = const Value.absent(),
    this.dates = const Value.absent(),
    this.enabled = const Value.absent(),
    this.suggest = const Value.absent(),
  }) : name = Value(name);
  static Insertable<CustomFestival> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? month,
    Expression<int>? day,
    Expression<String>? dates,
    Expression<bool>? enabled,
    Expression<String>? suggest,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (month != null) 'month': month,
      if (day != null) 'day': day,
      if (dates != null) 'dates': dates,
      if (enabled != null) 'enabled': enabled,
      if (suggest != null) 'suggest': suggest,
    });
  }

  CustomFestivalsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int?>? month,
    Value<int?>? day,
    Value<String?>? dates,
    Value<bool>? enabled,
    Value<String>? suggest,
  }) {
    return CustomFestivalsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      month: month ?? this.month,
      day: day ?? this.day,
      dates: dates ?? this.dates,
      enabled: enabled ?? this.enabled,
      suggest: suggest ?? this.suggest,
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
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (dates.present) {
      map['dates'] = Variable<String>(dates.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (suggest.present) {
      map['suggest'] = Variable<String>(suggest.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomFestivalsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('month: $month, ')
          ..write('day: $day, ')
          ..write('dates: $dates, ')
          ..write('enabled: $enabled, ')
          ..write('suggest: $suggest')
          ..write(')'))
        .toString();
  }
}

class $WishSessionsTable extends WishSessions
    with TableInfo<$WishSessionsTable, WishSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WishSessionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _festivalIdMeta = const VerificationMeta(
    'festivalId',
  );
  @override
  late final GeneratedColumn<String> festivalId = GeneratedColumn<String>(
    'festival_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occasionDateMeta = const VerificationMeta(
    'occasionDate',
  );
  @override
  late final GeneratedColumn<String> occasionDate = GeneratedColumn<String>(
    'occasion_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedMeta = const VerificationMeta(
    'finished',
  );
  @override
  late final GeneratedColumn<bool> finished = GeneratedColumn<bool>(
    'finished',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("finished" IN (0, 1))',
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
    title,
    festivalId,
    occasionDate,
    finished,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wish_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<WishSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('festival_id')) {
      context.handle(
        _festivalIdMeta,
        festivalId.isAcceptableOrUnknown(data['festival_id']!, _festivalIdMeta),
      );
    }
    if (data.containsKey('occasion_date')) {
      context.handle(
        _occasionDateMeta,
        occasionDate.isAcceptableOrUnknown(
          data['occasion_date']!,
          _occasionDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occasionDateMeta);
    }
    if (data.containsKey('finished')) {
      context.handle(
        _finishedMeta,
        finished.isAcceptableOrUnknown(data['finished']!, _finishedMeta),
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
  WishSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WishSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      festivalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}festival_id'],
      ),
      occasionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occasion_date'],
      )!,
      finished: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}finished'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WishSessionsTable createAlias(String alias) {
    return $WishSessionsTable(attachedDatabase, alias);
  }
}

class WishSession extends DataClass implements Insertable<WishSession> {
  final int id;
  final String title;

  /// Festival key ("b:diwali_lakshmi_puja" / "c:3"), or null for "Today".
  final String? festivalId;
  final String occasionDate;
  final bool finished;
  final DateTime createdAt;
  const WishSession({
    required this.id,
    required this.title,
    this.festivalId,
    required this.occasionDate,
    required this.finished,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || festivalId != null) {
      map['festival_id'] = Variable<String>(festivalId);
    }
    map['occasion_date'] = Variable<String>(occasionDate);
    map['finished'] = Variable<bool>(finished);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WishSessionsCompanion toCompanion(bool nullToAbsent) {
    return WishSessionsCompanion(
      id: Value(id),
      title: Value(title),
      festivalId: festivalId == null && nullToAbsent
          ? const Value.absent()
          : Value(festivalId),
      occasionDate: Value(occasionDate),
      finished: Value(finished),
      createdAt: Value(createdAt),
    );
  }

  factory WishSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WishSession(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      festivalId: serializer.fromJson<String?>(json['festivalId']),
      occasionDate: serializer.fromJson<String>(json['occasionDate']),
      finished: serializer.fromJson<bool>(json['finished']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'festivalId': serializer.toJson<String?>(festivalId),
      'occasionDate': serializer.toJson<String>(occasionDate),
      'finished': serializer.toJson<bool>(finished),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  WishSession copyWith({
    int? id,
    String? title,
    Value<String?> festivalId = const Value.absent(),
    String? occasionDate,
    bool? finished,
    DateTime? createdAt,
  }) => WishSession(
    id: id ?? this.id,
    title: title ?? this.title,
    festivalId: festivalId.present ? festivalId.value : this.festivalId,
    occasionDate: occasionDate ?? this.occasionDate,
    finished: finished ?? this.finished,
    createdAt: createdAt ?? this.createdAt,
  );
  WishSession copyWithCompanion(WishSessionsCompanion data) {
    return WishSession(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      festivalId: data.festivalId.present
          ? data.festivalId.value
          : this.festivalId,
      occasionDate: data.occasionDate.present
          ? data.occasionDate.value
          : this.occasionDate,
      finished: data.finished.present ? data.finished.value : this.finished,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WishSession(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('festivalId: $festivalId, ')
          ..write('occasionDate: $occasionDate, ')
          ..write('finished: $finished, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, festivalId, occasionDate, finished, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WishSession &&
          other.id == this.id &&
          other.title == this.title &&
          other.festivalId == this.festivalId &&
          other.occasionDate == this.occasionDate &&
          other.finished == this.finished &&
          other.createdAt == this.createdAt);
}

class WishSessionsCompanion extends UpdateCompanion<WishSession> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> festivalId;
  final Value<String> occasionDate;
  final Value<bool> finished;
  final Value<DateTime> createdAt;
  const WishSessionsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.festivalId = const Value.absent(),
    this.occasionDate = const Value.absent(),
    this.finished = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WishSessionsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.festivalId = const Value.absent(),
    required String occasionDate,
    this.finished = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : title = Value(title),
       occasionDate = Value(occasionDate);
  static Insertable<WishSession> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? festivalId,
    Expression<String>? occasionDate,
    Expression<bool>? finished,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (festivalId != null) 'festival_id': festivalId,
      if (occasionDate != null) 'occasion_date': occasionDate,
      if (finished != null) 'finished': finished,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WishSessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? festivalId,
    Value<String>? occasionDate,
    Value<bool>? finished,
    Value<DateTime>? createdAt,
  }) {
    return WishSessionsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      festivalId: festivalId ?? this.festivalId,
      occasionDate: occasionDate ?? this.occasionDate,
      finished: finished ?? this.finished,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (festivalId.present) {
      map['festival_id'] = Variable<String>(festivalId.value);
    }
    if (occasionDate.present) {
      map['occasion_date'] = Variable<String>(occasionDate.value);
    }
    if (finished.present) {
      map['finished'] = Variable<bool>(finished.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WishSessionsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('festivalId: $festivalId, ')
          ..write('occasionDate: $occasionDate, ')
          ..write('finished: $finished, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WishSessionItemsTable extends WishSessionItems
    with TableInfo<$WishSessionItemsTable, WishSessionItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WishSessionItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES wish_sessions (id) ON DELETE CASCADE',
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
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<int> eventId = GeneratedColumn<int>(
    'event_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    personId,
    eventId,
    position,
    status,
    message,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wish_session_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<WishSessionItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WishSessionItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WishSessionItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}event_id'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      ),
    );
  }

  @override
  $WishSessionItemsTable createAlias(String alias) {
    return $WishSessionItemsTable(attachedDatabase, alias);
  }
}

class WishSessionItem extends DataClass implements Insertable<WishSessionItem> {
  final int id;
  final int sessionId;
  final int personId;

  /// For "Today" sessions: the event being wished.
  final int? eventId;
  final int position;

  /// pending, wished, skipped.
  final String status;
  final String? message;
  const WishSessionItem({
    required this.id,
    required this.sessionId,
    required this.personId,
    this.eventId,
    required this.position,
    required this.status,
    this.message,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['person_id'] = Variable<int>(personId);
    if (!nullToAbsent || eventId != null) {
      map['event_id'] = Variable<int>(eventId);
    }
    map['position'] = Variable<int>(position);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || message != null) {
      map['message'] = Variable<String>(message);
    }
    return map;
  }

  WishSessionItemsCompanion toCompanion(bool nullToAbsent) {
    return WishSessionItemsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      personId: Value(personId),
      eventId: eventId == null && nullToAbsent
          ? const Value.absent()
          : Value(eventId),
      position: Value(position),
      status: Value(status),
      message: message == null && nullToAbsent
          ? const Value.absent()
          : Value(message),
    );
  }

  factory WishSessionItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WishSessionItem(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      personId: serializer.fromJson<int>(json['personId']),
      eventId: serializer.fromJson<int?>(json['eventId']),
      position: serializer.fromJson<int>(json['position']),
      status: serializer.fromJson<String>(json['status']),
      message: serializer.fromJson<String?>(json['message']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'personId': serializer.toJson<int>(personId),
      'eventId': serializer.toJson<int?>(eventId),
      'position': serializer.toJson<int>(position),
      'status': serializer.toJson<String>(status),
      'message': serializer.toJson<String?>(message),
    };
  }

  WishSessionItem copyWith({
    int? id,
    int? sessionId,
    int? personId,
    Value<int?> eventId = const Value.absent(),
    int? position,
    String? status,
    Value<String?> message = const Value.absent(),
  }) => WishSessionItem(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    personId: personId ?? this.personId,
    eventId: eventId.present ? eventId.value : this.eventId,
    position: position ?? this.position,
    status: status ?? this.status,
    message: message.present ? message.value : this.message,
  );
  WishSessionItem copyWithCompanion(WishSessionItemsCompanion data) {
    return WishSessionItem(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      personId: data.personId.present ? data.personId.value : this.personId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      position: data.position.present ? data.position.value : this.position,
      status: data.status.present ? data.status.value : this.status,
      message: data.message.present ? data.message.value : this.message,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WishSessionItem(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('personId: $personId, ')
          ..write('eventId: $eventId, ')
          ..write('position: $position, ')
          ..write('status: $status, ')
          ..write('message: $message')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionId, personId, eventId, position, status, message);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WishSessionItem &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.personId == this.personId &&
          other.eventId == this.eventId &&
          other.position == this.position &&
          other.status == this.status &&
          other.message == this.message);
}

class WishSessionItemsCompanion extends UpdateCompanion<WishSessionItem> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<int> personId;
  final Value<int?> eventId;
  final Value<int> position;
  final Value<String> status;
  final Value<String?> message;
  const WishSessionItemsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.personId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.position = const Value.absent(),
    this.status = const Value.absent(),
    this.message = const Value.absent(),
  });
  WishSessionItemsCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required int personId,
    this.eventId = const Value.absent(),
    required int position,
    this.status = const Value.absent(),
    this.message = const Value.absent(),
  }) : sessionId = Value(sessionId),
       personId = Value(personId),
       position = Value(position);
  static Insertable<WishSessionItem> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<int>? personId,
    Expression<int>? eventId,
    Expression<int>? position,
    Expression<String>? status,
    Expression<String>? message,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (personId != null) 'person_id': personId,
      if (eventId != null) 'event_id': eventId,
      if (position != null) 'position': position,
      if (status != null) 'status': status,
      if (message != null) 'message': message,
    });
  }

  WishSessionItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<int>? personId,
    Value<int?>? eventId,
    Value<int>? position,
    Value<String>? status,
    Value<String?>? message,
  }) {
    return WishSessionItemsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      personId: personId ?? this.personId,
      eventId: eventId ?? this.eventId,
      position: position ?? this.position,
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<int>(eventId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WishSessionItemsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('personId: $personId, ')
          ..write('eventId: $eventId, ')
          ..write('position: $position, ')
          ..write('status: $status, ')
          ..write('message: $message')
          ..write(')'))
        .toString();
  }
}

class $PhotoMemoriesTable extends PhotoMemories
    with TableInfo<$PhotoMemoriesTable, PhotoMemory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotoMemoriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _captionMeta = const VerificationMeta(
    'caption',
  );
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
    'caption',
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
    personId,
    year,
    path,
    caption,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photo_memories';
  @override
  VerificationContext validateIntegrity(
    Insertable<PhotoMemory> instance, {
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
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('caption')) {
      context.handle(
        _captionMeta,
        caption.isAcceptableOrUnknown(data['caption']!, _captionMeta),
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
  PhotoMemory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhotoMemory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      caption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caption'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PhotoMemoriesTable createAlias(String alias) {
    return $PhotoMemoriesTable(attachedDatabase, alias);
  }
}

class PhotoMemory extends DataClass implements Insertable<PhotoMemory> {
  final int id;
  final int personId;
  final int year;
  final String path;
  final String? caption;
  final DateTime createdAt;
  const PhotoMemory({
    required this.id,
    required this.personId,
    required this.year,
    required this.path,
    this.caption,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['person_id'] = Variable<int>(personId);
    map['year'] = Variable<int>(year);
    map['path'] = Variable<String>(path);
    if (!nullToAbsent || caption != null) {
      map['caption'] = Variable<String>(caption);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PhotoMemoriesCompanion toCompanion(bool nullToAbsent) {
    return PhotoMemoriesCompanion(
      id: Value(id),
      personId: Value(personId),
      year: Value(year),
      path: Value(path),
      caption: caption == null && nullToAbsent
          ? const Value.absent()
          : Value(caption),
      createdAt: Value(createdAt),
    );
  }

  factory PhotoMemory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhotoMemory(
      id: serializer.fromJson<int>(json['id']),
      personId: serializer.fromJson<int>(json['personId']),
      year: serializer.fromJson<int>(json['year']),
      path: serializer.fromJson<String>(json['path']),
      caption: serializer.fromJson<String?>(json['caption']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'personId': serializer.toJson<int>(personId),
      'year': serializer.toJson<int>(year),
      'path': serializer.toJson<String>(path),
      'caption': serializer.toJson<String?>(caption),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PhotoMemory copyWith({
    int? id,
    int? personId,
    int? year,
    String? path,
    Value<String?> caption = const Value.absent(),
    DateTime? createdAt,
  }) => PhotoMemory(
    id: id ?? this.id,
    personId: personId ?? this.personId,
    year: year ?? this.year,
    path: path ?? this.path,
    caption: caption.present ? caption.value : this.caption,
    createdAt: createdAt ?? this.createdAt,
  );
  PhotoMemory copyWithCompanion(PhotoMemoriesCompanion data) {
    return PhotoMemory(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      year: data.year.present ? data.year.value : this.year,
      path: data.path.present ? data.path.value : this.path,
      caption: data.caption.present ? data.caption.value : this.caption,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhotoMemory(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('year: $year, ')
          ..write('path: $path, ')
          ..write('caption: $caption, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, personId, year, path, caption, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhotoMemory &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.year == this.year &&
          other.path == this.path &&
          other.caption == this.caption &&
          other.createdAt == this.createdAt);
}

class PhotoMemoriesCompanion extends UpdateCompanion<PhotoMemory> {
  final Value<int> id;
  final Value<int> personId;
  final Value<int> year;
  final Value<String> path;
  final Value<String?> caption;
  final Value<DateTime> createdAt;
  const PhotoMemoriesCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.year = const Value.absent(),
    this.path = const Value.absent(),
    this.caption = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PhotoMemoriesCompanion.insert({
    this.id = const Value.absent(),
    required int personId,
    required int year,
    required String path,
    this.caption = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : personId = Value(personId),
       year = Value(year),
       path = Value(path);
  static Insertable<PhotoMemory> custom({
    Expression<int>? id,
    Expression<int>? personId,
    Expression<int>? year,
    Expression<String>? path,
    Expression<String>? caption,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (year != null) 'year': year,
      if (path != null) 'path': path,
      if (caption != null) 'caption': caption,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PhotoMemoriesCompanion copyWith({
    Value<int>? id,
    Value<int>? personId,
    Value<int>? year,
    Value<String>? path,
    Value<String?>? caption,
    Value<DateTime>? createdAt,
  }) {
    return PhotoMemoriesCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      year: year ?? this.year,
      path: path ?? this.path,
      caption: caption ?? this.caption,
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
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotoMemoriesCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('year: $year, ')
          ..write('path: $path, ')
          ..write('caption: $caption, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $GroupsTable extends Groups with TableInfo<$GroupsTable, PersonGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  List<GeneratedColumn> get $columns => [id, name, color, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonGroup> instance, {
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
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
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
  PersonGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonGroup(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $GroupsTable createAlias(String alias) {
    return $GroupsTable(attachedDatabase, alias);
  }
}

class PersonGroup extends DataClass implements Insertable<PersonGroup> {
  final int id;
  final String name;
  final int color;
  final DateTime createdAt;
  const PersonGroup({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<int>(color);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GroupsCompanion toCompanion(bool nullToAbsent) {
    return GroupsCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
      createdAt: Value(createdAt),
    );
  }

  factory PersonGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonGroup(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int>(json['color']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int>(color),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PersonGroup copyWith({
    int? id,
    String? name,
    int? color,
    DateTime? createdAt,
  }) => PersonGroup(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color ?? this.color,
    createdAt: createdAt ?? this.createdAt,
  );
  PersonGroup copyWithCompanion(GroupsCompanion data) {
    return PersonGroup(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonGroup(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonGroup &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.createdAt == this.createdAt);
}

class GroupsCompanion extends UpdateCompanion<PersonGroup> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> color;
  final Value<DateTime> createdAt;
  const GroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  GroupsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<PersonGroup> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? color,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  GroupsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? color,
    Value<DateTime>? createdAt,
  }) {
    return GroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
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
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $GroupMembersTable extends GroupMembers
    with TableInfo<$GroupMembersTable, GroupMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id) ON DELETE CASCADE',
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
  @override
  List<GeneratedColumn> get $columns => [groupId, personId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroupMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId, personId};
  @override
  GroupMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupMember(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      )!,
    );
  }

  @override
  $GroupMembersTable createAlias(String alias) {
    return $GroupMembersTable(attachedDatabase, alias);
  }
}

class GroupMember extends DataClass implements Insertable<GroupMember> {
  final int groupId;
  final int personId;
  const GroupMember({required this.groupId, required this.personId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<int>(groupId);
    map['person_id'] = Variable<int>(personId);
    return map;
  }

  GroupMembersCompanion toCompanion(bool nullToAbsent) {
    return GroupMembersCompanion(
      groupId: Value(groupId),
      personId: Value(personId),
    );
  }

  factory GroupMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupMember(
      groupId: serializer.fromJson<int>(json['groupId']),
      personId: serializer.fromJson<int>(json['personId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<int>(groupId),
      'personId': serializer.toJson<int>(personId),
    };
  }

  GroupMember copyWith({int? groupId, int? personId}) => GroupMember(
    groupId: groupId ?? this.groupId,
    personId: personId ?? this.personId,
  );
  GroupMember copyWithCompanion(GroupMembersCompanion data) {
    return GroupMember(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      personId: data.personId.present ? data.personId.value : this.personId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupMember(')
          ..write('groupId: $groupId, ')
          ..write('personId: $personId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(groupId, personId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupMember &&
          other.groupId == this.groupId &&
          other.personId == this.personId);
}

class GroupMembersCompanion extends UpdateCompanion<GroupMember> {
  final Value<int> groupId;
  final Value<int> personId;
  final Value<int> rowid;
  const GroupMembersCompanion({
    this.groupId = const Value.absent(),
    this.personId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupMembersCompanion.insert({
    required int groupId,
    required int personId,
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId),
       personId = Value(personId);
  static Insertable<GroupMember> custom({
    Expression<int>? groupId,
    Expression<int>? personId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (personId != null) 'person_id': personId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupMembersCompanion copyWith({
    Value<int>? groupId,
    Value<int>? personId,
    Value<int>? rowid,
  }) {
    return GroupMembersCompanion(
      groupId: groupId ?? this.groupId,
      personId: personId ?? this.personId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupMembersCompanion(')
          ..write('groupId: $groupId, ')
          ..write('personId: $personId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FamilyLinksTable extends FamilyLinks
    with TableInfo<$FamilyLinksTable, FamilyLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FamilyLinksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _relativeIdMeta = const VerificationMeta(
    'relativeId',
  );
  @override
  late final GeneratedColumn<int> relativeId = GeneratedColumn<int>(
    'relative_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES people (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _relationMeta = const VerificationMeta(
    'relation',
  );
  @override
  late final GeneratedColumn<String> relation = GeneratedColumn<String>(
    'relation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, personId, relativeId, relation];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'family_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<FamilyLink> instance, {
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
    if (data.containsKey('relative_id')) {
      context.handle(
        _relativeIdMeta,
        relativeId.isAcceptableOrUnknown(data['relative_id']!, _relativeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_relativeIdMeta);
    }
    if (data.containsKey('relation')) {
      context.handle(
        _relationMeta,
        relation.isAcceptableOrUnknown(data['relation']!, _relationMeta),
      );
    } else if (isInserting) {
      context.missing(_relationMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FamilyLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FamilyLink(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      )!,
      relativeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}relative_id'],
      )!,
      relation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relation'],
      )!,
    );
  }

  @override
  $FamilyLinksTable createAlias(String alias) {
    return $FamilyLinksTable(attachedDatabase, alias);
  }
}

class FamilyLink extends DataClass implements Insertable<FamilyLink> {
  final int id;
  final int personId;
  final int relativeId;
  final String relation;
  const FamilyLink({
    required this.id,
    required this.personId,
    required this.relativeId,
    required this.relation,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['person_id'] = Variable<int>(personId);
    map['relative_id'] = Variable<int>(relativeId);
    map['relation'] = Variable<String>(relation);
    return map;
  }

  FamilyLinksCompanion toCompanion(bool nullToAbsent) {
    return FamilyLinksCompanion(
      id: Value(id),
      personId: Value(personId),
      relativeId: Value(relativeId),
      relation: Value(relation),
    );
  }

  factory FamilyLink.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FamilyLink(
      id: serializer.fromJson<int>(json['id']),
      personId: serializer.fromJson<int>(json['personId']),
      relativeId: serializer.fromJson<int>(json['relativeId']),
      relation: serializer.fromJson<String>(json['relation']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'personId': serializer.toJson<int>(personId),
      'relativeId': serializer.toJson<int>(relativeId),
      'relation': serializer.toJson<String>(relation),
    };
  }

  FamilyLink copyWith({
    int? id,
    int? personId,
    int? relativeId,
    String? relation,
  }) => FamilyLink(
    id: id ?? this.id,
    personId: personId ?? this.personId,
    relativeId: relativeId ?? this.relativeId,
    relation: relation ?? this.relation,
  );
  FamilyLink copyWithCompanion(FamilyLinksCompanion data) {
    return FamilyLink(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      relativeId: data.relativeId.present
          ? data.relativeId.value
          : this.relativeId,
      relation: data.relation.present ? data.relation.value : this.relation,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FamilyLink(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('relativeId: $relativeId, ')
          ..write('relation: $relation')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, personId, relativeId, relation);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FamilyLink &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.relativeId == this.relativeId &&
          other.relation == this.relation);
}

class FamilyLinksCompanion extends UpdateCompanion<FamilyLink> {
  final Value<int> id;
  final Value<int> personId;
  final Value<int> relativeId;
  final Value<String> relation;
  const FamilyLinksCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.relativeId = const Value.absent(),
    this.relation = const Value.absent(),
  });
  FamilyLinksCompanion.insert({
    this.id = const Value.absent(),
    required int personId,
    required int relativeId,
    required String relation,
  }) : personId = Value(personId),
       relativeId = Value(relativeId),
       relation = Value(relation);
  static Insertable<FamilyLink> custom({
    Expression<int>? id,
    Expression<int>? personId,
    Expression<int>? relativeId,
    Expression<String>? relation,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (relativeId != null) 'relative_id': relativeId,
      if (relation != null) 'relation': relation,
    });
  }

  FamilyLinksCompanion copyWith({
    Value<int>? id,
    Value<int>? personId,
    Value<int>? relativeId,
    Value<String>? relation,
  }) {
    return FamilyLinksCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      relativeId: relativeId ?? this.relativeId,
      relation: relation ?? this.relation,
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
    if (relativeId.present) {
      map['relative_id'] = Variable<int>(relativeId.value);
    }
    if (relation.present) {
      map['relation'] = Variable<String>(relation.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FamilyLinksCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('relativeId: $relativeId, ')
          ..write('relation: $relation')
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
  late final $WishLogsTable wishLogs = $WishLogsTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $UserMessagesTable userMessages = $UserMessagesTable(this);
  late final $FavouriteMessagesTable favouriteMessages =
      $FavouriteMessagesTable(this);
  late final $FestivalOverridesTable festivalOverrides =
      $FestivalOverridesTable(this);
  late final $CustomFestivalsTable customFestivals = $CustomFestivalsTable(
    this,
  );
  late final $WishSessionsTable wishSessions = $WishSessionsTable(this);
  late final $WishSessionItemsTable wishSessionItems = $WishSessionItemsTable(
    this,
  );
  late final $PhotoMemoriesTable photoMemories = $PhotoMemoriesTable(this);
  late final $GroupsTable groups = $GroupsTable(this);
  late final $GroupMembersTable groupMembers = $GroupMembersTable(this);
  late final $FamilyLinksTable familyLinks = $FamilyLinksTable(this);
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
    wishLogs,
    reminders,
    userMessages,
    favouriteMessages,
    festivalOverrides,
    customFestivals,
    wishSessions,
    wishSessionItems,
    photoMemories,
    groups,
    groupMembers,
    familyLinks,
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
        'events',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('gift_ideas', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'people',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('contact_notices', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'people',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('wish_logs', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'events',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('wish_logs', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'events',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reminders', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'wish_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('wish_session_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'people',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('wish_session_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'people',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('photo_memories', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'groups',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('group_members', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'people',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('group_members', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'people',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('family_links', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'people',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('family_links', kind: UpdateKind.delete)],
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
  Value<String> whatsappApp,
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
  Value<String> whatsappApp,
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

  static MultiTypedResultKey<$WishLogsTable, List<WishLog>> _wishLogsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.wishLogs,
    aliasName: 'people__id__wish_logs__person_id',
  );

  $$WishLogsTableProcessedTableManager get wishLogsRefs {
    final manager = $$WishLogsTableTableManager(
      $_db,
      $_db.wishLogs,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_wishLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WishSessionItemsTable, List<WishSessionItem>>
  _wishSessionItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.wishSessionItems,
    aliasName: 'people__id__wish_session_items__person_id',
  );

  $$WishSessionItemsTableProcessedTableManager get wishSessionItemsRefs {
    final manager = $$WishSessionItemsTableTableManager(
      $_db,
      $_db.wishSessionItems,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _wishSessionItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PhotoMemoriesTable, List<PhotoMemory>>
  _photoMemoriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.photoMemories,
    aliasName: 'people__id__photo_memories__person_id',
  );

  $$PhotoMemoriesTableProcessedTableManager get photoMemoriesRefs {
    final manager = $$PhotoMemoriesTableTableManager(
      $_db,
      $_db.photoMemories,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_photoMemoriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GroupMembersTable, List<GroupMember>>
  _groupMembersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.groupMembers,
    aliasName: 'people__id__group_members__person_id',
  );

  $$GroupMembersTableProcessedTableManager get groupMembersRefs {
    final manager = $$GroupMembersTableTableManager(
      $_db,
      $_db.groupMembers,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_groupMembersRefsTable($_db));
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

  ColumnFilters<String> get whatsappApp => $composableBuilder(
    column: $table.whatsappApp,
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

  Expression<bool> wishLogsRefs(
    Expression<bool> Function($$WishLogsTableFilterComposer f) f,
  ) {
    final $$WishLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wishLogs,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WishLogsTableFilterComposer(
            $db: $db,
            $table: $db.wishLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> wishSessionItemsRefs(
    Expression<bool> Function($$WishSessionItemsTableFilterComposer f) f,
  ) {
    final $$WishSessionItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wishSessionItems,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WishSessionItemsTableFilterComposer(
            $db: $db,
            $table: $db.wishSessionItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> photoMemoriesRefs(
    Expression<bool> Function($$PhotoMemoriesTableFilterComposer f) f,
  ) {
    final $$PhotoMemoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.photoMemories,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotoMemoriesTableFilterComposer(
            $db: $db,
            $table: $db.photoMemories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> groupMembersRefs(
    Expression<bool> Function($$GroupMembersTableFilterComposer f) f,
  ) {
    final $$GroupMembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.groupMembers,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupMembersTableFilterComposer(
            $db: $db,
            $table: $db.groupMembers,
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

  ColumnOrderings<String> get whatsappApp => $composableBuilder(
    column: $table.whatsappApp,
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

  GeneratedColumn<String> get whatsappApp => $composableBuilder(
    column: $table.whatsappApp,
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

  Expression<T> wishLogsRefs<T extends Object>(
    Expression<T> Function($$WishLogsTableAnnotationComposer a) f,
  ) {
    final $$WishLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wishLogs,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WishLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.wishLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> wishSessionItemsRefs<T extends Object>(
    Expression<T> Function($$WishSessionItemsTableAnnotationComposer a) f,
  ) {
    final $$WishSessionItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wishSessionItems,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WishSessionItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.wishSessionItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> photoMemoriesRefs<T extends Object>(
    Expression<T> Function($$PhotoMemoriesTableAnnotationComposer a) f,
  ) {
    final $$PhotoMemoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.photoMemories,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotoMemoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.photoMemories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> groupMembersRefs<T extends Object>(
    Expression<T> Function($$GroupMembersTableAnnotationComposer a) f,
  ) {
    final $$GroupMembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.groupMembers,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupMembersTableAnnotationComposer(
            $db: $db,
            $table: $db.groupMembers,
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
            bool wishLogsRefs,
            bool wishSessionItemsRefs,
            bool photoMemoriesRefs,
            bool groupMembersRefs,
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
                Value<String> whatsappApp = const Value.absent(),
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
                whatsappApp: whatsappApp,
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
                Value<String> whatsappApp = const Value.absent(),
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
                whatsappApp: whatsappApp,
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
                wishLogsRefs = false,
                wishSessionItemsRefs = false,
                photoMemoriesRefs = false,
                groupMembersRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (eventPeopleRefs) db.eventPeople,
                    if (giftIdeasRefs) db.giftIdeas,
                    if (contactNoticesRefs) db.contactNotices,
                    if (wishLogsRefs) db.wishLogs,
                    if (wishSessionItemsRefs) db.wishSessionItems,
                    if (photoMemoriesRefs) db.photoMemories,
                    if (groupMembersRefs) db.groupMembers,
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
                      if (wishLogsRefs)
                        await $_getPrefetchedData<
                          Person,
                          $PeopleTable,
                          WishLog
                        >(
                          currentTable: table,
                          referencedTable: $$PeopleTableReferences
                              ._wishLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PeopleTableReferences(
                                db,
                                table,
                                p0,
                              ).wishLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (wishSessionItemsRefs)
                        await $_getPrefetchedData<
                          Person,
                          $PeopleTable,
                          WishSessionItem
                        >(
                          currentTable: table,
                          referencedTable: $$PeopleTableReferences
                              ._wishSessionItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PeopleTableReferences(
                                db,
                                table,
                                p0,
                              ).wishSessionItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (photoMemoriesRefs)
                        await $_getPrefetchedData<
                          Person,
                          $PeopleTable,
                          PhotoMemory
                        >(
                          currentTable: table,
                          referencedTable: $$PeopleTableReferences
                              ._photoMemoriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PeopleTableReferences(
                                db,
                                table,
                                p0,
                              ).photoMemoriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (groupMembersRefs)
                        await $_getPrefetchedData<
                          Person,
                          $PeopleTable,
                          GroupMember
                        >(
                          currentTable: table,
                          referencedTable: $$PeopleTableReferences
                              ._groupMembersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PeopleTableReferences(
                                db,
                                table,
                                p0,
                              ).groupMembersRefs,
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
        bool wishLogsRefs,
        bool wishSessionItemsRefs,
        bool photoMemoriesRefs,
        bool groupMembersRefs,
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

  static MultiTypedResultKey<$GiftIdeasTable, List<GiftIdea>>
  _giftIdeasRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.giftIdeas,
    aliasName: 'events__id__gift_ideas__event_id',
  );

  $$GiftIdeasTableProcessedTableManager get giftIdeasRefs {
    final manager = $$GiftIdeasTableTableManager(
      $_db,
      $_db.giftIdeas,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_giftIdeasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WishLogsTable, List<WishLog>> _wishLogsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.wishLogs,
    aliasName: 'events__id__wish_logs__event_id',
  );

  $$WishLogsTableProcessedTableManager get wishLogsRefs {
    final manager = $$WishLogsTableTableManager(
      $_db,
      $_db.wishLogs,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_wishLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RemindersTable, List<Reminder>>
  _remindersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reminders,
    aliasName: 'events__id__reminders__event_id',
  );

  $$RemindersTableProcessedTableManager get remindersRefs {
    final manager = $$RemindersTableTableManager(
      $_db,
      $_db.reminders,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_remindersRefsTable($_db));
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

  Expression<bool> giftIdeasRefs(
    Expression<bool> Function($$GiftIdeasTableFilterComposer f) f,
  ) {
    final $$GiftIdeasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.giftIdeas,
      getReferencedColumn: (t) => t.eventId,
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

  Expression<bool> wishLogsRefs(
    Expression<bool> Function($$WishLogsTableFilterComposer f) f,
  ) {
    final $$WishLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wishLogs,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WishLogsTableFilterComposer(
            $db: $db,
            $table: $db.wishLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> remindersRefs(
    Expression<bool> Function($$RemindersTableFilterComposer f) f,
  ) {
    final $$RemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableFilterComposer(
            $db: $db,
            $table: $db.reminders,
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

  Expression<T> giftIdeasRefs<T extends Object>(
    Expression<T> Function($$GiftIdeasTableAnnotationComposer a) f,
  ) {
    final $$GiftIdeasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.giftIdeas,
      getReferencedColumn: (t) => t.eventId,
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

  Expression<T> wishLogsRefs<T extends Object>(
    Expression<T> Function($$WishLogsTableAnnotationComposer a) f,
  ) {
    final $$WishLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wishLogs,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WishLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.wishLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> remindersRefs<T extends Object>(
    Expression<T> Function($$RemindersTableAnnotationComposer a) f,
  ) {
    final $$RemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.reminders,
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
          PrefetchHooks Function({
            bool eventPeopleRefs,
            bool giftIdeasRefs,
            bool wishLogsRefs,
            bool remindersRefs,
          })
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
          prefetchHooksCallback:
              ({
                eventPeopleRefs = false,
                giftIdeasRefs = false,
                wishLogsRefs = false,
                remindersRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (eventPeopleRefs) db.eventPeople,
                    if (giftIdeasRefs) db.giftIdeas,
                    if (wishLogsRefs) db.wishLogs,
                    if (remindersRefs) db.reminders,
                  ],
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
                          managerFromTypedResult: (p0) =>
                              $$EventsTableReferences(
                                db,
                                table,
                                p0,
                              ).eventPeopleRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (giftIdeasRefs)
                        await $_getPrefetchedData<
                          Event,
                          $EventsTable,
                          GiftIdea
                        >(
                          currentTable: table,
                          referencedTable: $$EventsTableReferences
                              ._giftIdeasRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EventsTableReferences(
                                db,
                                table,
                                p0,
                              ).giftIdeasRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (wishLogsRefs)
                        await $_getPrefetchedData<Event, $EventsTable, WishLog>(
                          currentTable: table,
                          referencedTable: $$EventsTableReferences
                              ._wishLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EventsTableReferences(
                                db,
                                table,
                                p0,
                              ).wishLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (remindersRefs)
                        await $_getPrefetchedData<
                          Event,
                          $EventsTable,
                          Reminder
                        >(
                          currentTable: table,
                          referencedTable: $$EventsTableReferences
                              ._remindersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EventsTableReferences(
                                db,
                                table,
                                p0,
                              ).remindersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventId == item.id,
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
      PrefetchHooks Function({
        bool eventPeopleRefs,
        bool giftIdeasRefs,
        bool wishLogsRefs,
        bool remindersRefs,
      })
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
  Value<int?> budget,
  Value<int?> eventId,
});
typedef $$GiftIdeasTableUpdateCompanionBuilder = GiftIdeasCompanion Function({
  Value<int> id,
  Value<int> personId,
  Value<String> idea,
  Value<bool> purchased,
  Value<DateTime> createdAt,
  Value<int?> budget,
  Value<int?> eventId,
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

  static $EventsTable _eventIdTable(_$AppDatabase db) =>
      db.events.createAlias('gift_ideas__event_id__events__id');

  $$EventsTableProcessedTableManager? get eventId {
    final $_column = $_itemColumn<int>('event_id');
    if ($_column == null) return null;
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

  ColumnFilters<int> get budget => $composableBuilder(
    column: $table.budget,
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

  ColumnOrderings<int> get budget => $composableBuilder(
    column: $table.budget,
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

  GeneratedColumn<int> get budget =>
      $composableBuilder(column: $table.budget, builder: (column) => column);

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
          PrefetchHooks Function({bool personId, bool eventId})
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
                Value<int?> budget = const Value.absent(),
                Value<int?> eventId = const Value.absent(),
              }) => GiftIdeasCompanion(
                id: id,
                personId: personId,
                idea: idea,
                purchased: purchased,
                createdAt: createdAt,
                budget: budget,
                eventId: eventId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int personId,
                required String idea,
                Value<bool> purchased = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int?> budget = const Value.absent(),
                Value<int?> eventId = const Value.absent(),
              }) => GiftIdeasCompanion.insert(
                id: id,
                personId: personId,
                idea: idea,
                purchased: purchased,
                createdAt: createdAt,
                budget: budget,
                eventId: eventId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GiftIdeasTable, GiftIdea>(table),
                  $$GiftIdeasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personId = false, eventId = false}) {
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
                    if (eventId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.eventId,
                        referencedTable: $$GiftIdeasTableReferences
                            ._eventIdTable(db),
                        referencedColumn: $$GiftIdeasTableReferences
                            ._eventIdTable(db)
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
      PrefetchHooks Function({bool personId, bool eventId})
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
typedef $$WishLogsTableCreateCompanionBuilder = WishLogsCompanion Function({
  Value<int> id,
  Value<int?> personId,
  Value<int?> eventId,
  Value<String?> festivalId,
  Value<String?> occasionDate,
  required String method,
  Value<String?> message,
  Value<String?> templateId,
  Value<bool> confirmed,
  Value<DateTime> createdAt,
});
typedef $$WishLogsTableUpdateCompanionBuilder = WishLogsCompanion Function({
  Value<int> id,
  Value<int?> personId,
  Value<int?> eventId,
  Value<String?> festivalId,
  Value<String?> occasionDate,
  Value<String> method,
  Value<String?> message,
  Value<String?> templateId,
  Value<bool> confirmed,
  Value<DateTime> createdAt,
});

final class $$WishLogsTableReferences
    extends BaseReferences<_$AppDatabase, $WishLogsTable, WishLog> {
  $$WishLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PeopleTable _personIdTable(_$AppDatabase db) =>
      db.people.createAlias('wish_logs__person_id__people__id');

  $$PeopleTableProcessedTableManager? get personId {
    final $_column = $_itemColumn<int>('person_id');
    if ($_column == null) return null;
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

  static $EventsTable _eventIdTable(_$AppDatabase db) =>
      db.events.createAlias('wish_logs__event_id__events__id');

  $$EventsTableProcessedTableManager? get eventId {
    final $_column = $_itemColumn<int>('event_id');
    if ($_column == null) return null;
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
}

class $$WishLogsTableFilterComposer
    extends Composer<_$AppDatabase, $WishLogsTable> {
  $$WishLogsTableFilterComposer({
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

  ColumnFilters<String> get festivalId => $composableBuilder(
    column: $table.festivalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occasionDate => $composableBuilder(
    column: $table.occasionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get confirmed => $composableBuilder(
    column: $table.confirmed,
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
}

class $$WishLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $WishLogsTable> {
  $$WishLogsTableOrderingComposer({
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

  ColumnOrderings<String> get festivalId => $composableBuilder(
    column: $table.festivalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occasionDate => $composableBuilder(
    column: $table.occasionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get confirmed => $composableBuilder(
    column: $table.confirmed,
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
}

class $$WishLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WishLogsTable> {
  $$WishLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get festivalId => $composableBuilder(
    column: $table.festivalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get occasionDate => $composableBuilder(
    column: $table.occasionDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get confirmed =>
      $composableBuilder(column: $table.confirmed, builder: (column) => column);

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
}

class $$WishLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WishLogsTable,
          WishLog,
          $$WishLogsTableFilterComposer,
          $$WishLogsTableOrderingComposer,
          $$WishLogsTableAnnotationComposer,
          $$WishLogsTableCreateCompanionBuilder,
          $$WishLogsTableUpdateCompanionBuilder,
          (WishLog, $$WishLogsTableReferences),
          WishLog,
          PrefetchHooks Function({bool personId, bool eventId})
        > {
  $$WishLogsTableTableManager(_$AppDatabase db, $WishLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WishLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WishLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WishLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> personId = const Value.absent(),
                Value<int?> eventId = const Value.absent(),
                Value<String?> festivalId = const Value.absent(),
                Value<String?> occasionDate = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<String?> message = const Value.absent(),
                Value<String?> templateId = const Value.absent(),
                Value<bool> confirmed = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => WishLogsCompanion(
                id: id,
                personId: personId,
                eventId: eventId,
                festivalId: festivalId,
                occasionDate: occasionDate,
                method: method,
                message: message,
                templateId: templateId,
                confirmed: confirmed,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> personId = const Value.absent(),
                Value<int?> eventId = const Value.absent(),
                Value<String?> festivalId = const Value.absent(),
                Value<String?> occasionDate = const Value.absent(),
                required String method,
                Value<String?> message = const Value.absent(),
                Value<String?> templateId = const Value.absent(),
                Value<bool> confirmed = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => WishLogsCompanion.insert(
                id: id,
                personId: personId,
                eventId: eventId,
                festivalId: festivalId,
                occasionDate: occasionDate,
                method: method,
                message: message,
                templateId: templateId,
                confirmed: confirmed,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WishLogsTable, WishLog>(table),
                  $$WishLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personId = false, eventId = false}) {
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
                        referencedTable: $$WishLogsTableReferences
                            ._personIdTable(db),
                        referencedColumn: $$WishLogsTableReferences
                            ._personIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (eventId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.eventId,
                        referencedTable: $$WishLogsTableReferences
                            ._eventIdTable(db),
                        referencedColumn: $$WishLogsTableReferences
                            ._eventIdTable(db)
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

typedef $$WishLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WishLogsTable,
      WishLog,
      $$WishLogsTableFilterComposer,
      $$WishLogsTableOrderingComposer,
      $$WishLogsTableAnnotationComposer,
      $$WishLogsTableCreateCompanionBuilder,
      $$WishLogsTableUpdateCompanionBuilder,
      (WishLog, $$WishLogsTableReferences),
      WishLog,
      PrefetchHooks Function({bool personId, bool eventId})
    >;
typedef $$RemindersTableCreateCompanionBuilder = RemindersCompanion Function({
  Value<int> id,
  required int eventId,
  required String kind,
  Value<int> daysBefore,
  Value<int> minuteOfDay,
  Value<bool> enabled,
});
typedef $$RemindersTableUpdateCompanionBuilder = RemindersCompanion Function({
  Value<int> id,
  Value<int> eventId,
  Value<String> kind,
  Value<int> daysBefore,
  Value<int> minuteOfDay,
  Value<bool> enabled,
});

final class $$RemindersTableReferences
    extends BaseReferences<_$AppDatabase, $RemindersTable, Reminder> {
  $$RemindersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EventsTable _eventIdTable(_$AppDatabase db) =>
      db.events.createAlias('reminders__event_id__events__id');

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
}

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
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

  ColumnFilters<int> get daysBefore => $composableBuilder(
    column: $table.daysBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minuteOfDay => $composableBuilder(
    column: $table.minuteOfDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
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
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
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

  ColumnOrderings<int> get daysBefore => $composableBuilder(
    column: $table.daysBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minuteOfDay => $composableBuilder(
    column: $table.minuteOfDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
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
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
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

  GeneratedColumn<int> get daysBefore => $composableBuilder(
    column: $table.daysBefore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get minuteOfDay => $composableBuilder(
    column: $table.minuteOfDay,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

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
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          Reminder,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (Reminder, $$RemindersTableReferences),
          Reminder,
          PrefetchHooks Function({bool eventId})
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> eventId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> daysBefore = const Value.absent(),
                Value<int> minuteOfDay = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                eventId: eventId,
                kind: kind,
                daysBefore: daysBefore,
                minuteOfDay: minuteOfDay,
                enabled: enabled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int eventId,
                required String kind,
                Value<int> daysBefore = const Value.absent(),
                Value<int> minuteOfDay = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
              }) => RemindersCompanion.insert(
                id: id,
                eventId: eventId,
                kind: kind,
                daysBefore: daysBefore,
                minuteOfDay: minuteOfDay,
                enabled: enabled,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RemindersTable, Reminder>(table),
                  $$RemindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({eventId = false}) {
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
                        referencedTable: $$RemindersTableReferences
                            ._eventIdTable(db),
                        referencedColumn: $$RemindersTableReferences
                            ._eventIdTable(db)
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

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      Reminder,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (Reminder, $$RemindersTableReferences),
      Reminder,
      PrefetchHooks Function({bool eventId})
    >;
typedef $$UserMessagesTableCreateCompanionBuilder =
    UserMessagesCompanion Function({
      Value<int> id,
      required String occasion,
      Value<String> relations,
      Value<String> tone,
      Value<String> lang,
      Value<String?> festival,
      required String body,
      Value<String?> baseId,
      Value<bool> favourite,
      Value<DateTime> createdAt,
    });
typedef $$UserMessagesTableUpdateCompanionBuilder =
    UserMessagesCompanion Function({
      Value<int> id,
      Value<String> occasion,
      Value<String> relations,
      Value<String> tone,
      Value<String> lang,
      Value<String?> festival,
      Value<String> body,
      Value<String?> baseId,
      Value<bool> favourite,
      Value<DateTime> createdAt,
    });

class $$UserMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $UserMessagesTable> {
  $$UserMessagesTableFilterComposer({
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

  ColumnFilters<String> get occasion => $composableBuilder(
    column: $table.occasion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relations => $composableBuilder(
    column: $table.relations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tone => $composableBuilder(
    column: $table.tone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get festival => $composableBuilder(
    column: $table.festival,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseId => $composableBuilder(
    column: $table.baseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get favourite => $composableBuilder(
    column: $table.favourite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserMessagesTable> {
  $$UserMessagesTableOrderingComposer({
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

  ColumnOrderings<String> get occasion => $composableBuilder(
    column: $table.occasion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relations => $composableBuilder(
    column: $table.relations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tone => $composableBuilder(
    column: $table.tone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get festival => $composableBuilder(
    column: $table.festival,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseId => $composableBuilder(
    column: $table.baseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get favourite => $composableBuilder(
    column: $table.favourite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserMessagesTable> {
  $$UserMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get occasion =>
      $composableBuilder(column: $table.occasion, builder: (column) => column);

  GeneratedColumn<String> get relations =>
      $composableBuilder(column: $table.relations, builder: (column) => column);

  GeneratedColumn<String> get tone =>
      $composableBuilder(column: $table.tone, builder: (column) => column);

  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);

  GeneratedColumn<String> get festival =>
      $composableBuilder(column: $table.festival, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get baseId =>
      $composableBuilder(column: $table.baseId, builder: (column) => column);

  GeneratedColumn<bool> get favourite =>
      $composableBuilder(column: $table.favourite, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UserMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserMessagesTable,
          UserMessage,
          $$UserMessagesTableFilterComposer,
          $$UserMessagesTableOrderingComposer,
          $$UserMessagesTableAnnotationComposer,
          $$UserMessagesTableCreateCompanionBuilder,
          $$UserMessagesTableUpdateCompanionBuilder,
          (
            UserMessage,
            BaseReferences<_$AppDatabase, $UserMessagesTable, UserMessage>,
          ),
          UserMessage,
          PrefetchHooks Function()
        > {
  $$UserMessagesTableTableManager(_$AppDatabase db, $UserMessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> occasion = const Value.absent(),
                Value<String> relations = const Value.absent(),
                Value<String> tone = const Value.absent(),
                Value<String> lang = const Value.absent(),
                Value<String?> festival = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String?> baseId = const Value.absent(),
                Value<bool> favourite = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => UserMessagesCompanion(
                id: id,
                occasion: occasion,
                relations: relations,
                tone: tone,
                lang: lang,
                festival: festival,
                body: body,
                baseId: baseId,
                favourite: favourite,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String occasion,
                Value<String> relations = const Value.absent(),
                Value<String> tone = const Value.absent(),
                Value<String> lang = const Value.absent(),
                Value<String?> festival = const Value.absent(),
                required String body,
                Value<String?> baseId = const Value.absent(),
                Value<bool> favourite = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => UserMessagesCompanion.insert(
                id: id,
                occasion: occasion,
                relations: relations,
                tone: tone,
                lang: lang,
                festival: festival,
                body: body,
                baseId: baseId,
                favourite: favourite,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserMessagesTable, UserMessage>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $UserMessagesTable,
                    UserMessage
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserMessagesTable,
      UserMessage,
      $$UserMessagesTableFilterComposer,
      $$UserMessagesTableOrderingComposer,
      $$UserMessagesTableAnnotationComposer,
      $$UserMessagesTableCreateCompanionBuilder,
      $$UserMessagesTableUpdateCompanionBuilder,
      (
        UserMessage,
        BaseReferences<_$AppDatabase, $UserMessagesTable, UserMessage>,
      ),
      UserMessage,
      PrefetchHooks Function()
    >;
typedef $$FavouriteMessagesTableCreateCompanionBuilder =
    FavouriteMessagesCompanion Function({
      required String templateId,
      Value<int> rowid,
    });
typedef $$FavouriteMessagesTableUpdateCompanionBuilder =
    FavouriteMessagesCompanion Function({
      Value<String> templateId,
      Value<int> rowid,
    });

class $$FavouriteMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $FavouriteMessagesTable> {
  $$FavouriteMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavouriteMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavouriteMessagesTable> {
  $$FavouriteMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavouriteMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavouriteMessagesTable> {
  $$FavouriteMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );
}

class $$FavouriteMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavouriteMessagesTable,
          FavouriteMessage,
          $$FavouriteMessagesTableFilterComposer,
          $$FavouriteMessagesTableOrderingComposer,
          $$FavouriteMessagesTableAnnotationComposer,
          $$FavouriteMessagesTableCreateCompanionBuilder,
          $$FavouriteMessagesTableUpdateCompanionBuilder,
          (
            FavouriteMessage,
            BaseReferences<
              _$AppDatabase,
              $FavouriteMessagesTable,
              FavouriteMessage
            >,
          ),
          FavouriteMessage,
          PrefetchHooks Function()
        > {
  $$FavouriteMessagesTableTableManager(
    _$AppDatabase db,
    $FavouriteMessagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavouriteMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavouriteMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavouriteMessagesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> templateId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavouriteMessagesCompanion(
                templateId: templateId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String templateId,
                Value<int> rowid = const Value.absent(),
              }) => FavouriteMessagesCompanion.insert(
                templateId: templateId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavouriteMessagesTable, FavouriteMessage>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FavouriteMessagesTable,
                    FavouriteMessage
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FavouriteMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavouriteMessagesTable,
      FavouriteMessage,
      $$FavouriteMessagesTableFilterComposer,
      $$FavouriteMessagesTableOrderingComposer,
      $$FavouriteMessagesTableAnnotationComposer,
      $$FavouriteMessagesTableCreateCompanionBuilder,
      $$FavouriteMessagesTableUpdateCompanionBuilder,
      (
        FavouriteMessage,
        BaseReferences<
          _$AppDatabase,
          $FavouriteMessagesTable,
          FavouriteMessage
        >,
      ),
      FavouriteMessage,
      PrefetchHooks Function()
    >;
typedef $$FestivalOverridesTableCreateCompanionBuilder =
    FestivalOverridesCompanion Function({
      required String festivalId,
      Value<bool?> enabled,
      Value<String?> name,
      Value<String?> dates,
      Value<String?> suggest,
      Value<int> rowid,
    });
typedef $$FestivalOverridesTableUpdateCompanionBuilder =
    FestivalOverridesCompanion Function({
      Value<String> festivalId,
      Value<bool?> enabled,
      Value<String?> name,
      Value<String?> dates,
      Value<String?> suggest,
      Value<int> rowid,
    });

class $$FestivalOverridesTableFilterComposer
    extends Composer<_$AppDatabase, $FestivalOverridesTable> {
  $$FestivalOverridesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get festivalId => $composableBuilder(
    column: $table.festivalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dates => $composableBuilder(
    column: $table.dates,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get suggest => $composableBuilder(
    column: $table.suggest,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FestivalOverridesTableOrderingComposer
    extends Composer<_$AppDatabase, $FestivalOverridesTable> {
  $$FestivalOverridesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get festivalId => $composableBuilder(
    column: $table.festivalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dates => $composableBuilder(
    column: $table.dates,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get suggest => $composableBuilder(
    column: $table.suggest,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FestivalOverridesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FestivalOverridesTable> {
  $$FestivalOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get festivalId => $composableBuilder(
    column: $table.festivalId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get dates =>
      $composableBuilder(column: $table.dates, builder: (column) => column);

  GeneratedColumn<String> get suggest =>
      $composableBuilder(column: $table.suggest, builder: (column) => column);
}

class $$FestivalOverridesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FestivalOverridesTable,
          FestivalOverride,
          $$FestivalOverridesTableFilterComposer,
          $$FestivalOverridesTableOrderingComposer,
          $$FestivalOverridesTableAnnotationComposer,
          $$FestivalOverridesTableCreateCompanionBuilder,
          $$FestivalOverridesTableUpdateCompanionBuilder,
          (
            FestivalOverride,
            BaseReferences<
              _$AppDatabase,
              $FestivalOverridesTable,
              FestivalOverride
            >,
          ),
          FestivalOverride,
          PrefetchHooks Function()
        > {
  $$FestivalOverridesTableTableManager(
    _$AppDatabase db,
    $FestivalOverridesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FestivalOverridesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FestivalOverridesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FestivalOverridesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> festivalId = const Value.absent(),
                Value<bool?> enabled = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> dates = const Value.absent(),
                Value<String?> suggest = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FestivalOverridesCompanion(
                festivalId: festivalId,
                enabled: enabled,
                name: name,
                dates: dates,
                suggest: suggest,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String festivalId,
                Value<bool?> enabled = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> dates = const Value.absent(),
                Value<String?> suggest = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FestivalOverridesCompanion.insert(
                festivalId: festivalId,
                enabled: enabled,
                name: name,
                dates: dates,
                suggest: suggest,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FestivalOverridesTable, FestivalOverride>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FestivalOverridesTable,
                    FestivalOverride
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FestivalOverridesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FestivalOverridesTable,
      FestivalOverride,
      $$FestivalOverridesTableFilterComposer,
      $$FestivalOverridesTableOrderingComposer,
      $$FestivalOverridesTableAnnotationComposer,
      $$FestivalOverridesTableCreateCompanionBuilder,
      $$FestivalOverridesTableUpdateCompanionBuilder,
      (
        FestivalOverride,
        BaseReferences<
          _$AppDatabase,
          $FestivalOverridesTable,
          FestivalOverride
        >,
      ),
      FestivalOverride,
      PrefetchHooks Function()
    >;
typedef $$CustomFestivalsTableCreateCompanionBuilder =
    CustomFestivalsCompanion Function({
      Value<int> id,
      required String name,
      Value<int?> month,
      Value<int?> day,
      Value<String?> dates,
      Value<bool> enabled,
      Value<String> suggest,
    });
typedef $$CustomFestivalsTableUpdateCompanionBuilder =
    CustomFestivalsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int?> month,
      Value<int?> day,
      Value<String?> dates,
      Value<bool> enabled,
      Value<String> suggest,
    });

class $$CustomFestivalsTableFilterComposer
    extends Composer<_$AppDatabase, $CustomFestivalsTable> {
  $$CustomFestivalsTableFilterComposer({
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

  ColumnFilters<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dates => $composableBuilder(
    column: $table.dates,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get suggest => $composableBuilder(
    column: $table.suggest,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomFestivalsTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomFestivalsTable> {
  $$CustomFestivalsTableOrderingComposer({
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

  ColumnOrderings<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dates => $composableBuilder(
    column: $table.dates,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get suggest => $composableBuilder(
    column: $table.suggest,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomFestivalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomFestivalsTable> {
  $$CustomFestivalsTableAnnotationComposer({
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

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get dates =>
      $composableBuilder(column: $table.dates, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<String> get suggest =>
      $composableBuilder(column: $table.suggest, builder: (column) => column);
}

class $$CustomFestivalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomFestivalsTable,
          CustomFestival,
          $$CustomFestivalsTableFilterComposer,
          $$CustomFestivalsTableOrderingComposer,
          $$CustomFestivalsTableAnnotationComposer,
          $$CustomFestivalsTableCreateCompanionBuilder,
          $$CustomFestivalsTableUpdateCompanionBuilder,
          (
            CustomFestival,
            BaseReferences<
              _$AppDatabase,
              $CustomFestivalsTable,
              CustomFestival
            >,
          ),
          CustomFestival,
          PrefetchHooks Function()
        > {
  $$CustomFestivalsTableTableManager(
    _$AppDatabase db,
    $CustomFestivalsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomFestivalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomFestivalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomFestivalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> month = const Value.absent(),
                Value<int?> day = const Value.absent(),
                Value<String?> dates = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String> suggest = const Value.absent(),
              }) => CustomFestivalsCompanion(
                id: id,
                name: name,
                month: month,
                day: day,
                dates: dates,
                enabled: enabled,
                suggest: suggest,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int?> month = const Value.absent(),
                Value<int?> day = const Value.absent(),
                Value<String?> dates = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String> suggest = const Value.absent(),
              }) => CustomFestivalsCompanion.insert(
                id: id,
                name: name,
                month: month,
                day: day,
                dates: dates,
                enabled: enabled,
                suggest: suggest,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CustomFestivalsTable, CustomFestival>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CustomFestivalsTable,
                    CustomFestival
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomFestivalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomFestivalsTable,
      CustomFestival,
      $$CustomFestivalsTableFilterComposer,
      $$CustomFestivalsTableOrderingComposer,
      $$CustomFestivalsTableAnnotationComposer,
      $$CustomFestivalsTableCreateCompanionBuilder,
      $$CustomFestivalsTableUpdateCompanionBuilder,
      (
        CustomFestival,
        BaseReferences<_$AppDatabase, $CustomFestivalsTable, CustomFestival>,
      ),
      CustomFestival,
      PrefetchHooks Function()
    >;
typedef $$WishSessionsTableCreateCompanionBuilder =
    WishSessionsCompanion Function({
      Value<int> id,
      required String title,
      Value<String?> festivalId,
      required String occasionDate,
      Value<bool> finished,
      Value<DateTime> createdAt,
    });
typedef $$WishSessionsTableUpdateCompanionBuilder =
    WishSessionsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String?> festivalId,
      Value<String> occasionDate,
      Value<bool> finished,
      Value<DateTime> createdAt,
    });

final class $$WishSessionsTableReferences
    extends BaseReferences<_$AppDatabase, $WishSessionsTable, WishSession> {
  $$WishSessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WishSessionItemsTable, List<WishSessionItem>>
  _wishSessionItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.wishSessionItems,
    aliasName: 'wish_sessions__id__wish_session_items__session_id',
  );

  $$WishSessionItemsTableProcessedTableManager get wishSessionItemsRefs {
    final manager = $$WishSessionItemsTableTableManager(
      $_db,
      $_db.wishSessionItems,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _wishSessionItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WishSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $WishSessionsTable> {
  $$WishSessionsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get festivalId => $composableBuilder(
    column: $table.festivalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occasionDate => $composableBuilder(
    column: $table.occasionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get finished => $composableBuilder(
    column: $table.finished,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> wishSessionItemsRefs(
    Expression<bool> Function($$WishSessionItemsTableFilterComposer f) f,
  ) {
    final $$WishSessionItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wishSessionItems,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WishSessionItemsTableFilterComposer(
            $db: $db,
            $table: $db.wishSessionItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WishSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $WishSessionsTable> {
  $$WishSessionsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get festivalId => $composableBuilder(
    column: $table.festivalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occasionDate => $composableBuilder(
    column: $table.occasionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get finished => $composableBuilder(
    column: $table.finished,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WishSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WishSessionsTable> {
  $$WishSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get festivalId => $composableBuilder(
    column: $table.festivalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get occasionDate => $composableBuilder(
    column: $table.occasionDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get finished =>
      $composableBuilder(column: $table.finished, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> wishSessionItemsRefs<T extends Object>(
    Expression<T> Function($$WishSessionItemsTableAnnotationComposer a) f,
  ) {
    final $$WishSessionItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wishSessionItems,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WishSessionItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.wishSessionItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WishSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WishSessionsTable,
          WishSession,
          $$WishSessionsTableFilterComposer,
          $$WishSessionsTableOrderingComposer,
          $$WishSessionsTableAnnotationComposer,
          $$WishSessionsTableCreateCompanionBuilder,
          $$WishSessionsTableUpdateCompanionBuilder,
          (WishSession, $$WishSessionsTableReferences),
          WishSession,
          PrefetchHooks Function({bool wishSessionItemsRefs})
        > {
  $$WishSessionsTableTableManager(_$AppDatabase db, $WishSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WishSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WishSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WishSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> festivalId = const Value.absent(),
                Value<String> occasionDate = const Value.absent(),
                Value<bool> finished = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => WishSessionsCompanion(
                id: id,
                title: title,
                festivalId: festivalId,
                occasionDate: occasionDate,
                finished: finished,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> festivalId = const Value.absent(),
                required String occasionDate,
                Value<bool> finished = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => WishSessionsCompanion.insert(
                id: id,
                title: title,
                festivalId: festivalId,
                occasionDate: occasionDate,
                finished: finished,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WishSessionsTable, WishSession>(table),
                  $$WishSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wishSessionItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (wishSessionItemsRefs) db.wishSessionItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (wishSessionItemsRefs)
                    await $_getPrefetchedData<
                      WishSession,
                      $WishSessionsTable,
                      WishSessionItem
                    >(
                      currentTable: table,
                      referencedTable: $$WishSessionsTableReferences
                          ._wishSessionItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$WishSessionsTableReferences(
                            db,
                            table,
                            p0,
                          ).wishSessionItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WishSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WishSessionsTable,
      WishSession,
      $$WishSessionsTableFilterComposer,
      $$WishSessionsTableOrderingComposer,
      $$WishSessionsTableAnnotationComposer,
      $$WishSessionsTableCreateCompanionBuilder,
      $$WishSessionsTableUpdateCompanionBuilder,
      (WishSession, $$WishSessionsTableReferences),
      WishSession,
      PrefetchHooks Function({bool wishSessionItemsRefs})
    >;
typedef $$WishSessionItemsTableCreateCompanionBuilder =
    WishSessionItemsCompanion Function({
      Value<int> id,
      required int sessionId,
      required int personId,
      Value<int?> eventId,
      required int position,
      Value<String> status,
      Value<String?> message,
    });
typedef $$WishSessionItemsTableUpdateCompanionBuilder =
    WishSessionItemsCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<int> personId,
      Value<int?> eventId,
      Value<int> position,
      Value<String> status,
      Value<String?> message,
    });

final class $$WishSessionItemsTableReferences
    extends
        BaseReferences<_$AppDatabase, $WishSessionItemsTable, WishSessionItem> {
  $$WishSessionItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WishSessionsTable _sessionIdTable(_$AppDatabase db) => db.wishSessions
      .createAlias('wish_session_items__session_id__wish_sessions__id');

  $$WishSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$WishSessionsTableTableManager(
      $_db,
      $_db.wishSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PeopleTable _personIdTable(_$AppDatabase db) =>
      db.people.createAlias('wish_session_items__person_id__people__id');

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

class $$WishSessionItemsTableFilterComposer
    extends Composer<_$AppDatabase, $WishSessionItemsTable> {
  $$WishSessionItemsTableFilterComposer({
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

  ColumnFilters<int> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  $$WishSessionsTableFilterComposer get sessionId {
    final $$WishSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.wishSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WishSessionsTableFilterComposer(
            $db: $db,
            $table: $db.wishSessions,
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

class $$WishSessionItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $WishSessionItemsTable> {
  $$WishSessionItemsTableOrderingComposer({
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

  ColumnOrderings<int> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  $$WishSessionsTableOrderingComposer get sessionId {
    final $$WishSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.wishSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WishSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.wishSessions,
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

class $$WishSessionItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WishSessionItemsTable> {
  $$WishSessionItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  $$WishSessionsTableAnnotationComposer get sessionId {
    final $$WishSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.wishSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WishSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.wishSessions,
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

class $$WishSessionItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WishSessionItemsTable,
          WishSessionItem,
          $$WishSessionItemsTableFilterComposer,
          $$WishSessionItemsTableOrderingComposer,
          $$WishSessionItemsTableAnnotationComposer,
          $$WishSessionItemsTableCreateCompanionBuilder,
          $$WishSessionItemsTableUpdateCompanionBuilder,
          (WishSessionItem, $$WishSessionItemsTableReferences),
          WishSessionItem,
          PrefetchHooks Function({bool sessionId, bool personId})
        > {
  $$WishSessionItemsTableTableManager(
    _$AppDatabase db,
    $WishSessionItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WishSessionItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WishSessionItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WishSessionItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<int> personId = const Value.absent(),
                Value<int?> eventId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> message = const Value.absent(),
              }) => WishSessionItemsCompanion(
                id: id,
                sessionId: sessionId,
                personId: personId,
                eventId: eventId,
                position: position,
                status: status,
                message: message,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required int personId,
                Value<int?> eventId = const Value.absent(),
                required int position,
                Value<String> status = const Value.absent(),
                Value<String?> message = const Value.absent(),
              }) => WishSessionItemsCompanion.insert(
                id: id,
                sessionId: sessionId,
                personId: personId,
                eventId: eventId,
                position: position,
                status: status,
                message: message,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WishSessionItemsTable, WishSessionItem>(table),
                  $$WishSessionItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false, personId = false}) {
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
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$WishSessionItemsTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$WishSessionItemsTableReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (personId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.personId,
                        referencedTable: $$WishSessionItemsTableReferences
                            ._personIdTable(db),
                        referencedColumn: $$WishSessionItemsTableReferences
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

typedef $$WishSessionItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WishSessionItemsTable,
      WishSessionItem,
      $$WishSessionItemsTableFilterComposer,
      $$WishSessionItemsTableOrderingComposer,
      $$WishSessionItemsTableAnnotationComposer,
      $$WishSessionItemsTableCreateCompanionBuilder,
      $$WishSessionItemsTableUpdateCompanionBuilder,
      (WishSessionItem, $$WishSessionItemsTableReferences),
      WishSessionItem,
      PrefetchHooks Function({bool sessionId, bool personId})
    >;
typedef $$PhotoMemoriesTableCreateCompanionBuilder =
    PhotoMemoriesCompanion Function({
      Value<int> id,
      required int personId,
      required int year,
      required String path,
      Value<String?> caption,
      Value<DateTime> createdAt,
    });
typedef $$PhotoMemoriesTableUpdateCompanionBuilder =
    PhotoMemoriesCompanion Function({
      Value<int> id,
      Value<int> personId,
      Value<int> year,
      Value<String> path,
      Value<String?> caption,
      Value<DateTime> createdAt,
    });

final class $$PhotoMemoriesTableReferences
    extends BaseReferences<_$AppDatabase, $PhotoMemoriesTable, PhotoMemory> {
  $$PhotoMemoriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PeopleTable _personIdTable(_$AppDatabase db) =>
      db.people.createAlias('photo_memories__person_id__people__id');

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

class $$PhotoMemoriesTableFilterComposer
    extends Composer<_$AppDatabase, $PhotoMemoriesTable> {
  $$PhotoMemoriesTableFilterComposer({
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

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caption => $composableBuilder(
    column: $table.caption,
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

class $$PhotoMemoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PhotoMemoriesTable> {
  $$PhotoMemoriesTableOrderingComposer({
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

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caption => $composableBuilder(
    column: $table.caption,
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

class $$PhotoMemoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhotoMemoriesTable> {
  $$PhotoMemoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

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

class $$PhotoMemoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PhotoMemoriesTable,
          PhotoMemory,
          $$PhotoMemoriesTableFilterComposer,
          $$PhotoMemoriesTableOrderingComposer,
          $$PhotoMemoriesTableAnnotationComposer,
          $$PhotoMemoriesTableCreateCompanionBuilder,
          $$PhotoMemoriesTableUpdateCompanionBuilder,
          (PhotoMemory, $$PhotoMemoriesTableReferences),
          PhotoMemory,
          PrefetchHooks Function({bool personId})
        > {
  $$PhotoMemoriesTableTableManager(_$AppDatabase db, $PhotoMemoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhotoMemoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhotoMemoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhotoMemoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> personId = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String?> caption = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PhotoMemoriesCompanion(
                id: id,
                personId: personId,
                year: year,
                path: path,
                caption: caption,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int personId,
                required int year,
                required String path,
                Value<String?> caption = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PhotoMemoriesCompanion.insert(
                id: id,
                personId: personId,
                year: year,
                path: path,
                caption: caption,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PhotoMemoriesTable, PhotoMemory>(table),
                  $$PhotoMemoriesTableReferences(db, table, e),
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
                        referencedTable: $$PhotoMemoriesTableReferences
                            ._personIdTable(db),
                        referencedColumn: $$PhotoMemoriesTableReferences
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

typedef $$PhotoMemoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PhotoMemoriesTable,
      PhotoMemory,
      $$PhotoMemoriesTableFilterComposer,
      $$PhotoMemoriesTableOrderingComposer,
      $$PhotoMemoriesTableAnnotationComposer,
      $$PhotoMemoriesTableCreateCompanionBuilder,
      $$PhotoMemoriesTableUpdateCompanionBuilder,
      (PhotoMemory, $$PhotoMemoriesTableReferences),
      PhotoMemory,
      PrefetchHooks Function({bool personId})
    >;
typedef $$GroupsTableCreateCompanionBuilder = GroupsCompanion Function({
  Value<int> id,
  required String name,
  Value<int> color,
  Value<DateTime> createdAt,
});
typedef $$GroupsTableUpdateCompanionBuilder = GroupsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> color,
  Value<DateTime> createdAt,
});

final class $$GroupsTableReferences
    extends BaseReferences<_$AppDatabase, $GroupsTable, PersonGroup> {
  $$GroupsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GroupMembersTable, List<GroupMember>>
  _groupMembersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.groupMembers,
    aliasName: 'groups__id__group_members__group_id',
  );

  $$GroupMembersTableProcessedTableManager get groupMembersRefs {
    final manager = $$GroupMembersTableTableManager(
      $_db,
      $_db.groupMembers,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_groupMembersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GroupsTableFilterComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableFilterComposer({
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

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> groupMembersRefs(
    Expression<bool> Function($$GroupMembersTableFilterComposer f) f,
  ) {
    final $$GroupMembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.groupMembers,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupMembersTableFilterComposer(
            $db: $db,
            $table: $db.groupMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableOrderingComposer({
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

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableAnnotationComposer({
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

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> groupMembersRefs<T extends Object>(
    Expression<T> Function($$GroupMembersTableAnnotationComposer a) f,
  ) {
    final $$GroupMembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.groupMembers,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupMembersTableAnnotationComposer(
            $db: $db,
            $table: $db.groupMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupsTable,
          PersonGroup,
          $$GroupsTableFilterComposer,
          $$GroupsTableOrderingComposer,
          $$GroupsTableAnnotationComposer,
          $$GroupsTableCreateCompanionBuilder,
          $$GroupsTableUpdateCompanionBuilder,
          (PersonGroup, $$GroupsTableReferences),
          PersonGroup,
          PrefetchHooks Function({bool groupMembersRefs})
        > {
  $$GroupsTableTableManager(_$AppDatabase db, $GroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => GroupsCompanion(
                id: id,
                name: name,
                color: color,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int> color = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => GroupsCompanion.insert(
                id: id,
                name: name,
                color: color,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GroupsTable, PersonGroup>(table),
                  $$GroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({groupMembersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (groupMembersRefs) db.groupMembers],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (groupMembersRefs)
                    await $_getPrefetchedData<
                      PersonGroup,
                      $GroupsTable,
                      GroupMember
                    >(
                      currentTable: table,
                      referencedTable: $$GroupsTableReferences
                          ._groupMembersRefsTable(db),
                      managerFromTypedResult: (p0) => $$GroupsTableReferences(
                        db,
                        table,
                        p0,
                      ).groupMembersRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.groupId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$GroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupsTable,
      PersonGroup,
      $$GroupsTableFilterComposer,
      $$GroupsTableOrderingComposer,
      $$GroupsTableAnnotationComposer,
      $$GroupsTableCreateCompanionBuilder,
      $$GroupsTableUpdateCompanionBuilder,
      (PersonGroup, $$GroupsTableReferences),
      PersonGroup,
      PrefetchHooks Function({bool groupMembersRefs})
    >;
typedef $$GroupMembersTableCreateCompanionBuilder =
    GroupMembersCompanion Function({
      required int groupId,
      required int personId,
      Value<int> rowid,
    });
typedef $$GroupMembersTableUpdateCompanionBuilder =
    GroupMembersCompanion Function({
      Value<int> groupId,
      Value<int> personId,
      Value<int> rowid,
    });

final class $$GroupMembersTableReferences
    extends BaseReferences<_$AppDatabase, $GroupMembersTable, GroupMember> {
  $$GroupMembersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GroupsTable _groupIdTable(_$AppDatabase db) =>
      db.groups.createAlias('group_members__group_id__groups__id');

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<int>('group_id')!;

    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PeopleTable _personIdTable(_$AppDatabase db) =>
      db.people.createAlias('group_members__person_id__people__id');

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

class $$GroupMembersTableFilterComposer
    extends Composer<_$AppDatabase, $GroupMembersTable> {
  $$GroupMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
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

class $$GroupMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupMembersTable> {
  $$GroupMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
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

class $$GroupMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupMembersTable> {
  $$GroupMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
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

class $$GroupMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupMembersTable,
          GroupMember,
          $$GroupMembersTableFilterComposer,
          $$GroupMembersTableOrderingComposer,
          $$GroupMembersTableAnnotationComposer,
          $$GroupMembersTableCreateCompanionBuilder,
          $$GroupMembersTableUpdateCompanionBuilder,
          (GroupMember, $$GroupMembersTableReferences),
          GroupMember,
          PrefetchHooks Function({bool groupId, bool personId})
        > {
  $$GroupMembersTableTableManager(_$AppDatabase db, $GroupMembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> groupId = const Value.absent(),
                Value<int> personId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupMembersCompanion(
                groupId: groupId,
                personId: personId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int groupId,
                required int personId,
                Value<int> rowid = const Value.absent(),
              }) => GroupMembersCompanion.insert(
                groupId: groupId,
                personId: personId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GroupMembersTable, GroupMember>(table),
                  $$GroupMembersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({groupId = false, personId = false}) {
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
                    if (groupId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.groupId,
                        referencedTable: $$GroupMembersTableReferences
                            ._groupIdTable(db),
                        referencedColumn: $$GroupMembersTableReferences
                            ._groupIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (personId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.personId,
                        referencedTable: $$GroupMembersTableReferences
                            ._personIdTable(db),
                        referencedColumn: $$GroupMembersTableReferences
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

typedef $$GroupMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupMembersTable,
      GroupMember,
      $$GroupMembersTableFilterComposer,
      $$GroupMembersTableOrderingComposer,
      $$GroupMembersTableAnnotationComposer,
      $$GroupMembersTableCreateCompanionBuilder,
      $$GroupMembersTableUpdateCompanionBuilder,
      (GroupMember, $$GroupMembersTableReferences),
      GroupMember,
      PrefetchHooks Function({bool groupId, bool personId})
    >;
typedef $$FamilyLinksTableCreateCompanionBuilder =
    FamilyLinksCompanion Function({
      Value<int> id,
      required int personId,
      required int relativeId,
      required String relation,
    });
typedef $$FamilyLinksTableUpdateCompanionBuilder =
    FamilyLinksCompanion Function({
      Value<int> id,
      Value<int> personId,
      Value<int> relativeId,
      Value<String> relation,
    });

final class $$FamilyLinksTableReferences
    extends BaseReferences<_$AppDatabase, $FamilyLinksTable, FamilyLink> {
  $$FamilyLinksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PeopleTable _personIdTable(_$AppDatabase db) =>
      db.people.createAlias('family_links__person_id__people__id');

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

  static $PeopleTable _relativeIdTable(_$AppDatabase db) =>
      db.people.createAlias('family_links__relative_id__people__id');

  $$PeopleTableProcessedTableManager get relativeId {
    final $_column = $_itemColumn<int>('relative_id')!;

    final manager = $$PeopleTableTableManager(
      $_db,
      $_db.people,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_relativeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FamilyLinksTableFilterComposer
    extends Composer<_$AppDatabase, $FamilyLinksTable> {
  $$FamilyLinksTableFilterComposer({
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

  ColumnFilters<String> get relation => $composableBuilder(
    column: $table.relation,
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

  $$PeopleTableFilterComposer get relativeId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.relativeId,
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

class $$FamilyLinksTableOrderingComposer
    extends Composer<_$AppDatabase, $FamilyLinksTable> {
  $$FamilyLinksTableOrderingComposer({
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

  ColumnOrderings<String> get relation => $composableBuilder(
    column: $table.relation,
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

  $$PeopleTableOrderingComposer get relativeId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.relativeId,
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

class $$FamilyLinksTableAnnotationComposer
    extends Composer<_$AppDatabase, $FamilyLinksTable> {
  $$FamilyLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get relation =>
      $composableBuilder(column: $table.relation, builder: (column) => column);

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

  $$PeopleTableAnnotationComposer get relativeId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.relativeId,
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

class $$FamilyLinksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FamilyLinksTable,
          FamilyLink,
          $$FamilyLinksTableFilterComposer,
          $$FamilyLinksTableOrderingComposer,
          $$FamilyLinksTableAnnotationComposer,
          $$FamilyLinksTableCreateCompanionBuilder,
          $$FamilyLinksTableUpdateCompanionBuilder,
          (FamilyLink, $$FamilyLinksTableReferences),
          FamilyLink,
          PrefetchHooks Function({bool personId, bool relativeId})
        > {
  $$FamilyLinksTableTableManager(_$AppDatabase db, $FamilyLinksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FamilyLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FamilyLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FamilyLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> personId = const Value.absent(),
                Value<int> relativeId = const Value.absent(),
                Value<String> relation = const Value.absent(),
              }) => FamilyLinksCompanion(
                id: id,
                personId: personId,
                relativeId: relativeId,
                relation: relation,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int personId,
                required int relativeId,
                required String relation,
              }) => FamilyLinksCompanion.insert(
                id: id,
                personId: personId,
                relativeId: relativeId,
                relation: relation,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FamilyLinksTable, FamilyLink>(table),
                  $$FamilyLinksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personId = false, relativeId = false}) {
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
                        referencedTable: $$FamilyLinksTableReferences
                            ._personIdTable(db),
                        referencedColumn: $$FamilyLinksTableReferences
                            ._personIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (relativeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.relativeId,
                        referencedTable: $$FamilyLinksTableReferences
                            ._relativeIdTable(db),
                        referencedColumn: $$FamilyLinksTableReferences
                            ._relativeIdTable(db)
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

typedef $$FamilyLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FamilyLinksTable,
      FamilyLink,
      $$FamilyLinksTableFilterComposer,
      $$FamilyLinksTableOrderingComposer,
      $$FamilyLinksTableAnnotationComposer,
      $$FamilyLinksTableCreateCompanionBuilder,
      $$FamilyLinksTableUpdateCompanionBuilder,
      (FamilyLink, $$FamilyLinksTableReferences),
      FamilyLink,
      PrefetchHooks Function({bool personId, bool relativeId})
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
  $$WishLogsTableTableManager get wishLogs =>
      $$WishLogsTableTableManager(_db, _db.wishLogs);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$UserMessagesTableTableManager get userMessages =>
      $$UserMessagesTableTableManager(_db, _db.userMessages);
  $$FavouriteMessagesTableTableManager get favouriteMessages =>
      $$FavouriteMessagesTableTableManager(_db, _db.favouriteMessages);
  $$FestivalOverridesTableTableManager get festivalOverrides =>
      $$FestivalOverridesTableTableManager(_db, _db.festivalOverrides);
  $$CustomFestivalsTableTableManager get customFestivals =>
      $$CustomFestivalsTableTableManager(_db, _db.customFestivals);
  $$WishSessionsTableTableManager get wishSessions =>
      $$WishSessionsTableTableManager(_db, _db.wishSessions);
  $$WishSessionItemsTableTableManager get wishSessionItems =>
      $$WishSessionItemsTableTableManager(_db, _db.wishSessionItems);
  $$PhotoMemoriesTableTableManager get photoMemories =>
      $$PhotoMemoriesTableTableManager(_db, _db.photoMemories);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db, _db.groups);
  $$GroupMembersTableTableManager get groupMembers =>
      $$GroupMembersTableTableManager(_db, _db.groupMembers);
  $$FamilyLinksTableTableManager get familyLinks =>
      $$FamilyLinksTableTableManager(_db, _db.familyLinks);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
