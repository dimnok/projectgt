"use client";

import { useState } from "react";
import {
  BellIcon,
  Building2Icon,
  SettingsIcon,
  UserRoundIcon,
  WalletIcon,
} from "lucide-react";

import { ErrorState } from "@/components/shared/error-state";
import { Skeleton } from "@/components/ui/skeleton";
import { useCurrentProfile } from "@/features/profile/hooks/use-current-profile";
import type { CurrentProfile } from "@/features/profile/types/profile.types";
import { ProfileAccessMobile } from "@/features/profile/ui/mobile/profile-access-mobile";
import { ProfileDetailsMobile } from "@/features/profile/ui/mobile/profile-details-mobile";
import { ProfileFinanceMobile } from "@/features/profile/ui/mobile/profile-finance-mobile";
import {
  ProfileMobileGroup,
  ProfileMobileRow,
} from "@/features/profile/ui/mobile/profile-mobile-group";
import { ProfileMobileShell } from "@/features/profile/ui/mobile/profile-mobile-shell";
import { ProfileNotificationsMobile } from "@/features/profile/ui/mobile/profile-notifications-mobile";
import { ProfilePhotoMobile } from "@/features/profile/ui/mobile/profile-photo-mobile";
import { ProfileSystemMobile } from "@/features/profile/ui/mobile/profile-system-mobile";
import {
  membershipRoleLabel,
  profileDisplayName,
} from "@/features/profile/utils/profile.utils";

type ProfileMobileSection =
  | "home"
  | "details"
  | "finance"
  | "notifications"
  | "access"
  | "system";

export function ProfileMobile() {
  const { data: profile, isLoading, isError, error } = useCurrentProfile();
  const [section, setSection] = useState<ProfileMobileSection>("home");

  if (isLoading) {
    return (
      <ProfileMobileShell title="Профиль">
        <ProfileMobileSkeleton />
      </ProfileMobileShell>
    );
  }

  if (isError || !profile) {
    return (
      <ProfileMobileShell title="Профиль">
        <ErrorState
          title="Не удалось загрузить профиль"
          message={
            error instanceof Error
              ? error.message
              : "Произошла ошибка при получении данных профиля"
          }
        />
      </ProfileMobileShell>
    );
  }

  if (section === "details") {
    return (
      <ProfileDetailsMobile
        profile={profile}
        onBack={() => setSection("home")}
      />
    );
  }

  if (section === "finance") {
    return <ProfileFinanceMobile onBack={() => setSection("home")} />;
  }

  if (section === "notifications") {
    return (
      <ProfileNotificationsMobile
        profile={profile}
        onBack={() => setSection("home")}
      />
    );
  }

  if (section === "access") {
    return (
      <ProfileAccessMobile
        profile={profile}
        onBack={() => setSection("home")}
      />
    );
  }

  if (section === "system") {
    return <ProfileSystemMobile onBack={() => setSection("home")} />;
  }

  return <ProfileMobileHome profile={profile} onOpen={setSection} />;
}

type ProfileMobileHomeProps = {
  profile: CurrentProfile;
  onOpen: (section: ProfileMobileSection) => void;
};

function ProfileMobileHome({ profile, onOpen }: ProfileMobileHomeProps) {
  const name = profileDisplayName(profile);
  const activeCompany = profile.activeMembership;
  const objectsCount = profile.objects.length;
  const subtitle = [profile.position || membershipRoleLabel(activeCompany), activeCompany?.companyName]
    .filter(Boolean)
    .join(" · ");

  return (
    <ProfileMobileShell title="Профиль">
      <div className="flex flex-col gap-5">
        <div className="flex flex-col items-center gap-3 pt-1 pb-1">
          <ProfilePhotoMobile profile={profile} />
          <div className="flex min-w-0 flex-col items-center gap-1 text-center">
            <h2 className="font-heading text-xl font-medium tracking-tight">
              {name}
            </h2>
            {subtitle ? (
              <p className="max-w-[20rem] text-sm text-muted-foreground">
                {subtitle}
              </p>
            ) : null}
          </div>
        </div>

        <ProfileMobileGroup>
          <ProfileMobileRow
            icon={UserRoundIcon}
            title="Личные данные"
            subtitle="ФИО, телефон и карточка сотрудника"
            onClick={() => onOpen("details")}
          />
          <ProfileMobileRow
            icon={WalletIcon}
            title="Финансы"
            subtitle="Часы, премии, штрафы и выплаты"
            onClick={() => onOpen("finance")}
          />
          <ProfileMobileRow
            icon={BellIcon}
            title="Уведомления"
            subtitle={reminderSlotsSubtitle(profile.slotTimes.length)}
            onClick={() => onOpen("notifications")}
          />
          <ProfileMobileRow
            icon={Building2Icon}
            title="Организация"
            subtitle={
              objectsCount > 0
                ? `${activeCompany?.companyName ?? "Компания"} · ${objectsCount} объектов`
                : (activeCompany?.companyName ?? "Нет активной компании")
            }
            onClick={() => onOpen("access")}
          />
        </ProfileMobileGroup>

        <ProfileMobileGroup>
          <ProfileMobileRow
            icon={SettingsIcon}
            title="Настройки"
            subtitle="Тема, версия и выход"
            onClick={() => onOpen("system")}
          />
        </ProfileMobileGroup>
      </div>
    </ProfileMobileShell>
  );
}

function reminderSlotsSubtitle(count: number) {
  if (count <= 0) {
    return "Напоминания выключены";
  }

  const mod10 = count % 10;
  const mod100 = count % 100;
  if (mod10 === 1 && mod100 !== 11) {
    return `${count} слот напоминаний`;
  }
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return `${count} слота напоминаний`;
  }
  return `${count} слотов напоминаний`;
}

function ProfileMobileSkeleton() {
  return (
    <div className="flex flex-col items-center gap-5">
      <Skeleton className="size-24 rounded-full" />
      <Skeleton className="h-7 w-48" />
      <Skeleton className="h-5 w-32" />
      <Skeleton className="h-36 w-full rounded-2xl" />
      <Skeleton className="h-16 w-full rounded-2xl" />
    </div>
  );
}
