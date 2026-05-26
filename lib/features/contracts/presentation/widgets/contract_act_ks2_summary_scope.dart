import 'package:flutter/widgets.dart';
import 'package:projectgt/domain/entities/contract_act.dart';
import 'package:projectgt/domain/utils/vat_calc.dart';
import 'package:projectgt/features/contracts/presentation/widgets/ks2_act_lines_table.dart';

/// Передаёт параметры НДС и удержаний из формы КС-2 в таблицу позиций.
class ContractActKs2SummaryScope extends InheritedWidget {
  /// Создаёт scope для дочерних таблиц.
  const ContractActKs2SummaryScope({
    super.key,
    required this.vatTerms,
    required this.advanceRetention,
    required this.warrantyRetention,
    required this.otherRetentions,
    required super.child,
  });

  /// Ставка и режим НДС договора.
  final ContractVatTerms vatTerms;

  /// Авансовое удержание.
  final double advanceRetention;

  /// Гарантийное удержание.
  final double warrantyRetention;

  /// Прочие удержания.
  final double otherRetentions;

  /// Ищет scope в дереве виджетов.
  static ContractActKs2SummaryScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ContractActKs2SummaryScope>();
  }

  /// Итог по сумме строк таблицы (без НДС) с НДС и удержаниями.
  Ks2ActLinesTableFinancialFooter? footerFromLineTotal(double lineTotal) {
    if (lineTotal.isNaN || lineTotal <= 0) return null;
    final split = splitActAmountForStorage(
      lineTotal: lineTotal,
      vatTerms: vatTerms,
    );
    return Ks2ActLinesTableFinancialFooter(
      amount: split.amount,
      vatAmount: split.vatAmount,
      totalToPay: computeContractActTotalToPay(
        amount: split.amount,
        vatAmount: split.vatAmount,
        advanceRetention: advanceRetention,
        warrantyRetention: warrantyRetention,
        otherRetentions: otherRetentions,
      ),
    );
  }

  @override
  bool updateShouldNotify(ContractActKs2SummaryScope oldWidget) {
    return vatTerms.vatRate != oldWidget.vatTerms.vatRate ||
        vatTerms.isVatIncluded != oldWidget.vatTerms.isVatIncluded ||
        advanceRetention != oldWidget.advanceRetention ||
        warrantyRetention != oldWidget.warrantyRetention ||
        otherRetentions != oldWidget.otherRetentions;
  }
}
