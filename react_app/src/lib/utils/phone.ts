/**
 * Russian phone helpers. Display and input match Flutter:
 * `+7 900 000 00 00` (`GtFormatters.formatPhone` / `phoneFormatter`).
 * Auth still uses E.164: `+79000000000`.
 */

function digitsOnly(value: string): string {
  return value.replace(/\D/g, "");
}

function formatSubscriber(digits: string): string {
  if (!digits) {
    return "";
  }
  if (digits.length <= 3) {
    return `+7 ${digits}`;
  }
  if (digits.length <= 6) {
    return `+7 ${digits.slice(0, 3)} ${digits.slice(3)}`;
  }
  if (digits.length <= 8) {
    return `+7 ${digits.slice(0, 3)} ${digits.slice(3, 6)} ${digits.slice(6)}`;
  }
  return `+7 ${digits.slice(0, 3)} ${digits.slice(3, 6)} ${digits.slice(6, 8)} ${digits.slice(8, 10)}`;
}

/**
 * Formats a phone number for display: `+7 900 000 00 00`.
 * Empty input returns an empty string. Non-Russian numbers are returned as-is.
 */
export function formatPhone(phone: string | null | undefined): string {
  if (!phone?.trim()) {
    return "";
  }

  let digits = digitsOnly(phone);

  if (
    digits.length === 11 &&
    (digits.startsWith("7") || digits.startsWith("8"))
  ) {
    digits = digits.slice(1);
  }

  if (digits.length === 10) {
    return formatSubscriber(digits);
  }

  if (digits.length > 0) {
    return phone.trim().startsWith("+") ? phone.trim() : `+${digits}`;
  }

  return phone.trim();
}

/**
 * Live input mask: `+7 900 000 00 00`.
 * Empty or a lone country code becomes an empty string.
 */
export function formatPhoneInput(value: string): string {
  let digits = digitsOnly(value);
  if (digits.startsWith("7") || digits.startsWith("8")) {
    digits = digits.slice(1);
  }
  return formatSubscriber(digits.slice(0, 10));
}

/**
 * Normalizes a Russian phone number to E.164: `+7XXXXXXXXXX`.
 * Matches the Flutter helper `normalizeRuPhoneE164`.
 */
export function normalizeRuPhoneE164(phone: string): string | null {
  let digits = digitsOnly(phone);
  if (!digits) {
    return null;
  }

  if (digits.length === 11 && digits.startsWith("8")) {
    digits = `7${digits.slice(1)}`;
  } else if (digits.length === 10) {
    digits = `7${digits}`;
  }

  if (digits.length === 11 && digits.startsWith("7")) {
    return `+${digits}`;
  }

  return null;
}
