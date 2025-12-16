// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ks2_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ks2ActsHash() => r'04a465a34cabf55e8392dbfb95944f4bbfea7a41';

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

abstract class _$Ks2Acts
    extends BuildlessAutoDisposeAsyncNotifier<List<Ks2Act>> {
  late final String contractId;

  FutureOr<List<Ks2Act>> build(
    String contractId,
  );
}

/// Провайдер списка актов для конкретного договора.
///
/// Copied from [Ks2Acts].
@ProviderFor(Ks2Acts)
const ks2ActsProvider = Ks2ActsFamily();

/// Провайдер списка актов для конкретного договора.
///
/// Copied from [Ks2Acts].
class Ks2ActsFamily extends Family<AsyncValue<List<Ks2Act>>> {
  /// Провайдер списка актов для конкретного договора.
  ///
  /// Copied from [Ks2Acts].
  const Ks2ActsFamily();

  /// Провайдер списка актов для конкретного договора.
  ///
  /// Copied from [Ks2Acts].
  Ks2ActsProvider call(
    String contractId,
  ) {
    return Ks2ActsProvider(
      contractId,
    );
  }

  @override
  Ks2ActsProvider getProviderOverride(
    covariant Ks2ActsProvider provider,
  ) {
    return call(
      provider.contractId,
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
  String? get name => r'ks2ActsProvider';
}

/// Провайдер списка актов для конкретного договора.
///
/// Copied from [Ks2Acts].
class Ks2ActsProvider
    extends AutoDisposeAsyncNotifierProviderImpl<Ks2Acts, List<Ks2Act>> {
  /// Провайдер списка актов для конкретного договора.
  ///
  /// Copied from [Ks2Acts].
  Ks2ActsProvider(
    String contractId,
  ) : this._internal(
          () => Ks2Acts()..contractId = contractId,
          from: ks2ActsProvider,
          name: r'ks2ActsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$ks2ActsHash,
          dependencies: Ks2ActsFamily._dependencies,
          allTransitiveDependencies: Ks2ActsFamily._allTransitiveDependencies,
          contractId: contractId,
        );

  Ks2ActsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.contractId,
  }) : super.internal();

  final String contractId;

  @override
  FutureOr<List<Ks2Act>> runNotifierBuild(
    covariant Ks2Acts notifier,
  ) {
    return notifier.build(
      contractId,
    );
  }

  @override
  Override overrideWith(Ks2Acts Function() create) {
    return ProviderOverride(
      origin: this,
      override: Ks2ActsProvider._internal(
        () => create()..contractId = contractId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        contractId: contractId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<Ks2Acts, List<Ks2Act>>
      createElement() {
    return _Ks2ActsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is Ks2ActsProvider && other.contractId == contractId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, contractId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin Ks2ActsRef on AutoDisposeAsyncNotifierProviderRef<List<Ks2Act>> {
  /// The parameter `contractId` of this provider.
  String get contractId;
}

class _Ks2ActsProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<Ks2Acts, List<Ks2Act>>
    with Ks2ActsRef {
  _Ks2ActsProviderElement(super.provider);

  @override
  String get contractId => (origin as Ks2ActsProvider).contractId;
}

String _$ks2CreationHash() => r'a9d56a0b906a7806ba4284e2fe462b725cb38e5e';

/// Состояние экрана создания КС-2.
///
/// Copied from [Ks2Creation].
@ProviderFor(Ks2Creation)
final ks2CreationProvider =
    AutoDisposeAsyncNotifierProvider<Ks2Creation, Ks2PreviewData?>.internal(
  Ks2Creation.new,
  name: r'ks2CreationProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$ks2CreationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Ks2Creation = AutoDisposeAsyncNotifier<Ks2PreviewData?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
