/// Проверяет, ожидает ли пользователь назначения роли в компании.
///
/// Владелец ([systemRole] == `owner`) всегда имеет полный доступ.
bool isAwaitingRoleAssignment({
  required String? roleId,
  required String? systemRole,
}) {
  if (systemRole == 'owner') return false;
  return roleId == null || roleId.isEmpty;
}
