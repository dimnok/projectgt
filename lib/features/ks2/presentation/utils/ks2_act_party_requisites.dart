import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/features/company/domain/entities/company_profile.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';

/// Внутренний маркер стороны «наша организация» при разрешении реквизитов из договора.
const String kKs2OwnCompanyPartyPickId = '__ks2_own_company__';

Contractor? _contractorById(List<Contractor> contractors, String id) {
  for (final c in contractors) {
    if (c.id == id) return c;
  }
  return null;
}

/// Реквизиты для шапки КС-2: **краткое наименование** и **юридический адрес** в одной строке через запятую.
///
/// Телефон и e-mail не подставляются — их при необходимости дописывают вручную в других полях формы.
String ks2PartyRequisitesMultiline({
  required String pickId,
  CompanyProfile? profile,
  required List<Contractor> contractors,
}) {
  if (pickId == kKs2OwnCompanyPartyPickId) {
    return _companyRequisitesMultiline(profile);
  }
  final c = _contractorById(contractors, pickId);
  if (c == null) return '';
  return _contractorRequisitesMultiline(c);
}

/// ОКПО выбранной стороны (пустая строка, если в карточке не заполнено).
String ks2PartyOkpoText({
  required String pickId,
  CompanyProfile? profile,
  required List<Contractor> contractors,
}) {
  if (pickId == kKs2OwnCompanyPartyPickId) {
    return (profile?.okpo ?? '').trim();
  }
  final c = _contractorById(contractors, pickId);
  return (c?.okpo ?? '').trim();
}

/// Проверяет, что [pickId] допустим для подстановки реквизитов (профиль компании или контрагент из списка).
bool ks2IsValidPartyPickId(
  String pickId, {
  required CompanyProfile? profile,
  required List<Contractor> contractors,
}) {
  if (pickId == kKs2OwnCompanyPartyPickId) {
    return profile != null;
  }
  return _contractorById(contractors, pickId) != null;
}

/// Начальное сопоставление сторон по типу договора и контрагенту в карточке договора.
///
/// [ContractKind.customer]: в договоре указан заказчик — контрагент по [Contract.contractorId],
/// исполнитель — наша организация.
///
/// [ContractKind.subcontract] / [supply]: заказчик — наша организация, контрагент по договору —
/// второй исполнитель (подрядчик / поставщик).
({String? customerPickId, String? contractorPickId}) ks2DefaultPartyPickIds({
  required Contract contract,
  required List<Contractor> contractors,
  required bool hasCompanyProfile,
}) {
  final linked = _contractorById(contractors, contract.contractorId);
  final own = hasCompanyProfile ? kKs2OwnCompanyPartyPickId : null;

  switch (contract.kind) {
    case ContractKind.customer:
      return (customerPickId: linked?.id, contractorPickId: own);
    case ContractKind.subcontract:
    case ContractKind.supply:
      return (customerPickId: own, contractorPickId: linked?.id);
  }
}

String _companyShortDisplayName(CompanyProfile p) {
  final short = p.nameShort.trim();
  if (short.isNotEmpty) return short;
  return p.nameFull.trim();
}

String _companyLegalAddressLine(CompanyProfile p) {
  final legal = (p.legalAddress ?? '').trim();
  if (legal.isNotEmpty) return legal;
  return (p.actualAddress ?? '').trim();
}

String _companyRequisitesMultiline(CompanyProfile? profile) {
  final p = profile;
  if (p == null) return '';
  final name = _companyShortDisplayName(p);
  final address = _companyLegalAddressLine(p);
  final lines = <String>[
    if (name.isNotEmpty) name,
    if (address.isNotEmpty) address,
  ];
  return lines.join(', ');
}

String _contractorShortDisplayName(Contractor c) {
  final short = c.shortName.trim();
  if (short.isNotEmpty) return short;
  return c.fullName.trim();
}

String _contractorLegalAddressLine(Contractor c) {
  final legal = c.legalAddress.trim();
  if (legal.isNotEmpty) return legal;
  return c.actualAddress.trim();
}

String _contractorRequisitesMultiline(Contractor c) {
  final name = _contractorShortDisplayName(c);
  final address = _contractorLegalAddressLine(c);
  final lines = <String>[
    if (name.isNotEmpty) name,
    if (address.isNotEmpty) address,
  ];
  return lines.join(', ');
}
