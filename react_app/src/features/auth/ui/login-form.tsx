"use client";

import { useEffect, useState, type FormEvent } from "react";

import { PhoneInput } from "@/components/shared/phone-input";
import { Button } from "@/components/ui/button";
import {
  Field,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field";
import { Spinner } from "@/components/ui/spinner";
import { requestPhoneOtp, verifyPhoneOtp } from "@/lib/supabase/auth";
import { cn } from "@/lib/utils";
import { formatPhone } from "@/lib/utils/phone";

type Step = "phone" | "code";

const CODE_LENGTH = 6;
const RESEND_SECONDS = 30;

export function LoginForm() {
  const [step, setStep] = useState<Step>("phone");
  const [phone, setPhone] = useState("");
  const [code, setCode] = useState("");
  const [error, setError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [secondsLeft, setSecondsLeft] = useState(0);

  useEffect(() => {
    if (step !== "code" || secondsLeft <= 0) {
      return;
    }
    const timer = setTimeout(() => setSecondsLeft((value) => value - 1), 1000);
    return () => clearTimeout(timer);
  }, [step, secondsLeft]);

  async function sendCode() {
    setError("");
    setIsSubmitting(true);
    try {
      await requestPhoneOtp(phone);
      setCode("");
      setStep("code");
      setSecondsLeft(RESEND_SECONDS);
    } catch (caught) {
      setError(
        caught instanceof Error ? caught.message : "Не удалось отправить код"
      );
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleSendCode(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await sendCode();
  }

  async function verify(value: string) {
    if (isSubmitting) {
      return;
    }
    setError("");
    setIsSubmitting(true);
    try {
      await verifyPhoneOtp(phone, value);
    } catch (caught) {
      setError(
        caught instanceof Error ? caught.message : "Не удалось подтвердить код"
      );
      setCode("");
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleVerifyCode(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await verify(code);
  }

  function handleCodeChange(value: string) {
    const digits = value.replace(/\D/g, "").slice(0, CODE_LENGTH);
    setCode(digits);
    if (error) {
      setError("");
    }
    if (digits.length === CODE_LENGTH) {
      void verify(digits);
    }
  }

  function backToPhone() {
    setStep("phone");
    setCode("");
    setError("");
    setSecondsLeft(0);
  }

  if (step === "code") {
    return (
      <form className="flex flex-col gap-4" onSubmit={handleVerifyCode}>
        <p className="text-sm text-muted-foreground">
          Код отправлен на номер {formatPhone(phone) || phone}
        </p>
        <Field data-invalid={Boolean(error)}>
          <FieldLabel htmlFor="login-code">Код из сообщения</FieldLabel>
          <div className="relative">
            <input
              id="login-code"
              value={code}
              inputMode="numeric"
              autoComplete="one-time-code"
              maxLength={CODE_LENGTH}
              autoFocus
              disabled={isSubmitting}
              aria-invalid={Boolean(error)}
              className="absolute inset-0 h-full w-full opacity-0"
              onChange={(event) => handleCodeChange(event.target.value)}
            />
            <div className="flex justify-center gap-2" aria-hidden="true">
              {Array.from({ length: CODE_LENGTH }).map((_, index) => (
                <div
                  key={index}
                  className={cn(
                    "flex size-11 items-center justify-center rounded-lg border text-lg font-semibold transition-colors",
                    error
                      ? "border-destructive"
                      : index === code.length && !isSubmitting
                        ? "border-ring ring-3 ring-ring/50"
                        : "border-input"
                  )}
                >
                  {code[index] ?? ""}
                </div>
              ))}
            </div>
          </div>
          <FieldError>{error}</FieldError>
        </Field>
        <Button type="submit" size="lg" disabled={isSubmitting || code.length < CODE_LENGTH}>
          {isSubmitting ? <Spinner data-icon="inline-start" /> : null}
          Войти
        </Button>
        {secondsLeft > 0 ? (
          <p className="text-center text-xs text-muted-foreground">
            Повторная отправка через {formatCountdown(secondsLeft)}
          </p>
        ) : (
          <Button
            type="button"
            variant="ghost"
            disabled={isSubmitting}
            onClick={() => void sendCode()}
          >
            Отправить код повторно
          </Button>
        )}
        <Button
          type="button"
          variant="ghost"
          disabled={isSubmitting}
          onClick={backToPhone}
        >
          Изменить номер
        </Button>
      </form>
    );
  }

  return (
    <form className="flex flex-col gap-4" onSubmit={handleSendCode}>
      <FieldGroup>
        <Field data-invalid={Boolean(error)}>
          <FieldLabel htmlFor="login-phone">Телефон</FieldLabel>
          <PhoneInput
            id="login-phone"
            value={phone}
            disabled={isSubmitting}
            aria-invalid={Boolean(error)}
            onValueChange={setPhone}
          />
          <FieldError>{error}</FieldError>
        </Field>
      </FieldGroup>
      <Button type="submit" size="lg" disabled={isSubmitting}>
        {isSubmitting ? <Spinner data-icon="inline-start" /> : null}
        Получить код
      </Button>
    </form>
  );
}

function formatCountdown(seconds: number) {
  const minutes = Math.floor(seconds / 60);
  const rest = seconds % 60;
  return `${String(minutes).padStart(2, "0")}:${String(rest).padStart(2, "0")}`;
}
