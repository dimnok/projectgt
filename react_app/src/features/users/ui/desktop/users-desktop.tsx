"use client";

import { useMemo, useState } from "react";

import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Loading } from "@/components/shared/loading";
import { useCurrentProfile } from "@/features/profile/hooks/use-current-profile";
import { useObjects } from "@/features/objects/hooks/use-objects";
import { ProfileEmployeeDialog } from "@/features/profile/ui/profile-employee-dialog";
import { useCompanyUsers } from "@/features/users/hooks/use-company-users";
import type {
  CompanyUser,
  CompanyUserLinkFilter,
} from "@/features/users/types/user.types";
import { UsersFilters } from "@/features/users/ui/desktop/users-filters";
import { UsersList } from "@/features/users/ui/desktop/users-list";
import { UsersSummary } from "@/features/users/ui/desktop/users-summary";
import { UserObjectsDialog } from "@/features/users/ui/shared/user-objects-dialog";
import { UserRoleDialog } from "@/features/users/ui/shared/user-role-dialog";
import { filterCompanyUsers, userDisplayName } from "@/features/users/utils/user.utils";
import { usePermissions } from "@/hooks/use-permissions";
import { useAppSearch, AppSearchField } from "@/layouts/desktop/app-search";

export function UsersDesktop() {
  const { data: profile, isLoading: profileLoading } = useCurrentProfile();
  const { can, isOwner } = usePermissions();
  const { data, isLoading, isError, error } = useCompanyUsers();
  const objectsQuery = useObjects();
  const objects = objectsQuery.data ?? [];
  const { query } = useAppSearch();
  const [link, setLink] = useState<CompanyUserLinkFilter>("all");
  const [editor, setEditor] = useState<CompanyUser | null>(null);
  const [roleEditor, setRoleEditor] = useState<CompanyUser | null>(null);
  const [objectsEditor, setObjectsEditor] = useState<CompanyUser | null>(null);

  const canRead = can("users", "read");
  const canLinkEmployee = Boolean(profile?.canManageUsers);
  const canAssignObjects = canLinkEmployee && objectsQuery.isSuccess;
  const canAssignRole = isOwner;

  const objectNames = useMemo(
    () => new Map(objects.map((object) => [object.id, object.name])),
    [objects]
  );

  const users = useMemo(
    () =>
      filterCompanyUsers(data ?? [], {
        search: query,
        link,
        objectNames,
      }),
    [data, query, link, objectNames]
  );

  if (profileLoading) {
    return <Loading />;
  }

  if (!canRead) {
    return (
      <ErrorState
        title="Нет доступа"
        message="У вашей роли нет права открывать список пользователей."
      />
    );
  }

  if (isLoading) {
    return <Loading />;
  }

  if (isError) {
    return (
      <ErrorState
        title="Не удалось загрузить пользователей"
        message={error instanceof Error ? error.message : "Неизвестная ошибка"}
      />
    );
  }

  const companyName = profile?.activeMembership?.companyName || "компания";

  return (
    <div className="grid min-h-fit min-w-0 w-full flex-1 grid-cols-1 content-start items-start gap-3 lg:grid-cols-[minmax(0,1fr)_var(--content-aside-width)] lg:gap-6">
      <div className="min-w-0">
        {users.length === 0 ? (
          <EmptyState
            title="Пользователи не найдены"
            description="Измените фильтр или поисковый запрос."
          />
        ) : (
          <UsersList
            users={users}
            objects={objects}
            canLinkEmployee={canLinkEmployee}
            canAssignObjects={canAssignObjects}
            canAssignRole={canAssignRole}
            canPreferWebApp={canLinkEmployee}
            onAssign={setEditor}
            onAssignRole={setRoleEditor}
            onAssignObjects={setObjectsEditor}
          />
        )}
      </div>

      <div className="flex min-w-0 flex-col gap-3 lg:sticky lg:top-0 lg:self-start lg:gap-6">
        <div className="flex min-w-0 flex-col gap-2">
          <AppSearchField
            variant="aside"
            placeholder="Поиск по имени, почте, телефону..."
            aria-label="Поиск по пользователям"
          />
          <UsersFilters link={link} onLinkChange={setLink} />
        </div>
        <UsersSummary users={data ?? []} />
      </div>

      {editor ? (
        <ProfileEmployeeDialog
          open
          onOpenChange={(open) => {
            if (!open) {
              setEditor(null);
            }
          }}
          userId={editor.id}
          userName={userDisplayName(editor)}
          currentEmployeeId={editor.employeeId}
          companyName={companyName}
        />
      ) : null}

      <UserRoleDialog
        user={roleEditor}
        onOpenChange={(open) => {
          if (!open) {
            setRoleEditor(null);
          }
        }}
      />

      <UserObjectsDialog
        user={objectsEditor}
        objects={objects}
        onOpenChange={(open) => {
          if (!open) {
            setObjectsEditor(null);
          }
        }}
      />
    </div>
  );
}
