"use client";

import type { ComponentProps } from "react";

import { Input } from "@/components/ui/input";
import { formatPhoneInput } from "@/lib/utils/phone";

type PhoneInputProps = Omit<
  ComponentProps<typeof Input>,
  "type" | "value" | "onChange" | "inputMode"
> & {
  value: string;
  onValueChange: (value: string) => void;
};

export function PhoneInput({
  value,
  onValueChange,
  placeholder = "+7 900 000 00 00",
  ...props
}: PhoneInputProps) {
  return (
    <Input
      type="tel"
      inputMode="tel"
      autoComplete="tel"
      placeholder={placeholder}
      value={formatPhoneInput(value)}
      onChange={(event) => onValueChange(formatPhoneInput(event.target.value))}
      {...props}
    />
  );
}
