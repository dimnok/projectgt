import { createClient, getRequiredClient } from "@/lib/supabase/client";
import { normalizeRuPhoneE164 } from "@/lib/utils/phone";

/**
 * Sends a phone OTP using the same Supabase Auth flow as Flutter.
 */
export async function requestPhoneOtp(phone: string) {
  const phoneE164 = normalizeRuPhoneE164(phone);
  if (!phoneE164) {
    throw new Error("Введите корректный номер телефона");
  }

  const { error } = await getRequiredClient().auth.signInWithOtp({
    phone: phoneE164,
  });

  if (error) {
    throw new Error(otpRequestErrorMessage(error.message));
  }

  return phoneE164;
}

/**
 * Confirms the SMS code and creates a browser session.
 */
export async function verifyPhoneOtp(phone: string, code: string) {
  const phoneE164 = normalizeRuPhoneE164(phone);
  if (!phoneE164) {
    throw new Error("Введите корректный номер телефона");
  }

  const token = code.trim();
  if (!token) {
    throw new Error("Введите код из сообщения");
  }

  const { data, error } = await getRequiredClient().auth.verifyOtp({
    phone: phoneE164,
    token,
    type: "sms",
  });

  if (error) {
    throw new Error(otpVerifyErrorMessage(error.message));
  }

  if (!data.session) {
    throw new Error("Не удалось подтвердить код");
  }

  return data.session;
}

/**
 * Ends the current browser session.
 */
export async function signOut() {
  const supabase = createClient();
  if (!supabase) {
    return;
  }

  const { error } = await supabase.auth.signOut();
  if (error) {
    throw new Error("Не удалось выйти");
  }
}

function otpRequestErrorMessage(message: string): string {
  const text = message.toLowerCase();
  if (text.includes("rate") || text.includes("too many") || text.includes("security")) {
    return "Слишком много попыток. Попробуйте позже.";
  }
  if (text.includes("network") || text.includes("fetch")) {
    return "Ошибка сети. Проверьте подключение к интернету.";
  }
  if (text.includes("phone") && text.includes("invalid")) {
    return "Введите корректный номер телефона";
  }
  return "Не удалось отправить код. Попробуйте позже.";
}

function otpVerifyErrorMessage(message: string): string {
  const text = message.toLowerCase();
  if (
    text.includes("expired") ||
    text.includes("invalid") ||
    text.includes("token") ||
    text.includes("otp")
  ) {
    return "Неверный или просроченный код";
  }
  if (text.includes("rate") || text.includes("too many") || text.includes("security")) {
    return "Слишком много попыток. Попробуйте позже.";
  }
  if (text.includes("network") || text.includes("fetch")) {
    return "Ошибка сети. Проверьте подключение к интернету.";
  }
  return "Не удалось подтвердить код. Попробуйте позже.";
}
