"use client";

import { FolderKanbanIcon, LinkIcon, ShieldIcon, UnlinkIcon } from "lucide-react";

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCaption,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import type { CompanyUser } from "@/features/users/types/user.types";
import { UserPreferWebSwitch } from "@/features/users/ui/shared/user-prefer-web-switch";
import {
  userDisplayName,
  userInitials,
  userObjectNames,
} from "@/features/users/utils/user.utils";
import { formatPhone } from "@/lib/utils/phone";

type UsersListProps = {
  users: CompanyUser[];
  objects: { id: string; name: string }[];
  canLinkEmployee: boolean;
  canAssignObjects: boolean;
  canAssignRole: boolean;
  canPreferWebApp: boolean;
  onAssign: (user: CompanyUser) => void;
  onAssignRole: (user: CompanyUser) => void;
  onAssignObjects: (user: CompanyUser) => void;
};

function EmptyCell() {
  return <span className="text-muted-foreground">—</span>;
}

function ObjectsCell({
  objectIds,
  objects,
}: {
  objectIds: string[];
  objects: { id: string; name: string }[];
}) {
  const names = userObjectNames(objectIds, objects);
  if (names.length === 0) {
    return <EmptyCell />;
  }
  const visible = names.slice(0, 2).join(", ");
  const rest = names.length - 2;
  return (
    <p className="max-w-56 truncate text-sm" title={names.join(", ")}>
      {visible}
      {rest > 0 ? ` +${rest}` : ""}
    </p>
  );
}

export function UsersList({
  users,
  objects,
  canLinkEmployee,
  canAssignObjects,
  canAssignRole,
  canPreferWebApp,
  onAssign,
  onAssignRole,
  onAssignObjects,
}: UsersListProps) {
  return (
    <Card size="sm" className="gap-0 overflow-hidden py-0 shadow-float">
      <Table>
        <TableCaption className="sr-only">Список пользователей</TableCaption>
        <TableHeader>
          <TableRow className="hover:bg-transparent">
            <TableHead>Пользователь</TableHead>
            <TableHead>Роль</TableHead>
            <TableHead>Статус</TableHead>
            <TableHead>Карточка сотрудника</TableHead>
            <TableHead>Объекты</TableHead>
            <TableHead className="text-right">Новая версия</TableHead>
            <TableHead className="text-right">Действие</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {users.map((user) => {
            const name = userDisplayName(user);
            const phone = formatPhone(user.phone);

            return (
              <TableRow key={user.id}>
                <TableCell>
                  <div className="flex items-center gap-3">
                    <Avatar className="size-8">
                      {user.photoUrl ? (
                        <AvatarImage src={user.photoUrl} alt={name} />
                      ) : null}
                      <AvatarFallback>{userInitials(user)}</AvatarFallback>
                    </Avatar>
                    <div className="min-w-0">
                      <p className="truncate font-medium">{name}</p>
                      <p className="truncate text-xs text-muted-foreground">
                        {phone || user.email || "Контакт не указан"}
                      </p>
                    </div>
                  </div>
                </TableCell>
                <TableCell>
                  <Badge variant={user.isOwner ? "secondary" : "outline"}>
                    {user.roleName}
                  </Badge>
                </TableCell>
                <TableCell>
                  {user.isActive ? (
                    <Badge variant="outline" className="text-emerald-600">
                      Активен
                    </Badge>
                  ) : (
                    <Badge variant="secondary">Неактивен</Badge>
                  )}
                </TableCell>
                <TableCell>
                  {user.linkedEmployee ? (
                    <div className="min-w-0">
                      <p className="truncate font-medium">
                        {user.linkedEmployee.fullName}
                      </p>
                      <p className="truncate text-xs text-muted-foreground">
                        {user.linkedEmployee.position || "Должность не указана"}
                      </p>
                    </div>
                  ) : (
                    <EmptyCell />
                  )}
                </TableCell>
                <TableCell>
                  <ObjectsCell objectIds={user.objectIds} objects={objects} />
                </TableCell>
                <TableCell className="text-right">
                  <UserPreferWebSwitch
                    user={user}
                    canToggle={canPreferWebApp}
                  />
                </TableCell>
                <TableCell className="text-right">
                  <div className="flex flex-wrap justify-end gap-1.5">
                    {canAssignObjects ? (
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        className="gap-1.5"
                        onClick={() => onAssignObjects(user)}
                      >
                        <FolderKanbanIcon />
                        Объекты
                      </Button>
                    ) : null}
                    {canAssignRole ? (
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        className="gap-1.5"
                        onClick={() => onAssignRole(user)}
                      >
                        <ShieldIcon />
                        Роль
                      </Button>
                    ) : null}
                    {canLinkEmployee ? (
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        className="gap-1.5"
                        onClick={() => onAssign(user)}
                      >
                        {user.employeeId ? (
                          <UnlinkIcon />
                        ) : (
                          <LinkIcon />
                        )}
                        {user.employeeId ? "Сменить" : "Привязать"}
                      </Button>
                    ) : null}
                  </div>
                </TableCell>
              </TableRow>
            );
          })}
        </TableBody>
      </Table>
    </Card>
  );
}
