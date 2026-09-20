"use client";

import { useState } from "react";
import { CheckIcon, CopyIcon, PhoneIcon } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { formatPhone, normalizeRuPhoneE164 } from "@/lib/utils/phone";

type EmployeePhoneActionsProps = {
  phone: string;
};

function telHref(phone: string) {
  const normalized = normalizeRuPhoneE164(phone);
  if (normalized) {
    return `tel:${normalized}`;
  }
  return `tel:${phone.replace(/\D/g, "")}`;
}

export function EmployeePhoneActions({ phone }: EmployeePhoneActionsProps) {
  const [copied, setCopied] = useState(false);
  const display = formatPhone(phone) || phone;
  const href = telHref(phone);

  function copyNumber() {
    void navigator.clipboard.writeText(display);
    setCopied(true);
    toast.success("Номер скопирован");
    window.setTimeout(() => setCopied(false), 2000);
  }

  return (
    <div className="flex min-w-0 flex-wrap items-center gap-2">
      <span className="inline-flex min-w-0 max-w-full items-center rounded-full border border-border/80 bg-background px-3 py-1 text-xs font-semibold shadow-2xs">
        <span className="truncate">{display}</span>
      </span>
      <div className="flex shrink-0 items-center gap-2">
        <Button
          nativeButton={false}
          render={<a href={href} />}
          size="icon"
          className="rounded-full"
          aria-label={`Позвонить ${display}`}
        >
          <PhoneIcon />
        </Button>
        <Button
          type="button"
          variant="outline"
          size="icon"
          className="rounded-full"
          aria-label="Скопировать номер"
          onClick={copyNumber}
        >
          {copied ? <CheckIcon /> : <CopyIcon />}
        </Button>
      </div>
    </div>
  );
}
