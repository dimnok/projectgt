/// Раздел навигации по карточке договора (строка ссылок в шапке встроенного вида).
enum ContractDetailNavigationSection {
  /// Общие данные (основная информация по договору).
  general,

  /// Сметы.
  estimates,

  /// Дополнительные соглашения.
  addenda,

  /// Акты.
  acts,

  /// Документы.
  documents,

  /// Финансы.
  finances,
}

/// Публичная подпись раздела в UI и заглушках.
extension ContractDetailNavigationSectionLabels on ContractDetailNavigationSection {
  /// Русское название для подписей и текстов состояния.
  String get label => switch (this) {
        ContractDetailNavigationSection.general => 'Общие данные',
        ContractDetailNavigationSection.estimates => 'Сметы',
        ContractDetailNavigationSection.addenda => 'Доп. соглашения',
        ContractDetailNavigationSection.acts => 'Акты',
        ContractDetailNavigationSection.documents => 'Документы',
        ContractDetailNavigationSection.finances => 'Финансы',
      };
}