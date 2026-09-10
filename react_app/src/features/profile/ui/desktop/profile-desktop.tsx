"use client";

import {
  BellIcon,
  Building2Icon,
  SettingsIcon,
  UserRoundIcon,
  WalletIcon,
} from "lucide-react";

import { ErrorState } from "@/components/shared/error-state";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Tabs,
  TabsContent,
  TabsIndicator,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
import { ProfileHeader } from "@/features/profile/ui/profile-header";
import { ProfileAccessTab } from "@/features/profile/ui/tabs/profile-access-tab";
import { ProfileDetailsTab } from "@/features/profile/ui/tabs/profile-details-tab";
import { ProfileFinanceTab } from "@/features/profile/ui/tabs/profile-finance-tab";
import { ProfileNotificationsTab } from "@/features/profile/ui/tabs/profile-notifications-tab";
import { ProfileSystemTab } from "@/features/profile/ui/tabs/profile-system-tab";
import { useCurrentProfile } from "@/features/profile/hooks/use-current-profile";

export function ProfileDesktop() {
  const { data: profile, isLoading, isError, error } = useCurrentProfile();

  if (isLoading) {
    return <ProfileSkeleton />;
  }

  if (isError || !profile) {
    return (
      <div className="mx-auto w-full max-w-4xl py-6">
        <ErrorState
          title="Не удалось загрузить профиль"
          message={
            error instanceof Error
              ? error.message
              : "Произошла ошибка при получении данных профиля"
          }
        />
      </div>
    );
  }

  return (
    <div className="mx-auto flex w-full max-w-4xl min-w-0 flex-col gap-6 pb-12">
      <ProfileHeader profile={profile} />

      <Tabs defaultValue="details" className="flex flex-col gap-6">
        <div className="overflow-x-auto pb-1 -mx-1 px-1 sm:overflow-visible">
          <TabsList
            variant="pills"
            className="w-full justify-start min-w-[680px] sm:min-w-0"
          >
            <TabsTrigger value="details" className="gap-2">
              <UserRoundIcon className="size-4" />
              <span>Личные данные</span>
            </TabsTrigger>
            <TabsTrigger value="finance" className="gap-2">
              <WalletIcon className="size-4" />
              <span>Финансы</span>
            </TabsTrigger>
            <TabsTrigger value="notifications" className="gap-2">
              <BellIcon className="size-4" />
              <span>Уведомления</span>
            </TabsTrigger>
            <TabsTrigger value="access" className="gap-2">
              <Building2Icon className="size-4" />
              <span>Организация и доступ</span>
            </TabsTrigger>
            <TabsTrigger value="system" className="gap-2">
              <SettingsIcon className="size-4" />
              <span>Настройки и система</span>
            </TabsTrigger>
            <TabsIndicator />
          </TabsList>
        </div>

        <TabsContent value="details">
          <ProfileDetailsTab profile={profile} />
        </TabsContent>

        <TabsContent value="finance">
          <ProfileFinanceTab />
        </TabsContent>

        <TabsContent value="notifications">
          <ProfileNotificationsTab profile={profile} />
        </TabsContent>

        <TabsContent value="access">
          <ProfileAccessTab profile={profile} />
        </TabsContent>

        <TabsContent value="system">
          <ProfileSystemTab />
        </TabsContent>
      </Tabs>
    </div>
  );
}

function ProfileSkeleton() {
  return (
    <div className="mx-auto flex w-full max-w-4xl flex-col gap-6">
      <div className="flex flex-col gap-6 rounded-2xl bg-card p-6 ring-1 ring-foreground/10 sm:flex-row sm:items-start">
        <Skeleton className="size-32 rounded-2xl sm:size-36" />
        <div className="flex flex-1 flex-col gap-3">
          <Skeleton className="h-8 w-56" />
          <Skeleton className="h-5 w-40" />
          <Skeleton className="h-4 w-48" />
        </div>
      </div>
      <Skeleton className="h-10 w-full rounded-full" />
      <Skeleton className="h-72 w-full rounded-2xl" />
    </div>
  );
}
