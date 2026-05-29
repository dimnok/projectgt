/// Сообщения об ошибках одноразовых приглашений для пользователя.
String invitationErrorMessage(Object error) {
  final text = error.toString().toLowerCase();
  if (text.contains('invitation_not_found') || text.contains('invalid_code')) {
    return 'Код не найден. Проверьте ввод.';
  }
  if (text.contains('invitation_already_used')) {
    return 'Этот код уже использован.';
  }
  if (text.contains('invitation_revoked')) {
    return 'Код отменён администратором.';
  }
  if (text.contains('invitation_expired')) {
    return 'Срок действия кода истёк.';
  }
  if (text.contains('already_member')) {
    return 'Вы уже состоите в этой организации.';
  }
  if (text.contains('forbidden')) {
    return 'Недостаточно прав.';
  }
  if (text.contains('not_authenticated')) {
    return 'Войдите в аккаунт.';
  }
  return 'Не удалось выполнить операцию. Попробуйте позже.';
}

/// Может ли пользователь выдавать приглашения (владелец или админ).
bool canManageCompanyInvitations(String? systemRole) {
  final role = systemRole?.toLowerCase();
  return role == 'owner' || role == 'admin';
}
