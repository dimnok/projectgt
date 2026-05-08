/// Режим экрана [SubcontractorsMobileScreen]: расценки, выполнение или сводка.
enum SubcontractorsPresentationMode {
  /// Таблица сметы и расценки выбранного подрядчика.
  ratesTable,

  /// Таблица план-факт выполнения выбранного подрядчика.
  executionTable,

  /// Укрупнённо: объекты, договора, сметы, наша сумма и плановая маржа.
  marginDashboard,
}
