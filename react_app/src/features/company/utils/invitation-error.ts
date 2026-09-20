/** Сообщения об ошибках одноразовых приглашений. Совпадают с приложением. */
export function invitationErrorMessage(error: string): string {
  const text = error.toLowerCase();
  if (text.includes("invitation_not_found") || text.includes("invalid_code")) {
    return "Код не найден. Проверьте ввод.";
  }
  if (text.includes("invitation_already_used")) {
    return "Этот код уже использован.";
  }
  if (text.includes("invitation_revoked")) {
    return "Код отменён администратором.";
  }
  if (text.includes("invitation_expired")) {
    return "Срок действия кода истёк.";
  }
  if (text.includes("already_member")) {
    return "Вы уже состоите в этой организации.";
  }
  if (text.includes("forbidden")) {
    return "Недостаточно прав.";
  }
  if (text.includes("not_authenticated")) {
    return "Войдите в аккаунт.";
  }
  return "Не удалось выполнить операцию. Попробуйте позже.";
}
