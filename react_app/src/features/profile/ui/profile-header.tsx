"use client";

import { CheckIcon, CopyIcon, ShieldCheckIcon } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { ProfilePhoto } from "@/features/profile/ui/profile-photo";
import type { CurrentProfile } from "@/features/profile/types/profile.types";
import {
  formatJoinedDate,
  membershipRoleLabel,
  profileDisplayName,
} from "@/features/profile/utils/profile.utils";

type ProfileHeaderProps = {
  profile: CurrentProfile;
};

export function ProfileHeader({ profile }: ProfileHeaderProps) {
  const [copiedId, setCopiedId] = useState(false);
  const name = profileDisplayName(profile);
  const joined = formatJoinedDate(profile.createdAt);
  const activeCompany = profile.activeMembership;

  async function handleCopyId() {
    try {
      await navigator.clipboard.writeText(profile.id);
      setCopiedId(true);
      toast.success("ID пользователя скопирован");
      setTimeout(() => setCopiedId(false), 2000);
    } catch {
      toast.error("Не удалось скопировать");
    }
  }

  return (
    <div className="flex flex-col gap-6 rounded-2xl bg-card p-5 ring-1 ring-foreground/10 sm:flex-row sm:items-start sm:p-6">
      <ProfilePhoto profile={profile} />

      <div className="flex min-w-0 flex-1 flex-col gap-3">
        {/* Верхняя строка: Имя и статус */}
        <div className="flex flex-wrap items-center gap-3">
          <h2 className="font-heading text-xl font-medium tracking-tight sm:text-2xl">
            {name}
          </h2>
          {profile.shortName && profile.shortName !== profile.fullName ? (
            <span className="text-sm text-muted-foreground">
              ({profile.shortName})
            </span>
          ) : null}

          <div className="inline-flex items-center gap-1.5 rounded-full bg-emerald-500/10 px-2.5 py-0.5 text-xs font-medium text-emerald-600 dark:bg-emerald-500/20 dark:text-emerald-400">
            <span className="size-1.5 rounded-full bg-emerald-500" />
            Активен
          </div>
        </div>

        {/* Роли и компания */}
        <div className="flex flex-wrap items-center gap-2">
          <Badge variant="secondary" className="gap-1">
            <ShieldCheckIcon className="size-3 text-primary" />
            {membershipRoleLabel(activeCompany)}
          </Badge>

          {activeCompany ? (
            <Badge variant="outline">{activeCompany.companyName}</Badge>
          ) : null}

          {profile.position ? (
            <Badge variant="outline" className="text-muted-foreground">
              {profile.position}
            </Badge>
          ) : null}
        </div>

        {/* Системные метаданные (компактно, без дублирования контактов) */}
        <div className="mt-2 flex flex-wrap items-center gap-x-4 gap-y-1.5 text-xs text-muted-foreground">
          <div className="flex items-center gap-1">
            <span>ID:</span>
            <code className="rounded bg-muted px-1.5 py-0.5 font-mono text-[11px] text-foreground">
              {profile.id.slice(0, 8)}…{profile.id.slice(-4)}
            </code>
            <Button
              type="button"
              variant="ghost"
              size="icon-xs"
              className="size-5 rounded"
              aria-label="Скопировать полный ID"
              onClick={() => void handleCopyId()}
            >
              {copiedId ? (
                <CheckIcon className="size-3 text-emerald-600" />
              ) : (
                <CopyIcon className="size-3" />
              )}
            </Button>
          </div>

          {joined ? <span>В системе с {joined}</span> : null}
        </div>
      </div>
    </div>
  );
}
