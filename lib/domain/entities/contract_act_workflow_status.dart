/// Статус согласования / подписания акта по договору.
enum ContractActWorkflowStatus {
  /// На согласовании.
  pendingApproval,

  /// Согласован.
  approved,

  /// Подписан.
  signed,
}
