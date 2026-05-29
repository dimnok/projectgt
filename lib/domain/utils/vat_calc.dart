/// Расчёт НДС по правилам договора (`vat_rate`, `is_vat_included`).
///
/// Используется в карточке договора, актах КС-2 и сводках.
library;

/// Параметры НДС договора для расчёта актов.
class ContractVatTerms {
  /// Создаёт параметры НДС.
  const ContractVatTerms({required this.vatRate, required this.isVatIncluded});

  /// Ставка НДС, %.
  final double vatRate;

  /// `true` — НДС включён в сумму договора; `false` — начисляется сверху.
  ///
  /// Для актов КС-2 не используется: сумма строк ВОР всегда без НДС.
  final bool isVatIncluded;
}

/// Сумма акта и НДС для записи в `contract_acts`.
class ActAmountVatSplit {
  /// Создаёт пару сумм для сохранения акта.
  const ActAmountVatSplit({required this.amount, required this.vatAmount});

  /// База акта без начисляемого «сверху» НДС (при включённом НДС — нетто).
  final double amount;

  /// Сумма НДС (для `total_to_pay` складывается с [amount]).
  final double vatAmount;
}

/// Округление денежной суммы до копеек.
double roundMoney(double value) {
  if (value.isNaN || value.isInfinite) return 0;
  return (value * 100).round() / 100;
}

/// НДС от суммы [baseAmount] по ставке договора.
///
/// При [isVatIncluded] `baseAmount` трактуется как сумма с учётом НДС
/// (извлекается доля НДС). Иначе НДС начисляется сверху.
double computeVatAmount({
  required double baseAmount,
  required double vatRate,
  required bool isVatIncluded,
}) {
  if (vatRate <= 0 || baseAmount <= 0) return 0;
  final raw = isVatIncluded
      ? baseAmount * vatRate / (100 + vatRate)
      : baseAmount * vatRate / 100;
  return roundMoney(raw);
}

/// Разбивает итог строк акта КС-2 на поля `amount` и `vat_amount`.
///
/// [lineTotal] — сумма строк ВОР/КС-2 **без НДС**. НДС начисляется сверху
/// по [ContractVatTerms.vatRate] (режим «включён в договор» на карточку договора
/// к строкам акта не распространяется).
ActAmountVatSplit splitActAmountForStorage({
  required double lineTotal,
  required ContractVatTerms vatTerms,
}) {
  if (lineTotal.isNaN || lineTotal <= 0) {
    return const ActAmountVatSplit(amount: 0, vatAmount: 0);
  }
  final amount = roundMoney(lineTotal);
  if (vatTerms.vatRate <= 0) {
    return ActAmountVatSplit(amount: amount, vatAmount: 0);
  }
  final vatAmount = computeVatAmount(
    baseAmount: amount,
    vatRate: vatTerms.vatRate,
    isVatIncluded: false,
  );
  return ActAmountVatSplit(amount: amount, vatAmount: vatAmount);
}
