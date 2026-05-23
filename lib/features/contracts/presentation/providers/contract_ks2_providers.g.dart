// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract_ks2_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$contractKs2ApprovedVorsHash() =>
    r'd0057e64154ca3bdf8147ac684b117d6e689d13e';

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

/// Утверждённые ВОР по договору — только для сценария КС-2 в карточке договора.
///
/// Запрос к таблице `vors` напрямую, без [vorsProvider] из модуля смет.
///
/// Copied from [contractKs2ApprovedVors].
@ProviderFor(contractKs2ApprovedVors)
const contractKs2ApprovedVorsProvider = ContractKs2ApprovedVorsFamily();

/// Утверждённые ВОР по договору — только для сценария КС-2 в карточке договора.
///
/// Запрос к таблице `vors` напрямую, без [vorsProvider] из модуля смет.
///
/// Copied from [contractKs2ApprovedVors].
class ContractKs2ApprovedVorsFamily extends Family<AsyncValue<List<Vor>>> {
  /// Утверждённые ВОР по договору — только для сценария КС-2 в карточке договора.
  ///
  /// Запрос к таблице `vors` напрямую, без [vorsProvider] из модуля смет.
  ///
  /// Copied from [contractKs2ApprovedVors].
  const ContractKs2ApprovedVorsFamily();

  /// Утверждённые ВОР по договору — только для сценария КС-2 в карточке договора.
  ///
  /// Запрос к таблице `vors` напрямую, без [vorsProvider] из модуля смет.
  ///
  /// Copied from [contractKs2ApprovedVors].
  ContractKs2ApprovedVorsProvider call(String contractId) {
    return ContractKs2ApprovedVorsProvider(contractId);
  }

  @override
  ContractKs2ApprovedVorsProvider getProviderOverride(
    covariant ContractKs2ApprovedVorsProvider provider,
  ) {
    return call(provider.contractId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'contractKs2ApprovedVorsProvider';
}

/// Утверждённые ВОР по договору — только для сценария КС-2 в карточке договора.
///
/// Запрос к таблице `vors` напрямую, без [vorsProvider] из модуля смет.
///
/// Copied from [contractKs2ApprovedVors].
class ContractKs2ApprovedVorsProvider
    extends AutoDisposeFutureProvider<List<Vor>> {
  /// Утверждённые ВОР по договору — только для сценария КС-2 в карточке договора.
  ///
  /// Запрос к таблице `vors` напрямую, без [vorsProvider] из модуля смет.
  ///
  /// Copied from [contractKs2ApprovedVors].
  ContractKs2ApprovedVorsProvider(String contractId)
    : this._internal(
        (ref) => contractKs2ApprovedVors(
          ref as ContractKs2ApprovedVorsRef,
          contractId,
        ),
        from: contractKs2ApprovedVorsProvider,
        name: r'contractKs2ApprovedVorsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$contractKs2ApprovedVorsHash,
        dependencies: ContractKs2ApprovedVorsFamily._dependencies,
        allTransitiveDependencies:
            ContractKs2ApprovedVorsFamily._allTransitiveDependencies,
        contractId: contractId,
      );

  ContractKs2ApprovedVorsProvider._internal(
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
  Override overrideWith(
    FutureOr<List<Vor>> Function(ContractKs2ApprovedVorsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ContractKs2ApprovedVorsProvider._internal(
        (ref) => create(ref as ContractKs2ApprovedVorsRef),
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
  AutoDisposeFutureProviderElement<List<Vor>> createElement() {
    return _ContractKs2ApprovedVorsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ContractKs2ApprovedVorsProvider &&
        other.contractId == contractId;
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
mixin ContractKs2ApprovedVorsRef on AutoDisposeFutureProviderRef<List<Vor>> {
  /// The parameter `contractId` of this provider.
  String get contractId;
}

class _ContractKs2ApprovedVorsProviderElement
    extends AutoDisposeFutureProviderElement<List<Vor>>
    with ContractKs2ApprovedVorsRef {
  _ContractKs2ApprovedVorsProviderElement(super.provider);

  @override
  String get contractId =>
      (origin as ContractKs2ApprovedVorsProvider).contractId;
}

String _$contractKs2ActsHash() => r'327be6d1e5c1d5283cb05933200703c7e5d910d1';

abstract class _$ContractKs2Acts
    extends BuildlessAutoDisposeAsyncNotifier<List<Ks2Act>> {
  late final String contractId;

  FutureOr<List<Ks2Act>> build(String contractId);
}

/// Список актов КС-2 по договору (модуль «Договоры»).
///
/// Copied from [ContractKs2Acts].
@ProviderFor(ContractKs2Acts)
const contractKs2ActsProvider = ContractKs2ActsFamily();

/// Список актов КС-2 по договору (модуль «Договоры»).
///
/// Copied from [ContractKs2Acts].
class ContractKs2ActsFamily extends Family<AsyncValue<List<Ks2Act>>> {
  /// Список актов КС-2 по договору (модуль «Договоры»).
  ///
  /// Copied from [ContractKs2Acts].
  const ContractKs2ActsFamily();

  /// Список актов КС-2 по договору (модуль «Договоры»).
  ///
  /// Copied from [ContractKs2Acts].
  ContractKs2ActsProvider call(String contractId) {
    return ContractKs2ActsProvider(contractId);
  }

  @override
  ContractKs2ActsProvider getProviderOverride(
    covariant ContractKs2ActsProvider provider,
  ) {
    return call(provider.contractId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'contractKs2ActsProvider';
}

/// Список актов КС-2 по договору (модуль «Договоры»).
///
/// Copied from [ContractKs2Acts].
class ContractKs2ActsProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<ContractKs2Acts, List<Ks2Act>> {
  /// Список актов КС-2 по договору (модуль «Договоры»).
  ///
  /// Copied from [ContractKs2Acts].
  ContractKs2ActsProvider(String contractId)
    : this._internal(
        () => ContractKs2Acts()..contractId = contractId,
        from: contractKs2ActsProvider,
        name: r'contractKs2ActsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$contractKs2ActsHash,
        dependencies: ContractKs2ActsFamily._dependencies,
        allTransitiveDependencies:
            ContractKs2ActsFamily._allTransitiveDependencies,
        contractId: contractId,
      );

  ContractKs2ActsProvider._internal(
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
  FutureOr<List<Ks2Act>> runNotifierBuild(covariant ContractKs2Acts notifier) {
    return notifier.build(contractId);
  }

  @override
  Override overrideWith(ContractKs2Acts Function() create) {
    return ProviderOverride(
      origin: this,
      override: ContractKs2ActsProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<ContractKs2Acts, List<Ks2Act>>
  createElement() {
    return _ContractKs2ActsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ContractKs2ActsProvider && other.contractId == contractId;
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
mixin ContractKs2ActsRef on AutoDisposeAsyncNotifierProviderRef<List<Ks2Act>> {
  /// The parameter `contractId` of this provider.
  String get contractId;
}

class _ContractKs2ActsProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<ContractKs2Acts, List<Ks2Act>>
    with ContractKs2ActsRef {
  _ContractKs2ActsProviderElement(super.provider);

  @override
  String get contractId => (origin as ContractKs2ActsProvider).contractId;
}

String _$contractKs2CreationHash() =>
    r'cafae49335988041be411f5ba8d73de301f8c6ae';

/// Состояние формы создания акта КС-2 по ВОР (модуль «Договоры»).
///
/// Copied from [ContractKs2Creation].
@ProviderFor(ContractKs2Creation)
final contractKs2CreationProvider =
    AutoDisposeAsyncNotifierProvider<
      ContractKs2Creation,
      Ks2PreviewData?
    >.internal(
      ContractKs2Creation.new,
      name: r'contractKs2CreationProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$contractKs2CreationHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ContractKs2Creation = AutoDisposeAsyncNotifier<Ks2PreviewData?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
