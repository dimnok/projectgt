// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'company_document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CompanyDocument {
  String get id;
  @JsonKey(name: 'company_id')
  String get companyId;
  String get type;
  String get title;
  String? get number;
  @JsonKey(name: 'issue_date')
  DateTime? get issueDate;
  @JsonKey(name: 'expiry_date')
  DateTime? get expiryDate;
  @JsonKey(name: 'file_url')
  String? get fileUrl;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of CompanyDocument
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CompanyDocumentCopyWith<CompanyDocument> get copyWith =>
      _$CompanyDocumentCopyWithImpl<CompanyDocument>(
          this as CompanyDocument, _$identity);

  /// Serializes this CompanyDocument to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CompanyDocument &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.companyId, companyId) ||
                other.companyId == companyId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.issueDate, issueDate) ||
                other.issueDate == issueDate) &&
            (identical(other.expiryDate, expiryDate) ||
                other.expiryDate == expiryDate) &&
            (identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, companyId, type, title,
      number, issueDate, expiryDate, fileUrl, createdAt);

  @override
  String toString() {
    return 'CompanyDocument(id: $id, companyId: $companyId, type: $type, title: $title, number: $number, issueDate: $issueDate, expiryDate: $expiryDate, fileUrl: $fileUrl, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class $CompanyDocumentCopyWith<$Res> {
  factory $CompanyDocumentCopyWith(
          CompanyDocument value, $Res Function(CompanyDocument) _then) =
      _$CompanyDocumentCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'company_id') String companyId,
      String type,
      String title,
      String? number,
      @JsonKey(name: 'issue_date') DateTime? issueDate,
      @JsonKey(name: 'expiry_date') DateTime? expiryDate,
      @JsonKey(name: 'file_url') String? fileUrl,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class _$CompanyDocumentCopyWithImpl<$Res>
    implements $CompanyDocumentCopyWith<$Res> {
  _$CompanyDocumentCopyWithImpl(this._self, this._then);

  final CompanyDocument _self;
  final $Res Function(CompanyDocument) _then;

  /// Create a copy of CompanyDocument
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? companyId = null,
    Object? type = null,
    Object? title = null,
    Object? number = freezed,
    Object? issueDate = freezed,
    Object? expiryDate = freezed,
    Object? fileUrl = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      companyId: null == companyId
          ? _self.companyId
          : companyId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      number: freezed == number
          ? _self.number
          : number // ignore: cast_nullable_to_non_nullable
              as String?,
      issueDate: freezed == issueDate
          ? _self.issueDate
          : issueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      expiryDate: freezed == expiryDate
          ? _self.expiryDate
          : expiryDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      fileUrl: freezed == fileUrl
          ? _self.fileUrl
          : fileUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _CompanyDocument implements CompanyDocument {
  const _CompanyDocument(
      {required this.id,
      @JsonKey(name: 'company_id') required this.companyId,
      required this.type,
      required this.title,
      this.number,
      @JsonKey(name: 'issue_date') this.issueDate,
      @JsonKey(name: 'expiry_date') this.expiryDate,
      @JsonKey(name: 'file_url') this.fileUrl,
      @JsonKey(name: 'created_at') this.createdAt});
  factory _CompanyDocument.fromJson(Map<String, dynamic> json) =>
      _$CompanyDocumentFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'company_id')
  final String companyId;
  @override
  final String type;
  @override
  final String title;
  @override
  final String? number;
  @override
  @JsonKey(name: 'issue_date')
  final DateTime? issueDate;
  @override
  @JsonKey(name: 'expiry_date')
  final DateTime? expiryDate;
  @override
  @JsonKey(name: 'file_url')
  final String? fileUrl;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  /// Create a copy of CompanyDocument
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CompanyDocumentCopyWith<_CompanyDocument> get copyWith =>
      __$CompanyDocumentCopyWithImpl<_CompanyDocument>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CompanyDocumentToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CompanyDocument &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.companyId, companyId) ||
                other.companyId == companyId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.issueDate, issueDate) ||
                other.issueDate == issueDate) &&
            (identical(other.expiryDate, expiryDate) ||
                other.expiryDate == expiryDate) &&
            (identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, companyId, type, title,
      number, issueDate, expiryDate, fileUrl, createdAt);

  @override
  String toString() {
    return 'CompanyDocument(id: $id, companyId: $companyId, type: $type, title: $title, number: $number, issueDate: $issueDate, expiryDate: $expiryDate, fileUrl: $fileUrl, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$CompanyDocumentCopyWith<$Res>
    implements $CompanyDocumentCopyWith<$Res> {
  factory _$CompanyDocumentCopyWith(
          _CompanyDocument value, $Res Function(_CompanyDocument) _then) =
      __$CompanyDocumentCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'company_id') String companyId,
      String type,
      String title,
      String? number,
      @JsonKey(name: 'issue_date') DateTime? issueDate,
      @JsonKey(name: 'expiry_date') DateTime? expiryDate,
      @JsonKey(name: 'file_url') String? fileUrl,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class __$CompanyDocumentCopyWithImpl<$Res>
    implements _$CompanyDocumentCopyWith<$Res> {
  __$CompanyDocumentCopyWithImpl(this._self, this._then);

  final _CompanyDocument _self;
  final $Res Function(_CompanyDocument) _then;

  /// Create a copy of CompanyDocument
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? companyId = null,
    Object? type = null,
    Object? title = null,
    Object? number = freezed,
    Object? issueDate = freezed,
    Object? expiryDate = freezed,
    Object? fileUrl = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_CompanyDocument(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      companyId: null == companyId
          ? _self.companyId
          : companyId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      number: freezed == number
          ? _self.number
          : number // ignore: cast_nullable_to_non_nullable
              as String?,
      issueDate: freezed == issueDate
          ? _self.issueDate
          : issueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      expiryDate: freezed == expiryDate
          ? _self.expiryDate
          : expiryDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      fileUrl: freezed == fileUrl
          ? _self.fileUrl
          : fileUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
