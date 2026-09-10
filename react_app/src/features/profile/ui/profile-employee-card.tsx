"use client";

import {
  InfoIcon,
  PhoneIcon,
  UserCheckIcon,
  UserXIcon,
} from "lucide-react";

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { EmployeeStatusBadge } from "@/features/employees/ui/shared/employee-status-badge";
import {
  employeeEmploymentLabel,
  isEmployeeEmploymentType,
} from "@/features/employees/utils/employee-employment";
import { isEmployeeStatus } from "@/features/employees/utils/employee-status";
import type { CurrentProfile } from "@/features/profile/types/profile.types";
import { profileInitials } from "@/features/profile/utils/profile.utils";

type ProfileEmployeeCardProps = {
  profile: CurrentProfile;
};

export function ProfileEmployeeCard({ profile }: ProfileEmployeeCardProps) {
  const linked = profile.linkedEmployee;
  const companyName =
    profile.activeMembership?.companyName || "активная организация";

  return (
    <Card>
      <CardHeader className="gap-2">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <div className="flex items-center gap-2">
            {linked ? (
              <UserCheckIcon className="size-4.5 text-primary" />
            ) : (
              <UserXIcon className="size-4.5 text-muted-foreground" />
            )}
            <CardTitle>Связь с карточкой сотрудника</CardTitle>
          </div>
          {linked ? (
            <Badge variant="outline" className="gap-1 border-primary/30 text-primary">
              <span className="size-1.5 rounded-full bg-primary inline-block" />
              Синхронизировано
            </Badge>
          ) : (
            <Badge variant="secondary" className="gap-1 text-muted-foreground">
              Не привязано
            </Badge>
          )}
        </div>
        <CardDescription>
          Карточка нужна для смен, табеля и зарплаты. Назначить или сменить её
          может только супер-админ или руководитель.
        </CardDescription>
      </CardHeader>

      <CardContent>
        {linked ? (
          <div className="flex items-center gap-3.5 p-4 rounded-xl border bg-muted/20">
            <Avatar className="size-12 shrink-0 border">
              {linked.photoUrl ? (
                <AvatarImage src={linked.photoUrl} alt={linked.fullName} />
              ) : null}
              <AvatarFallback className="text-base font-semibold">
                {profileInitials(linked.fullName)}
              </AvatarFallback>
            </Avatar>

            <div className="min-w-0 flex-1">
              <p className="font-semibold text-base text-foreground leading-snug truncate">
                {linked.fullName}
              </p>

              <div className="flex flex-wrap items-center gap-1.5 mt-1">
                {linked.position ? (
                  <Badge variant="outline" className="font-normal text-xs">
                    {linked.position}
                  </Badge>
                ) : null}

                {isEmployeeStatus(linked.status) ? (
                  <EmployeeStatusBadge status={linked.status} />
                ) : null}

                {isEmployeeEmploymentType(linked.employmentType) ? (
                  <Badge variant="secondary" className="text-[11px] font-normal">
                    {employeeEmploymentLabel(linked.employmentType)}
                  </Badge>
                ) : null}
              </div>

              {linked.phone ? (
                <div className="flex items-center gap-1 text-xs text-muted-foreground mt-1.5">
                  <PhoneIcon className="size-3" />
                  <a
                    href={`tel:${linked.phone}`}
                    className="hover:underline font-mono"
                  >
                    {linked.phone}
                  </a>
                </div>
              ) : null}
            </div>
          </div>
        ) : (
          <div className="flex items-start gap-3 p-4 rounded-xl border border-dashed bg-muted/20">
            <div className="p-2 rounded-lg bg-muted text-muted-foreground shrink-0 mt-0.5">
              <InfoIcon className="size-4" />
            </div>
            <div className="space-y-0.5">
              <p className="text-sm font-medium text-foreground">
                Карточка сотрудника не назначена
              </p>
              <p className="text-xs text-muted-foreground max-w-md">
                Профиль ещё не сопоставлен со штатной единицей в «{companyName}».
                Обратитесь к руководителю — сам пользователь эту связь не меняет.
              </p>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
