// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contractor_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$filteredContractorsHash() =>
    r'd6af9b382b489bf6a0a4ab252a5e948decec21e2';

/// Провайдер для отфильтрованного списка контрагентов.
///
/// Copied from [filteredContractors].
@ProviderFor(filteredContractors)
final filteredContractorsProvider =
    AutoDisposeProvider<List<Contractor>>.internal(
      filteredContractors,
      name: r'filteredContractorsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$filteredContractorsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FilteredContractorsRef = AutoDisposeProviderRef<List<Contractor>>;
String _$contractorNotifierHash() =>
    r'c6be3969ecf2688aedf9e80f44e129ab8bb015fb';

/// Нотификатор для управления состоянием контрагентов.
///
/// Copied from [ContractorNotifier].
@ProviderFor(ContractorNotifier)
final contractorNotifierProvider =
    AutoDisposeNotifierProvider<ContractorNotifier, ContractorState>.internal(
      ContractorNotifier.new,
      name: r'contractorNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$contractorNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ContractorNotifier = AutoDisposeNotifier<ContractorState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
