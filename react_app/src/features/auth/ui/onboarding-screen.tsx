"use client";

import { Building2Icon, ChevronLeftIcon, UserPlusIcon } from "lucide-react";
import { useState, type ReactNode } from "react";

import { Button } from "@/components/ui/button";
import { AuthFlowShell } from "@/features/auth/ui/auth-flow-shell";
import { CompanyCreateForm } from "@/features/company/ui/company-create-form";
import { CompanyJoinForm } from "@/features/company/ui/company-join-form";
import { signOut } from "@/lib/supabase/auth";

type Mode = "choice" | "create" | "join";

/**
 * Онбординг: создание организации или вступление по коду.
 * Как `OnboardingScreen` в приложении.
 */
export function OnboardingScreen() {
  const [mode, setMode] = useState<Mode>("choice");

  if (mode === "choice") {
    return (
      <AuthFlowShell className="max-w-2xl">
        <div className="flex flex-col gap-6">
          <div className="flex flex-col gap-2 text-center">
            <h1 className="font-heading text-2xl font-medium">Начало работы</h1>
            <p className="text-sm text-muted-foreground">
              Создайте новую организацию или вступите в существующую по коду
              приглашения.
            </p>
          </div>
          <div className="grid gap-4 sm:grid-cols-2">
            <ChoiceCard
              icon={<Building2Icon className="size-5" />}
              title="Создать организацию"
              description="Вы станете владельцем и сможете приглашать сотрудников."
              onClick={() => setMode("create")}
            />
            <ChoiceCard
              icon={<UserPlusIcon className="size-5" />}
              title="Вступить по коду"
              description="Есть код приглашения от руководителя организации."
              onClick={() => setMode("join")}
            />
          </div>
          <div className="flex justify-center">
            <Button type="button" variant="ghost" onClick={() => void signOut()}>
              Выйти из аккаунта
            </Button>
          </div>
        </div>
      </AuthFlowShell>
    );
  }

  const isCreate = mode === "create";

  return (
    <AuthFlowShell className={isCreate ? "max-w-2xl" : "max-w-md"}>
      <div className="flex flex-col gap-6">
        <div className="flex items-center gap-2">
          <Button
            type="button"
            variant="ghost"
            size="icon"
            aria-label="Назад"
            onClick={() => setMode("choice")}
          >
            <ChevronLeftIcon />
          </Button>
          <h1 className="font-heading text-xl font-medium">
            {isCreate ? "Создать организацию" : "Вступить в организацию"}
          </h1>
        </div>
        {isCreate ? <CompanyCreateForm /> : <CompanyJoinForm />}
      </div>
    </AuthFlowShell>
  );
}

type ChoiceCardProps = {
  icon: ReactNode;
  title: string;
  description: string;
  onClick: () => void;
};

function ChoiceCard({ icon, title, description, onClick }: ChoiceCardProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="flex flex-col gap-2 rounded-xl bg-card p-5 text-left ring-1 ring-foreground/10 transition-colors hover:bg-muted/40"
    >
      <span className="flex size-10 items-center justify-center rounded-lg bg-primary/10 text-primary">
        {icon}
      </span>
      <span className="font-heading text-base font-medium">{title}</span>
      <span className="text-sm text-muted-foreground">{description}</span>
    </button>
  );
}
