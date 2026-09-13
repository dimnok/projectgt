"use client";

import { CheckCircle2Icon, HardHatIcon } from "lucide-react";
import { toast } from "sonner";

import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
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
import { ProfileMobileShell } from "@/features/profile/ui/mobile/profile-mobile-shell";
import { ProfileCompanyOutputNorm } from "@/features/profile/ui/shared/profile-company-output-norm";
import { membershipRoleLabel } from "@/features/profile/utils/profile.utils";

type ProfileAccessMobileProps = {
  profile: CurrentProfile;
  onBack: () => void;
};

export function ProfileAccessMobile({
  profile,
  onBack,
}: ProfileAccessMobileProps) {
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
    <ProfileMobileShell title="Организация" onBack={onBack}>
      <div className="flex flex-col gap-5">
        <div className="flex flex-col gap-4 rounded-2xl bg-card p-4 ring-1 ring-foreground/10">
          <div className="flex items-start justify-between gap-3">
            <div className="min-w-0">
              <p className="text-sm font-medium">
                {active?.companyName ?? "Организация не выбрана"}
              </p>
              <p className="mt-0.5 text-xs text-muted-foreground">
                {membershipRoleLabel(active)}
                {active?.isOwner ? " · Владелец" : ""}
              </p>
            </div>
            {active ? (
              <Badge variant={active.isActive ? "success" : "destructive"}>
                {active.isActive ? "Доступ есть" : "Нет доступа"}
              </Badge>
            ) : null}
          </div>

          {canSwitch ? (
            <div className="flex flex-col gap-2">
              <label
                htmlFor="company-select-mobile"
                className="text-xs font-medium text-muted-foreground"
              >
                Активная компания
              </label>
              <Select
                value={profile.lastCompanyId ?? undefined}
                items={companyItems}
                disabled={switchCompany.isPending}
                onValueChange={handleChangeCompany}
              >
                <SelectTrigger id="company-select-mobile" className="h-11 w-full">
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
              {switchCompany.isPending ? (
                <div className="flex items-center gap-2 text-xs text-muted-foreground">
                  <Spinner />
                  Переключение…
                </div>
              ) : null}
            </div>
          ) : null}
        </div>

        {active ? (
          <div className="flex flex-col gap-3 rounded-2xl bg-card p-4 ring-1 ring-foreground/10">
            <div>
              <p className="text-sm font-medium">Производство</p>
              <p className="mt-0.5 text-xs text-muted-foreground">
                Минимум выработки по организации, ₽ на человека в час.
              </p>
            </div>
            <ProfileCompanyOutputNorm profile={profile} compact />
          </div>
        ) : null}

        <div className="flex flex-col gap-3">
          <div className="flex items-center justify-between gap-2 px-1">
            <p className="text-sm font-medium">Объекты</p>
            <Badge variant="outline">{profile.objects.length}</Badge>
          </div>

          {profile.objects.length > 0 ? (
            <div className="flex flex-col overflow-hidden rounded-2xl bg-card ring-1 ring-foreground/10">
              {profile.objects.map((object, index) => (
                <div
                  key={object.id}
                  className={
                    index === 0
                      ? "flex items-center gap-3 px-3 py-3"
                      : "flex items-center gap-3 border-t px-3 py-3"
                  }
                >
                  <span className="flex size-9 shrink-0 items-center justify-center rounded-full bg-muted">
                    <HardHatIcon />
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-medium">{object.name}</p>
                    <p className="flex items-center gap-1 text-xs text-muted-foreground">
                      <CheckCircle2Icon className="size-3.5" />
                      Доступ активен
                    </p>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <Alert>
              <AlertTitle>Нет закреплённых объектов</AlertTitle>
              <AlertDescription>
                Назначение объектов делает руководитель компании.
              </AlertDescription>
            </Alert>
          )}
        </div>
      </div>
    </ProfileMobileShell>
  );
}
