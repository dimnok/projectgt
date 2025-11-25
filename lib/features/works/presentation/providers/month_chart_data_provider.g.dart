// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'month_chart_data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$monthChartDataHash() => r'7a3008c8f6e9c7e5a41bcd0ba72416a0643a2c10';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Провайдер для загрузки данных графика за месяц.
///
/// Использует [LightWork] для получения всех смен месяца без пагинации,
/// но с минимальным набором полей (только дата и сумма).
///
/// Copied from [monthChartData].
@ProviderFor(monthChartData)
const monthChartDataProvider = MonthChartDataFamily();

/// Провайдер для загрузки данных графика за месяц.
///
/// Использует [LightWork] для получения всех смен месяца без пагинации,
/// но с минимальным набором полей (только дата и сумма).
///
/// Copied from [monthChartData].
class MonthChartDataFamily extends Family<AsyncValue<List<LightWork>>> {
  /// Провайдер для загрузки данных графика за месяц.
  ///
  /// Использует [LightWork] для получения всех смен месяца без пагинации,
  /// но с минимальным набором полей (только дата и сумма).
  ///
  /// Copied from [monthChartData].
  const MonthChartDataFamily();

  /// Провайдер для загрузки данных графика за месяц.
  ///
  /// Использует [LightWork] для получения всех смен месяца без пагинации,
  /// но с минимальным набором полей (только дата и сумма).
  ///
  /// Copied from [monthChartData].
  MonthChartDataProvider call(
    DateTime month,
  ) {
    return MonthChartDataProvider(
      month,
    );
  }

  @override
  MonthChartDataProvider getProviderOverride(
    covariant MonthChartDataProvider provider,
  ) {
    return call(
      provider.month,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'monthChartDataProvider';
}

/// Провайдер для загрузки данных графика за месяц.
///
/// Использует [LightWork] для получения всех смен месяца без пагинации,
/// но с минимальным набором полей (только дата и сумма).
///
/// Copied from [monthChartData].
class MonthChartDataProvider
    extends AutoDisposeFutureProvider<List<LightWork>> {
  /// Провайдер для загрузки данных графика за месяц.
  ///
  /// Использует [LightWork] для получения всех смен месяца без пагинации,
  /// но с минимальным набором полей (только дата и сумма).
  ///
  /// Copied from [monthChartData].
  MonthChartDataProvider(
    DateTime month,
  ) : this._internal(
          (ref) => monthChartData(
            ref as MonthChartDataRef,
            month,
          ),
          from: monthChartDataProvider,
          name: r'monthChartDataProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$monthChartDataHash,
          dependencies: MonthChartDataFamily._dependencies,
          allTransitiveDependencies:
              MonthChartDataFamily._allTransitiveDependencies,
          month: month,
        );

  MonthChartDataProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.month,
  }) : super.internal();

  final DateTime month;

  @override
  Override overrideWith(
    FutureOr<List<LightWork>> Function(MonthChartDataRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MonthChartDataProvider._internal(
        (ref) => create(ref as MonthChartDataRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        month: month,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<LightWork>> createElement() {
    return _MonthChartDataProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthChartDataProvider && other.month == month;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MonthChartDataRef on AutoDisposeFutureProviderRef<List<LightWork>> {
  /// The parameter `month` of this provider.
  DateTime get month;
}

class _MonthChartDataProviderElement
    extends AutoDisposeFutureProviderElement<List<LightWork>>
    with MonthChartDataRef {
  _MonthChartDataProviderElement(super.provider);

  @override
  DateTime get month => (origin as MonthChartDataProvider).month;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
