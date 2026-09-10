"use client";

import {
  Building2Icon,
  CheckCircle2Icon,
  FolderKanbanIcon,
  HardHatIcon,
  ShieldCheckIcon,
} from "lucide-react";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Spinner } from "@/components/ui/spinner";
import { useSwitchActiveCompany } from "@/features/profile/hooks/use-current-profile";
import type { CurrentProfile } from "@/features/profile/types/profile.types";
import { membershipRoleLabel } from "@/features/profile/utils/profile.utils";

type ProfileAccessTabProps = {
  profile: CurrentProfile;
};

export function ProfileAccessTab({ profile }: ProfileAccessTabProps) {
  const switchCompany = useSwitchActiveCompany();
  const active = profile.activeMembership;
  const activeCompanies = profile.memberships.filter((item) => item.isActive);
  const canSwitch = activeCompanies.length > 1;

  const companyItems = activeCompanies.map((item) => ({
    value: item.companyId,
    label: item.companyName,
  }));

  function handleChangeCompany(companyId: string | null) {
    if (!companyId || companyId === profile.lastCompanyId) return;

    switchCompany.mutate(companyId, {
      onSuccess: () => toast.success("Активная организация переключена"),
      onError: (err) =>
        toast.error(
          err instanceof Error ? err.message : "Не удалось сменить организацию"
        ),
    });
  }

  return (
    <div className="flex flex-col gap-6">
      {/* 1. Текущая организация */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between gap-4">
            <div className="flex items-center gap-2">
              <Building2Icon className="size-4 text-primary" />
              <CardTitle>Организация и членство</CardTitle>
            </div>
            {active ? (
              <Badge variant={active.isActive ? "success" : "destructive"}>
                {active.isActive ? "Доступ активен" : "Доступ заблокирован"}
              </Badge>
            ) : null}
          </div>
          <CardDescription>
            Компания, в контексте которой отображаются сметы, договоры, объекты
            и сотрудники.
          </CardDescription>
        </CardHeader>

        <CardContent className="flex flex-col gap-4">
          {canSwitch ? (
            <div className="flex flex-col gap-2">
              <label
                htmlFor="company-select"
                className="text-xs font-medium text-muted-foreground"
              >
                Выберите активную компанию:
              </label>
              <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
                <div className="min-w-0 flex-1">
                  <Select
                    value={profile.lastCompanyId ?? undefined}
                    items={companyItems}
                    disabled={switchCompany.isPending}
                    onValueChange={handleChangeCompany}
                  >
                    <SelectTrigger id="company-select" className="w-full">
                      <SelectValue placeholder="Выберите организацию" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectGroup>
                        {companyItems.map((item) => (
                          <SelectItem key={item.value} value={item.value}>
                            {item.label}
                          </SelectItem>
                        ))}
                      </SelectGroup>
                    </SelectContent>
                  </Select>
                </div>
                {switchCompany.isPending ? (
                  <div className="flex items-center gap-2 text-xs text-muted-foreground">
                    <Spinner className="size-3.5" />
                    <span>Переключение…</span>
                  </div>
                ) : null}
              </div>
            </div>
          ) : (
            <div className="flex items-center justify-between rounded-lg border bg-muted/30 p-3">
              <div className="flex items-center gap-2.5">
                <Building2Icon className="size-5 text-muted-foreground" />
                <div>
                  <p className="font-medium text-foreground">
                    {active?.companyName ?? "Организация не выбрана"}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    Основная рабочая организация
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* Карточка роли в компании */}
          <div className="flex items-center justify-between rounded-lg border bg-muted/20 p-3">
            <div className="flex items-center gap-2.5">
              <ShieldCheckIcon className="size-5 text-primary" />
              <div>
                <p className="text-xs text-muted-foreground">Роль в компании</p>
                <p className="font-medium text-foreground">
                  {membershipRoleLabel(active)}
                </p>
              </div>
            </div>
            {active?.isOwner ? (
              <Badge variant="secondary">Владелец компании</Badge>
            ) : null}
          </div>
        </CardContent>
      </Card>

      {/* 2. Закрепленные объекты */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <FolderKanbanIcon className="size-4 text-primary" />
              <CardTitle>Закрепленные объекты</CardTitle>
            </div>
            <Badge variant="outline">
              {profile.objects.length > 0
                ? `${profile.objects.length} объектов`
                : "Нет объектов"}
            </Badge>
          </div>
          <CardDescription>
            Строительные площадки и проекты, на которые у вас открыт доступ для
            ведения смен и работ.
          </CardDescription>
        </CardHeader>

        <CardContent>
          {profile.objects.length > 0 ? (
            <div className="grid gap-2.5 sm:grid-cols-2">
              {profile.objects.map((object) => (
                <div
                  key={object.id}
                  className="flex items-center gap-3 rounded-lg border bg-card p-3 shadow-xs"
                >
                  <div className="flex size-8 shrink-0 items-center justify-center rounded-md bg-primary/10 text-primary">
                    <HardHatIcon className="size-4" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-medium text-foreground">
                      {object.name}
                    </p>
                    <p className="text-[11px] text-muted-foreground flex items-center gap-1">
                      <CheckCircle2Icon className="size-3 text-emerald-600" />
                      Доступ активен
                    </p>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="rounded-lg border border-dashed p-6 text-center text-sm text-muted-foreground">
              За вашим профилем пока не закреплено ни одного объекта.
              Назначение объектов осуществляется руководителем компании.
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
