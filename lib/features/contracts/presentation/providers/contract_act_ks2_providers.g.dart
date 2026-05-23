// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract_act_ks2_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$contractActApprovedVorsHash() =>
    r'3c284ba9544cc2037f22b48ba75119b3bde1084f';

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

/// Утверждённые ВОР по договору без уже сохранённого акта КС-2.
///
/// Copied from [contractActApprovedVors].
@ProviderFor(contractActApprovedVors)
const contractActApprovedVorsProvider = ContractActApprovedVorsFamily();

/// Утверждённые ВОР по договору без уже сохранённого акта КС-2.
///
/// Copied from [contractActApprovedVors].
class ContractActApprovedVorsFamily extends Family<AsyncValue<List<Vor>>> {
  /// Утверждённые ВОР по договору без уже сохранённого акта КС-2.
  ///
  /// Copied from [contractActApprovedVors].
  const ContractActApprovedVorsFamily();

  /// Утверждённые ВОР по договору без уже сохранённого акта КС-2.
  ///
  /// Copied from [contractActApprovedVors].
  ContractActApprovedVorsProvider call(String contractId) {
    return ContractActApprovedVorsProvider(contractId);
  }

  @override
  ContractActApprovedVorsProvider getProviderOverride(
    covariant ContractActApprovedVorsProvider provider,
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
  String? get name => r'contractActApprovedVorsProvider';
}

/// Утверждённые ВОР по договору без уже сохранённого акта КС-2.
///
/// Copied from [contractActApprovedVors].
class ContractActApprovedVorsProvider
    extends AutoDisposeFutureProvider<List<Vor>> {
  /// Утверждённые ВОР по договору без уже сохранённого акта КС-2.
  ///
  /// Copied from [contractActApprovedVors].
  ContractActApprovedVorsProvider(String contractId)
    : this._internal(
        (ref) => contractActApprovedVors(
          ref as ContractActApprovedVorsRef,
          contractId,
        ),
        from: contractActApprovedVorsProvider,
        name: r'contractActApprovedVorsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$contractActApprovedVorsHash,
        dependencies: ContractActApprovedVorsFamily._dependencies,
        allTransitiveDependencies:
            ContractActApprovedVorsFamily._allTransitiveDependencies,
        contractId: contractId,
      );

  ContractActApprovedVorsProvider._internal(
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
    FutureOr<List<Vor>> Function(ContractActApprovedVorsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ContractActApprovedVorsProvider._internal(
        (ref) => create(ref as ContractActApprovedVorsRef),
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
    return _ContractActApprovedVorsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ContractActApprovedVorsProvider &&
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
mixin ContractActApprovedVorsRef on AutoDisposeFutureProviderRef<List<Vor>> {
  /// The parameter `contractId` of this provider.
  String get contractId;
}

class _ContractActApprovedVorsProviderElement
    extends AutoDisposeFutureProviderElement<List<Vor>>
    with ContractActApprovedVorsRef {
  _ContractActApprovedVorsProviderElement(super.provider);

  @override
  String get contractId =>
      (origin as ContractActApprovedVorsProvider).contractId;
}

String _$contractActKs2PreviewNotifierHash() =>
    r'768160a409d5640a4f5640df65fa2742cca9645c';

/// Предпросмотр состава КС-2 по выбранной ВОР.
///
/// Copied from [ContractActKs2PreviewNotifier].
@ProviderFor(ContractActKs2PreviewNotifier)
final contractActKs2PreviewNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      ContractActKs2PreviewNotifier,
      ContractActKs2Preview?
    >.internal(
      ContractActKs2PreviewNotifier.new,
      name: r'contractActKs2PreviewNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$contractActKs2PreviewNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ContractActKs2PreviewNotifier =
    AutoDisposeAsyncNotifier<ContractActKs2Preview?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
