"use client";

import { useState, type FormEvent } from "react";

import { PhoneInput } from "@/components/shared/phone-input";
import { Button } from "@/components/ui/button";
import {
  Field,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Spinner } from "@/components/ui/spinner";
import { requestPhoneOtp, verifyPhoneOtp } from "@/lib/supabase/auth";
import { formatPhone } from "@/lib/utils/phone";

type Step = "phone" | "code";

export function LoginForm() {
  const [step, setStep] = useState<Step>("phone");
  const [phone, setPhone] = useState("");
  const [code, setCode] = useState("");
  const [error, setError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSendCode(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    setIsSubmitting(true);

    try {
      await requestPhoneOtp(phone);
      setStep("code");
    } catch (caught) {
      setError(
        caught instanceof Error ? caught.message : "Не удалось отправить код"
      );
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleVerifyCode(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    setIsSubmitting(true);

    try {
      await verifyPhoneOtp(phone, code);
    } catch (caught) {
      setError(
        caught instanceof Error ? caught.message : "Не удалось подтвердить код"
      );
    } finally {
      setIsSubmitting(false);
    }
  }

  if (step === "code") {
    return (
      <form className="flex flex-col gap-4" onSubmit={handleVerifyCode}>
        <p className="text-sm text-muted-foreground">
          Код отправлен на номер {formatPhone(phone) || phone}
        </p>
        <FieldGroup>
          <Field data-invalid={Boolean(error)}>
            <FieldLabel htmlFor="otp-code">Код из сообщения</FieldLabel>
            <Input
              id="otp-code"
              value={code}
              inputMode="numeric"
              autoComplete="one-time-code"
              placeholder="123456"
              disabled={isSubmitting}
              aria-invalid={Boolean(error)}
              onChange={(event) => setCode(event.target.value)}
            />
            <FieldError>{error}</FieldError>
          </Field>
        </FieldGroup>
        <Button type="submit" disabled={isSubmitting}>
          {isSubmitting ? <Spinner data-icon="inline-start" /> : null}
          Войти
        </Button>
        <Button
          type="button"
          variant="ghost"
          disabled={isSubmitting}
          onClick={() => {
            setStep("phone");
            setCode("");
            setError("");
          }}
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
      <Button type="submit" disabled={isSubmitting}>
        {isSubmitting ? <Spinner data-icon="inline-start" /> : null}
        Получить код
      </Button>
    </form>
  );
}
