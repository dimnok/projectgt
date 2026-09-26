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
  CompanyUserSort,
} from "@/features/users/types/user.types";
import { UsersFilters } from "@/features/users/ui/desktop/users-filters";
import { UsersList } from "@/features/users/ui/desktop/users-list";
import { UserObjectsDialog } from "@/features/users/ui/shared/user-objects-dialog";
import { UserRoleDialog } from "@/features/users/ui/shared/user-role-dialog";
import { UserStatusDialog } from "@/features/users/ui/shared/user-status-dialog";
import {
  filterCompanyUsers,
  sortCompanyUsers,
  userDisplayName,
} from "@/features/users/utils/user.utils";
import { usePermissions } from "@/hooks/use-permissions";
import { useAppSearch, AppSearchField } from "@/layouts/desktop/app-search";

export function UsersDesktop() {
  const { data: profile, isLoading: profileLoading } = useCurrentProfile();
  const { can, isOwner } = usePermissions();
  const { data, isLoading, isError, error } = useCompanyUsers();
  const objectsQuery = useObjects();
  const objects = useMemo(() => objectsQuery.data ?? [], [objectsQuery.data]);
  const { query } = useAppSearch();
  const [link, setLink] = useState<CompanyUserLinkFilter>("all");
  const [sort, setSort] = useState<CompanyUserSort>(null);
  const [editor, setEditor] = useState<CompanyUser | null>(null);
  const [roleEditor, setRoleEditor] = useState<CompanyUser | null>(null);
  const [objectsEditor, setObjectsEditor] = useState<CompanyUser | null>(null);
  const [statusEditor, setStatusEditor] = useState<CompanyUser | null>(null);

  const canRead = can("users", "read");
  const canLinkEmployee = Boolean(profile?.canManageUsers);
  const canAssignObjects = canLinkEmployee && objectsQuery.isSuccess;
  const canAssignRole = isOwner;
  const canChangeStatus = isOwner;

  const objectNames = useMemo(
    () => new Map(objects.map((object) => [object.id, object.name])),
    [objects]
  );

  const users = useMemo(
    () =>
      sortCompanyUsers(
        filterCompanyUsers(data ?? [], {
          search: query,
          link,
          objectNames,
        }),
        sort
      ),
    [data, query, link, objectNames, sort]
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
  const total = data?.length ?? 0;
  const isFiltered = users.length !== total;

  return (
    <div
      data-fill-viewport
      className="flex h-full min-h-0 min-w-0 w-full flex-1 flex-col gap-3"
    >
      <div className="flex min-w-0 shrink-0 flex-wrap items-center gap-2">
        <AppSearchField
          className="min-w-64 flex-1"
          placeholder="Поиск по имени, почте, телефону..."
          aria-label="Поиск по пользователям"
        />
        <UsersFilters link={link} onLinkChange={setLink} />
        <p className="ml-auto shrink-0 pl-2 text-xs text-muted-foreground tabular-nums max-lg:hidden">
          {isFiltered ? `Найдено: ${users.length} из ${total}` : `Всего: ${total}`}
        </p>
      </div>

      {users.length === 0 ? (
        <div className="flex min-h-0 w-full flex-1 items-center justify-center rounded-xl bg-card p-6 shadow-float ring-1 ring-foreground/10">
          <EmptyState
            title="Пользователи не найдены"
            description="Измените фильтр или поисковый запрос."
          />
        </div>
      ) : (
        <UsersList
          users={users}
          objects={objects}
          canLinkEmployee={canLinkEmployee}
          canAssignObjects={canAssignObjects}
          canAssignRole={canAssignRole}
          canChangeStatus={canChangeStatus}
          canPreferWebApp={canLinkEmployee}
          sort={sort}
          onSortChange={setSort}
          onAssign={setEditor}
          onAssignRole={setRoleEditor}
          onAssignObjects={setObjectsEditor}
          onChangeStatus={setStatusEditor}
        />
      )}

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

      <UserStatusDialog
        user={statusEditor}
        onOpenChange={(open) => {
          if (!open) {
            setStatusEditor(null);
          }
        }}
      />
    </div>
  );
}
