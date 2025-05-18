// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contractor_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ContractorModel {
  String get id;
  @JsonKey(name: 'logo_url')
  String? get logoUrl;
  @JsonKey(name: 'full_name')
  String get fullName;
  @JsonKey(name: 'short_name')
  String get shortName;
  String get inn;
  String get director;
  @JsonKey(name: 'legal_address')
  String get legalAddress;
  @JsonKey(name: 'actual_address')
  String get actualAddress;
  String get phone;
  String get email;
  ContractorType get type;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of ContractorModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ContractorModelCopyWith<ContractorModel> get copyWith =>
      _$ContractorModelCopyWithImpl<ContractorModel>(
          this as ContractorModel, _$identity);

  /// Serializes this ContractorModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ContractorModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.shortName, shortName) ||
                other.shortName == shortName) &&
            (identical(other.inn, inn) || other.inn == inn) &&
            (identical(other.director, director) ||
                other.director == director) &&
            (identical(other.legalAddress, legalAddress) ||
                other.legalAddress == legalAddress) &&
            (identical(other.actualAddress, actualAddress) ||
                other.actualAddress == actualAddress) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      logoUrl,
      fullName,
      shortName,
      inn,
      director,
      legalAddress,
      actualAddress,
      phone,
      email,
      type,
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'ContractorModel(id: $id, logoUrl: $logoUrl, fullName: $fullName, shortName: $shortName, inn: $inn, director: $director, legalAddress: $legalAddress, actualAddress: $actualAddress, phone: $phone, email: $email, type: $type, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $ContractorModelCopyWith<$Res> {
  factory $ContractorModelCopyWith(
          ContractorModel value, $Res Function(ContractorModel) _then) =
      _$ContractorModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'logo_url') String? logoUrl,
      @JsonKey(name: 'full_name') String fullName,
      @JsonKey(name: 'short_name') String shortName,
      String inn,
      String director,
      @JsonKey(name: 'legal_address') String legalAddress,
      @JsonKey(name: 'actual_address') String actualAddress,
      String phone,
      String email,
      ContractorType type,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$ContractorModelCopyWithImpl<$Res>
    implements $ContractorModelCopyWith<$Res> {
  _$ContractorModelCopyWithImpl(this._self, this._then);

  final ContractorModel _self;
  final $Res Function(ContractorModel) _then;

  /// Create a copy of ContractorModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? logoUrl = freezed,
    Object? fullName = null,
    Object? shortName = null,
    Object? inn = null,
    Object? director = null,
    Object? legalAddress = null,
    Object? actualAddress = null,
    Object? phone = null,
    Object? email = null,
    Object? type = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      logoUrl: freezed == logoUrl
          ? _self.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      fullName: null == fullName
          ? _self.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      shortName: null == shortName
          ? _self.shortName
          : shortName // ignore: cast_nullable_to_non_nullable
              as String,
      inn: null == inn
          ? _self.inn
          : inn // ignore: cast_nullable_to_non_nullable
              as String,
      director: null == director
          ? _self.director
          : director // ignore: cast_nullable_to_non_nullable
              as String,
      legalAddress: null == legalAddress
          ? _self.legalAddress
          : legalAddress // ignore: cast_nullable_to_non_nullable
              as String,
      actualAddress: null == actualAddress
          ? _self.actualAddress
          : actualAddress // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _self.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as ContractorType,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class _ContractorModel extends ContractorModel {
  const _ContractorModel(
      {required this.id,
      @JsonKey(name: 'logo_url') this.logoUrl,
      @JsonKey(name: 'full_name') required this.fullName,
      @JsonKey(name: 'short_name') required this.shortName,
      required this.inn,
      required this.director,
      @JsonKey(name: 'legal_address') required this.legalAddress,
      @JsonKey(name: 'actual_address') required this.actualAddress,
      required this.phone,
      required this.email,
      required this.type,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt})
      : super._();
  factory _ContractorModel.fromJson(Map<String, dynamic> json) =>
      _$ContractorModelFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'logo_url')
  final String? logoUrl;
  @override
  @JsonKey(name: 'full_name')
  final String fullName;
  @override
  @JsonKey(name: 'short_name')
  final String shortName;
  @override
  final String inn;
  @override
  final String director;
  @override
  @JsonKey(name: 'legal_address')
  final String legalAddress;
  @override
  @JsonKey(name: 'actual_address')
  final String actualAddress;
  @override
  final String phone;
  @override
  final String email;
  @override
  final ContractorType type;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  /// Create a copy of ContractorModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ContractorModelCopyWith<_ContractorModel> get copyWith =>
      __$ContractorModelCopyWithImpl<_ContractorModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ContractorModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ContractorModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.shortName, shortName) ||
                other.shortName == shortName) &&
            (identical(other.inn, inn) || other.inn == inn) &&
            (identical(other.director, director) ||
                other.director == director) &&
            (identical(other.legalAddress, legalAddress) ||
                other.legalAddress == legalAddress) &&
            (identical(other.actualAddress, actualAddress) ||
                other.actualAddress == actualAddress) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      logoUrl,
      fullName,
      shortName,
      inn,
      director,
      legalAddress,
      actualAddress,
      phone,
      email,
      type,
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'ContractorModel(id: $id, logoUrl: $logoUrl, fullName: $fullName, shortName: $shortName, inn: $inn, director: $director, legalAddress: $legalAddress, actualAddress: $actualAddress, phone: $phone, email: $email, type: $type, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$ContractorModelCopyWith<$Res>
    implements $ContractorModelCopyWith<$Res> {
  factory _$ContractorModelCopyWith(
          _ContractorModel value, $Res Function(_ContractorModel) _then) =
      __$ContractorModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'logo_url') String? logoUrl,
      @JsonKey(name: 'full_name') String fullName,
      @JsonKey(name: 'short_name') String shortName,
      String inn,
      String director,
      @JsonKey(name: 'legal_address') String legalAddress,
      @JsonKey(name: 'actual_address') String actualAddress,
      String phone,
      String email,
      ContractorType type,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class __$ContractorModelCopyWithImpl<$Res>
    implements _$ContractorModelCopyWith<$Res> {
  __$ContractorModelCopyWithImpl(this._self, this._then);

  final _ContractorModel _self;
  final $Res Function(_ContractorModel) _then;

  /// Create a copy of ContractorModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? logoUrl = freezed,
    Object? fullName = null,
    Object? shortName = null,
    Object? inn = null,
    Object? director = null,
    Object? legalAddress = null,
    Object? actualAddress = null,
    Object? phone = null,
    Object? email = null,
    Object? type = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_ContractorModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      logoUrl: freezed == logoUrl
          ? _self.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      fullName: null == fullName
          ? _self.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      shortName: null == shortName
          ? _self.shortName
          : shortName // ignore: cast_nullable_to_non_nullable
              as String,
      inn: null == inn
          ? _self.inn
          : inn // ignore: cast_nullable_to_non_nullable
              as String,
      director: null == director
          ? _self.director
          : director // ignore: cast_nullable_to_non_nullable
              as String,
      legalAddress: null == legalAddress
          ? _self.legalAddress
          : legalAddress // ignore: cast_nullable_to_non_nullable
              as String,
      actualAddress: null == actualAddress
          ? _self.actualAddress
          : actualAddress // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _self.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as ContractorType,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
