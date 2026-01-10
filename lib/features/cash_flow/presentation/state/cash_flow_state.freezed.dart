// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cash_flow_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CashFlowState {

/// Текущий статус состояния.
 CashFlowStatus get status;/// Текущий вид отображения.
 CashFlowView get currentView;/// Список финансовых операций.
 List<CashFlowTransaction> get transactions;/// Список категорий ДДС.
 List<CashFlowCategory> get categories;/// Список шаблонов импорта банковских выписок.
 List<BankImportTemplate> get bankImportTemplates;/// Список записей из текущей загруженной выписки.
 List<BankStatementEntry> get bankStatementEntries;/// Данные аналитики по месяцам за весь год.
 List<MonthlyAnalytics> get yearlyAnalytics;/// Доступные ID для фильтрации ( Option B ).
 AvailableFilters get availableFilters;/// Сообщение об ошибке.
 String? get errorMessage;/// Поисковый запрос.
 String get searchQuery;/// Выбранный год для фильтрации.
 int get selectedYear;/// Выбранный объект для фильтрации.
 String? get selectedObjectId;/// Выбранный контрагент для фильтрации.
 String? get selectedContractorId;/// Выбранные договоры для фильтрации.
 List<String> get selectedContractIds;/// Выбранные типы операций (income/expense).
 List<String> get selectedOperationTypes;/// Выбранный банковский счет (для выписок).
 String? get selectedBankAccountId;/// Есть ли ещё данные для загрузки (пагинация).
 bool get hasMore;/// Загружаются ли сейчас дополнительные данные.
 bool get isLoadingMore;/// Отображать ли детальную аналитику по статьям.
 bool get isDetailedAnalytics;
/// Create a copy of CashFlowState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CashFlowStateCopyWith<CashFlowState> get copyWith => _$CashFlowStateCopyWithImpl<CashFlowState>(this as CashFlowState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CashFlowState&&(identical(other.status, status) || other.status == status)&&(identical(other.currentView, currentView) || other.currentView == currentView)&&const DeepCollectionEquality().equals(other.transactions, transactions)&&const DeepCollectionEquality().equals(other.categories, categories)&&const DeepCollectionEquality().equals(other.bankImportTemplates, bankImportTemplates)&&const DeepCollectionEquality().equals(other.bankStatementEntries, bankStatementEntries)&&const DeepCollectionEquality().equals(other.yearlyAnalytics, yearlyAnalytics)&&(identical(other.availableFilters, availableFilters) || other.availableFilters == availableFilters)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.selectedYear, selectedYear) || other.selectedYear == selectedYear)&&(identical(other.selectedObjectId, selectedObjectId) || other.selectedObjectId == selectedObjectId)&&(identical(other.selectedContractorId, selectedContractorId) || other.selectedContractorId == selectedContractorId)&&const DeepCollectionEquality().equals(other.selectedContractIds, selectedContractIds)&&const DeepCollectionEquality().equals(other.selectedOperationTypes, selectedOperationTypes)&&(identical(other.selectedBankAccountId, selectedBankAccountId) || other.selectedBankAccountId == selectedBankAccountId)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.isDetailedAnalytics, isDetailedAnalytics) || other.isDetailedAnalytics == isDetailedAnalytics));
}


@override
int get hashCode => Object.hashAll([runtimeType,status,currentView,const DeepCollectionEquality().hash(transactions),const DeepCollectionEquality().hash(categories),const DeepCollectionEquality().hash(bankImportTemplates),const DeepCollectionEquality().hash(bankStatementEntries),const DeepCollectionEquality().hash(yearlyAnalytics),availableFilters,errorMessage,searchQuery,selectedYear,selectedObjectId,selectedContractorId,const DeepCollectionEquality().hash(selectedContractIds),const DeepCollectionEquality().hash(selectedOperationTypes),selectedBankAccountId,hasMore,isLoadingMore,isDetailedAnalytics]);

@override
String toString() {
  return 'CashFlowState(status: $status, currentView: $currentView, transactions: $transactions, categories: $categories, bankImportTemplates: $bankImportTemplates, bankStatementEntries: $bankStatementEntries, yearlyAnalytics: $yearlyAnalytics, availableFilters: $availableFilters, errorMessage: $errorMessage, searchQuery: $searchQuery, selectedYear: $selectedYear, selectedObjectId: $selectedObjectId, selectedContractorId: $selectedContractorId, selectedContractIds: $selectedContractIds, selectedOperationTypes: $selectedOperationTypes, selectedBankAccountId: $selectedBankAccountId, hasMore: $hasMore, isLoadingMore: $isLoadingMore, isDetailedAnalytics: $isDetailedAnalytics)';
}


}

/// @nodoc
abstract mixin class $CashFlowStateCopyWith<$Res>  {
  factory $CashFlowStateCopyWith(CashFlowState value, $Res Function(CashFlowState) _then) = _$CashFlowStateCopyWithImpl;
@useResult
$Res call({
 CashFlowStatus status, CashFlowView currentView, List<CashFlowTransaction> transactions, List<CashFlowCategory> categories, List<BankImportTemplate> bankImportTemplates, List<BankStatementEntry> bankStatementEntries, List<MonthlyAnalytics> yearlyAnalytics, AvailableFilters availableFilters, String? errorMessage, String searchQuery, int selectedYear, String? selectedObjectId, String? selectedContractorId, List<String> selectedContractIds, List<String> selectedOperationTypes, String? selectedBankAccountId, bool hasMore, bool isLoadingMore, bool isDetailedAnalytics
});


$AvailableFiltersCopyWith<$Res> get availableFilters;

}
/// @nodoc
class _$CashFlowStateCopyWithImpl<$Res>
    implements $CashFlowStateCopyWith<$Res> {
  _$CashFlowStateCopyWithImpl(this._self, this._then);

  final CashFlowState _self;
  final $Res Function(CashFlowState) _then;

/// Create a copy of CashFlowState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? currentView = null,Object? transactions = null,Object? categories = null,Object? bankImportTemplates = null,Object? bankStatementEntries = null,Object? yearlyAnalytics = null,Object? availableFilters = null,Object? errorMessage = freezed,Object? searchQuery = null,Object? selectedYear = null,Object? selectedObjectId = freezed,Object? selectedContractorId = freezed,Object? selectedContractIds = null,Object? selectedOperationTypes = null,Object? selectedBankAccountId = freezed,Object? hasMore = null,Object? isLoadingMore = null,Object? isDetailedAnalytics = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CashFlowStatus,currentView: null == currentView ? _self.currentView : currentView // ignore: cast_nullable_to_non_nullable
as CashFlowView,transactions: null == transactions ? _self.transactions : transactions // ignore: cast_nullable_to_non_nullable
as List<CashFlowTransaction>,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<CashFlowCategory>,bankImportTemplates: null == bankImportTemplates ? _self.bankImportTemplates : bankImportTemplates // ignore: cast_nullable_to_non_nullable
as List<BankImportTemplate>,bankStatementEntries: null == bankStatementEntries ? _self.bankStatementEntries : bankStatementEntries // ignore: cast_nullable_to_non_nullable
as List<BankStatementEntry>,yearlyAnalytics: null == yearlyAnalytics ? _self.yearlyAnalytics : yearlyAnalytics // ignore: cast_nullable_to_non_nullable
as List<MonthlyAnalytics>,availableFilters: null == availableFilters ? _self.availableFilters : availableFilters // ignore: cast_nullable_to_non_nullable
as AvailableFilters,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,selectedYear: null == selectedYear ? _self.selectedYear : selectedYear // ignore: cast_nullable_to_non_nullable
as int,selectedObjectId: freezed == selectedObjectId ? _self.selectedObjectId : selectedObjectId // ignore: cast_nullable_to_non_nullable
as String?,selectedContractorId: freezed == selectedContractorId ? _self.selectedContractorId : selectedContractorId // ignore: cast_nullable_to_non_nullable
as String?,selectedContractIds: null == selectedContractIds ? _self.selectedContractIds : selectedContractIds // ignore: cast_nullable_to_non_nullable
as List<String>,selectedOperationTypes: null == selectedOperationTypes ? _self.selectedOperationTypes : selectedOperationTypes // ignore: cast_nullable_to_non_nullable
as List<String>,selectedBankAccountId: freezed == selectedBankAccountId ? _self.selectedBankAccountId : selectedBankAccountId // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,isDetailedAnalytics: null == isDetailedAnalytics ? _self.isDetailedAnalytics : isDetailedAnalytics // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of CashFlowState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AvailableFiltersCopyWith<$Res> get availableFilters {
  
  return $AvailableFiltersCopyWith<$Res>(_self.availableFilters, (value) {
    return _then(_self.copyWith(availableFilters: value));
  });
}
}


/// @nodoc


class _CashFlowState extends CashFlowState {
  const _CashFlowState({required this.status, this.currentView = CashFlowView.transactions, final  List<CashFlowTransaction> transactions = const [], final  List<CashFlowCategory> categories = const [], final  List<BankImportTemplate> bankImportTemplates = const [], final  List<BankStatementEntry> bankStatementEntries = const [], final  List<MonthlyAnalytics> yearlyAnalytics = const [], this.availableFilters = const AvailableFilters(), this.errorMessage, this.searchQuery = '', required this.selectedYear, this.selectedObjectId, this.selectedContractorId, final  List<String> selectedContractIds = const [], final  List<String> selectedOperationTypes = const [], this.selectedBankAccountId, this.hasMore = true, this.isLoadingMore = false, this.isDetailedAnalytics = false}): _transactions = transactions,_categories = categories,_bankImportTemplates = bankImportTemplates,_bankStatementEntries = bankStatementEntries,_yearlyAnalytics = yearlyAnalytics,_selectedContractIds = selectedContractIds,_selectedOperationTypes = selectedOperationTypes,super._();
  

/// Текущий статус состояния.
@override final  CashFlowStatus status;
/// Текущий вид отображения.
@override@JsonKey() final  CashFlowView currentView;
/// Список финансовых операций.
 final  List<CashFlowTransaction> _transactions;
/// Список финансовых операций.
@override@JsonKey() List<CashFlowTransaction> get transactions {
  if (_transactions is EqualUnmodifiableListView) return _transactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transactions);
}

/// Список категорий ДДС.
 final  List<CashFlowCategory> _categories;
/// Список категорий ДДС.
@override@JsonKey() List<CashFlowCategory> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

/// Список шаблонов импорта банковских выписок.
 final  List<BankImportTemplate> _bankImportTemplates;
/// Список шаблонов импорта банковских выписок.
@override@JsonKey() List<BankImportTemplate> get bankImportTemplates {
  if (_bankImportTemplates is EqualUnmodifiableListView) return _bankImportTemplates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bankImportTemplates);
}

/// Список записей из текущей загруженной выписки.
 final  List<BankStatementEntry> _bankStatementEntries;
/// Список записей из текущей загруженной выписки.
@override@JsonKey() List<BankStatementEntry> get bankStatementEntries {
  if (_bankStatementEntries is EqualUnmodifiableListView) return _bankStatementEntries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bankStatementEntries);
}

/// Данные аналитики по месяцам за весь год.
 final  List<MonthlyAnalytics> _yearlyAnalytics;
/// Данные аналитики по месяцам за весь год.
@override@JsonKey() List<MonthlyAnalytics> get yearlyAnalytics {
  if (_yearlyAnalytics is EqualUnmodifiableListView) return _yearlyAnalytics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_yearlyAnalytics);
}

/// Доступные ID для фильтрации ( Option B ).
@override@JsonKey() final  AvailableFilters availableFilters;
/// Сообщение об ошибке.
@override final  String? errorMessage;
/// Поисковый запрос.
@override@JsonKey() final  String searchQuery;
/// Выбранный год для фильтрации.
@override final  int selectedYear;
/// Выбранный объект для фильтрации.
@override final  String? selectedObjectId;
/// Выбранный контрагент для фильтрации.
@override final  String? selectedContractorId;
/// Выбранные договоры для фильтрации.
 final  List<String> _selectedContractIds;
/// Выбранные договоры для фильтрации.
@override@JsonKey() List<String> get selectedContractIds {
  if (_selectedContractIds is EqualUnmodifiableListView) return _selectedContractIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedContractIds);
}

/// Выбранные типы операций (income/expense).
 final  List<String> _selectedOperationTypes;
/// Выбранные типы операций (income/expense).
@override@JsonKey() List<String> get selectedOperationTypes {
  if (_selectedOperationTypes is EqualUnmodifiableListView) return _selectedOperationTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedOperationTypes);
}

/// Выбранный банковский счет (для выписок).
@override final  String? selectedBankAccountId;
/// Есть ли ещё данные для загрузки (пагинация).
@override@JsonKey() final  bool hasMore;
/// Загружаются ли сейчас дополнительные данные.
@override@JsonKey() final  bool isLoadingMore;
/// Отображать ли детальную аналитику по статьям.
@override@JsonKey() final  bool isDetailedAnalytics;

/// Create a copy of CashFlowState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CashFlowStateCopyWith<_CashFlowState> get copyWith => __$CashFlowStateCopyWithImpl<_CashFlowState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CashFlowState&&(identical(other.status, status) || other.status == status)&&(identical(other.currentView, currentView) || other.currentView == currentView)&&const DeepCollectionEquality().equals(other._transactions, _transactions)&&const DeepCollectionEquality().equals(other._categories, _categories)&&const DeepCollectionEquality().equals(other._bankImportTemplates, _bankImportTemplates)&&const DeepCollectionEquality().equals(other._bankStatementEntries, _bankStatementEntries)&&const DeepCollectionEquality().equals(other._yearlyAnalytics, _yearlyAnalytics)&&(identical(other.availableFilters, availableFilters) || other.availableFilters == availableFilters)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.selectedYear, selectedYear) || other.selectedYear == selectedYear)&&(identical(other.selectedObjectId, selectedObjectId) || other.selectedObjectId == selectedObjectId)&&(identical(other.selectedContractorId, selectedContractorId) || other.selectedContractorId == selectedContractorId)&&const DeepCollectionEquality().equals(other._selectedContractIds, _selectedContractIds)&&const DeepCollectionEquality().equals(other._selectedOperationTypes, _selectedOperationTypes)&&(identical(other.selectedBankAccountId, selectedBankAccountId) || other.selectedBankAccountId == selectedBankAccountId)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.isDetailedAnalytics, isDetailedAnalytics) || other.isDetailedAnalytics == isDetailedAnalytics));
}


@override
int get hashCode => Object.hashAll([runtimeType,status,currentView,const DeepCollectionEquality().hash(_transactions),const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_bankImportTemplates),const DeepCollectionEquality().hash(_bankStatementEntries),const DeepCollectionEquality().hash(_yearlyAnalytics),availableFilters,errorMessage,searchQuery,selectedYear,selectedObjectId,selectedContractorId,const DeepCollectionEquality().hash(_selectedContractIds),const DeepCollectionEquality().hash(_selectedOperationTypes),selectedBankAccountId,hasMore,isLoadingMore,isDetailedAnalytics]);

@override
String toString() {
  return 'CashFlowState(status: $status, currentView: $currentView, transactions: $transactions, categories: $categories, bankImportTemplates: $bankImportTemplates, bankStatementEntries: $bankStatementEntries, yearlyAnalytics: $yearlyAnalytics, availableFilters: $availableFilters, errorMessage: $errorMessage, searchQuery: $searchQuery, selectedYear: $selectedYear, selectedObjectId: $selectedObjectId, selectedContractorId: $selectedContractorId, selectedContractIds: $selectedContractIds, selectedOperationTypes: $selectedOperationTypes, selectedBankAccountId: $selectedBankAccountId, hasMore: $hasMore, isLoadingMore: $isLoadingMore, isDetailedAnalytics: $isDetailedAnalytics)';
}


}

/// @nodoc
abstract mixin class _$CashFlowStateCopyWith<$Res> implements $CashFlowStateCopyWith<$Res> {
  factory _$CashFlowStateCopyWith(_CashFlowState value, $Res Function(_CashFlowState) _then) = __$CashFlowStateCopyWithImpl;
@override @useResult
$Res call({
 CashFlowStatus status, CashFlowView currentView, List<CashFlowTransaction> transactions, List<CashFlowCategory> categories, List<BankImportTemplate> bankImportTemplates, List<BankStatementEntry> bankStatementEntries, List<MonthlyAnalytics> yearlyAnalytics, AvailableFilters availableFilters, String? errorMessage, String searchQuery, int selectedYear, String? selectedObjectId, String? selectedContractorId, List<String> selectedContractIds, List<String> selectedOperationTypes, String? selectedBankAccountId, bool hasMore, bool isLoadingMore, bool isDetailedAnalytics
});


@override $AvailableFiltersCopyWith<$Res> get availableFilters;

}
/// @nodoc
class __$CashFlowStateCopyWithImpl<$Res>
    implements _$CashFlowStateCopyWith<$Res> {
  __$CashFlowStateCopyWithImpl(this._self, this._then);

  final _CashFlowState _self;
  final $Res Function(_CashFlowState) _then;

/// Create a copy of CashFlowState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? currentView = null,Object? transactions = null,Object? categories = null,Object? bankImportTemplates = null,Object? bankStatementEntries = null,Object? yearlyAnalytics = null,Object? availableFilters = null,Object? errorMessage = freezed,Object? searchQuery = null,Object? selectedYear = null,Object? selectedObjectId = freezed,Object? selectedContractorId = freezed,Object? selectedContractIds = null,Object? selectedOperationTypes = null,Object? selectedBankAccountId = freezed,Object? hasMore = null,Object? isLoadingMore = null,Object? isDetailedAnalytics = null,}) {
  return _then(_CashFlowState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CashFlowStatus,currentView: null == currentView ? _self.currentView : currentView // ignore: cast_nullable_to_non_nullable
as CashFlowView,transactions: null == transactions ? _self._transactions : transactions // ignore: cast_nullable_to_non_nullable
as List<CashFlowTransaction>,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<CashFlowCategory>,bankImportTemplates: null == bankImportTemplates ? _self._bankImportTemplates : bankImportTemplates // ignore: cast_nullable_to_non_nullable
as List<BankImportTemplate>,bankStatementEntries: null == bankStatementEntries ? _self._bankStatementEntries : bankStatementEntries // ignore: cast_nullable_to_non_nullable
as List<BankStatementEntry>,yearlyAnalytics: null == yearlyAnalytics ? _self._yearlyAnalytics : yearlyAnalytics // ignore: cast_nullable_to_non_nullable
as List<MonthlyAnalytics>,availableFilters: null == availableFilters ? _self.availableFilters : availableFilters // ignore: cast_nullable_to_non_nullable
as AvailableFilters,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,selectedYear: null == selectedYear ? _self.selectedYear : selectedYear // ignore: cast_nullable_to_non_nullable
as int,selectedObjectId: freezed == selectedObjectId ? _self.selectedObjectId : selectedObjectId // ignore: cast_nullable_to_non_nullable
as String?,selectedContractorId: freezed == selectedContractorId ? _self.selectedContractorId : selectedContractorId // ignore: cast_nullable_to_non_nullable
as String?,selectedContractIds: null == selectedContractIds ? _self._selectedContractIds : selectedContractIds // ignore: cast_nullable_to_non_nullable
as List<String>,selectedOperationTypes: null == selectedOperationTypes ? _self._selectedOperationTypes : selectedOperationTypes // ignore: cast_nullable_to_non_nullable
as List<String>,selectedBankAccountId: freezed == selectedBankAccountId ? _self.selectedBankAccountId : selectedBankAccountId // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,isDetailedAnalytics: null == isDetailedAnalytics ? _self.isDetailedAnalytics : isDetailedAnalytics // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of CashFlowState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AvailableFiltersCopyWith<$Res> get availableFilters {
  
  return $AvailableFiltersCopyWith<$Res>(_self.availableFilters, (value) {
    return _then(_self.copyWith(availableFilters: value));
  });
}
}

// dart format on
