/**
 * Имя пользователя для интерфейса: короткое, полное, почта — что есть.
 * `null` означает, что показать нечего.
 */
export function pickUserDisplayName(options: {
  shortName?: string | null;
  fullName?: string | null;
  email?: string | null;
}): string | null {
  for (const value of [options.shortName, options.fullName, options.email]) {
    const trimmed = value?.trim();
    if (trimmed) {
      return trimmed;
    }
  }
  return null;
}

/** Имя для строки интерфейса: пустое значение заменяется прочерком. */
export function formatUserDisplayLabel(
  name: string | null | undefined,
  fallback = "—"
): string {
  const trimmed = name?.trim();
  return trimmed ? trimmed : fallback;
}

/** Имя из строки `profiles`: короткое, полное или почта. */
export function pickProfileDisplayName(profile: Record<string, unknown>) {
  return pickUserDisplayName({
    shortName: asOptionalString(profile.short_name),
    fullName: asOptionalString(profile.full_name),
    email: asOptionalString(profile.email),
  });
}

/** Строка из базы или `null`: значения приходят без типов. */
export function asOptionalString(value: unknown): string | null {
  return typeof value === "string" ? value : null;
}
